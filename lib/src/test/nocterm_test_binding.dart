import 'dart:async';

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import 'package:nocterm/src/rendering/mouse_hit_test.dart';
import 'package:nocterm/src/rendering/mouse_tracker.dart';

import '../backend/terminal.dart' as term;
import '../buffer.dart' as buf;

/// Test binding for TUI applications that provides controlled frame rendering
/// and state inspection capabilities for testing.
class NoctermTestBinding extends NoctermBinding with SchedulerBinding {
  NoctermTestBinding({term.Terminal? terminal, this.size = const Size(80, 24)})
    : terminal = terminal ?? _MockTerminal(size) {
    _instance = this;
    _initializePipelineOwner();
  }

  static NoctermTestBinding? _instance;
  static NoctermTestBinding get instance => _instance!;

  final term.Terminal terminal;
  final Size size;
  PipelineOwner? _pipelineOwner;
  PipelineOwner get pipelineOwner => _pipelineOwner!;

  void _initializePipelineOwner() {
    _pipelineOwner = PipelineOwner();
    _pipelineOwner!.onNeedsVisualUpdate = scheduleFrame;
  }

  /// The current buffer state after the last frame
  buf.Buffer? _lastBuffer;
  buf.Buffer? get lastBuffer => _lastBuffer;

  /// Stream controller for simulating keyboard events
  final _testKeyboardController = StreamController<KeyboardEvent>.broadcast();

  /// Queue of pending keyboard events to be processed
  final _pendingKeyboardEvents = <KeyboardEvent>[];

  /// Queue of pending mouse events to be processed
  final _pendingMouseEvents = <MouseEvent>[];

  /// Mouse tracker for managing mouse annotations
  final _mouseTracker = MouseTracker();

  /// Number of frames that have been rendered
  int _frameCount = 0;
  int get frameCount => _frameCount;

  /// Pump a single frame
  Future<void> pump([Duration? duration]) async {
    if (duration != null) {
      await Future.delayed(duration);
    }

    // Process any pending keyboard events
    while (_pendingKeyboardEvents.isNotEmpty) {
      final event = _pendingKeyboardEvents.removeAt(0);
      _routeKeyboardEvent(event);
    }

    // Process any pending mouse events
    while (_pendingMouseEvents.isNotEmpty) {
      final event = _pendingMouseEvents.removeAt(0);
      _routeMouseEvent(event);
    }

    // Execute a frame using the scheduler
    final timestamp = Duration(
      microseconds: DateTime.now().microsecondsSinceEpoch,
    );
    handleBeginFrame(timestamp);
    _frameCount++;

    // Allow async operations to complete
    await Future.delayed(Duration.zero);
  }

  /// Pump frames until there are no more scheduled frames
  Future<void> pumpAndSettle([
    Duration duration = const Duration(milliseconds: 100),
    int maxIterations = 20,
  ]) async {
    int iterations = 0;
    bool hasChanges = true;

    while (hasChanges && iterations < maxIterations) {
      final previousFrameCount = _frameCount;
      await pump(duration);
      hasChanges = _frameCount > previousFrameCount || hasScheduledFrame;
      iterations++;
    }

    if (iterations >= maxIterations) {
      throw StateError(
        'pumpAndSettle exceeded maximum iterations ($maxIterations). '
        'The component tree may be continuously scheduling frames.',
      );
    }
  }

  /// Simulate keyboard input
  void sendKeyboardEvent(KeyboardEvent event) {
    _pendingKeyboardEvents.add(event);
  }

  /// Simulate text input
  void enterText(String text) {
    for (int i = 0; i < text.length; i++) {
      final key = LogicalKey.fromCharacter(text[i]);
      if (key != null) {
        _pendingKeyboardEvents.add(
          KeyboardEvent(logicalKey: key, character: text[i]),
        );
      }
    }
  }

  /// Simulate a mouse event
  void sendMouseEvent(MouseEvent event) {
    _pendingMouseEvents.add(event);
  }

  @override
  void scheduleFrameImpl() {
    // Override to prevent actual async scheduling in tests
    // The _hasScheduledFrame flag in SchedulerBinding will be set by scheduleFrame()
    // Tests manually call pump() to render frames
  }

  /// The actual frame drawing logic, registered as a persistent callback.
  void _drawFrameCallback(Duration timeStamp) {
    if (rootElement == null) return;

    // Build phase - handled by BuildOwner via persistent callback
    super.drawFrame();

    // Create a new buffer for this frame
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
      renderObject.layout(
        BoxConstraints.tight(
          Size(size.width.toDouble(), size.height.toDouble()),
        ),
      );

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

    // Store the buffer for inspection
    _lastBuffer = buffer;
  }

  @override
  void initializeBinding() {
    super.initializeBinding();
    // Register the test frame drawing as a persistent callback
    addPersistentFrameCallback(_drawFrameCallback);
  }

  /// Shutdown the test binding
  void shutdown() {
    _testKeyboardController.close();
    // Clear the singleton instance to allow multiple tests
    NoctermBinding.resetInstance();
    _instance = null;
  }

  /// Route a keyboard event through the component tree
  void _routeKeyboardEvent(KeyboardEvent event) {
    if (rootElement == null) return;

    // Try to dispatch the event to the root element
    _dispatchKeyToElement(rootElement!, event);
  }

  /// Route a mouse event through the component tree
  void _routeMouseEvent(MouseEvent event) {
    if (rootElement == null) return;

    // Find the render object in the tree
    final renderObject = _findRenderObjectInTree(rootElement!);
    if (renderObject != null) {
      final hitTestResult = MouseHitTestResult();
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
    // Import BlockFocusElement dynamically to avoid circular dependencies
    if (element.runtimeType.toString() == 'BlockFocusElement') {
      final dynamic blockFocusElement = element;
      if (blockFocusElement.isBlocking == true) {
        // Block all keyboard events from reaching children
        return true; // Event is "handled" (blocked)
      }
    }

    // First, try to dispatch to children (depth-first)
    bool handled = false;
    element.visitChildren((child) {
      if (!handled) {
        handled = _dispatchKeyToElement(child, event);
      }
    });

    // Check if this is a FocusableElement
    if (!handled && element is FocusableElement) {
      handled = element.handleKeyEvent(event);
    }

    // If no child handled it, and this element's component can handle keys, try it
    if (!handled && element.component is KeyboardHandler) {
      final handler = element.component as KeyboardHandler;
      handled = handler.handleKeyEvent(event);
    }

    return handled;
  }
}

/// Mock backend for testing that doesn't output to stdout
class _MockBackend implements TerminalBackend {
  final Size _size;

  _MockBackend(this._size);

  @override
  void writeRaw(String data) {}

  @override
  Size getSize() => _size;

  @override
  bool get supportsSize => true;

  @override
  Stream<List<int>>? get inputStream => null;

  @override
  Stream<Size>? get resizeStream => null;

  @override
  Stream<void>? get shutdownStream => null;

  @override
  void enableRawMode() {}

  @override
  void disableRawMode() {}

  @override
  bool get isAvailable => true;

  @override
  void notifySizeChanged(Size newSize) {}

  @override
  void requestExit([int exitCode = 0]) {}

  @override
  void dispose() {}
}

/// Mock terminal for testing that doesn't output to stdout
class _MockTerminal extends term.Terminal {
  _MockTerminal(Size size) : super(_MockBackend(size), size: size);

  @override
  void enterAlternateScreen() {}

  @override
  void leaveAlternateScreen() {}

  @override
  void hideCursor() {}

  @override
  void showCursor() {}

  @override
  void clear() {}

  @override
  void clearLine() {}

  @override
  void moveCursor(int x, int y) {}

  @override
  void moveToHome() {}

  @override
  void moveTo(int x, int y) {}

  @override
  void write(String text) {}

  @override
  void flush() {}

  @override
  void reset() {}
}

/// Interface for components that can handle keyboard events
abstract class KeyboardHandler {
  bool handleKeyEvent(KeyboardEvent event);
}
