import 'package:nocterm/nocterm.dart';

/// Represents the state of a terminal at a point in time.
/// Provides methods for querying and asserting on terminal content.
class TerminalState {
  final Buffer buffer;
  final Size size;

  const TerminalState({required this.buffer, required this.size});

  /// Get the text content of the entire terminal as a string
  String getText({Rect? area}) {
    final targetArea =
        area ??
        Rect.fromLTWH(0, 0, size.width.toDouble(), size.height.toDouble());

    final lines = <String>[];
    for (
      int y = targetArea.top.toInt();
      y < targetArea.bottom.toInt() && y < size.height;
      y++
    ) {
      final line = StringBuffer();
      for (
        int x = targetArea.left.toInt();
        x < targetArea.right.toInt() && x < size.width;
        x++
      ) {
        final cell = buffer.getCell(x, y);
        // Skip zero-width space markers
        if (cell.char != '\u200B') {
          line.write(cell.char);
        }
      }
      lines.add(line.toString());
    }
    return lines.join('\n');
  }

  /// Check if the terminal contains the specified text anywhere
  bool containsText(String text) {
    final content = getText();
    return content.contains(text);
  }

  /// Get the cell at the specified position
  Cell? getCellAt(int x, int y) {
    if (x < 0 || x >= size.width || y < 0 || y >= size.height) {
      return null;
    }
    return buffer.getCell(x, y);
  }

  /// Get text at a specific position with optional length
  String? getTextAt(int x, int y, {int? length}) {
    if (y < 0 || y >= size.height) return null;

    final maxLength = length ?? (size.width - x);
    final result = StringBuffer();

    for (int i = 0; i < maxLength && (x + i) < size.width; i++) {
      final cell = buffer.getCell(x + i, y);
      if (cell.char != '\u200B') {
        result.write(cell.char);
      }
    }

    return result.toString();
  }

  /// Find all occurrences of text with their positions
  List<TextMatch> findText(String searchText) {
    final matches = <TextMatch>[];
    final content = getText();
    final lines = content.split('\n');

    for (int y = 0; y < lines.length; y++) {
      final line = lines[y];
      int index = 0;
      while ((index = line.indexOf(searchText, index)) != -1) {
        matches.add(TextMatch(text: searchText, x: index, y: y));
        index += searchText.length;
      }
    }

    return matches;
  }

  /// Get all styled text segments
  List<StyledText> getStyledText() {
    final segments = <StyledText>[];

    for (int y = 0; y < size.height; y++) {
      int x = 0;
      while (x < size.width) {
        final startX = x;
        final cell = buffer.getCell(x, y);
        final style = cell.style;
        final text = StringBuffer();

        // Collect consecutive cells with the same style
        while (x < size.width) {
          final currentCell = buffer.getCell(x, y);
          if (!_stylesEqual(currentCell.style, style)) {
            break;
          }
          if (currentCell.char != '\u200B') {
            text.write(currentCell.char);
          }
          x++;
        }

        if (text.isNotEmpty && !_isDefaultStyle(style)) {
          segments.add(
            StyledText(text: text.toString(), style: style, x: startX, y: y),
          );
        }

        if (x == startX) x++; // Prevent infinite loop
      }
    }

    return segments;
  }

  /// Render the terminal state as a string for debugging
  String renderToString({bool showBorders = true}) {
    final output = StringBuffer();

    if (showBorders) {
      output.writeln('┌${'─' * size.width.toInt()}┐');
    }

    for (int y = 0; y < size.height; y++) {
      if (showBorders) output.write('│');

      for (int x = 0; x < size.width; x++) {
        final cell = buffer.getCell(x, y);
        // Don't render zero-width space markers (used for wide char tracking)
        if (cell.char != '\u200B') {
          output.write(cell.char);
        }
        // Skip the marker entirely - don't replace with space
      }

      if (showBorders) output.write('│');
      output.writeln();
    }

    if (showBorders) {
      output.writeln('└${'─' * size.width.toInt()}┘');
    }

    return output.toString();
  }

  /// Create a snapshot string that can be used for comparison
  String toSnapshot() {
    final lines = <String>[];

    for (int y = 0; y < size.height; y++) {
      final line = StringBuffer();
      for (int x = 0; x < size.width; x++) {
        final cell = buffer.getCell(x, y);
        // Use a placeholder for empty cells to preserve spacing
        line.write(cell.char == ' ' ? '·' : cell.char);
      }
      // Trim trailing spaces (shown as dots)
      final lineStr = line.toString().replaceAll(RegExp(r'·+$'), '');
      if (lineStr.isNotEmpty) {
        lines.add(lineStr);
      }
    }

    // Remove trailing empty lines
    while (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }

    return lines.join('\n');
  }

  bool _stylesEqual(TextStyle a, TextStyle b) {
    return a.color == b.color &&
        a.backgroundColor == b.backgroundColor &&
        a.fontWeight == b.fontWeight &&
        a.fontStyle == b.fontStyle &&
        a.decoration == b.decoration &&
        a.reverse == b.reverse;
  }

  bool _isDefaultStyle(TextStyle style) {
    return style.color == null &&
        style.backgroundColor == null &&
        style.fontWeight == null &&
        style.fontStyle == null &&
        style.decoration == null;
  }
}

/// Represents a text match found in the terminal
class TextMatch {
  final String text;
  final int x;
  final int y;

  const TextMatch({required this.text, required this.x, required this.y});

  @override
  String toString() => 'TextMatch("$text" at $x,$y)';
}

/// Represents a styled text segment in the terminal
class StyledText {
  final String text;
  final TextStyle style;
  final int x;
  final int y;

  const StyledText({
    required this.text,
    required this.style,
    required this.x,
    required this.y,
  });

  @override
  String toString() => 'StyledText("$text" with $style at $x,$y)';
}
