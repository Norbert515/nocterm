import 'package:characters/characters.dart';
import 'package:nocterm/nocterm.dart' hide TextAlign;
import 'package:nocterm/src/framework/terminal_canvas.dart';
import 'package:nocterm/src/utils/unicode_width.dart';

import 'render_text.dart' show TextAlign;

/// Configuration for ASCII text layout.
class AsciiLayoutConfig {
  const AsciiLayoutConfig({
    required this.font,
    this.maxWidth,
    this.textAlign = TextAlign.left,
  });

  /// The ASCII font to use for rendering.
  final AsciiFont font;

  /// Maximum width in characters. If null, no wrapping is applied.
  final int? maxWidth;

  /// Text alignment within the available width.
  final TextAlign textAlign;
}

/// Result of ASCII text layout calculation.
class AsciiLayoutResult {
  const AsciiLayoutResult({
    required this.lines,
    required this.width,
    required this.height,
  });

  /// The rendered ASCII art lines.
  final List<String> lines;

  /// The total width in characters.
  final int width;

  /// The total height in lines.
  final int height;
}

/// Engine for converting text to ASCII art using a given font.
class AsciiLayoutEngine {
  AsciiLayoutEngine._();

  /// Convert text to ASCII art lines.
  static AsciiLayoutResult layout(String text, AsciiLayoutConfig config) {
    if (text.isEmpty) {
      return const AsciiLayoutResult(lines: [], width: 0, height: 0);
    }

    final font = config.font;
    final fontHeight = font.height;
    final letterSpacing = font.letterSpacing;

    // Split text into words for potential wrapping
    final words = text.split(' ');

    // Calculate total width per word and layout accordingly
    final List<List<String>> wordLayouts = [];
    final List<int> wordWidths = [];

    for (final word in words) {
      final layout = _layoutWord(word, font);
      wordLayouts.add(layout);
      wordWidths.add(
        layout.isEmpty ? 0 : UnicodeWidth.stringWidth(layout.first),
      );
    }

    // Calculate space width
    final spaceGlyph = font.getGlyph(' ');
    final spaceWidth = spaceGlyph.width + letterSpacing;

    // Build lines with optional wrapping
    final List<String> resultLines = [];
    int maxLineWidth = 0;

    if (config.maxWidth != null && config.maxWidth! > 0) {
      // With wrapping
      final wrappedRows = _wrapWords(
        wordLayouts,
        wordWidths,
        spaceWidth,
        config.maxWidth!,
        fontHeight,
      );

      for (final row in wrappedRows) {
        final rowWidth = UnicodeWidth.stringWidth(row.first);
        if (rowWidth > maxLineWidth) maxLineWidth = rowWidth;
        resultLines.addAll(row);
      }
    } else {
      // No wrapping - single line
      final singleLine = _joinWords(wordLayouts, spaceWidth, fontHeight);
      maxLineWidth = singleLine.isEmpty
          ? 0
          : UnicodeWidth.stringWidth(singleLine.first);
      resultLines.addAll(singleLine);
    }

    return AsciiLayoutResult(
      lines: resultLines,
      width: maxLineWidth,
      height: resultLines.length,
    );
  }

  /// Layout a single word without spaces.
  static List<String> _layoutWord(String word, AsciiFont font) {
    if (word.isEmpty) return [];

    final fontHeight = font.height;
    final letterSpacing = font.letterSpacing;
    final spacer = ' ' * letterSpacing;

    // Initialize lines for the word
    final lines = List.generate(fontHeight, (_) => StringBuffer());

    // Iterate by grapheme clusters to handle multi-codepoint characters correctly
    // (e.g., combining marks, emoji sequences)
    bool isFirst = true;
    for (final char in word.characters) {
      final glyph = font.getGlyph(char);

      // Add spacing between characters (not before first)
      if (!isFirst) {
        for (int lineIdx = 0; lineIdx < fontHeight; lineIdx++) {
          lines[lineIdx].write(spacer);
        }
      }
      isFirst = false;

      // Add glyph lines
      for (int lineIdx = 0; lineIdx < fontHeight; lineIdx++) {
        if (lineIdx < glyph.lines.length) {
          lines[lineIdx].write(glyph.lines[lineIdx]);
        } else {
          // Pad if glyph has fewer lines than font height
          lines[lineIdx].write(' ' * glyph.width);
        }
      }
    }

    return lines.map((sb) => sb.toString()).toList();
  }

  /// Wrap words to fit within maxWidth.
  static List<List<String>> _wrapWords(
    List<List<String>> wordLayouts,
    List<int> wordWidths,
    int spaceWidth,
    int maxWidth,
    int fontHeight,
  ) {
    final List<List<String>> rows = [];
    List<List<String>> currentRowWords = [];
    int currentRowWidth = 0;

    for (int i = 0; i < wordLayouts.length; i++) {
      final wordLayout = wordLayouts[i];
      final wordWidth = wordWidths[i];

      if (wordLayout.isEmpty) continue;

      final widthIfAdded = currentRowWidth == 0
          ? wordWidth
          : currentRowWidth + spaceWidth + wordWidth;

      if (widthIfAdded <= maxWidth || currentRowWords.isEmpty) {
        // Add to current row
        currentRowWords.add(wordLayout);
        currentRowWidth = widthIfAdded;
      } else {
        // Start new row
        rows.add(_joinWords(currentRowWords, spaceWidth, fontHeight));
        currentRowWords = [wordLayout];
        currentRowWidth = wordWidth;
      }
    }

    // Add final row
    if (currentRowWords.isNotEmpty) {
      rows.add(_joinWords(currentRowWords, spaceWidth, fontHeight));
    }

    return rows;
  }

  /// Join multiple word layouts with space between them.
  static List<String> _joinWords(
    List<List<String>> wordLayouts,
    int spaceWidth,
    int fontHeight,
  ) {
    if (wordLayouts.isEmpty) return [];
    if (wordLayouts.length == 1) return wordLayouts.first;

    final lines = List.generate(fontHeight, (_) => StringBuffer());
    final spacer = ' ' * spaceWidth;

    for (int wordIdx = 0; wordIdx < wordLayouts.length; wordIdx++) {
      final wordLayout = wordLayouts[wordIdx];

      // Add space between words
      if (wordIdx > 0) {
        for (int lineIdx = 0; lineIdx < fontHeight; lineIdx++) {
          lines[lineIdx].write(spacer);
        }
      }

      // Add word lines
      for (int lineIdx = 0; lineIdx < fontHeight; lineIdx++) {
        if (lineIdx < wordLayout.length) {
          lines[lineIdx].write(wordLayout[lineIdx]);
        }
      }
    }

    return lines.map((sb) => sb.toString()).toList();
  }

  /// Calculate alignment offset for a line.
  static double calculateAlignmentOffset(
    String line,
    int maxWidth,
    TextAlign textAlign,
  ) {
    final lineWidth = UnicodeWidth.stringWidth(line);
    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.justify:
        return 0.0;
      case TextAlign.right:
        return (maxWidth - lineWidth).toDouble().clamp(0, double.infinity);
      case TextAlign.center:
        return ((maxWidth - lineWidth) / 2).clamp(0, double.infinity);
    }
  }
}

/// Render object for ASCII art text.
class RenderAsciiText extends RenderObject {
  RenderAsciiText({
    required String text,
    TextStyle? style,
    AsciiFont font = const _StandardFontRef(),
    TextAlign textAlign = TextAlign.left,
  }) : _text = text,
       _style = style,
       _font = font,
       _textAlign = textAlign;

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

  AsciiFont _font;
  AsciiFont get font => _font;
  set font(AsciiFont value) {
    if (_font == value) return;
    _font = value;
    markNeedsLayout();
  }

  TextAlign _textAlign;
  TextAlign get textAlign => _textAlign;
  set textAlign(TextAlign value) {
    if (_textAlign == value) return;
    _textAlign = value;
    markNeedsPaint();
  }

  AsciiLayoutResult? _layoutResult;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void performLayout() {
    final maxWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth.toInt()
        : null;

    final config = AsciiLayoutConfig(
      font: _font,
      maxWidth: maxWidth,
      textAlign: _textAlign,
    );

    _layoutResult = AsciiLayoutEngine.layout(_text, config);

    size = constraints.constrain(
      Size(_layoutResult!.width.toDouble(), _layoutResult!.height.toDouble()),
    );
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);

    if (_layoutResult == null) return;

    final lines = _layoutResult!.lines;
    final alignmentWidth = size.width.toInt();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Calculate horizontal offset based on text alignment
      final xOffset =
          offset.dx +
          AsciiLayoutEngine.calculateAlignmentOffset(
            line,
            alignmentWidth,
            _textAlign,
          );

      canvas.drawText(Offset(xOffset, offset.dy + i), line, style: _style);
    }
  }
}

/// Internal reference class for default font (to avoid import cycles).
class _StandardFontRef extends AsciiFont {
  const _StandardFontRef();

  @override
  int get height => AsciiFont.standard.height;

  @override
  int get letterSpacing => AsciiFont.standard.letterSpacing;

  @override
  Map<String, AsciiGlyph> get glyphs => AsciiFont.standard.glyphs;
}
