import 'dart:math' as math;
import 'package:characters/characters.dart';
import '../../text/text_layout_engine.dart';
import '../../utils/unicode_width.dart';

/// Helper class for cursor movement calculations based on text layout
class CursorMovement {
  /// Information about a cursor position in the laid out text
  static CursorPosition getCursorPosition({
    required TextLayoutResult layoutResult,
    required String text,
    required int cursorOffset,
  }) {
    if (layoutResult.lines.isEmpty) {
      return CursorPosition(
        line: 0,
        column: 0,
        visualColumn: 0,
        lineStartOffset: 0,
        lineEndOffset: 0,
      );
    }

    // Find which line the cursor is on
    // We need to track both the position in the layout lines and original text
    int textOffset = 0;
    int actualLineIndex = 0;

    for (int i = 0; i < layoutResult.lines.length; i++) {
      final line = layoutResult.lines[i];
      final lineLength = line.length;

      // Check if there's a newline after this line in the original text
      bool hasNewline = false;
      if (i < layoutResult.lines.length - 1 && textOffset + lineLength < text.length) {
        // The layout engine splits on newlines, so there should be a newline if we're not at the end
        if (text[textOffset + lineLength] == '\n') {
          hasNewline = true;
        }
      }

      final lineEndOffset = textOffset + lineLength;
      final lineEndWithNewline = lineEndOffset + (hasNewline ? 1 : 0);

      // Check if cursor is on this line
      if (cursorOffset < lineEndWithNewline || i == layoutResult.lines.length - 1) {
        // Cursor is on this line
        final positionInLine = math.min(math.max(0, cursorOffset - textOffset), lineLength);
        final textBeforeCursor = positionInLine > 0 ? line.substring(0, positionInLine) : '';
        final visualColumn = UnicodeWidth.stringWidth(textBeforeCursor);

        return CursorPosition(
          line: i,
          column: positionInLine,
          visualColumn: visualColumn,
          lineStartOffset: textOffset,
          lineEndOffset: lineEndOffset,
          actualLineIndex: actualLineIndex,
        );
      }

      textOffset = lineEndWithNewline;
      if (hasNewline) {
        actualLineIndex++;
      }
    }

    // Cursor is at the very end
    final lastLine = layoutResult.lines.last;
    return CursorPosition(
      line: layoutResult.lines.length - 1,
      column: lastLine.length,
      visualColumn: UnicodeWidth.stringWidth(lastLine),
      lineStartOffset: textOffset - lastLine.length,
      lineEndOffset: textOffset,
      actualLineIndex: actualLineIndex,
    );
  }

  /// Move cursor horizontally by one grapheme cluster
  static int moveCursorHorizontally({
    required String text,
    required int currentOffset,
    required int direction,
  }) {
    if (direction == 0) return currentOffset;

    final graphemes = text.characters.toList();
    if (graphemes.isEmpty) return 0;

    // Find current position in grapheme clusters
    int currentGraphemeIndex = 0;
    int charCount = 0;

    for (int i = 0; i < graphemes.length; i++) {
      if (charCount >= currentOffset) {
        currentGraphemeIndex = i;
        break;
      }
      charCount += graphemes[i].length;
      if (i == graphemes.length - 1) {
        currentGraphemeIndex = graphemes.length;
      }
    }

    // Move by one grapheme cluster
    final newGraphemeIndex = (currentGraphemeIndex + direction).clamp(0, graphemes.length);

    // Calculate new character offset
    int newOffset = 0;
    for (int i = 0; i < newGraphemeIndex && i < graphemes.length; i++) {
      newOffset += graphemes[i].length;
    }

    return newOffset;
  }

  /// Move cursor vertically maintaining visual column position
  static int moveCursorVertically({
    required TextLayoutResult layoutResult,
    required String text,
    required int currentOffset,
    required int direction,
    required int targetVisualColumn,
  }) {
    if (layoutResult.lines.isEmpty || direction == 0) return currentOffset;

    final currentPos = getCursorPosition(
      layoutResult: layoutResult,
      text: text,
      cursorOffset: currentOffset,
    );

    final targetLine = (currentPos.line + direction).clamp(0, layoutResult.lines.length - 1);
    if (targetLine == currentPos.line) return currentOffset;

    // Find the new cursor position on the target line
    final newLine = layoutResult.lines[targetLine];

    // Calculate the line start offset
    int newLineStartOffset = 0;
    for (int i = 0; i < targetLine; i++) {
      newLineStartOffset += layoutResult.lines[i].length;
      // Add newline if it exists
      if (i < layoutResult.lines.length - 1) {
        final endOfLineOffset = newLineStartOffset;
        if (endOfLineOffset < text.length && text[endOfLineOffset] == '\n') {
          newLineStartOffset++;
        }
      }
    }

    // Find position in new line that matches target visual column
    int columnInNewLine = 0;
    int visualColumnCount = 0;

    for (final char in newLine.characters) {
      final charWidth = UnicodeWidth.stringWidth(char);
      if (visualColumnCount + charWidth > targetVisualColumn) {
        // We've gone past the target column
        break;
      }
      visualColumnCount += charWidth;
      columnInNewLine += char.length;
    }

    return newLineStartOffset + columnInNewLine;
  }

  /// Move cursor by word
  static int moveCursorByWord({
    required String text,
    required int currentOffset,
    required int direction,
  }) {
    if (direction == 0 || text.isEmpty) return currentOffset;

    int offset = currentOffset;

    if (direction < 0) {
      // Move backward by word
      if (offset == 0) return 0;

      // Skip spaces backward
      while (offset > 0 && _isWordBoundary(text[offset - 1])) {
        offset--;
      }

      // Skip word characters backward
      while (offset > 0 && !_isWordBoundary(text[offset - 1])) {
        offset--;
      }
    } else {
      // Move forward by word
      if (offset >= text.length) return text.length;

      // Skip current word forward
      while (offset < text.length && !_isWordBoundary(text[offset])) {
        offset++;
      }

      // Skip spaces forward
      while (offset < text.length && _isWordBoundary(text[offset])) {
        offset++;
      }
    }

    return offset;
  }

  /// Move cursor to start of current line
  static int moveCursorToLineStart({
    required TextLayoutResult layoutResult,
    required String text,
    required int currentOffset,
  }) {
    final pos = getCursorPosition(
      layoutResult: layoutResult,
      text: text,
      cursorOffset: currentOffset,
    );

    return pos.lineStartOffset;
  }

  /// Move cursor to end of current line
  static int moveCursorToLineEnd({
    required TextLayoutResult layoutResult,
    required String text,
    required int currentOffset,
  }) {
    final pos = getCursorPosition(
      layoutResult: layoutResult,
      text: text,
      cursorOffset: currentOffset,
    );

    return pos.lineEndOffset;
  }

  static bool _isWordBoundary(String char) {
    return char == ' ' || char == '\t' || char == '\n' || char == '\r' ||
           char == '.' || char == ',' || char == ';' || char == ':' ||
           char == '!' || char == '?' || char == '(' || char == ')' ||
           char == '[' || char == ']' || char == '{' || char == '}' ||
           char == '"' || char == "'" || char == '/' || char == '\\';
  }
}

/// Information about a cursor position in laid out text
class CursorPosition {
  final int line;           // Line index in the layout result
  final int column;          // Character column within the line
  final int visualColumn;    // Visual column accounting for Unicode width
  final int lineStartOffset; // Character offset of line start in original text
  final int lineEndOffset;   // Character offset of line end in original text
  final int actualLineIndex; // Actual line index (counting only real newlines)

  const CursorPosition({
    required this.line,
    required this.column,
    required this.visualColumn,
    required this.lineStartOffset,
    required this.lineEndOffset,
    this.actualLineIndex = 0,
  });
}