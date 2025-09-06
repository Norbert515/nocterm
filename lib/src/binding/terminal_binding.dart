import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import 'package:nocterm/src/rectangle.dart';

import '../backend/terminal.dart' as term;
import '../buffer.dart' as buf;
import '../keyboard/input_parser.dart';
import '../keyboard/input_event.dart';
import '../keyboard/mouse_event.dart';
import '../components/scrollable_element.dart';
import 'hot_reload_mixin.dart';

/// Terminal UI binding that handles terminal input/output and event loop
class TerminalBinding extends NoctermBinding with HotReloadBinding {
  TerminalBinding(this.terminal) {
    _instance = this;
    _initializePipelineOwner();
  }

  static TerminalBinding? _instance;
  static TerminalBinding get instance => _instance!;

  final term.Terminal terminal;
  PipelineOwner? _pipelineOwner;
  PipelineOwner get pipelineOwner => _pipelineOwner!;

  Timer? _frameTimer;
  bool _shouldExit = false;
  final _inputController = StreamController<String>.broadcast();
  final _keyboardEventController = StreamController<KeyboardEvent>.broadcast();
  final _inputParser = InputParser();
  final _mouseEventController = StreamController<MouseEvent>.broadcast();
  StreamSubscription? _inputSubscription;
  StreamSubscription? _sigwinchSubscription;
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
  }

  void _startInputHandling() {
    // Only set stdin mode if we have a terminal
    try {
      if (stdin.hasTerminal) {
        stdin.echoMode = false;
        stdin.lineMode = false;
      }
    } catch (e) {
      // Ignore errors when running without a proper terminal
      // This happens in CI/CD environments or when piping output
    }

    // Listen for input at the byte level for proper escape sequence handling
    _inputSubscription = stdin.listen((bytes) {
      // Parse the bytes and process ALL events in the buffer
      _inputParser.addBytes(bytes);
      
      // Process all available events
      InputEvent? inputEvent;
      while ((inputEvent = _inputParser.parseNext()) != null) {
        if (inputEvent is KeyboardInputEvent) {
          final event = inputEvent.event;
          // Add to keyboard event stream
          _keyboardEventController.add(event);
          
          // Route the event through the component tree
          _routeKeyboardEvent(event);
          
          // Exit on Ctrl+C or Escape
          if (event.logicalKey == LogicalKey.escape || (event.matches(LogicalKey.keyC, ctrl: true))) {
            shutdown();
          }
        } else if (inputEvent is MouseInputEvent) {
          final event = inputEvent.event;
          // Add to mouse event stream
          _mouseEventController.add(event);
          
          // Route the mouse event through the component tree
          _routeMouseEvent(event);
        }
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
    
    // For now, just route wheel events to scrollable widgets
    if (event.button == MouseButton.wheelUp || event.button == MouseButton.wheelDown) {
      // Find the render object at the mouse position
      final renderObject = _findRenderObjectInTree(rootElement!);
      if (renderObject != null) {
        _dispatchMouseWheelAtPosition(rootElement!, event, Offset(event.x.toDouble(), event.y.toDouble()), Offset.zero);
      }
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
  
  /// Dispatch a mouse wheel event to scrollable elements at a specific position
  bool _dispatchMouseWheelAtPosition(Element element, MouseEvent event, Offset mousePos, Offset currentOffset) {
    // Calculate this element's bounds if it has a render object
    Rect? elementBounds;
    if (element is RenderObjectElement) {
      final renderObject = element.renderObject;
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
    
    // If no child handled it and this element is scrollable, handle it here
    if (!handled && element is StatefulElement) {
      final state = element.state;
      if (state is ScrollableElement) {
        handled = (state as ScrollableElement).handleMouseWheel(event);
      }
    }
    
    return handled;
  }

  /// Run the main event loop
  Future<void> runEventLoop() async {
    // Initial frame
    drawFrame();

    // Keep the app running until shutdown is called
    while (!_shouldExit) {
      await Future.delayed(const Duration(milliseconds: 16)); // ~60 FPS max
    }
  }

  /// Shutdown the terminal and cleanup
  void shutdown() {
    _shouldExit = true;
    _frameTimer?.cancel();
    _inputSubscription?.cancel();
    _sigwinchSubscription?.cancel();
    _inputController.close();
    _keyboardEventController.close();
    _mouseEventController.close();

    // Stop hot reload if it was initialized
    shutdownWithHotReload();
    
    // Disable mouse tracking
    stdout.write('\x1B[?1000l'); // Disable basic mouse tracking
    stdout.write('\x1B[?1002l'); // Disable button event tracking
    stdout.write('\x1B[?1003l'); // Disable all motion tracking  
    stdout.write('\x1B[?1006l'); // Disable SGR mouse mode

    // Restore stdin if we have a terminal
    try {
      if (stdin.hasTerminal) {
        stdin.echoMode = true;
        stdin.lineMode = true;
      }
    } catch (e) {
      // Ignore errors when running without a proper terminal
    }

    // Restore terminal
    terminal.showCursor();
    terminal.leaveAlternateScreen();
    terminal.clear();
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
      renderObject.paint(canvas, Offset.zero);
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
  }
}

/// Run a TUI application
Future<void> runApp(Component app, {bool enableHotReload = true}) async {
  // Open log file for capturing print statements
  final logFile = File('log.txt');
  final logSink = logFile.openWrite(mode: FileMode.writeOnly);

  try {
    await runZoned(() async {
      final terminal = term.Terminal();
      final binding = TerminalBinding(terminal);

      binding.initialize();
      binding.attachRootComponent(app);

      // Initialize hot reload in development mode
      if (enableHotReload && !bool.fromEnvironment('dart.vm.product')) {
        await binding.initializeHotReload();
      }

      await binding.runEventLoop();
    },
        zoneSpecification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String message) {
            // Write to log file instead of stdout
            logSink.writeln('[${DateTime.now().toIso8601String()}] $message');
          },
          handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone, Object error, StackTrace stackTrace) {
            logSink.writeln('[${DateTime.now().toIso8601String()}] $error ${stackTrace.toString()}');
          },
        ));
  } finally {
    await logSink.flush();
    await logSink.close();
  }
}
