import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:nocterm/src/binding/scheduler_phase.dart';
import 'package:nocterm/src/foundation/nocterm_error.dart';
import 'package:nocterm/src/foundation/performance.dart';
import 'package:nocterm/src/framework/framework.dart';

/// Signature for frame callbacks.
///
/// The [timeStamp] is the current time when the frame begins.
typedef FrameCallback = void Function(Duration timeStamp);

/// Entry for a transient frame callback that can be cancelled.
class _FrameCallbackEntry {
  _FrameCallbackEntry(this.callback, {this.debugLabel});

  final FrameCallback callback;
  final String? debugLabel;
  bool cancelled = false;
}

/// Scheduler for coordinating frame callbacks and managing frame lifecycle.
///
/// This mixin provides the frame scheduling mechanism that prevents excessive
/// rendering work when rapid events arrive (e.g., scroll events, rapid key presses).
///
/// ## Frame Phases
///
/// Each frame progresses through distinct phases:
/// 1. [SchedulerPhase.transientCallbacks] - Animations and tickers
/// 2. [SchedulerPhase.midFrameMicrotasks] - Microtask processing
/// 3. [SchedulerPhase.persistentCallbacks] - Build, layout, paint pipeline
/// 4. [SchedulerPhase.postFrameCallbacks] - Cleanup and deferred work
///
/// ## Frame Batching
///
/// Multiple calls to [scheduleFrame] are collapsed into a single frame via
/// the [_hasScheduledFrame] flag. This ensures that:
/// - 100 rapid scroll events → 1 rebuild
/// - Multiple setState() calls → 1 render
/// - Efficient terminal updates under event floods
///
/// ## Usage
///
/// ```dart
/// // Schedule a frame (idempotent - multiple calls = 1 frame)
/// binding.scheduleFrame();
///
/// // Register animation callback
/// final id = binding.scheduleFrameCallback((timeStamp) {
///   updateAnimation(timeStamp);
/// });
///
/// // Cancel animation
/// binding.cancelFrameCallbackWithId(id);
///
/// // Post-frame cleanup
/// binding.addPostFrameCallback((timeStamp) {
///   // Runs after frame completes
/// });
/// ```
mixin SchedulerBinding on NoctermBinding {
  @override
  void initializeBinding() {
    super.initializeBinding();
    _instance = this;
  }

  static SchedulerBinding? _instance;

  /// The current [SchedulerBinding] instance.
  static SchedulerBinding get instance {
    assert(
      _instance != null,
      'SchedulerBinding has not been initialized.\n'
      'Ensure runApp() has been called to initialize the binding.',
    );
    return _instance!;
  }

  // --- Performance Tracking ---

  final List<FrameTimingCallback> _frameTimingCallbacks = [];
  int _frameNumber = 0;
  DateTime? _lastFrameTime;

  /// Target frame duration (default: 60fps = ~16.67ms).
  Duration targetFrameDuration = const Duration(microseconds: 16667);

  /// Whether to enable frame rate limiting to prevent CPU saturation.
  ///
  /// When true, frames are throttled to approximately [targetFrameDuration].
  /// When false, frames render as fast as possible (may cause 100% CPU).
  bool enableFrameRateLimiting = true;

  /// Register a callback to receive frame timing data.
  ///
  /// The callback is invoked after each frame completes with detailed
  /// timing information about build, layout, and paint phases.
  ///
  /// Use this to detect slow frames and monitor performance:
  /// ```dart
  /// binding.addFrameTimingCallback((timing) {
  ///   if (timing.isSlowFrame) {
  ///     print('Slow frame detected: $timing');
  ///   }
  /// });
  /// ```
  void addFrameTimingCallback(FrameTimingCallback callback) {
    _frameTimingCallbacks.add(callback);
  }

  /// Remove a frame timing callback.
  void removeFrameTimingCallback(FrameTimingCallback callback) {
    _frameTimingCallbacks.remove(callback);
  }

  void _reportFrameTiming(FrameTiming timing) {
    for (final callback in List.of(_frameTimingCallbacks)) {
      try {
        callback(timing);
      } catch (e, stack) {
        NoctermError.reportError(
          NoctermErrorDetails(
            exception: e,
            stack: stack,
            library: 'nocterm scheduler',
            context: 'during frame timing callback',
          ),
        );
      }
    }
  }

  /// Current phase of frame processing.
  ///
  /// This transitions through [SchedulerPhase] values during each frame.
  SchedulerPhase get schedulerPhase => _schedulerPhase;
  SchedulerPhase _schedulerPhase = SchedulerPhase.idle;

  /// Whether a frame has been scheduled but not yet executed.
  ///
  /// This flag prevents scheduling multiple frames redundantly.
  bool get hasScheduledFrame => _hasScheduledFrame;
  bool _hasScheduledFrame = false;

  /// The current frame timestamp.
  ///
  /// Available during frame processing. Represents microseconds since epoch.
  Duration? get currentFrameTimeStamp => _currentFrameTimeStamp;
  Duration? _currentFrameTimeStamp;

  /// The current system time.
  ///
  /// This is updated at the start of each frame.
  Duration get currentSystemFrameTimeStamp => _currentSystemFrameTimeStamp;
  Duration _currentSystemFrameTimeStamp = Duration.zero;

  // --- Transient Callbacks ---

  final Map<int, _FrameCallbackEntry> _transientCallbacks =
      <int, _FrameCallbackEntry>{};
  int _nextFrameCallbackId = 0;

  /// Registers a transient frame callback.
  ///
  /// Transient callbacks execute during the [SchedulerPhase.transientCallbacks]
  /// phase and are automatically removed after execution.
  ///
  /// Returns a callback ID that can be used with [cancelFrameCallbackWithId].
  ///
  /// Typically used for animations via [Ticker].
  ///
  /// Example:
  /// ```dart
  /// final callbackId = binding.scheduleFrameCallback((timeStamp) {
  ///   // Update animation based on timeStamp
  ///   position += velocity * deltaTime;
  /// });
  /// ```
  int scheduleFrameCallback(
    FrameCallback callback, {
    bool rescheduling = false,
    String? debugLabel,
  }) {
    final int id = _nextFrameCallbackId++;
    _transientCallbacks[id] = _FrameCallbackEntry(
      callback,
      debugLabel: debugLabel,
    );
    if (!rescheduling) {
      scheduleFrame();
    }
    return id;
  }

  /// Cancels a transient frame callback.
  ///
  /// The callback with the given [id] will not execute, even if a frame
  /// has already been scheduled.
  void cancelFrameCallbackWithId(int id) {
    final entry = _transientCallbacks[id];
    if (entry != null) {
      entry.cancelled = true;
    }
  }

  /// Removes all cancelled transient callbacks.
  void _removeCompletedCallbacks() {
    _transientCallbacks.removeWhere((key, entry) => entry.cancelled);
  }

  // --- Persistent Callbacks ---

  final List<FrameCallback> _persistentCallbacks = <FrameCallback>[];

  /// Registers a persistent frame callback.
  ///
  /// Persistent callbacks execute during [SchedulerPhase.persistentCallbacks]
  /// on **every frame** and cannot be unregistered.
  ///
  /// These drive the rendering pipeline (build, layout, paint).
  ///
  /// Example:
  /// ```dart
  /// binding.addPersistentFrameCallback((timeStamp) {
  ///   // This runs every frame
  ///   buildOwner.buildScope(rootElement);
  /// });
  /// ```
  void addPersistentFrameCallback(FrameCallback callback) {
    _persistentCallbacks.add(callback);
  }

  // --- Post-Frame Callbacks ---

  final Queue<FrameCallback> _postFrameCallbacks = Queue<FrameCallback>();

  /// Registers a post-frame callback.
  ///
  /// Post-frame callbacks execute during [SchedulerPhase.postFrameCallbacks]
  /// **after** the frame completes. They run exactly once.
  ///
  /// Useful for:
  /// - Cleanup after first render
  /// - Scheduling work for next frame
  /// - Reading layout information after layout completes
  ///
  /// Example:
  /// ```dart
  /// binding.addPostFrameCallback((timeStamp) {
  ///   // Read layout information
  ///   final height = renderBox.size.height;
  ///   // Schedule setState for next frame
  ///   setState(() => measuredHeight = height);
  /// });
  /// ```
  void addPostFrameCallback(FrameCallback callback) {
    _postFrameCallbacks.add(callback);
  }

  // --- Frame Scheduling ---

  /// Schedules a frame to be rendered.
  ///
  /// This method is idempotent - calling it multiple times before the frame
  /// executes will only schedule a single frame.
  ///
  /// The frame will execute asynchronously via [Timer.run], which places it
  /// on the event loop. In the future, this may use vsync-like timing for
  /// more precise frame pacing.
  ///
  /// Example flow:
  /// ```dart
  /// // User scrolls rapidly
  /// onScroll(event1); // setState() → scheduleFrame() [frame scheduled]
  /// onScroll(event2); // setState() → scheduleFrame() [no-op, already scheduled]
  /// onScroll(event3); // setState() → scheduleFrame() [no-op, already scheduled]
  /// // ... (100 more events)
  ///
  /// // Event loop processes one frame:
  /// handleBeginFrame();  // Transient callbacks
  /// handleDrawFrame();   // Build/layout/paint ONCE
  /// ```
  @override
  void scheduleFrame() {
    if (_hasScheduledFrame) {
      return; // Frame already scheduled
    }
    _hasScheduledFrame = true;
    scheduleFrameImpl();
  }

  /// Platform-specific frame scheduling implementation.
  ///
  /// Schedules frames with optional frame rate limiting to prevent CPU saturation.
  /// When [enableFrameRateLimiting] is true, enforces [targetFrameDuration] between frames.
  ///
  /// Subclasses can override for different timing strategies (e.g., vsync).
  @protected
  void scheduleFrameImpl() {
    if (enableFrameRateLimiting && _lastFrameTime != null) {
      final now = DateTime.now();
      final elapsed = now.difference(_lastFrameTime!);

      if (elapsed < targetFrameDuration) {
        // Too soon, delay the frame
        final delay = targetFrameDuration - elapsed;
        Timer(delay, () {
          _executeFrame();
        });
        return;
      }
    }

    // Execute frame immediately
    Timer.run(_executeFrame);
  }

  void _executeFrame() {
    _lastFrameTime = DateTime.now();
    final timeStamp = Duration(
      microseconds: _lastFrameTime!.microsecondsSinceEpoch,
    );
    handleBeginFrame(timeStamp);
  }

  /// Ensures a visual update occurs.
  ///
  /// If the scheduler is idle, this schedules a frame.
  /// If a frame is already in progress, this is a no-op.
  ///
  /// Used by build and paint systems to request rendering.
  void ensureVisualUpdate() {
    switch (schedulerPhase) {
      case SchedulerPhase.idle:
      case SchedulerPhase.postFrameCallbacks:
        scheduleFrame();
        return;
      case SchedulerPhase.transientCallbacks:
      case SchedulerPhase.midFrameMicrotasks:
      case SchedulerPhase.persistentCallbacks:
        // Already in a frame, no need to schedule another
        return;
    }
  }

  // --- Frame Execution ---

  /// Begins a frame by executing transient callbacks.
  ///
  /// This is the first phase of frame processing. It:
  /// 1. Updates the current frame timestamp
  /// 2. Transitions to [SchedulerPhase.transientCallbacks]
  /// 3. Executes all registered transient callbacks (animations)
  /// 4. Cleans up cancelled callbacks
  /// 5. Transitions to [SchedulerPhase.midFrameMicrotasks]
  /// 6. Calls [handleDrawFrame] to continue the frame
  ///
  /// The microtask phase allows Futures/Promises that completed during
  /// transient callbacks to execute before the build phase.
  void handleBeginFrame(Duration rawTimeStamp) {
    _frameNumber++;
    NoctermTimeline.startSync('Frame #$_frameNumber');

    _currentFrameTimeStamp = rawTimeStamp;
    _currentSystemFrameTimeStamp = rawTimeStamp;

    assert(_schedulerPhase == SchedulerPhase.idle);
    _hasScheduledFrame = false;

    try {
      // Phase 1: Transient callbacks (animations)
      NoctermTimeline.startSync('Animate');
      _schedulerPhase = SchedulerPhase.transientCallbacks;
      final localTransientCallbacks = Map<int, _FrameCallbackEntry>.of(
        _transientCallbacks,
      );
      for (final entry in localTransientCallbacks.values) {
        if (!entry.cancelled) {
          _invokeFrameCallback(
            entry.callback,
            _currentFrameTimeStamp!,
            entry.debugLabel,
          );
        }
      }
      _transientCallbacks.clear();
      _removeCompletedCallbacks();
      NoctermTimeline.finishSync(); // Animate

      // Phase 2: Microtasks
      // (These run automatically as part of the event loop)
      _schedulerPhase = SchedulerPhase.midFrameMicrotasks;
    } finally {
      // Continue to draw phase
      _schedulerPhase = SchedulerPhase.persistentCallbacks;
    }

    // Now execute the persistent callbacks (build/layout/paint)
    handleDrawFrame();
  }

  /// Executes the rendering pipeline and post-frame callbacks.
  ///
  /// This completes the frame by:
  /// 1. Executing persistent callbacks (build, layout, paint)
  /// 2. Transitioning to [SchedulerPhase.postFrameCallbacks]
  /// 3. Executing all registered post-frame callbacks
  /// 4. Returning to [SchedulerPhase.idle]
  ///
  /// Subclasses should override this to integrate with their rendering
  /// pipeline, but must call `super.handleDrawFrame()` to maintain proper
  /// phase transitions.
  void handleDrawFrame() {
    assert(_schedulerPhase == SchedulerPhase.persistentCallbacks);

    final frameStart = DateTime.now();
    int buildEnd = 0;
    int layoutEnd = 0;
    int paintEnd = 0;

    try {
      // Execute persistent frame callbacks
      NoctermTimeline.startSync('Build');
      for (final callback in List<FrameCallback>.of(_persistentCallbacks)) {
        _invokeFrameCallback(callback, _currentFrameTimeStamp!);
      }
      NoctermTimeline.finishSync(); // Build
      buildEnd = DateTime.now().microsecondsSinceEpoch;

      // TODO: Add explicit layout and paint phases when rendering system is implemented
      // For now, treat persistent callbacks as combined build+layout+paint
      layoutEnd = buildEnd;
      paintEnd = buildEnd;

      // Phase 4: Post-frame callbacks
      _schedulerPhase = SchedulerPhase.postFrameCallbacks;
      final localPostFrameCallbacks = Queue<FrameCallback>.of(
        _postFrameCallbacks,
      );
      _postFrameCallbacks.clear();
      for (final callback in localPostFrameCallbacks) {
        _invokeFrameCallback(callback, _currentFrameTimeStamp!);
      }
    } finally {
      NoctermTimeline.finishSync(); // Frame

      final frameEnd = DateTime.now();

      // Report frame timing
      if (_frameTimingCallbacks.isNotEmpty) {
        final timing = FrameTiming(
          frameNumber: _frameNumber,
          buildDuration: Duration(
            microseconds: buildEnd - frameStart.microsecondsSinceEpoch,
          ),
          layoutDuration: Duration(microseconds: layoutEnd - buildEnd),
          paintDuration: Duration(microseconds: paintEnd - layoutEnd),
          compositingDuration:
              Duration.zero, // Tracked separately in TerminalBinding
          totalDuration: frameEnd.difference(frameStart),
          timestamp: frameStart,
        );
        _reportFrameTiming(timing);
      }

      // Return to idle
      _schedulerPhase = SchedulerPhase.idle;
      _currentFrameTimeStamp = null;
    }
  }

  /// Invokes a frame callback with error handling.
  void _invokeFrameCallback(
    FrameCallback callback,
    Duration timeStamp, [
    String? debugLabel,
  ]) {
    try {
      callback(timeStamp);
    } catch (exception, stack) {
      NoctermError.reportError(
        NoctermErrorDetails(
          exception: exception,
          stack: stack,
          library: 'nocterm scheduler',
          context:
              'during frame callback${debugLabel != null ? ' ($debugLabel)' : ''}',
        ),
      );
    }
  }

  /// Returns a Future that completes after the current frame finishes.
  ///
  /// If called during a frame, the Future completes when that frame ends.
  /// If called while idle, a frame is scheduled and the Future completes
  /// when that frame ends.
  ///
  /// Useful for waiting for layout to complete:
  /// ```dart
  /// await binding.endOfFrame;
  /// final height = renderBox.size.height; // Layout is done
  /// ```
  Future<void> get endOfFrame {
    if (_endOfFrameCompleter == null) {
      if (schedulerPhase == SchedulerPhase.idle) {
        scheduleFrame();
      }
      _endOfFrameCompleter = Completer<void>();
      addPostFrameCallback((_) {
        _endOfFrameCompleter!.complete();
        _endOfFrameCompleter = null;
      });
    }
    return _endOfFrameCompleter!.future;
  }

  Completer<void>? _endOfFrameCompleter;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('SchedulerBinding:');
    buffer.writeln('  schedulerPhase: $schedulerPhase');
    buffer.writeln('  hasScheduledFrame: $hasScheduledFrame');
    buffer.writeln('  transientCallbacks: ${_transientCallbacks.length}');
    buffer.writeln('  persistentCallbacks: ${_persistentCallbacks.length}');
    buffer.writeln('  postFrameCallbacks: ${_postFrameCallbacks.length}');
    return buffer.toString();
  }
}
