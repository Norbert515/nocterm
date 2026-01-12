import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import 'package:nocterm/src/navigation/render_theater.dart';
import 'package:nocterm/src/rendering/scrollable_render_object.dart';

import '../backend/terminal.dart' as term;
import '../buffer.dart' as buf;
import '../keyboard/input_event.dart';
import '../keyboard/input_parser.dart';
import '../rendering/mouse_hit_test.dart';
import '../rendering/mouse_tracker.dart';
import 'hot_reload_mixin.dart';

/// Terminal UI binding that handles terminal input/output and event loop
class TerminalBinding extends NoctermBinding
    with SchedulerBinding, HotReloadBinding {
  TerminalBinding(this.terminal) {
    _instance = this;
    _initializePipelineOwner();
  }

  static TerminalBinding? _instance;
  static TerminalBinding get instance => _instance!;

  final term.Terminal terminal;
  PipelineOwner? _pipelineOwner;
  PipelineOwner get pipelineOwner => _pipelineOwner!;

  bool _shouldExit = false;

  /// Whether the binding has been signaled to exit
  bool get shouldExit => _shouldExit;

  final _inputController = StreamController<String>.broadcast();
  final _keyboardEventController = StreamController<KeyboardEvent>.broadcast();
  final _inputParser = InputParser();
  final _mouseEventController = StreamController<MouseEvent>.broadcast();

  /// Timestamp of last input bytes added to parser (for buffer staleness detection)
  DateTime? _lastInputTime;

  /// Timeout for stale buffer detection (100ms)
  static const _bufferStaleTimeout = Duration(milliseconds: 100);
  final _mouseTracker = MouseTracker();
  final _oscEventsController = StreamController<String>.broadcast();

  /// Timer for detecting standalone ESC key press.
  /// When ESC arrives as part of an incomplete escape sequence (e.g., ESC [),
  /// we wait briefly to see if more bytes arrive. If not, we treat it as ESC.
  Timer? _escapeTimer;

  /// Duration to wait for additional escape sequence bytes before flushing ESC.
  static const _escapeTimeoutDuration = Duration(milliseconds: 50);

  // Event-driven loop support
  final _eventLoopController = StreamController<void>.broadcast();
  Stream<void> get _eventLoopStream => _eventLoopController.stream;

  /// Previous frame's buffer for differential rendering.
  buf.Buffer? _previousBuffer;

  StreamSubscription? _inputSubscription;
  StreamSubscription? _resizeSubscription;
  StreamSubscription? _shutdownSubscription;
  Size? _lastKnownSize;

  void _initializePipelineOwner() {
    _pipelineOwner = PipelineOwner();
    _pipelineOwner!.onNeedsVisualUpdate = scheduleFrame;
  }

  /// Stream of keyboard input events (raw strings)
  Stream<String> get input => _inputController.stream;

  /// Stream of parsed keyboard events
  Stream<KeyboardEvent> get keyboardEvents => _keyboardEventController.stream;

  /// Stream of parsed mouse events
  Stream<MouseEvent> get mouseEvents => _mouseEventController.stream;

  /// Stream of OSC responses captured from the terminal
  Stream<String> get oscEvents => _oscEventsController.stream;

  /// Initialize the terminal and start the event loop
  void initialize() {
    // Setup terminal
    terminal.enterAlternateScreen();
    terminal.hideCursor();
    terminal.bindOSCStream(_oscEventsController.stream);
    terminal.clear();

    // Enable mouse tracking (SGR mode for better coordinate support)
    // ESC [ ? 1000 h - Send Mouse X & Y on button press and release
    // ESC [ ? 1002 h - Use Cell Motion Mouse Tracking
    // ESC [ ? 1003 h - Enable all motion mouse tracking
    // ESC [ ? 1006 h - Enable SGR mouse mode
    terminal.write(EscapeCodes.enable.basicMouseTracking);
    terminal.write(EscapeCodes.enable.buttonEventTracking);
    terminal.write(EscapeCodes.enable.motionTracking);
    terminal.write(EscapeCodes.enable.sgrMouseMode);

    // Enable bracketed paste mode
    // ESC [ ? 2004 h - Enables bracketed paste mode
    // When enabled, pasted text is wrapped in ESC[200~ ... ESC[201~
    // This allows applications to distinguish pasted text from typed text
    terminal.write(EscapeCodes.enable.bracketedPasteMode);
    terminal.flush();

    // Store initial size
    _lastKnownSize = terminal.size;

    // Start listening for keyboard input
    _startInputHandling();

    // Start listening for terminal resize events
    _startResizeHandling();

    // Start listening for termination signals
    _startSignalHandling();
  }

  void _startInputHandling() {
    // Get input stream from the terminal's backend
    final inputStream = terminal.backend.inputStream;
    if (inputStream == null) {
      throw StateError('Terminal backend does not provide input stream');
    }

    // Enable raw mode via backend
    try {
      terminal.backend.enableRawMode();
    } catch (e) {
      // Ignore errors when running without a proper terminal
      // This happens in CI/CD environments or when piping output
    }

    // Listen for input at the byte level for proper escape sequence handling
    _inputSubscription = inputStream.listen((bytes) {
      // Cancel any pending escape timer since new bytes arrived
      _escapeTimer?.cancel();
      _escapeTimer = null;

      // Extract OSC sequences from input stream:
      // - Normal mode: Terminal emulator responses (color queries, clipboard, etc.)
      // - Shell mode: Above + custom protocol (e.g., OSC 9999 size updates)
      bytes = _processOscSequences(bytes);

      // Check for stale buffer - if too much time has passed since last input,
      // clear any incomplete sequences that may be blocking the parser.
      // This handles edge cases where rapid key sequences get corrupted.
      final now = DateTime.now();
      if (_lastInputTime != null &&
          now.difference(_lastInputTime!) > _bufferStaleTimeout) {
        _inputParser.clear();
      }
      _lastInputTime = now;

      // Parse the bytes and process ALL events in the buffer
      _inputParser.addBytes(bytes);

      // Collect all events from this stdin read
      final events = <InputEvent>[];
      InputEvent? inputEvent;
      while ((inputEvent = _inputParser.parseNext()) != null) {
        events.add(inputEvent!);
      }

      // Batch consecutive printable character events into a synthetic paste
      // This handles terminals (like Warp) that don't use bracketed paste for drag-drop
      final batchedEvents = _batchCharacterEvents(events);

      // Process all batched events
      for (final event in batchedEvents) {
        if (event is KeyboardInputEvent) {
          final keyEvent = event.event;
          // Add to keyboard event stream
          _keyboardEventController.add(keyEvent);

          // Route the event through the component tree
          _routeKeyboardEvent(keyEvent);

          // Note: Ctrl+C (SIGINT) is routed through the event system first,
          // allowing components to intercept it. Falls back to shutdown if unhandled.
        } else if (event is MouseInputEvent) {
          final mouseEvent = event.event;

          // Add to mouse event stream
          _mouseEventController.add(mouseEvent);

          // Route the mouse event through the component tree
          _routeMouseEvent(mouseEvent);
        } else if (event is PasteInputEvent) {
          // Handle bracketed paste (or batched characters): copy to clipboard then send Ctrl+V
          ClipboardManager.copy(event.text);

          // Generate a Ctrl+V keyboard event to trigger the paste
          final pasteEvent = KeyboardEvent(
            logicalKey: LogicalKey.keyV,
            modifiers: const ModifierKeys(ctrl: true),
          );
          _keyboardEventController.add(pasteEvent);
          _routeKeyboardEvent(pasteEvent);
        }
      }

      // After processing ALL events in the buffer, schedule a frame if needed
      // The scheduler will batch all state changes and render once
      // This ensures rapid events (scroll, paste) don't trigger excessive renders
      if (buildOwner.hasDirtyElements) {
        scheduleFrame();
      }

      // Check for incomplete escape sequences and start timer if needed.
      // This handles the case where ESC arrives as part of a potential escape
      // sequence (e.g., ESC [) but no more bytes arrive. After a timeout,
      // we flush the buffer as a standalone ESC key event.
      if (_inputParser.hasIncompleteEscapeSequence()) {
        _escapeTimer = Timer(_escapeTimeoutDuration, _flushEscapeSequence);
      }

      // Also add raw string for backwards compatibility
      try {
        final str = utf8.decode(bytes);
        _inputController.add(str);
      } catch (e) {
        // Ignore decode errors for escape sequences
      }
    });
  }

  /// Flush an incomplete escape sequence as a standalone ESC key event.
  /// Called by the escape timer when no additional bytes arrive.
  void _flushEscapeSequence() {
    _escapeTimer = null;
    final escEvent = _inputParser.forceFlushEscape();
    if (escEvent != null) {
      // Add to keyboard event stream
      _keyboardEventController.add(escEvent);

      // Route the event through the component tree
      _routeKeyboardEvent(escEvent);

      // Schedule a frame if needed
      if (buildOwner.hasDirtyElements) {
        scheduleFrame();
      }
    }
  }

  /// Process bytes in shell mode to extract terminal size OSC sequences
  /// Returns filtered bytes with OSC sequences removed
  List<int> _processOscSequences(List<int> bytes) {
    final result = <int>[];
    int i = 0;

    while (i < bytes.length) {
      // Check for OSC sequence: ESC ] ... BEL or ESC ] ... ST (ESC \)
      if (i + 2 < bytes.length && bytes[i] == 0x1b && bytes[i + 1] == 0x5d) {
        // Found ESC ]
        int end = i + 2;
        bool foundTerminator = false;

        // Look for BEL (0x07) or ST (ESC \ = 0x1b 0x5c) terminator
        while (end < bytes.length) {
          if (bytes[end] == 0x07) {
            // Found BEL terminator
            foundTerminator = true;
            break;
          }
          if (end + 1 < bytes.length &&
              bytes[end] == 0x1b &&
              bytes[end + 1] == 0x5c) {
            // Found ST terminator
            foundTerminator = true;
            end++;
            break;
          }
          end++;
        }

        if (foundTerminator && end < bytes.length) {
          // Extract OSC content
          final oscContent = utf8.decode(
            bytes.sublist(i + 2, end),
            allowMalformed: true,
          );

          // Handle OSC sequence based on command number
          _handleOscSequence(oscContent);

          // Skip this OSC sequence
          i = end + 1;
          continue;
        }
      }

      // Regular byte, keep it
      result.add(bytes[i]);
      i++;
    }

    return result;
  }

  /// Handle a parsed OSC sequence
  void _handleOscSequence(String oscContent) {
    // Parse command number (everything before first semicolon)
    final semicolonIndex = oscContent.indexOf(';');
    if (semicolonIndex == -1) {
      // No semicolon, treat entire content as command
      _oscEventsController.add(oscContent);
      return;
    }

    final command = oscContent.substring(0, semicolonIndex);
    final payload = oscContent.substring(semicolonIndex + 1);
    // Check if backend supports OSC 9999 size updates (shell mode)
    final supportsOscSizeUpdates = terminal.backend.resizeStream != null;
    switch (command) {
      // Custom OSC sequences for shell mode
      case "9999" when supportsOscSizeUpdates: // Terminal Size
        _handleTerminalSizeOsc(payload);
        _oscEventsController.add(oscContent);
        break;
      // Standard OSC sequences
      case "0": // Set icon name and window title
      case "1": // Set icon name
      case "2": // Set window title
      case "4": // Set/query color palette
      case "10": // Query foreground color response
      case "11": // Query background color response
      case "12": // Query cursor color response
      case "52": // Clipboard operations
        _oscEventsController.add(oscContent);
        break;
      default: // Unknown or unhandled OSC sequence
        break;
    }
  }

  /// Handle terminal size OSC sequence
  void _handleTerminalSizeOsc(String payload) {
    final parts = payload.split(';');
    if (parts.length == 2) {
      try {
        final cols = int.parse(parts[0]);
        final rows = int.parse(parts[1]);
        final newSize = Size(cols.toDouble(), rows.toDouble());

        // Notify backend of size change (it will emit on resizeStream)
        terminal.backend.notifySizeChanged(newSize);

        // Update terminal size
        terminal.updateSize(newSize);
        _lastKnownSize = newSize;

        // Trigger a redraw with new size
        scheduleFrame();
      } catch (e) {
        // Invalid size, ignore
      }
    }
  }

  /// Batch consecutive printable character events into a single PasteInputEvent.
  ///
  /// This handles terminals (like Warp) that don't wrap drag-drop in bracketed
  /// paste mode. When multiple printable characters arrive in a single stdin
  /// read, they're clearly from a paste/drag-drop rather than typing, so we
  /// batch them together for efficient processing.
  ///
  /// Single characters pass through unchanged for responsive typing.
  List<InputEvent> _batchCharacterEvents(List<InputEvent> events) {
    if (events.length <= 1) {
      // Single event or empty - no batching needed, keeps typing responsive
      return events;
    }

    final result = <InputEvent>[];
    final charBuffer = StringBuffer();

    void flushCharBuffer() {
      if (charBuffer.isNotEmpty) {
        // Convert batched characters to a PasteInputEvent
        result.add(PasteInputEvent(charBuffer.toString()));
        charBuffer.clear();
      }
    }

    for (final event in events) {
      if (event is KeyboardInputEvent) {
        final keyEvent = event.event;
        // Check if this is a simple printable character (no modifiers except shift)
        final isPrintable =
            keyEvent.character != null &&
            keyEvent.character!.isNotEmpty &&
            !keyEvent.isControlPressed &&
            !keyEvent.isAltPressed &&
            !keyEvent.isMetaPressed;

        if (isPrintable) {
          // Add to batch
          charBuffer.write(keyEvent.character);
        } else {
          // Non-printable key (arrow, enter, ctrl+x, etc.) - flush buffer first
          flushCharBuffer();
          result.add(event);
        }
      } else {
        // Mouse event or other - flush buffer first
        flushCharBuffer();
        result.add(event);
      }
    }

    // Flush any remaining characters
    flushCharBuffer();

    return result;
  }

  void _startResizeHandling() {
    // Listen to backend's resize stream
    final resizeStream = terminal.backend.resizeStream;
    if (resizeStream != null) {
      _resizeSubscription = resizeStream.listen((newSize) {
        if (_lastKnownSize == null ||
            _lastKnownSize!.width != newSize.width ||
            _lastKnownSize!.height != newSize.height) {
          _lastKnownSize = newSize;
          terminal.updateSize(newSize);
          // Clear previous buffer to force full redraw on resize
          _previousBuffer = null;
          scheduleFrame();
        }
      });
    }
  }

  void _startSignalHandling() {
    // Listen to backend's shutdown stream
    final shutdownStream = terminal.backend.shutdownStream;
    if (shutdownStream != null) {
      _shutdownSubscription = shutdownStream.listen((_) {
        // Create a synthetic Ctrl+C keyboard event
        final ctrlCEvent = KeyboardEvent(
          logicalKey: LogicalKey.keyC,
          character: null,
          modifiers: const ModifierKeys(ctrl: true),
        );

        // Add to keyboard event stream for monitoring
        _keyboardEventController.add(ctrlCEvent);

        // Route through component tree - components can intercept by returning true
        final handled = _routeKeyboardEvent(ctrlCEvent);

        // If no component handled it, perform default shutdown
        if (!handled) {
          _performImmediateShutdown();
          terminal.backend.requestExit(0);
        }
      });
    }
  }

  /// Perform immediate synchronous shutdown for signal handlers
  void _performImmediateShutdown() {
    // Prevent multiple shutdowns
    if (_shouldExit) return;
    _shouldExit = true;

    // Cancel escape timer if pending
    _escapeTimer?.cancel();
    _escapeTimer = null;

    // Cancel all subscriptions immediately
    _inputSubscription?.cancel();
    _resizeSubscription?.cancel();
    _shutdownSubscription?.cancel();

    // Close all controllers
    try {
      _inputController.close();
    } catch (_) {}
    try {
      _keyboardEventController.close();
    } catch (_) {}
    try {
      _mouseEventController.close();
    } catch (_) {}
    try {
      _eventLoopController.close();
    } catch (_) {}
    try {
      _oscEventsController.close();
    } catch (_) {}

    // Stop hot reload if it was initialized
    try {
      shutdownWithHotReload();
    } catch (_) {}

    // Perform terminal cleanup synchronously
    try {
      // IMPORTANT: Disable mouse tracking BEFORE leaving alternate screen
      terminal.backend.writeRaw('\x1B[?1003l'); // Disable all motion tracking
      terminal.backend.writeRaw('\x1B[?1006l'); // Disable SGR mouse mode
      terminal.backend.writeRaw('\x1B[?1002l'); // Disable button event tracking
      terminal.backend.writeRaw('\x1B[?1000l'); // Disable basic mouse tracking
      terminal.restoreColors(); // Restore terminal colors
      terminal.flush();

      // Restore terminal
      terminal.showCursor();
      terminal.leaveAlternateScreen();
      terminal.clear();

      // Restore raw mode via backend
      terminal.backend.disableRawMode();
    } catch (_) {
      // Ignore any errors during cleanup
    }
  }

  /// Route a keyboard event through the component tree
  /// Returns true if the event was handled by a component
  bool _routeKeyboardEvent(KeyboardEvent event) {
    if (rootElement == null) return false;

    // Try to dispatch the event to the root element
    // The event will bubble through focused components
    return _dispatchKeyToElement(rootElement!, event);
  }

  /// Route a mouse event through the component tree
  void _routeMouseEvent(MouseEvent event) {
    if (rootElement == null) {
      return;
    }

    // Handle wheel events for scrollable widgets
    if (event.button == MouseButton.wheelUp ||
        event.button == MouseButton.wheelDown) {
      // Find the render object at the mouse position
      final renderObject = _findRenderObjectInTree(rootElement!);
      if (renderObject != null) {
        _dispatchMouseWheelAtPosition(
          rootElement!,
          event,
          Offset(event.x.toDouble(), event.y.toDouble()),
          Offset.zero,
        );
      }
    }

    // Perform hit test for all mouse events
    final renderObject = _findRenderObjectInTree(rootElement!);
    if (renderObject != null) {
      final hitTestResult = MouseHitTestResult();
      // Mouse coordinates are already 0-based (converted by MouseParser)
      final position = Offset(event.x.toDouble(), event.y.toDouble());

      // Perform hit test from the root render object
      renderObject.hitTest(hitTestResult, position: position);

      // Update mouse tracker with hit test results
      _mouseTracker.updateAnnotations(hitTestResult, event);
    }
  }

  /// Find the render object in the element tree
  RenderObject? _findRenderObjectInTree(Element element) {
    if (element is RenderObjectElement) {
      return element.renderObject;
    }
    RenderObject? result;
    element.visitChildren((child) {
      result ??= _findRenderObjectInTree(child);
    });
    return result;
  }

  /// Dispatch a keyboard event to an element and its children
  bool _dispatchKeyToElement(Element element, KeyboardEvent event) {
    // Check if this element is a BlockFocus that's blocking
    if (element is BlockFocusElement && element.isBlocking) {
      return false; // Event is "handled" (blocked)
    }

    // First, try to dispatch to children (depth-first)
    bool handled = false;

    // Special handling for RenderTheater (Navigator's Overlay):
    // Only dispatch to the topmost route (last child) for keyboard events
    if (element.renderObject is RenderTheater) {
      final multiChildRenderObject = element as MultiChildRenderObjectElement;
      if (multiChildRenderObject.children.isNotEmpty) {
        final child = multiChildRenderObject.children.last;
        handled = _dispatchKeyToElement(child, event);
      }
    } else {
      // Normal case: visit all children
      element.visitChildren((child) {
        if (!handled) {
          handled = _dispatchKeyToElement(child, event);
        }
      });
    }

    // If no child handled it, and this element can handle keys, try it
    if (!handled && element is FocusableElement) {
      handled = element.handleKeyEvent(event);
    }

    return handled;
  }

  /// Dispatch a mouse wheel event to scrollable RenderObjects at a specific position
  bool _dispatchMouseWheelAtPosition(
    Element element,
    MouseEvent event,
    Offset mousePos,
    Offset currentOffset,
  ) {
    // TODO: This is a hack to handle RenderTheater specially for Navigator
    // Should be properly integrated into the render object hierarchy
    if (element.renderObject is RenderTheater) {
      final multiChildRenderObject = element as MultiChildRenderObjectElement;
      if (multiChildRenderObject.children.isNotEmpty) {
        final child = multiChildRenderObject.children.last;
        return _dispatchMouseWheelAtPosition(
          child,
          event,
          mousePos,
          currentOffset,
        );
      }
    }

    // Calculate this element's bounds if it has a render object
    Rect? elementBounds;
    RenderObject? renderObject;

    if (element is RenderObjectElement) {
      renderObject = element.renderObject;
      final size = renderObject.size;

      // Get the offset from parent data if available
      Offset localOffset = currentOffset;
      if (renderObject.parentData is BoxParentData) {
        final boxParentData = renderObject.parentData as BoxParentData;
        localOffset = currentOffset + boxParentData.offset;
      }

      elementBounds = Rect.fromLTWH(
        localOffset.dx,
        localOffset.dy,
        size.width,
        size.height,
      );
    }

    // Check if mouse is within this element's bounds
    bool isWithinBounds = elementBounds?.contains(mousePos) ?? true;

    if (!isWithinBounds) {
      return false; // Mouse is outside this element
    }

    // Try to dispatch to children first (depth-first, but only if within their bounds)
    bool handled = false;

    // Calculate offset for children
    Offset childrenOffset = currentOffset;
    if (element is RenderObjectElement && elementBounds != null) {
      // Use the element's actual position for its children
      childrenOffset = Offset(elementBounds.left, elementBounds.top);
    }

    // Visit children in reverse order to respect visual stacking
    // (last child is visually on top in Stack-like containers)
    final children = <Element>[];
    element.visitChildren((child) {
      children.add(child);
    });

    for (final child in children.reversed) {
      if (!handled) {
        handled = _dispatchMouseWheelAtPosition(
          child,
          event,
          mousePos,
          childrenOffset,
        );
      }
    }

    // If no child handled it and this element's render object is scrollable, handle it here
    if (!handled &&
        renderObject != null &&
        renderObject is ScrollableRenderObjectMixin) {
      final scrollableRenderObject =
          renderObject as ScrollableRenderObjectMixin;
      // Check if the render object implements scrolling through duck typing
      // This allows the RenderObject to handle scrolling without importing the mixin
      handled = scrollableRenderObject.handleMouseWheel(event);
    }

    return handled;
  }

  /// Run the main event loop
  Future<void> runEventLoop() async {
    // Initial frame
    drawFrame();

    // Keep the app running until shutdown is called
    // Use a completer-based approach for truly event-driven behavior
    final exitCompleter = Completer<void>();

    // Listen to the event stream
    final subscription = _eventLoopStream.listen((_) {
      // Events are handled by scheduleFrame, nothing to do here
    });

    // Check periodically for exit condition (much less frequently)
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_shouldExit) {
        timer.cancel();
        subscription.cancel();
        if (!exitCompleter.isCompleted) {
          exitCompleter.complete();
        }
      }
    });

    // Wait until we should exit
    await exitCompleter.future;
  }

  /// Shutdown the terminal and cleanup
  void shutdown() {
    // Prevent multiple shutdowns
    if (_shouldExit) return;

    _shouldExit = true;

    // Cancel escape timer if pending
    _escapeTimer?.cancel();
    _escapeTimer = null;

    _inputSubscription?.cancel();
    _resizeSubscription?.cancel();

    // Don't cancel shutdown subscription here - let it stay active
    // so it can handle additional signals if needed
    // _shutdownSubscription?.cancel();

    try {
      _inputController.close();
    } catch (_) {}
    try {
      _keyboardEventController.close();
    } catch (_) {}
    try {
      _mouseEventController.close();
    } catch (_) {}

    // Wake up event loop one last time before closing
    if (!_eventLoopController.isClosed) {
      _eventLoopController.add(null);
      _eventLoopController.close();
    }

    // Stop hot reload if it was initialized
    shutdownWithHotReload();

    // Try to cleanup terminal, but handle errors gracefully
    try {
      // IMPORTANT: Disable mouse tracking and bracketed paste BEFORE leaving alternate screen
      // This ensures the terminal properly processes the disable commands
      terminal.backend.writeRaw(EscapeCodes.disable.motionTracking);
      terminal.backend.writeRaw(EscapeCodes.disable.sgrMouseMode);
      terminal.backend.writeRaw(EscapeCodes.disable.buttonEventTracking);
      terminal.backend.writeRaw(EscapeCodes.disable.basicMouseTracking);
      terminal.backend.writeRaw(EscapeCodes.disable.bracketedPasteMode);

      // Restore terminal (this includes leaving alternate screen)
      terminal.showCursor();
      terminal.leaveAlternateScreen();

      // CRITICAL: Disable mouse tracking again after leaving alternate screen
      // Some terminals restore previous state when switching buffers
      terminal.backend.writeRaw(EscapeCodes.disable.motionTracking);
      terminal.backend.writeRaw(EscapeCodes.disable.sgrMouseMode);
      terminal.backend.writeRaw(EscapeCodes.disable.buttonEventTracking);
      terminal.backend.writeRaw(EscapeCodes.disable.basicMouseTracking);

      // Send a terminal reset sequence as a final safety measure
      // This helps ensure the terminal is in a clean state
      terminal.backend.writeRaw(EscapeCodes.resetDeviceAttributes);

      terminal.clear();

      // Final flush to ensure all cleanup is complete
      terminal.flush();
    } catch (e) {
      // If backend is already closed, we can't write to it
      // This can happen during signal-based shutdown
      // The important thing is we tried to cleanup
    }

    // Restore raw mode via backend
    try {
      terminal.backend.disableRawMode();
    } catch (e) {
      // Ignore errors when running without a proper terminal
    }
  }

  @override
  void scheduleFrameImpl() {
    // Override scheduler's frame implementation to also wake the event loop.
    // Respects frame rate limiting from SchedulerBinding.
    if (enableFrameRateLimiting && lastFrameTime != null) {
      final now = DateTime.now();
      final elapsed = now.difference(lastFrameTime!);

      if (elapsed < targetFrameDuration) {
        // Too soon, delay the frame
        final delay = targetFrameDuration - elapsed;
        Timer(delay, () {
          _executeFrameAndWakeEventLoop();
        });
        return;
      }
    }

    // Execute frame immediately
    Timer.run(_executeFrameAndWakeEventLoop);
  }

  /// Executes frame and wakes the event loop.
  void _executeFrameAndWakeEventLoop() {
    executeFrame();

    // Wake up the event loop after executing the frame
    if (!_eventLoopController.isClosed) {
      _eventLoopController.add(null);
    }
  }

  @override
  void handleDrawFrame() {
    if (rootElement == null) {
      super.handleDrawFrame(); // Let scheduler handle phase transitions
      return;
    }

    // Execute the persistent callbacks (build phase happens via BuildOwner)
    // The SchedulerBinding's handleDrawFrame will:
    // 1. Call persistent callbacks (including our _drawFrameCallback)
    // 2. Run post-frame callbacks
    // 3. Return to idle phase
    super.handleDrawFrame();
  }

  /// Renders only the cells that changed since the previous frame.
  void _renderDifferential(buf.Buffer buffer) {
    final previous = _previousBuffer;

    // First frame or size changed: full redraw
    if (previous == null ||
        previous.width != buffer.width ||
        previous.height != buffer.height) {
      _renderFull(buffer);
      return;
    }

    // Full buffer diff - compare every cell
    _renderFullDiff(buffer, previous);
  }

  /// Full buffer diff - compare every cell.
  void _renderFullDiff(buf.Buffer buffer, buf.Buffer previous) {
    TextStyle? currentStyle;

    for (int y = 0; y < buffer.height; y++) {
      for (int x = 0; x < buffer.width; x++) {
        final cell = buffer.getCell(x, y);
        final prevCell = previous.getCell(x, y);

        // Skip unchanged cells
        if (cell == prevCell) {
          continue;
        }

        // Skip zero-width space markers (used for wide character tracking)
        if (cell.char == '\u200B') {
          continue;
        }

        // Cell changed - move cursor and write
        terminal.moveCursor(x, y);

        // Handle style
        final hasStyle =
            cell.style.color != null ||
            cell.style.backgroundColor != null ||
            cell.style.fontWeight == FontWeight.bold ||
            cell.style.fontWeight == FontWeight.dim ||
            cell.style.fontStyle == FontStyle.italic ||
            cell.style.decoration?.hasUnderline == true ||
            cell.style.reverse;

        if (hasStyle) {
          if (currentStyle != cell.style) {
            if (currentStyle != null) {
              terminal.write(TextStyle.reset);
            }
            terminal.write(cell.style.toAnsi());
            currentStyle = cell.style;
          }
          terminal.write(cell.char);
        } else {
          if (currentStyle != null) {
            terminal.write(TextStyle.reset);
            currentStyle = null;
          }
          terminal.write(cell.char);
        }
      }
    }

    // Reset style at end of frame
    if (currentStyle != null) {
      terminal.write(TextStyle.reset);
    }

    terminal.flush();
  }

  /// Full redraw (used for first frame or after resize).
  void _renderFull(buf.Buffer buffer) {
    terminal.moveTo(0, 0);
    TextStyle? currentStyle;

    for (int y = 0; y < buffer.height; y++) {
      for (int x = 0; x < buffer.width; x++) {
        final cell = buffer.getCell(x, y);

        // Skip zero-width space markers (used for wide character tracking)
        if (cell.char == '\u200B') {
          continue;
        }

        // Handle style
        final hasStyle =
            cell.style.color != null ||
            cell.style.backgroundColor != null ||
            cell.style.fontWeight == FontWeight.bold ||
            cell.style.fontWeight == FontWeight.dim ||
            cell.style.fontStyle == FontStyle.italic ||
            cell.style.decoration?.hasUnderline == true ||
            cell.style.reverse;

        if (hasStyle) {
          if (currentStyle != cell.style) {
            if (currentStyle != null) {
              terminal.write(TextStyle.reset);
            }
            terminal.write(cell.style.toAnsi());
            currentStyle = cell.style;
          }
          terminal.write(cell.char);
        } else {
          if (currentStyle != null) {
            terminal.write(TextStyle.reset);
            currentStyle = null;
          }
          terminal.write(cell.char);
        }
      }
      if (y < buffer.height - 1) {
        terminal.write('\n');
      }
    }

    // Reset style at end
    if (currentStyle != null) {
      terminal.write(TextStyle.reset);
    }

    terminal.flush();
  }

  /// The actual frame drawing logic, registered as a persistent callback.
  void _drawFrameCallback(Duration timeStamp) {
    if (rootElement == null) return;

    // Build phase - handled by BuildOwner via persistent callback
    super.drawFrame();

    // Get current terminal size (may have been updated by resize event)
    final size = terminal.size;
    final buffer = buf.Buffer(size.width.toInt(), size.height.toInt());
    final screenRect = Rect.fromLTWH(
      0,
      0,
      size.width.toDouble(),
      size.height.toDouble(),
    );

    // Find render object in tree
    RenderObject? findRenderObject(Element element) {
      if (element is RenderObjectElement) {
        return element.renderObject;
      }
      RenderObject? result;
      element.visitChildren((child) {
        result ??= findRenderObject(child);
      });
      return result;
    }

    final renderObject = findRenderObject(rootElement!);

    if (renderObject != null) {
      // Attach render object to pipeline owner if needed
      if (renderObject.owner != pipelineOwner) {
        renderObject.attach(pipelineOwner);
      }

      // Layout phase
      renderObject.layout(
        BoxConstraints.tight(
          Size(size.width.toDouble(), size.height.toDouble()),
        ),
      );

      // Flush layout pipeline
      pipelineOwner.flushLayout();

      // Flush paint pipeline
      pipelineOwner.flushPaint();

      // Paint phase - paint directly to buffer
      final canvas = TerminalCanvas(buffer, screenRect);
      renderObject.paintWithContext(canvas, Offset.zero);
    }

    // Render to terminal using differential rendering (buffer diff)
    _renderDifferential(buffer);

    // Store buffer for next frame comparison
    _previousBuffer = buffer;

    // Rotate rainbow debug color for next frame
    if (debugRepaintRainbowEnabled) {
      debugCurrentRepaintColor = debugCurrentRepaintColor.withHue(
        (debugCurrentRepaintColor.hue + 2.0) % 360.0,
      );
    }
  }

  @override
  void initializeBinding() {
    super.initializeBinding();
    // Register the terminal drawing as a persistent callback
    addPersistentFrameCallback(_drawFrameCallback);
  }

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    registerBoolServiceExtension(
      name: 'repaintRainbow',
      getter: () async => debugRepaintRainbowEnabled,
      setter: (bool value) async {
        debugRepaintRainbowEnabled = value;
        // Force a repaint when toggling
        scheduleFrame();
      },
    );
  }

  /// Request application shutdown with proper cleanup
  ///
  /// This is the recommended way to exit a nocterm application.
  /// It ensures all terminal cleanup (including mouse tracking disable)
  /// happens before the process exits.
  ///
  /// IMPORTANT: Do NOT call dart:io's exit() directly, as it will bypass
  /// terminal cleanup and may leave the terminal in a broken state (e.g.,
  /// mouse movement producing escape sequences).
  ///
  /// Instead, always use this method or set [_shouldExit] to true.
  void requestShutdown([int exitCode = 0]) {
    _performImmediateShutdown();
    terminal.backend.requestExit(exitCode);
  }
}
