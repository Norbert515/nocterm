import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';

/// A widget that displays an error message when a render object fails.
///
/// This widget is used as a fallback when errors occur during rendering.
/// It provides a visual representation of the error in the terminal.
class TUIErrorWidget extends SingleChildRenderObjectComponent {
  const TUIErrorWidget({
    super.key,
    this.message = 'Error',
    this.error,
    this.stackTrace,
  });

  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTUIErrorBox(
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTUIErrorBox renderObject,
  ) {
    // RenderTUIErrorBox is immutable after creation
  }
}

/// A widget that deliberately throws an error during layout.
/// Used for testing error handling.
class ErrorThrowingWidget extends SingleChildRenderObjectComponent {
  const ErrorThrowingWidget({
    super.key,
    this.throwInLayout = true,
    this.throwInPaint = false,
    this.errorMessage = 'Deliberate test error',
  });

  final bool throwInLayout;
  final bool throwInPaint;
  final String errorMessage;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderErrorThrowing(
      throwInLayout: throwInLayout,
      throwInPaint: throwInPaint,
      errorMessage: errorMessage,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderErrorThrowing renderObject,
  ) {
    renderObject
      ..throwInLayout = throwInLayout
      ..throwInPaint = throwInPaint
      ..errorMessage = errorMessage;
  }
}

/// A render object that deliberately throws errors for testing.
class RenderErrorThrowing extends RenderObject {
  RenderErrorThrowing({
    required bool throwInLayout,
    required bool throwInPaint,
    required String errorMessage,
  }) : _throwInLayout = throwInLayout,
       _throwInPaint = throwInPaint,
       _errorMessage = errorMessage;

  bool _throwInLayout;
  bool get throwInLayout => _throwInLayout;
  set throwInLayout(bool value) {
    if (_throwInLayout != value) {
      _throwInLayout = value;
      markNeedsLayout();
    }
  }

  bool _throwInPaint;
  bool get throwInPaint => _throwInPaint;
  set throwInPaint(bool value) {
    if (_throwInPaint != value) {
      _throwInPaint = value;
      markNeedsPaint();
    }
  }

  String _errorMessage;
  String get errorMessage => _errorMessage;
  set errorMessage(String value) {
    if (_errorMessage != value) {
      _errorMessage = value;
      markNeedsPaint();
    }
  }

  @override
  void performLayout() {
    if (_throwInLayout) {
      // Deliberately cause an error - divide by zero
      final x = 1;
      final y = 0;
      final z = x ~/ y; // This will throw
      print('This should never print: $z');
    }

    // If we somehow get here, set a size
    size = constraints.constrain(const Size(20, 5));
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);

    if (_throwInPaint) {
      // Deliberately cause an error
      throw Exception(_errorMessage);
    }

    // Normal paint (if not throwing)
    canvas.drawText(offset, 'No Error');
  }

  @override
  bool hitTestSelf(Offset position) => true;
}
