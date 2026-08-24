import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:nocterm/nocterm.dart';

import '../utils/unicode_width.dart';

/// Utilities for text selection hit testing and painting.
///
/// Computes the character offset for the start of each line in [text].
///
/// The [lines] input should be the layout engine output: line strings with
/// wrapping applied and without embedded `\n` characters. This helper advances
/// past newline characters in [text] so empty lines (consecutive `\n`s) map to
/// distinct offsets.
List<int> lineStartOffsets(String text, List<String> lines) {
  final offsets = <int>[];
  int offset = 0;
  for (int i = 0; i < lines.length; i++) {
    offsets.add(offset);
    offset += lines[i].length;
    if (offset < text.length && text[offset] == '\n') {
      offset++;
    }
  }
  return offsets;
}

/// Maps a local position (x, y) to a character index within [text].
int getCharacterIndexAtLocalPosition({
  required Offset localPos,
  required String text,
  required List<String> lines,
}) {
  if (lines.isEmpty) return 0;

  final lineIndex = localPos.dy.toInt().clamp(0, lines.length - 1);
  final lineStartOffset = lineStartOffsets(text, lines)[lineIndex];
  final line = lines[lineIndex];
  final targetX = localPos.dx;

  int cumulativeWidth = 0;
  int charIndex = 0;
  for (final grapheme in line.characters) {
    final gw = UnicodeWidth.graphemeWidth(grapheme);
    if (cumulativeWidth.toDouble() + gw / 2.0 > targetX) {
      break;
    }
    cumulativeWidth += gw;
    charIndex += grapheme.length;
  }

  return (lineStartOffset + charIndex).clamp(0, text.length);
}

/// Paints a single line of text with optional selection highlighting.
void paintTextWithSelection({
  required TerminalCanvas canvas,
  required Offset offset,
  required String line,
  required TextStyle? style,
  required int lineIndex,
  required String text,
  required List<String> lines,
  required int? selectionStart,
  required int? selectionEnd,
  required Color selectionColor,
}) {
  if (selectionStart == null ||
      selectionEnd == null ||
      selectionStart == selectionEnd) {
    canvas.drawText(offset, line, style: style);
    return;
  }

  final lineStartOffset =
      (lines.isNotEmpty && lineIndex > 0 && lineIndex < lines.length)
          ? lineStartOffsets(text, lines)[lineIndex]
          : 0;
  final lineEndOffset = lineStartOffset + line.length;

  final selStart = math.min(selectionStart, selectionEnd);
  final selEnd = math.max(selectionStart, selectionEnd);

  if (selEnd > lineStartOffset && selStart < lineEndOffset) {
    final localSelStart = math.max(0, selStart - lineStartOffset);
    final localSelEnd = math.min(line.length, selEnd - lineStartOffset);

    if (localSelStart < localSelEnd) {
      if (localSelStart > 0) {
        final beforeText = line.substring(0, localSelStart);
        canvas.drawText(offset, beforeText, style: style);
      }

      final selectedText = line.substring(localSelStart, localSelEnd);
      final beforeWidth = localSelStart > 0
          ? UnicodeWidth.stringWidth(line.substring(0, localSelStart))
          : 0;
      final selectionStyle = (style ?? const TextStyle())
          .copyWith(backgroundColor: selectionColor);
      canvas.drawText(
        offset + Offset(beforeWidth.toDouble(), 0),
        selectedText,
        style: selectionStyle,
      );

      if (localSelEnd < line.length) {
        final afterText = line.substring(localSelEnd);
        final beforeSelectedWidth =
            UnicodeWidth.stringWidth(line.substring(0, localSelEnd));
        canvas.drawText(
          offset + Offset(beforeSelectedWidth.toDouble(), 0),
          afterText,
          style: style,
        );
      }
      return;
    }
  }

  canvas.drawText(offset, line, style: style);
}
