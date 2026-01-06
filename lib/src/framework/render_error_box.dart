part of 'framework.dart';

/// A render object used as a placeholder when an error occurs.
///
/// Similar to Flutter's RenderErrorBox, this provides a visual representation
/// of errors that occur during rendering. It displays a red bordered box with
/// the error message inside.
class RenderTUIErrorBox extends RenderObject
    with RenderObjectWithChildMixin<RenderObject> {
  /// Creates a RenderTUIErrorBox render object.
  ///
  /// A message can optionally be provided. If a message is provided,
  /// it will be rendered inside the error box.
  RenderTUIErrorBox({
    String message = '',
    Object? error,
    StackTrace? stackTrace,
  }) : _message = message.isNotEmpty
           ? message
           : error != null
           ? error.toString()
           : 'Error',
       _error = error,
       _stackTrace = stackTrace;

  final String _message;
  final Object? _error;
  final StackTrace? _stackTrace;

  /// Maximum size to use when constraints are unbounded
  static const double _kMaxSize = 100.0;

  @override
  void performLayout() {
    // Be defensive - ensure we don't throw during error handling
    try {
      // Try to fit within constraints, but use a reasonable default if unbounded
      final width = constraints.maxWidth.isFinite
          ? constraints.maxWidth.clamp(10.0, _kMaxSize)
          : 80.0; // Default terminal width
      final height = constraints.maxHeight.isFinite
          ? constraints.maxHeight.clamp(5.0, _kMaxSize)
          : 10.0; // Reasonable height for error display

      size = constraints.constrain(Size(width, height));
    } catch (e) {
      // If even error handling fails, use a minimal size
      size = const Size(20, 5);
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    try {
      // Draw red border box
      final rect = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

      // Draw border using box drawing characters with red color
      _drawBorder(canvas, rect);

      // Draw error message inside the box
      if (_message.isNotEmpty && size.width > 2 && size.height > 2) {
        _drawErrorText(canvas, rect);
      }
    } catch (e) {
      // If painting fails, at least try to output something
      try {
        canvas.drawText(
          offset,
          'ERROR',
          style: TextStyle(color: Color.fromRGB(255, 0, 0)),
        );
      } catch (_) {
        // Give up silently
      }
    }
  }

  void _drawBorder(TerminalCanvas canvas, Rect rect) {
    final left = rect.left.round();
    final top = rect.top.round();
    final right = (rect.right - 1).round();
    final bottom = (rect.bottom - 1).round();

    final borderStyle = TextStyle(color: Color.fromRGB(255, 0, 0));

    // Top border
    canvas.drawText(
      Offset(left.toDouble(), top.toDouble()),
      '┌',
      style: borderStyle,
    );
    for (int x = left + 1; x < right; x++) {
      canvas.drawText(
        Offset(x.toDouble(), top.toDouble()),
        '─',
        style: borderStyle,
      );
    }
    canvas.drawText(
      Offset(right.toDouble(), top.toDouble()),
      '┐',
      style: borderStyle,
    );

    // Side borders
    for (int y = top + 1; y < bottom; y++) {
      canvas.drawText(
        Offset(left.toDouble(), y.toDouble()),
        '│',
        style: borderStyle,
      );
      canvas.drawText(
        Offset(right.toDouble(), y.toDouble()),
        '│',
        style: borderStyle,
      );
    }

    // Bottom border
    canvas.drawText(
      Offset(left.toDouble(), bottom.toDouble()),
      '└',
      style: borderStyle,
    );
    for (int x = left + 1; x < right; x++) {
      canvas.drawText(
        Offset(x.toDouble(), bottom.toDouble()),
        '─',
        style: borderStyle,
      );
    }
    canvas.drawText(
      Offset(right.toDouble(), bottom.toDouble()),
      '┘',
      style: borderStyle,
    );
  }

  void _drawErrorText(TerminalCanvas canvas, Rect rect) {
    final left = rect.left.round() + 1;
    final top = rect.top.round() + 1;
    final availableWidth = (rect.width - 2).round();
    final availableHeight = (rect.height - 2).round();

    if (availableWidth <= 0 || availableHeight <= 0) return;

    final lines = <String>[];

    // Add the main error message
    lines.addAll(_wrapText(_message, availableWidth));

    // Add error details if available
    if (_error != null) {
      lines.add('');
      lines.addAll(_wrapText('Error: ${_error.toString()}', availableWidth));
    }

    // Add stack trace if available
    if (_stackTrace != null) {
      lines.add('');
      lines.add('Stack trace:');
      final stackLines = _stackTrace.toString().split('\n');
      // Show first few lines of stack trace that fit
      for (int i = 0; i < stackLines.length && i < 10; i++) {
        final stackLine = stackLines[i];
        if (stackLine.isNotEmpty) {
          // Truncate long stack lines
          final truncated = stackLine.length > availableWidth
              ? '${stackLine.substring(0, availableWidth - 3)}...'
              : stackLine;
          lines.add(truncated);
        }
      }
      if (stackLines.length > 10) {
        lines.add('... ${stackLines.length - 10} more lines');
      }
    }

    // Draw as many lines as will fit
    for (int i = 0; i < lines.length && i < availableHeight; i++) {
      canvas.drawText(Offset(left.toDouble(), (top + i).toDouble()), lines[i]);
    }
  }

  List<String> _wrapText(String text, int maxWidth) {
    if (maxWidth <= 0) return [];

    final lines = <String>[];
    final words = text.split(RegExp(r'\s+'));

    String currentLine = '';
    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ((currentLine.length + 1 + word.length) <= maxWidth) {
        currentLine += ' $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    // Truncate lines that are still too long
    return lines.map((line) {
      if (line.length > maxWidth) {
        return '${line.substring(0, maxWidth - 3)}...';
      }
      return line;
    }).toList();
  }

  @override
  bool hitTestSelf(Offset position) => true;
}
