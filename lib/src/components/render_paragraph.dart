import 'package:characters/characters.dart';
import 'package:nocterm/nocterm.dart' hide TextAlign;
import 'package:nocterm/src/framework/terminal_canvas.dart';

import '../text/text_layout_engine.dart';
import '../utils/unicode_width.dart';
export '../text/text_layout_engine.dart' show TextOverflow, TextAlign;

/// Render object for displaying rich text (text with multiple styles).
///
/// This is similar to RenderText but supports TextSpan with mixed styles.
class RenderParagraph extends RenderObject with Selectable {
  RenderParagraph({
    required InlineSpan text,
    TextAlign textAlign = TextAlign.left,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    int? maxLines,
  })  : _text = text,
        _textAlign = textAlign,
        _softWrap = softWrap,
        _overflow = overflow,
        _maxLines = maxLines;

  InlineSpan _text;
  InlineSpan get text => _text;
  set text(InlineSpan value) {
    if (_text == value) return;
    _text = value;
    _cachedSegments = null;
    markNeedsLayout();
  }

  TextAlign _textAlign;
  TextAlign get textAlign => _textAlign;
  set textAlign(TextAlign value) {
    if (_textAlign == value) return;
    _textAlign = value;
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

  int? _maxLines;
  int? get maxLines => _maxLines;
  set maxLines(int? value) {
    if (_maxLines == value) return;
    _maxLines = value;
    markNeedsLayout();
  }

  // Cache the styled segments to avoid recomputing them
  List<StyledTextSegment>? _cachedSegments;

  // Store the layout result and the styled lines
  TextLayoutResult? _layoutResult;
  List<List<StyledTextSegment>>? _styledLines;

  List<StyledTextSegment> get _segments {
    _cachedSegments ??= _text.toStyledSegments();
    return _cachedSegments!;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void performLayout() {
    final maxWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth.toInt()
        : double.maxFinite.toInt();

    // Get the plain text for layout calculation
    final plainText = _text.toPlainText();

    final config = TextLayoutConfig(
      softWrap: _softWrap,
      overflow: _overflow,
      textAlign: _textAlign,
      maxLines: _maxLines,
      maxWidth: maxWidth,
    );

    _layoutResult = TextLayoutEngine.layout(plainText, config);

    // Now map the styled segments to the laid out lines
    _styledLines = _mapSegmentsToLines(_segments, _layoutResult!.lines);

    size = constraints.constrain(Size(
      _layoutResult!.actualWidth.toDouble(),
      _layoutResult!.actualHeight.toDouble(),
    ));
  }

  /// Maps styled segments to the laid out lines.
  ///
  /// This function takes the original styled segments and the lines produced
  /// by the layout engine, and creates a list of styled segments for each line.
  ///
  /// The key insight is that the layout engine:
  /// 1. Splits text by '\n' into paragraphs
  /// 2. Word-wraps each paragraph into multiple lines
  /// 3. Returns lines WITHOUT the newline characters
  ///
  /// We need to map character positions from the laid-out lines back to the
  /// original styled segments, skipping newlines in the source text.
  List<List<StyledTextSegment>> _mapSegmentsToLines(
    List<StyledTextSegment> segments,
    List<String> lines,
  ) {
    final List<List<StyledTextSegment>> styledLines = [];

    // Flatten segments into a list of (grapheme, style) pairs for easier indexing
    // Use grapheme clusters for proper Unicode handling (emojis, ZWJ sequences, etc.)
    final List<(String, TextStyle?)> charStyles = [];
    for (final segment in segments) {
      for (final grapheme in segment.text.characters) {
        charStyles.add((grapheme, segment.style));
      }
    }

    int charIndex = 0;

    for (final line in lines) {
      final List<StyledTextSegment> lineSegments = [];

      // Skip any newlines at current position (paragraph breaks)
      while (
          charIndex < charStyles.length && charStyles[charIndex].$1 == '\n') {
        charIndex++;
      }

      // Now consume graphemes for this line
      // Use grapheme count for proper Unicode handling
      final lineGraphemeCount = line.characters.length;
      int linePos = 0;
      while (linePos < lineGraphemeCount && charIndex < charStyles.length) {
        final (char, style) = charStyles[charIndex];

        // Skip newlines in source (they don't appear in laid out lines)
        if (char == '\n') {
          charIndex++;
          continue;
        }

        // Find consecutive graphemes with same style
        final currentStyle = style;
        final buffer = StringBuffer();

        while (charIndex < charStyles.length &&
            linePos < lineGraphemeCount &&
            charStyles[charIndex].$2 == currentStyle &&
            charStyles[charIndex].$1 != '\n') {
          buffer.write(charStyles[charIndex].$1);
          charIndex++;
          linePos++;
        }

        if (buffer.isNotEmpty) {
          lineSegments.add(StyledTextSegment(buffer.toString(), currentStyle));
        }
      }

      styledLines.add(lineSegments);
    }

    return styledLines;
  }

  String get plainText => _text.toPlainText();

  @override
  String get selectableText => plainText;

  @override
  TextLayoutResult? get selectableLayout => _layoutResult;

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);

    if (_layoutResult == null || _styledLines == null) return;

    final alignmentWidth = size.width.toInt();

    for (int i = 0; i < _styledLines!.length; i++) {
      final lineSegments = _styledLines![i];

      // Calculate the full line text for alignment
      final StringBuffer lineBuffer = StringBuffer();
      for (final segment in lineSegments) {
        lineBuffer.write(segment.text);
      }
      final lineText = lineBuffer.toString();

      // Apply justification if needed
      String displayLine = lineText;
      bool isLastLine = i == _styledLines!.length - 1;
      if (_textAlign == TextAlign.justify && !isLastLine) {
        displayLine = TextLayoutEngine.justifyLine(lineText, alignmentWidth,
            isLastLine: isLastLine);
      }

      // Calculate horizontal offset based on text alignment
      final xOffset = offset.dx +
          TextLayoutEngine.calculateAlignmentOffset(
            displayLine,
            alignmentWidth,
            _textAlign,
          );

      // Use selection-aware painting if there is an active selection
      if (hasSelection) {
        _paintLineWithSelection(
            canvas, Offset(xOffset, offset.dy + i), lineSegments, lineText, i);
      } else {
        // Paint each segment with its style
        // Snap to integer cell boundary — fractional offsets from
        // alignment calculations (e.g. center: (width - text) / 2)
        // cause rounding drift across styled segments.
        int currentX = xOffset.round();
        for (final segment in lineSegments) {
          canvas.drawText(
            Offset(currentX.toDouble(), offset.dy + i),
            segment.text,
            style: segment.style,
          );
          currentX += UnicodeWidth.stringWidth(segment.text);
        }
      }
    }
  }

  /// Paints a line with styled segments and selection highlighting.
  void _paintLineWithSelection(
    TerminalCanvas canvas,
    Offset offset,
    List<StyledTextSegment> segments,
    String lineText,
    int lineIndex,
  ) {
    final lines = _layoutResult?.lines ?? const [];
    final text = selectableText;
    final selStart = selectionStart;
    final selEnd = selectionEnd;

    // Calculate line start offset in the full text
    final lineStartOffset = Selectable.lineStartOffsets(text, lines)[lineIndex];
    final lineEndOffset = lineStartOffset + lineText.length;

    // Normalize selection range
    final normalizedSelStart =
        selStart != null && selEnd != null ? selStart.clamp(0, text.length) : 0;
    final normalizedSelEnd =
        selStart != null && selEnd != null ? selEnd.clamp(0, text.length) : 0;
    final selRangeStart = normalizedSelStart < normalizedSelEnd
        ? normalizedSelStart
        : normalizedSelEnd;
    final selRangeEnd = normalizedSelStart < normalizedSelEnd
        ? normalizedSelEnd
        : normalizedSelStart;

    // Check if selection intersects this line
    final hasLineSelection =
        selRangeEnd > lineStartOffset && selRangeStart < lineEndOffset;

    double currentX = offset.dx.roundToDouble();
    int charOffset = lineStartOffset;

    for (final segment in segments) {
      final segmentText = segment.text;
      final segmentEnd = charOffset + segmentText.length;

      if (hasLineSelection &&
          selRangeEnd > charOffset &&
          selRangeStart < segmentEnd) {
        // Selection intersects this segment - split it
        final localSelStart =
            (selRangeStart - charOffset).clamp(0, segmentText.length);
        final localSelEnd =
            (selRangeEnd - charOffset).clamp(0, segmentText.length);

        // Paint before selection
        if (localSelStart > 0) {
          final beforeText = segmentText.substring(0, localSelStart);
          canvas.drawText(
            Offset(currentX, offset.dy),
            beforeText,
            style: segment.style,
          );
          currentX += UnicodeWidth.stringWidth(beforeText);
        }

        // Paint selected portion
        if (localSelStart < localSelEnd) {
          final selectedText =
              segmentText.substring(localSelStart, localSelEnd);
          final selectionStyle = (segment.style ?? const TextStyle())
              .copyWith(backgroundColor: selectionColor ?? Colors.blue);
          canvas.drawText(
            Offset(currentX, offset.dy),
            selectedText,
            style: selectionStyle,
          );
          currentX += UnicodeWidth.stringWidth(selectedText);
        }

        // Paint after selection
        if (localSelEnd < segmentText.length) {
          final afterText = segmentText.substring(localSelEnd);
          canvas.drawText(
            Offset(currentX, offset.dy),
            afterText,
            style: segment.style,
          );
          currentX += UnicodeWidth.stringWidth(afterText);
        }
      } else {
        // No selection in this segment, paint normally
        canvas.drawText(
          Offset(currentX, offset.dy),
          segmentText,
          style: segment.style,
        );
        currentX += UnicodeWidth.stringWidth(segmentText);
      }

      charOffset = segmentEnd;
    }
  }
}
