import 'package:nocterm/nocterm.dart' hide TextAlign;
import 'package:nocterm/src/framework/terminal_canvas.dart';

import '../text/text_layout_engine.dart';

// Re-export text related enums
export '../text/text_layout_engine.dart' show TextOverflow, TextAlign;

/// Render object for displaying text
class RenderText extends RenderObject {
  RenderText({
    required String text,
    TextStyle? style,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    TextAlign textAlign = TextAlign.left,
    int? maxLines,
  }) : _text = text,
       _style = style,
       _softWrap = softWrap,
       _overflow = overflow,
       _textAlign = textAlign,
       _maxLines = maxLines;

  String _text;
  String get text => _text;
  set text(String value) {
    if (_text == value) return;
    _text = value;
    markNeedsLayout();
  }

  TextStyle? _style;
  TextStyle? get style => _style;
  set style(TextStyle? value) {
    if (_style == value) return;
    _style = value;
    markNeedsPaint();
  }

  bool _softWrap;
  bool get softWrap => _softWrap;
  set softWrap(bool value) {
    if (_softWrap == value) return;
    _softWrap = value;
    markNeedsLayout();
  }

  TextOverflow _overflow;
  TextOverflow get overflow => _overflow;
  set overflow(TextOverflow value) {
    if (_overflow == value) return;
    _overflow = value;
    markNeedsLayout();
  }

  TextAlign _textAlign;
  TextAlign get textAlign => _textAlign;
  set textAlign(TextAlign value) {
    if (_textAlign == value) return;
    _textAlign = value;
    markNeedsPaint();
  }

  int? _maxLines;
  int? get maxLines => _maxLines;
  set maxLines(int? value) {
    if (_maxLines == value) return;
    _maxLines = value;
    markNeedsLayout();
  }

  TextLayoutResult? _layoutResult;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void performLayout() {
    // For text alignment to work properly, we need to use the actual constraint width
    // When in a Column without stretch, we get infinite width, so we use intrinsic width
    final maxWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth.toInt()
        : double.maxFinite.toInt();

    // Debug: print constraint info
    // print('RenderText layout: text="$_text", constraints=$constraints, maxWidth=$maxWidth');

    final config = TextLayoutConfig(
      softWrap: _softWrap,
      overflow: _overflow,
      textAlign: _textAlign,
      maxLines: _maxLines,
      maxWidth: maxWidth,
    );

    _layoutResult = TextLayoutEngine.layout(_text, config);

    size = constraints.constrain(
      Size(
        _layoutResult!.actualWidth.toDouble(),
        _layoutResult!.actualHeight.toDouble(),
      ),
    );
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);

    if (_layoutResult == null) return;

    final lines = _layoutResult!.lines;
    // Use the actual size width for alignment, not the constraint
    // The size has been constrained during layout
    final alignmentWidth = size.width.toInt();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Check if this is the last line of a paragraph for justification
      bool isLastLine = i == lines.length - 1;
      if (i < lines.length - 1) {
        // Check if next line starts a new paragraph (was preceded by newline)
        // This is a simplification - proper implementation would track paragraph boundaries
        isLastLine = false;
      }

      // Apply justification if needed
      String displayLine = line;
      if (_textAlign == TextAlign.justify && !isLastLine) {
        displayLine = TextLayoutEngine.justifyLine(
          line,
          alignmentWidth,
          isLastLine: isLastLine,
        );
      }

      // Calculate horizontal offset based on text alignment
      final xOffset =
          offset.dx +
          TextLayoutEngine.calculateAlignmentOffset(
            displayLine,
            alignmentWidth,
            _textAlign,
          );

      // Apply clipping if needed
      if (_overflow == TextOverflow.clip && constraints.maxWidth.isFinite) {
        // The TextLayoutEngine already handles truncation, so we just paint what it gave us
        // But we might need to clip at the canvas level for safety
      }

      canvas.drawText(
        Offset(xOffset, offset.dy + i),
        displayLine,
        style: _style,
      );
    }
  }
}
