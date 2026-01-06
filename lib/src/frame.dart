import 'package:nocterm/src/rectangle.dart';
import 'package:nocterm/src/size.dart';

import 'buffer.dart';
import 'style.dart';
import 'backend/terminal.dart';

class Frame {
  final Buffer buffer;
  final Size size;
  final Buffer? _previousBuffer;
  final int _contentHeight = 0;
  bool _fullRedraw = true;

  Frame({required this.size, Buffer? previousBuffer})
    : buffer = Buffer(size.width.toInt(), size.height.toInt()),
      _previousBuffer = previousBuffer;

  Rect get area =>
      Rect.fromLTWH(0, 0, size.width.toDouble(), size.height.toDouble());

  void render(Terminal terminal) {
    // Move to home position instead of clearing (prevents flicker)
    terminal.moveToHome();

    final output = StringBuffer();

    // Determine render height - only render up to content height
    final renderHeight = _fullRedraw ? buffer.height : _contentHeight;

    for (int y = 0; y < renderHeight; y++) {
      bool lineChanged = _hasLineChanged(y);

      // Skip unchanged lines when not doing full redraw
      if (!_fullRedraw && !lineChanged && _previousBuffer != null) {
        continue;
      }

      // Move cursor to the line
      output.write('\x1b[${y + 1};1H');

      // Clear the line only if it changed or on full redraw
      if (_fullRedraw || lineChanged) {
        output.write('\x1b[2K');
      }

      // Render the line content
      for (int x = 0; x < buffer.width; x++) {
        final cell = buffer.getCell(x, y);

        // For zero-width space markers (used for wide character tracking),
        // skip them entirely - they're placeholders for the second cell of wide chars
        if (cell.char == '\u200B') {
          continue;
        }

        if (cell.style.color != null ||
            cell.style.backgroundColor != null ||
            cell.style.fontWeight == FontWeight.bold ||
            cell.style.fontStyle == FontStyle.italic ||
            cell.style.decoration?.hasUnderline == true) {
          output.write(cell.style.toAnsi());
          output.write(cell.char);
          output.write(TextStyle.reset);
        } else {
          output.write(cell.char);
        }
      }
    }

    // Clear remaining lines if content shrunk
    if (_previousBuffer != null && _contentHeight < buffer.height) {
      for (int y = _contentHeight; y < buffer.height; y++) {
        output.write('\x1b[${y + 1};1H');
        output.write('\x1b[2K');
      }
    }

    terminal.write(output.toString());
    terminal.flush();

    // Reset full redraw flag after first render
    _fullRedraw = false;
  }

  bool _hasLineChanged(int y) {
    if (_previousBuffer == null) return true;

    for (int x = 0; x < buffer.width; x++) {
      final currentCell = buffer.getCell(x, y);
      final previousCell = _previousBuffer.getCell(x, y);

      if (currentCell.char != previousCell.char ||
          currentCell.style.color != previousCell.style.color ||
          currentCell.style.backgroundColor !=
              previousCell.style.backgroundColor ||
          currentCell.style.fontWeight != previousCell.style.fontWeight ||
          currentCell.style.fontStyle != previousCell.style.fontStyle ||
          currentCell.style.decoration != previousCell.style.decoration ||
          currentCell.style.reverse != previousCell.style.reverse) {
        return true;
      }
    }

    return false;
  }

  void forceFullRedraw() {
    _fullRedraw = true;
  }
}
