import 'dart:async';

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import 'package:nocterm/src/rectangle.dart';

import '../backend/terminal.dart' as term;
import '../buffer.dart' as buf;

/// Test binding for TUI applications that provides controlled frame rendering
/// and state inspection capabilities for testing.
class NoctermTestBinding extends NoctermBinding {
  NoctermTestBinding({
    term.Terminal? terminal,
    this.size = const Size(80, 24),
  }) : terminal = terminal ?? _MockTerminal(size) {
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

  /// Number of frames that have been rendered
  int _frameCount = 0;
  int get frameCount => _frameCount;

  /// Whether there are pending frame callbacks
  bool _hasScheduledFrame = false;

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

    // Draw the frame
    drawFrame();
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
      hasChanges = _frameCount > previousFrameCount || _hasScheduledFrame;
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
        _pendingKeyboardEvents.add(KeyboardEvent(
          logicalKey: key,
          character: text[i],
        ));
      }
    }
  }

  @override
  void scheduleFrame() {
    _hasScheduledFrame = true;
    // Don't actually schedule - wait for pump() to be called
  }

  @override
  void drawFrame() {
    if (rootElement == null) return;

    // Build phase
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
      renderObject.layout(BoxConstraints.tight(
        Size(size.width.toDouble(), size.height.toDouble()),
      ));

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

    // Store the buffer for inspection
    _lastBuffer = buffer;
    _hasScheduledFrame = false;
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

  /// Dispatch a keyboard event to an element and its children
  bool _dispatchKeyToElement(Element element, KeyboardEvent event) {
    // First, try to dispatch to children (depth-first)
    bool handled = false;
    element.visitChildren((child) {
      if (!handled) {
        handled = _dispatchKeyToElement(child, event);
      }
    });

    // If no child handled it, and this element's component can handle keys, try it
    if (!handled && element.component is KeyboardHandler) {
      final handler = element.component as KeyboardHandler;
      handled = handler.handleKeyEvent(event);
    }

    return handled;
  }
}

/// Mock terminal for testing that doesn't output to stdout
class _MockTerminal extends term.Terminal {
  _MockTerminal(Size size) : super(size: size);

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
