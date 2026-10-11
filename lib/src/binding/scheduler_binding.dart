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

/// Preset frame rate configurations for common use cases.
///
/// Use these with [SchedulerBinding.targetFrameDuration] to easily configure
/// the frame rate of your application.
///
/// Example:
/// ```dart
/// // In your app initialization
/// SchedulerBinding.instance.targetFrameDuration = FrameRate.fps60;
///
/// // Or disable frame rate limiting entirely
/// SchedulerBinding.instance.enableFrameRateLimiting = false;
/// ```
abstract final class FrameRate {
  /// 15 frames per second (~66.67ms per frame).
  ///
  /// Best for: Static dashboards, log viewers, minimal CPU usage.
  static const Duration fps15 = Duration(microseconds: 66667);

  /// 24 frames per second (~41.67ms per frame).
  ///
  /// Best for: Film-like animations, moderate refresh needs.
  static const Duration fps24 = Duration(microseconds: 41667);

  /// 30 frames per second (~33.33ms per frame).
  ///
  /// Best for: Most TUI applications. Good balance of responsiveness
  /// and CPU efficiency. This is the default.
  static const Duration fps30 = Duration(microseconds: 33333);

  /// 60 frames per second (~16.67ms per frame).
  ///
  /// Best for: Smooth animations, games, highly interactive UIs.
  /// Uses more CPU than lower frame rates.
  static const Duration fps60 = Duration(microseconds: 16667);

  /// 120 frames per second (~8.33ms per frame).
  ///
  /// Best for: High refresh rate displays, extremely smooth animations.
  /// Uses significantly more CPU.
  static const Duration fps120 = Duration(microseconds: 8333);

  /// Creates a custom frame duration from a target FPS value.
  ///
  /// Example:
  /// ```dart
  /// SchedulerBinding.instance.targetFrameDuration = FrameRate.fromFps(45);
  /// ```
  static Duration fromFps(double fps) {
    if (fps <= 0) {
      throw ArgumentError.value(fps, 'fps', 'FPS must be greater than 0');
    }
    return Duration(microseconds: (1000000 / fps).round());
  }
}

/// Entry for a transient frame callback that can be cancelled.
class _FrameCallbackEntry {
  _FrameCallbackEntry(this.callback,
      {this.debugLabel, bool rescheduling = false}) {
    // In debug mode, capture the stack trace where the callback was registered.
    // When rescheduling (animations), keep the original stack trace.
    assert(() {
      if (rescheduling) {
        debugStack = debugCurrentCallbackStack;
      } else {
        debugStack = StackTrace.current;
      }
      return true;
    }());
  }

  final FrameCallback callback;
  final String? debugLabel;
  bool cancelled = false;

  /// The stack trace where this callback was originally registered.
  /// Only captured in debug mode (via assert).
  StackTrace? debugStack;

  /// Used during callback execution to track the current callback's stack.
  /// This allows rescheduling callbacks to preserve the original stack trace.
  static StackTrace? debugCurrentCallbackStack;
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

  /// Returns the time of the last frame execution.
  ///
  /// This is protected for subclasses that need to implement their own
  /// frame scheduling while respecting frame rate limiting.
  @protected
  DateTime? get lastFrameTime => _lastFrameTime;

  /// Target frame duration (default: 30fps = ~33.33ms).
  ///
  /// Common values:
  /// - 30fps: `Duration(microseconds: 33333)` - Good for most TUIs (default)
  /// - 60fps: `Duration(microseconds: 16667)` - Smooth animations
  /// - 15fps: `Duration(microseconds: 66667)` - Static dashboards, minimal CPU
  ///
  /// See also [FrameRate] for convenient presets.
  Duration targetFrameDuration = const Duration(microseconds: 33333);

  /// Whether to enable frame rate limiting to prevent CPU saturation.
  ///
  /// When true, frames are throttled to approximately [targetFrameDuration].
  /// When false, frames render as fast as possible (may cause 100% CPU).
  bool enableFrameRateLimiting = true;

  /// Sets the target frame rate in frames per second.
  ///
  /// This is a convenience method that sets [targetFrameDuration] based on
  /// the desired FPS value.
  ///
  /// Example:
  /// ```dart
  /// // Set to 60 FPS for smooth animations
  /// SchedulerBinding.instance.setTargetFps(60);
  ///
  /// // Or use the preset constants
  /// SchedulerBinding.instance.targetFrameDuration = FrameRate.fps60;
  /// ```
  ///
  /// See also:
  /// - [FrameRate] for preset frame duration constants
  /// - [targetFrameDuration] to set the duration directly
  void setTargetFps(double fps) {
    targetFrameDuration = FrameRate.fromFps(fps);
  }

  /// Returns the current target frame rate in frames per second.
  ///
  /// This is calculated from [targetFrameDuration].
  double get targetFps => 1000000 / targetFrameDuration.inMicroseconds;

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
        NoctermError.reportError(NoctermErrorDetails(
          exception: e,
          stack: stack,
          library: 'nocterm scheduler',
          context: 'during frame timing callback',
        ));
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
  /// Unlike Flutter, nocterm resets this at the START of frame execution
  /// (in [handleBeginFrame]) to match Flutter's semantics and allow
  /// animations to reschedule themselves during the frame.
  bool get hasScheduledFrame => _hasScheduledFrame;
  bool _hasScheduledFrame = false;

  /// Timer for the pending delayed frame, if any.
  ///
  /// This tracks whether a frame timer is already running to avoid
  /// scheduling duplicate timers. The frame rate limiter may delay
  /// frame execution, and this ensures we don't create multiple timers.
  ///
  /// Protected so subclasses (like TerminalBinding) can use it.
  @protected
  Timer? pendingFrameTimer;

  /// Phase timing data for the current frame.
  ///
  /// Subclasses (like TerminalBinding) should set these during frame
  /// execution to provide accurate timing data to [FrameTiming].
  /// All values are in microseconds since epoch.
  @protected
  int? currentFrameBuildEnd;
  @protected
  int? currentFrameLayoutEnd;
  @protected
  int? currentFramePaintEnd;

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
  ///
  /// The [scheduleNewFrame] parameter controls whether [scheduleFrame] is called.
  /// Defaults to true. Set to false when you've already called [scheduleFrame]
  /// separately (like [Ticker] does) to avoid redundant scheduling.
  int scheduleFrameCallback(
    FrameCallback callback, {
    bool rescheduling = false,
    bool scheduleNewFrame = true,
    String? debugLabel,
  }) {
    final int id = _nextFrameCallbackId++;
    _transientCallbacks[id] = _FrameCallbackEntry(
      callback,
      debugLabel: debugLabel,
      rescheduling: rescheduling,
    );
    if (scheduleNewFrame) {
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
  /// Debug flag to trace what's scheduling frames.
  /// Set to true via debug overlay or programmatically to see stack traces.
  static bool debugPrintScheduleFrameStacks = false;

  /// Prints debug information about all currently registered transient callbacks.
  ///
  /// This is useful for debugging which animations or callbacks are keeping
  /// the frame loop running. Call this when you see unexpected constant FPS.
  ///
  /// Example:
  /// ```dart
  /// SchedulerBinding.instance.debugPrintTransientCallbacks();
  /// ```
  void debugPrintTransientCallbacks() {
    if (_transientCallbacks.isEmpty) {
      print('No transient callbacks registered.');
      return;
    }
    print('${_transientCallbacks.length} transient callback(s) registered:');
    for (final entry in _transientCallbacks.entries) {
      final callback = entry.value;
      print('  [${entry.key}] ${callback.debugLabel ?? "anonymous"}');
      if (callback.debugStack != null) {
        // Print first few lines of the stack trace showing where it was registered
        final lines = callback.debugStack.toString().split('\n');
        for (final line in lines.take(5)) {
          print('      $line');
        }
      }
    }
  }

  @override
  void scheduleFrame() {
    if (_hasScheduledFrame) {
      return; // Frame already scheduled
    }
    if (debugPrintScheduleFrameStacks) {
      print('scheduleFrame() called:');
      print(StackTrace.current.toString().split('\n').take(50).join('\n'));
    }
    _hasScheduledFrame = true;
    scheduleFrameImpl();
  }

  /// Platform-specific frame scheduling implementation.
  ///
  /// Schedules frames with optional frame rate limiting to prevent CPU saturation.
  /// When [enableFrameRateLimiting] is true, enforces [targetFrameDuration] between frames.
  ///
  /// This method checks if a frame timer is already pending ([pendingFrameTimer])
  /// to avoid scheduling duplicate timers. This is separate from [_hasScheduledFrame]
  /// because that flag is reset at the start of each frame (like Flutter), while
  /// the timer may persist across frames for rate limiting.
  ///
  /// Subclasses can override for different timing strategies (e.g., vsync).
  @protected
  void scheduleFrameImpl() {
    // Don't schedule if a timer is already pending
    if (pendingFrameTimer != null && pendingFrameTimer!.isActive) {
      return;
    }

    if (enableFrameRateLimiting && _lastFrameTime != null) {
      final now = DateTime.now();
      final elapsed = now.difference(_lastFrameTime!);

      if (elapsed < targetFrameDuration) {
        // Too soon, delay the frame
        final delay = targetFrameDuration - elapsed;
        pendingFrameTimer = Timer(delay, () {
          pendingFrameTimer = null;
          executeFrame();
        });
        return;
      }
    }

    // Execute frame immediately (but still async to allow event loop to process)
    pendingFrameTimer = Timer(Duration.zero, () {
      pendingFrameTimer = null;
      executeFrame();
    });
  }

  /// Executes a single frame by recording the time and calling [handleBeginFrame].
  ///
  /// This is protected for subclasses that need custom frame execution logic
  /// (e.g., waking an event loop after frame execution).
  @protected
  void executeFrame() {
    _lastFrameTime = DateTime.now();
    final timeStamp =
        Duration(microseconds: _lastFrameTime!.microsecondsSinceEpoch);
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

    // Reset _hasScheduledFrame at the START of frame execution, matching Flutter's
    // semantics. This allows animations to reschedule themselves during the frame.
    // Frame rate limiting is handled by pendingFrameTimer in scheduleFrameImpl(),
    // which is separate from this flag.
    _hasScheduledFrame = false;

    try {
      // Phase 1: Transient callbacks (animations)
      NoctermTimeline.startSync('Animate');
      _schedulerPhase = SchedulerPhase.transientCallbacks;
      final localTransientCallbacks =
          Map<int, _FrameCallbackEntry>.of(_transientCallbacks);
      // Remove only the callbacks we're about to process, not any new ones
      // that might be added during callback execution
      for (final id in localTransientCallbacks.keys) {
        _transientCallbacks.remove(id);
      }
      for (final entry in localTransientCallbacks.values) {
        if (!entry.cancelled) {
          _invokeFrameCallback(
            entry.callback,
            _currentFrameTimeStamp!,
            entry.debugLabel,
            entry.debugStack,
          );
        }
      }
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
    final frameStartMicros = frameStart.microsecondsSinceEpoch;

    // Clear phase timing from previous frame
    currentFrameBuildEnd = null;
    currentFrameLayoutEnd = null;
    currentFramePaintEnd = null;

    try {
      // Execute persistent frame callbacks
      // Subclasses (like TerminalBinding) set currentFrameBuildEnd/LayoutEnd/PaintEnd
      // during their _drawFrameCallback to provide accurate phase timings.
      // The 'Build' NoctermTimeline section is opened INSIDE
      // TerminalBinding's _drawFrameCallback around the actual
      // `super.drawFrame()` call (the buildScope + finalizeTree),
      // not here — opening it here would also enclose the layout
      // and paint the callback runs, which is misleading.
      for (final callback in List<FrameCallback>.of(_persistentCallbacks)) {
        _invokeFrameCallback(callback, _currentFrameTimeStamp!);
      }

      // Use subclass-provided timing if available, otherwise use now
      final buildEnd =
          currentFrameBuildEnd ?? DateTime.now().microsecondsSinceEpoch;
      final layoutEnd = currentFrameLayoutEnd ?? buildEnd;
      final paintEnd = currentFramePaintEnd ?? layoutEnd;

      // Phase 4: Post-frame callbacks
      _schedulerPhase = SchedulerPhase.postFrameCallbacks;
      final localPostFrameCallbacks =
          Queue<FrameCallback>.of(_postFrameCallbacks);
      _postFrameCallbacks.clear();
      for (final callback in localPostFrameCallbacks) {
        _invokeFrameCallback(callback, _currentFrameTimeStamp!);
      }

      // Report frame timing (moved inside try to access buildEnd/layoutEnd/paintEnd)
      final frameEnd = DateTime.now();
      if (_frameTimingCallbacks.isNotEmpty) {
        final timing = FrameTiming(
          frameNumber: _frameNumber,
          buildDuration: Duration(microseconds: buildEnd - frameStartMicros),
          layoutDuration: Duration(microseconds: layoutEnd - buildEnd),
          paintDuration: Duration(microseconds: paintEnd - layoutEnd),
          compositingDuration:
              Duration.zero, // Tracked separately in TerminalBinding
          totalDuration: frameEnd.difference(frameStart),
          timestamp: frameStart,
        );
        _reportFrameTiming(timing);
      }
    } finally {
      NoctermTimeline.finishSync(); // Frame

      // Return to idle
      _schedulerPhase = SchedulerPhase.idle;
      _currentFrameTimeStamp = null;

      // Note: _hasScheduledFrame is reset at the START of frame in handleBeginFrame(),
      // matching Flutter's semantics. Frame rate limiting is handled by
      // pendingFrameTimer in scheduleFrameImpl().
    }
  }

  /// Invokes a frame callback with error handling.
  ///
  /// The optional [callbackStack] parameter contains the stack trace from
  /// when the callback was originally registered, which helps debugging
  /// by showing where the animation/callback was started.
  void _invokeFrameCallback(
    FrameCallback callback,
    Duration timeStamp, [
    String? debugLabel,
    StackTrace? callbackStack,
  ]) {
    assert(_FrameCallbackEntry.debugCurrentCallbackStack == null);
    assert(() {
      _FrameCallbackEntry.debugCurrentCallbackStack = callbackStack;
      return true;
    }());
    try {
      callback(timeStamp);
    } catch (exception, stack) {
      final contextMessage = StringBuffer('during frame callback');
      if (debugLabel != null) {
        contextMessage.write(' ($debugLabel)');
      }
      if (callbackStack != null) {
        contextMessage.write('\n\nCallback was originally registered at:\n');
        contextMessage
            .write(callbackStack.toString().split('\n').take(15).join('\n'));
      }
      NoctermError.reportError(NoctermErrorDetails(
        exception: exception,
        stack: stack,
        library: 'nocterm scheduler',
        context: contextMessage.toString(),
      ));
    } finally {
      assert(() {
        _FrameCallbackEntry.debugCurrentCallbackStack = null;
        return true;
      }());
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
