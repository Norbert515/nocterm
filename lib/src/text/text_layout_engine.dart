import 'package:characters/characters.dart';
import '../utils/unicode_width.dart';

/// How overflowing text should be handled
enum TextOverflow {
  /// Clip the overflowing text to fix its container
  clip,
  
  /// Use an ellipsis to indicate that the text has overflowed
  ellipsis,
  
  /// Render overflowing text outside of its container
  visible,
}

/// How the text should be aligned horizontally
enum TextAlign {
  /// Align the text on the left edge of the container
  left,
  
  /// Align the text on the right edge of the container  
  right,
  
  /// Align the text in the center of the container
  center,
  
  /// Stretch lines of text to align both edges to the container
  justify,
}

/// Configuration for text layout
class TextLayoutConfig {
  final bool softWrap;
  final TextOverflow overflow;
  final TextAlign textAlign;
  final int? maxLines;
  final int maxWidth;
  
  const TextLayoutConfig({
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textAlign = TextAlign.left,
    this.maxLines,
    required this.maxWidth,
  });
}

/// Result of text layout calculation
class TextLayoutResult {
  final List<String> lines;
  final int actualWidth;
  final int actualHeight;
  final bool didOverflowWidth;
  final bool didOverflowHeight;
  
  const TextLayoutResult({
    required this.lines,
    required this.actualWidth,
    required this.actualHeight,
    required this.didOverflowWidth,
    required this.didOverflowHeight,
  });
}

/// Engine for laying out text with word wrapping and overflow handling
class TextLayoutEngine {
  static const String _ellipsis = '...';
  
  /// Perform text layout with the given configuration
  static TextLayoutResult layout(String text, TextLayoutConfig config) {
    if (!config.softWrap || config.maxWidth == double.maxFinite.toInt()) {
      return _layoutNoWrap(text, config);
    }
    
    return _layoutWithWrap(text, config);
  }
  
  /// Layout text without wrapping (only handle explicit newlines)
  static TextLayoutResult _layoutNoWrap(String text, TextLayoutConfig config) {
    final lines = text.split('\n');
    final maxLineWidth = lines.fold(0, (max, line) {
      final width = UnicodeWidth.stringWidth(line);
      return width > max ? width : max;
    });
    
    // Apply maxLines constraint
    List<String> finalLines = lines;
    bool didOverflowHeight = false;
    
    if (config.maxLines != null && lines.length > config.maxLines!) {
      didOverflowHeight = true;
      finalLines = lines.take(config.maxLines!).toList();
      
      if (config.overflow == TextOverflow.ellipsis && finalLines.isNotEmpty) {
        finalLines[finalLines.length - 1] = 
            _addEllipsisToLine(finalLines.last, config.maxWidth);
      }
    }
    
    return TextLayoutResult(
      lines: finalLines,
      actualWidth: maxLineWidth,
      actualHeight: finalLines.length,
      didOverflowWidth: maxLineWidth > config.maxWidth,
      didOverflowHeight: didOverflowHeight,
    );
  }
  
  /// Layout text with word wrapping
  static TextLayoutResult _layoutWithWrap(String text, TextLayoutConfig config) {
    final List<String> wrappedLines = [];
    final paragraphs = text.split('\n');
    
    for (final paragraph in paragraphs) {
      if (paragraph.isEmpty) {
        wrappedLines.add('');
        continue;
      }
      
      final lines = _wrapParagraph(paragraph, config.maxWidth);
      wrappedLines.addAll(lines);
    }
    
    // Apply maxLines constraint
    List<String> finalLines = wrappedLines;
    bool didOverflowHeight = false;
    
    if (config.maxLines != null && wrappedLines.length > config.maxLines!) {
      didOverflowHeight = true;
      finalLines = wrappedLines.take(config.maxLines!).toList();
      
      if (config.overflow == TextOverflow.ellipsis && finalLines.isNotEmpty) {
        finalLines[finalLines.length - 1] = 
            _addEllipsisToLine(finalLines.last, config.maxWidth);
      }
    }
    
    // Calculate actual width
    final actualWidth = finalLines.fold(0, (max, line) {
      final width = UnicodeWidth.stringWidth(line);
      return width > max ? width : max;
    });
    
    return TextLayoutResult(
      lines: finalLines,
      actualWidth: actualWidth,
      actualHeight: finalLines.length,
      didOverflowWidth: actualWidth > config.maxWidth,
      didOverflowHeight: didOverflowHeight,
    );
  }
  
  /// Wrap a single paragraph into multiple lines
  static List<String> _wrapParagraph(String paragraph, int maxWidth) {
    final List<String> lines = [];
    final words = _splitIntoWords(paragraph);
    
    String currentLine = '';
    int currentLineWidth = 0;
    
    for (final word in words) {
      final wordWidth = UnicodeWidth.stringWidth(word);
      
      if (currentLineWidth == 0) {
        // First word on line
        if (wordWidth > maxWidth) {
          // Word is too long - need to break it
          final brokenWords = _breakLongWord(word, maxWidth);
          for (int i = 0; i < brokenWords.length - 1; i++) {
            lines.add(brokenWords[i]);
          }
          currentLine = brokenWords.last;
          currentLineWidth = UnicodeWidth.stringWidth(brokenWords.last);
        } else {
          currentLine = word;
          currentLineWidth = wordWidth;
        }
      } else if (currentLineWidth + wordWidth <= maxWidth) {
        // Word fits on current line
        currentLine += word;
        currentLineWidth += wordWidth;
      } else {
        // Word doesn't fit - start new line
        lines.add(currentLine);
        
        if (wordWidth > maxWidth) {
          // Word is too long for a line by itself
          final brokenWords = _breakLongWord(word, maxWidth);
          for (int i = 0; i < brokenWords.length - 1; i++) {
            lines.add(brokenWords[i]);
          }
          currentLine = brokenWords.last;
          currentLineWidth = UnicodeWidth.stringWidth(brokenWords.last);
        } else {
          currentLine = word;
          currentLineWidth = wordWidth;
        }
      }
    }
    
    // Add remaining line
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    
    return lines;
  }
  
  /// Split text into words, preserving spaces and considering break opportunities
  static List<String> _splitIntoWords(String text) {
    final List<String> words = [];
    final StringBuffer currentWord = StringBuffer();

    String? prevGrapheme;
    for (final grapheme in text.characters) {
      // Check for break opportunities
      if (_canBreakAfter(prevGrapheme, grapheme)) {
        if (currentWord.isNotEmpty) {
          words.add(currentWord.toString());
          currentWord.clear();
        }
        if (grapheme == ' ') {
          words.add(' ');
        } else {
          currentWord.write(grapheme);
        }
      } else {
        currentWord.write(grapheme);
      }
      prevGrapheme = grapheme;
    }

    if (currentWord.isNotEmpty) {
      words.add(currentWord.toString());
    }

    return words;
  }

  /// Check if we can break between two graphemes
  static bool _canBreakAfter(String? prev, String next) {
    if (prev == null) return false;

    // Always break on spaces
    if (next == ' ' || prev == ' ') return true;

    // Break after hyphens
    if (prev == '-') return true;

    // Break after slashes (for URLs)
    if (prev == '/') return true;

    // Zero-width space is an explicit break opportunity
    if (prev == '\u200B' || next == '\u200B') return true;

    // CJK characters can break between each other
    if (_isCJK(prev) && _isCJK(next)) return true;

    return false;
  }

  /// Check if a grapheme is a CJK character
  static bool _isCJK(String grapheme) {
    if (grapheme.isEmpty) return false;
    final rune = grapheme.runes.first;

    // CJK Unified Ideographs
    if ((rune >= 0x4E00 && rune <= 0x9FFF) ||
        (rune >= 0x3400 && rune <= 0x4DBF) ||
        (rune >= 0x20000 && rune <= 0x2A6DF)) {
      return true;
    }

    // Hiragana, Katakana
    if ((rune >= 0x3040 && rune <= 0x309F) ||
        (rune >= 0x30A0 && rune <= 0x30FF)) {
      return true;
    }

    // Hangul
    if (rune >= 0xAC00 && rune <= 0xD7AF) {
      return true;
    }

    return false;
  }
  
  /// Break a long word that doesn't fit on a single line
  static List<String> _breakLongWord(String word, int maxWidth) {
    final List<String> parts = [];
    String currentPart = '';
    int currentWidth = 0;

    // Use grapheme clusters to avoid breaking multi-codepoint characters
    for (final grapheme in word.characters) {
      final graphemeW = UnicodeWidth.graphemeWidth(grapheme);

      if (currentWidth + graphemeW > maxWidth && currentPart.isNotEmpty) {
        parts.add(currentPart);
        currentPart = grapheme;
        currentWidth = graphemeW;
      } else {
        currentPart += grapheme;
        currentWidth += graphemeW;
      }
    }

    if (currentPart.isNotEmpty) {
      parts.add(currentPart);
    }

    return parts.isEmpty ? [''] : parts;
  }
  
  /// Add ellipsis to a line, truncating as needed
  static String _addEllipsisToLine(String line, int maxWidth) {
    final ellipsisWidth = UnicodeWidth.stringWidth(_ellipsis);
    final lineWidth = UnicodeWidth.stringWidth(line);

    if (lineWidth <= maxWidth - ellipsisWidth) {
      return line + _ellipsis;
    }

    // Truncate line to make room for ellipsis using grapheme clusters
    String truncated = '';
    int width = 0;

    for (final grapheme in line.characters) {
      final graphemeW = UnicodeWidth.graphemeWidth(grapheme);

      if (width + graphemeW + ellipsisWidth > maxWidth) {
        break;
      }

      truncated += grapheme;
      width += graphemeW;
    }

    return truncated + _ellipsis;
  }
  
  /// Calculate horizontal offset for a line based on alignment
  static double calculateAlignmentOffset(
    String line,
    int maxWidth,
    TextAlign textAlign,
  ) {
    final lineWidth = UnicodeWidth.stringWidth(line);
    
    switch (textAlign) {
      case TextAlign.left:
        return 0;
      case TextAlign.right:
        return (maxWidth - lineWidth).toDouble();
      case TextAlign.center:
        return (maxWidth - lineWidth) / 2;
      case TextAlign.justify:
        // Justify is handled separately with word spacing
        return 0;
    }
  }
  
  /// Apply justification to a line by adding spaces between words
  static String justifyLine(String line, int maxWidth, {bool isLastLine = false}) {
    if (isLastLine) {
      return line; // Don't justify last line of paragraph
    }
    
    final words = _splitIntoWords(line).where((w) => w != ' ').toList();
    if (words.length <= 1) {
      return line; // Can't justify single word
    }
    
    final totalWordWidth = words.fold(0, 
        (sum, word) => sum + UnicodeWidth.stringWidth(word));
    final totalSpaces = maxWidth - totalWordWidth;
    final gaps = words.length - 1;
    
    if (gaps == 0) return line;
    
    final spacesPerGap = totalSpaces ~/ gaps;
    final extraSpaces = totalSpaces % gaps;
    
    final buffer = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      buffer.write(words[i]);
      if (i < words.length - 1) {
        final spaces = spacesPerGap + (i < extraSpaces ? 1 : 0);
        buffer.write(' ' * spaces);
      }
    }
    
    return buffer.toString();
  }
}