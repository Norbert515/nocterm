import 'package:nocterm/src/rectangle.dart';

import 'style.dart';
import 'utils/unicode_width.dart';

class Cell {
  String char;
  TextStyle style;

  /// Cached display width of the character.
  /// Computed lazily on first access to avoid expensive width calculations.
  int? _cachedWidth;

  Cell({this.char = ' ', TextStyle? style}) : style = style ?? TextStyle();

  /// Returns the display width of this cell's character.
  /// The width is cached after the first computation for performance.
  int get width {
    _cachedWidth ??= UnicodeWidth.graphemeWidth(char);
    return _cachedWidth!;
  }

  Cell copyWith({String? char, TextStyle? style}) {
    return Cell(char: char ?? this.char, style: style ?? this.style);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is Cell && other.char == char && other.style == style;
  }

  @override
  int get hashCode => Object.hash(char, style);
}

class Buffer {
  final int width;
  final int height;
  final List<List<Cell>> cells;

  Buffer(this.width, this.height)
    : cells = List.generate(height, (_) => List.generate(width, (_) => Cell()));

  Cell getCell(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return Cell();
    }
    return cells[y][x];
  }

  void setCell(int x, int y, Cell cell) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      cells[y][x] = cell;
    }
  }

  void setString(int x, int y, String text, {TextStyle? style}) {
    int currentX = x;
    final runes = text.runes.toList();

    for (int i = 0; i < runes.length; i++) {
      if (currentX >= width) break;

      final rune = runes[i];
      final char = String.fromCharCode(rune);
      final charWidth = UnicodeWidth.runeWidth(rune);

      // Skip zero-width characters
      if (charWidth == 0) continue;

      // Check if we have enough space for wide characters
      if (charWidth == 2 && currentX + 1 >= width) break;

      if (y >= 0 && y < height && currentX >= 0) {
        cells[y][currentX] = Cell(char: char, style: style);

        // For wide characters, mark the next cell as occupied
        if (charWidth == 2 && currentX + 1 < width) {
          cells[y][currentX + 1] = Cell(
            char: '\u200B',
            style: style,
          ); // Zero-width space marker
        }
      }

      currentX += charWidth;
    }
  }

  void clear() {
    for (var row in cells) {
      for (int i = 0; i < row.length; i++) {
        row[i] = Cell();
      }
    }
  }

  void fillArea(Rect area, String char, {TextStyle? style}) {
    for (double y = area.top; y < area.bottom && y < height; y++) {
      for (double x = area.left; x < area.right && x < width; x++) {
        if (x >= 0 && y >= 0) {
          setCell(x.toInt(), y.toInt(), Cell(char: char, style: style));
        }
      }
    }
  }
}
