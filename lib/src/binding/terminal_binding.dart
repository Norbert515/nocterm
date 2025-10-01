import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import 'package:nocterm/src/navigation/render_theater.dart';
import 'package:nocterm/src/rectangle.dart';
import 'package:nocterm/src/rendering/scrollable_render_object.dart';
import 'package:nocterm/src/win32_ansi_stdin.dart';

import '../backend/terminal.dart' as term;
import '../buffer.dart' as buf;
import '../keyboard/input_parser.dart';
import '../keyboard/input_event.dart';
import '../keyboard/mouse_event.dart';
import '../components/block_focus.dart';
import 'hot_reload_mixin.dart';

/// Terminal UI binding that handles terminal input/output and event loop
class TerminalBinding extends NoctermBinding with HotReloadBinding {
  TerminalBinding(this.terminal, { this.logSink}) {
    _instance = this;
    _initializePipelineOwner();
  }

  static TerminalBinding? _instance;
  static TerminalBinding get instance => _instance!;

  final term.Terminal terminal;
  final IOSink? logSink;
  PipelineOwner? _pipelineOwner;
  PipelineOwner get pipelineOwner => _pipelineOwner!;

  // Expose buildOwner from the base class
  BuildOwner get buildOwner => super.buildOwner;

  Timer? _frameTimer;
  bool _shouldExit = false;
  final _inputController = StreamController<String>.broadcast();
  final _keyboardEventController = StreamController<KeyboardEvent>.broadcast();
  final _inputParser = InputParser();
  final _mouseEventController = StreamController<MouseEvent>.broadcast();

  // Event-driven loop support
  final _eventLoopController = StreamController<void>.broadcast();
  Stream<void> get _eventLoopStream => _eventLoopController.stream;

  // Post-frame callbacks
  final List<VoidCallback> _postFrameCallbacks = [];
  StreamSubscription? _inputSubscription;
  StreamSubscription? _sigwinchSubscription;
  StreamSubscription? _sigintSubscription;
  StreamSubscription? _sigtermSubscription;
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

  /// Initialize the terminal and start the event loop
  void initialize() {
    // Setup terminal
    terminal.enterAlternateScreen();
    terminal.hideCursor();
    terminal.clear();

    // Enable mouse tracking (SGR mode for better coordinate support)
    // ESC [ ? 1000 h - Send Mouse X & Y on button press and release
    // ESC [ ? 1002 h - Use Cell Motion Mouse Tracking
    // ESC [ ? 1003 h - Enable all motion mouse tracking
    // ESC [ ? 1006 h - Enable SGR mouse mode
    stdout.write('\x1B[?1000h'); // Basic mouse tracking
    stdout.write('\x1B[?1002h'); // Button event tracking
    stdout.write('\x1B[?1003h'); // All motion tracking
    stdout.write('\x1B[?1006h'); // SGR mouse mode

    // Store initial size
    _lastKnownSize = terminal.size;

    // Start listening for keyboard input
    _startInputHandling();

    // Start listening for terminal resize events
    _startResizeHandling();

    // Start listening for termination signals
    _startSignalHandling();
  }

  final Stdin platformStdin = Platform.isWindows ? Win32AnsiStdin() : stdin;

  void _startInputHandling() {
    // Only set stdin mode if we have a terminal
    try {
      if (platformStdin.hasTerminal) {
        platformStdin.echoMode = false;
        platformStdin.lineMode = false;
      }
    } catch (e) {
      // Ignore errors when running without a proper terminal
      // This happens in CI/CD environments or when piping output
    }

    // Listen for input at the byte level for proper escape sequence handling
    _inputSubscription = platformStdin.listen((bytes) {
      // Parse the bytes and process ALL events in the buffer
      _inputParser.addBytes(bytes);
  
      // For debugging, show raw input (replace ESC and ENTER for visibility)
      final data = utf8.decode(bytes);
      final visual = data.replaceAll('\x1b', 'ESC').replaceAll('\r', 'ENTER\n');
      logSink?.writeln('RAW Received: $visual');

      // Process all available events
      InputEvent? inputEvent;
      while ((inputEvent = _inputParser.parseNext()) != null) {
        if (inputEvent is KeyboardInputEvent) {

          logSink?.writeln('KeyboardInputEvent: ${inputEvent.event}');

          final event = inputEvent.event;
          // Add to keyboard event stream
          _keyboardEventController.add(event);

          // Route the event through the component tree
          _routeKeyboardEvent(event);

          // Note: Ctrl+C is handled by SIGINT signal handler, not here
          // This prevents double-handling and ensures proper cleanup
        } else if (inputEvent is MouseInputEvent) {

          logSink?.writeln('MouseInputEvent: ${inputEvent.event}');

  
          final event = inputEvent.event;
          // Add to mouse event stream
          _mouseEventController.add(event);

          // Route the mouse event through the component tree
          _routeMouseEvent(event);
        }
      }

      // After processing ALL events in the buffer, draw the frame once
      // This ensures that pasted text (multiple characters) gets processed
      // completely before rendering, rather than blocking after each character
      if (buildOwner.hasDirtyElements) {
        drawFrame();
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

  void _startResizeHandling() {
    // Listen for SIGWINCH signal on Unix systems
    if (Platform.isLinux || Platform.isMacOS) {
      _sigwinchSubscription = ProcessSignal.sigwinch.watch().listen((_) {
        _handleTerminalResize();
      });
    }

    // Also poll for size changes as a fallback
    // This helps on systems where SIGWINCH might not work properly
    Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_shouldExit) {
        _checkForSizeChange();
      }
    });
  }

  void _startSignalHandling() {
    // Listen for termination signals to ensure cleanup runs
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      // Handle SIGINT (Ctrl+C)
      _sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
        // Perform cleanup synchronously
        _performImmediateShutdown();

        // Exit immediately without async delays
        // This ensures single Ctrl+C quits the app
        exit(0);
      });
    }
    if (Platform.isLinux || Platform.isMacOS) {
      // Handle SIGTERM (kill command)
      _sigtermSubscription = ProcessSignal.sigterm.watch().listen((_) {
        // Perform cleanup synchronously
        _performImmediateShutdown();

        // Exit immediately
        exit(0);
      });
    }
  }

  /// Perform immediate synchronous shutdown for signal handlers
  void _performImmediateShutdown() {
    // Prevent multiple shutdowns
    if (_shouldExit) return;
    _shouldExit = true;

    // if we are using the win32 stdin, close it
    if (platformStdin is Win32AnsiStdin) {
      (platformStdin as Win32AnsiStdin).close();
    }

    // Cancel all timers and subscriptions immediately
    _frameTimer?.cancel();
    _inputSubscription?.cancel();
    _sigwinchSubscription?.cancel();
    _sigintSubscription?.cancel();
    _sigtermSubscription?.cancel();

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

    // Stop hot reload if it was initialized
    try {
      shutdownWithHotReload();
    } catch (_) {}

    // Perform terminal cleanup synchronously
    try {
      // IMPORTANT: Disable mouse tracking BEFORE leaving alternate screen
      stdout.write('\x1B[?1003l'); // Disable all motion tracking
      stdout.write('\x1B[?1006l'); // Disable SGR mouse mode
      stdout.write('\x1B[?1002l'); // Disable button event tracking
      stdout.write('\x1B[?1000l'); // Disable basic mouse tracking

      // Restore terminal
      terminal.showCursor();
      terminal.leaveAlternateScreen();
      terminal.clear();

      // Restore stdin
      if (platformStdin.hasTerminal) {
        platformStdin.echoMode = true;
        platformStdin.lineMode = true;
      }
    } catch (_) {
      // Ignore any errors during cleanup
    }
  }

  void _handleTerminalResize() {
    // Update terminal size and trigger a redraw
    if (stdout.hasTerminal) {
      final newSize = Size(stdout.terminalColumns.toDouble(), stdout.terminalLines.toDouble());
      if (_lastKnownSize == null ||
          _lastKnownSize!.width != newSize.width ||
          _lastKnownSize!.height != newSize.height) {
        _lastKnownSize = newSize;
        // Update the terminal's cached size
        terminal.updateSize(newSize);
        // Schedule a frame redraw
        scheduleFrame();
      }
    }
  }

  void _checkForSizeChange() {
    // Periodic check for size changes (fallback for systems without SIGWINCH)
    if (stdout.hasTerminal) {
      final currentSize = Size(stdout.terminalColumns.toDouble(), stdout.terminalLines.toDouble());
      if (_lastKnownSize == null ||
          _lastKnownSize!.width != currentSize.width ||
          _lastKnownSize!.height != currentSize.height) {
        _handleTerminalResize();
      }
    }
  }

  /// Route a keyboard event through the component tree
  void _routeKeyboardEvent(KeyboardEvent event) {
    if (rootElement == null) return;

    // Try to dispatch the event to the root element
    // The event will bubble through focused components
    _dispatchKeyToElement(rootElement!, event);
  }

  /// Route a mouse event through the component tree
  void _routeMouseEvent(MouseEvent event) {
    if (rootElement == null) return;

    // Handle wheel events for scrollable widgets
    if (event.button == MouseButton.wheelUp || event.button == MouseButton.wheelDown) {
      // Find the render object at the mouse position
      final renderObject = _findRenderObjectInTree(rootElement!);
      if (renderObject != null) {
        _dispatchMouseWheelAtPosition(rootElement!, event, Offset(event.x.toDouble(), event.y.toDouble()), Offset.zero);
      }
    }
    // For non-wheel mouse events (movement, clicks), we currently don't dispatch them
    // This prevents them from being converted to keyboard events
    // In the future, we could add proper mouse event handling here
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
      // Block all keyboard events from reaching children
      return false; // Event is "handled" (blocked)
    }

    // TODO: This is a hack to handle RenderTheater specially for Navigator
    // Should be properly integrated into the render object hierarchy
    if (element.renderObject is RenderTheater) {
      final multiChildRenderObject = element as MultiChildRenderObjectElement;
      if (multiChildRenderObject.children.length > 0) {
        final child = multiChildRenderObject.children.last;
        return _dispatchKeyToElement(child, event);
      }
    }

    // First, try to dispatch to children (depth-first)
    bool handled = false;
    element.visitChildren((child) {
      if (!handled) {
        handled = _dispatchKeyToElement(child, event);
      }
    });

    // If no child handled it, and this element can handle keys, try it
    if (!handled && element is FocusableElement) {
      handled = element.handleKeyEvent(event);
    }

    return handled;
  }

  /// Dispatch a mouse wheel event to scrollable RenderObjects at a specific position
  bool _dispatchMouseWheelAtPosition(Element element, MouseEvent event, Offset mousePos, Offset currentOffset) {
    // TODO: This is a hack to handle RenderTheater specially for Navigator
    // Should be properly integrated into the render object hierarchy
    if (element.renderObject is RenderTheater) {
      final multiChildRenderObject = element as MultiChildRenderObjectElement;
      if (multiChildRenderObject.children.length > 0) {
        final child = multiChildRenderObject.children.last;
        return _dispatchMouseWheelAtPosition(child, event, mousePos, currentOffset);
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

    element.visitChildren((child) {
      if (!handled) {
        handled = _dispatchMouseWheelAtPosition(child, event, mousePos, childrenOffset);
      }
    });

    // If no child handled it and this element's render object is scrollable, handle it here
    if (!handled && renderObject != null && renderObject is ScrollableRenderObjectMixin) {
      final scrollableRenderObject = renderObject as ScrollableRenderObjectMixin;
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
    _frameTimer?.cancel();
    _inputSubscription?.cancel();
    _sigwinchSubscription?.cancel();

    // Don't cancel signal subscriptions here - let them stay active
    // so they can handle additional signals if needed
    // _sigintSubscription?.cancel();
    // _sigtermSubscription?.cancel();

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
      // IMPORTANT: Disable mouse tracking BEFORE leaving alternate screen
      // This ensures the terminal properly processes the disable commands
      stdout.write('\x1B[?1003l'); // Disable all motion tracking FIRST
      stdout.write('\x1B[?1006l'); // Disable SGR mouse mode
      stdout.write('\x1B[?1002l'); // Disable button event tracking
      stdout.write('\x1B[?1000l'); // Disable basic mouse tracking LAST

      // Flush to ensure mouse disable commands are sent immediately
      stdout.flush();

      // Restore terminal (this includes leaving alternate screen)
      terminal.showCursor();
      terminal.leaveAlternateScreen();

      // CRITICAL: Disable mouse tracking again after leaving alternate screen
      // Some terminals restore previous state when switching buffers
      stdout.write('\x1B[?1003l'); // Disable all motion tracking
      stdout.write('\x1B[?1006l'); // Disable SGR mouse mode
      stdout.write('\x1B[?1002l'); // Disable button event tracking
      stdout.write('\x1B[?1000l'); // Disable basic mouse tracking

      // Send a terminal reset sequence as a final safety measure
      // This helps ensure the terminal is in a clean state
      stdout.write('\x1B[c'); // Reset Device Attributes (soft reset)

      stdout.flush();

      terminal.clear();

      // Final flush to ensure all cleanup is complete
      terminal.flush();
    } catch (e) {
      // If stdout is already closed or bound, we can't write to it
      // This can happen during signal-based shutdown
      // The important thing is we tried to cleanup
    }

    // Restore stdin if we have a terminal
    try {
      if (platformStdin.hasTerminal) {
        platformStdin.echoMode = true;
        platformStdin.lineMode = true;
      }
    } catch (e) {
      // Ignore errors when running without a proper terminal
    }
  }

  @override
  void scheduleFrame() {
    // Cancel any existing timer
    _frameTimer?.cancel();

    // Schedule frame to be drawn on next microtask
    // This batches updates that happen in the same event loop iteration
    _frameTimer = Timer(Duration.zero, () {
      drawFrame();
      _frameTimer = null;
    });

    // Wake up the event loop
    if (!_eventLoopController.isClosed) {
      _eventLoopController.add(null);
    }
  }

  @override
  void drawFrame() {
    if (rootElement == null) return;

    // Build phase
    super.drawFrame();

    // Get current terminal size (may have been updated by resize event)
    final size = terminal.size;
    final buffer = buf.Buffer(size.width.toInt(), size.height.toInt());

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
      renderObject.layout(BoxConstraints.tight(Size(size.width.toDouble(), size.height.toDouble())));

      // Flush layout pipeline
      pipelineOwner.flushLayout();

      // Flush paint pipeline
      pipelineOwner.flushPaint();

      // Paint phase - actually render to canvas
      final canvas = TerminalCanvas(
        buffer,
        Rect.fromLTWH(0, 0, size.width.toDouble(), size.height.toDouble()),
      );
      renderObject.paintWithContext(canvas, Offset.zero);
    }

    // Render to terminal
    terminal.moveTo(0, 0);
    for (int y = 0; y < buffer.height; y++) {
      for (int x = 0; x < buffer.width; x++) {
        final cell = buffer.getCell(x, y);

        // Skip zero-width space markers (used for emoji second column)
        if (cell.char == '\u200B') {
          continue;
        }

        // Apply style if present
        if (cell.style.color != null ||
            cell.style.backgroundColor != null ||
            cell.style.fontWeight == FontWeight.bold ||
            cell.style.fontWeight == FontWeight.dim ||
            cell.style.fontStyle == FontStyle.italic ||
            cell.style.decoration?.hasUnderline == true ||
            cell.style.reverse) {
          terminal.write(cell.style.toAnsi());
          terminal.write(cell.char);
          terminal.write(TextStyle.reset);
        } else {
          terminal.write(cell.char);
        }
      }
      if (y < buffer.height - 1) {
        terminal.write('\n');
      }
    }
    terminal.flush();

    // Execute post-frame callbacks
    final callbacks = List<VoidCallback>.from(_postFrameCallbacks);
    _postFrameCallbacks.clear();
    for (final callback in callbacks) {
      callback();
    }
  }

  /// Schedules a callback to be executed after the next frame is drawn.
  ///
  /// This is useful for performing actions that depend on the layout being
  /// complete, such as scrolling to a specific position after adding content.
  void addPostFrameCallback(VoidCallback callback) {
    _postFrameCallbacks.add(callback);
    // Schedule a frame if one isn't already scheduled
    scheduleFrame();
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
    exit(exitCode);
  }
}

/// Run a TUI application
Future<void> runApp(Component app, {bool enableHotReload = true}) async {
  // Open log file for capturing print statements
  final logFile = File('log.txt');
  final logSink = logFile.openWrite(mode: FileMode.writeOnly);

  // Store reference to binding for signal handler access
  TerminalBinding? binding;

  try {
    await runZoned(() async {
      final terminal = term.Terminal();
      binding = TerminalBinding(terminal, logSink: logSink);

      binding!.initialize();
      binding!.attachRootComponent(app);

      // Initialize hot reload in development mode
      if (enableHotReload && !bool.fromEnvironment('dart.vm.product')) {
        await binding!.initializeHotReload();
      }

      await binding!.runEventLoop();
    },
        zoneSpecification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String message) {
            // Write to log file instead of stdout
            try {
              logSink.writeln('[${DateTime.now().toIso8601String()}] $message');
            } catch (_) {
              // Ignore write errors if log sink is closed
            }
          },
          handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone, Object error, StackTrace stackTrace) {
            try {
              logSink.writeln('[${DateTime.now().toIso8601String()}] $error ${stackTrace.toString()}');
            } catch (_) {
              // Ignore write errors if log sink is closed
            }
          },
        ));
  } catch (e) {
    // If we exit via signal handler, this might throw
    // Just ensure cleanup happens
  } finally {
    // Ensure binding cleanup if not already done
    if (binding != null && !binding!._shouldExit) {
      binding!.shutdown();
    }

    // Close log file gracefully
    try {
      await logSink.flush();
      await logSink.close();
    } catch (_) {
      // Ignore errors if already closed
    }
  }
}
