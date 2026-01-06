library;

import 'dart:math' as math;
import 'package:characters/characters.dart';
import 'package:nocterm/src/rectangle.dart';

import '../buffer.dart';
import '../style.dart';
import '../utils/unicode_width.dart';
import 'framework.dart';

/// Canvas for drawing to the terminal
class TerminalCanvas {
  TerminalCanvas(this._buffer, this.area);

  final Buffer _buffer;
  final Rect area;

  /// Blends a style with the background color from the existing cell if needed.
  ///
  /// This handles alpha blending for semi-transparent colors:
  /// - Foreground colors with alpha < 255 are blended with existing background
  /// - Background colors with alpha < 255 are blended with existing background
  /// - If no background exists, uses Color.defaultColor
  TextStyle _blendStyle(TextStyle style, Cell existingCell) {
    Color? blendedColor = style.color;
    Color? blendedBgColor = style.backgroundColor;

    // Blend foreground color if it has transparency
    if (style.color != null && style.color!.alpha < 255) {
      final existingBg =
          existingCell.style.backgroundColor ?? Color.defaultColor;
      blendedColor = Color.alphaBlend(style.color!, existingBg);
    }

    // Blend background color if it has transparency
    if (style.backgroundColor != null && style.backgroundColor!.alpha < 255) {
      final existingBg =
          existingCell.style.backgroundColor ?? Color.defaultColor;
      blendedBgColor = Color.alphaBlend(style.backgroundColor!, existingBg);
    }

    // If no background was specified in the style, preserve existing
    if (style.backgroundColor == null) {
      blendedBgColor = existingCell.style.backgroundColor;
    }

    return TextStyle(
      color: blendedColor,
      backgroundColor: blendedBgColor,
      fontWeight: style.fontWeight,
      fontStyle: style.fontStyle,
      decoration: style.decoration,
      reverse: style.reverse,
    );
  }

  /// Draw text at the given position
  void drawText(Offset position, String text, {TextStyle? style}) {
    final x = position.dx.round();
    final y = position.dy.round();

    if (x < 0 || y < 0 || x >= area.width || y >= area.height) {
      return;
    }

    // Replace tab characters with spaces to avoid terminal tab stop behavior
    text = text.replaceAll('\t', ' ');

    int currentColumn = x;

    // Use grapheme clusters to properly handle ZWJ sequences and other complex emoji
    for (final grapheme in text.characters) {
      if (currentColumn >= area.width) break;

      final width = UnicodeWidth.graphemeWidth(grapheme);

      // Skip zero-width graphemes (combining marks only)
      if (width == 0) {
        continue;
      }

      // Check if we have enough space for wide characters
      if (width == 2 && currentColumn + 1 >= area.width) {
        break;
      }

      // Set the main cell
      final cellX = area.left.round() + currentColumn;
      final cellY = area.top.round() + y;

      // Get existing cell and blend style (handles alpha + background preservation)
      final existingCell = _buffer.getCell(cellX, cellY);
      final effectiveStyle = style ?? const TextStyle();
      final finalStyle = _blendStyle(effectiveStyle, existingCell);

      _buffer.setCell(
        cellX,
        cellY,
        Cell(
          char: grapheme, // Use the full grapheme cluster, not individual runes
          style: finalStyle,
        ),
      );

      // For wide characters, we need to mark the next cell as occupied
      // but without rendering anything there (the terminal handles the width)
      if (width == 2 && currentColumn + 1 < area.width) {
        // Mark the cell as occupied by the emoji's second half
        // We use a special marker that won't be rendered
        final nextCellX = area.left.round() + currentColumn + 1;
        final nextCellY = area.top.round() + y;

        // Get existing cell and blend style (handles alpha + background preservation)
        final nextExistingCell = _buffer.getCell(nextCellX, nextCellY);
        final nextEffectiveStyle = style ?? const TextStyle();
        final nextFinalStyle = _blendStyle(
          nextEffectiveStyle,
          nextExistingCell,
        );

        _buffer.setCell(
          nextCellX,
          nextCellY,
          Cell(
            char: '\u200B', // Zero-width space as a marker
            style: nextFinalStyle,
          ),
        );
      }

      currentColumn += width;
    }
  }

  /// Fill a rectangle with a character
  void fillRect(Rect rect, String char, {TextStyle? style}) {
    final left = math.max(0, rect.left.round());
    final top = math.max(0, rect.top.round());
    final right = math.min(area.width, (rect.left + rect.width).round());
    final bottom = math.min(area.height, (rect.top + rect.height).round());

    final effectiveStyle = style ?? const TextStyle();

    for (int y = top; y < bottom; y++) {
      for (int x = left; x < right; x++) {
        final cellX = area.left.round() + x;
        final cellY = area.top.round() + y;

        // Get existing cell and blend style (handles alpha blending)
        final existingCell = _buffer.getCell(cellX, cellY);
        final finalStyle = _blendStyle(effectiveStyle, existingCell);

        _buffer.setCell(cellX, cellY, Cell(char: char, style: finalStyle));
      }
    }
  }

  /// Draw a box with borders
  void drawBox(Rect rect, {BorderStyle? border, TextStyle? style}) {
    if (border == null) return;

    final left = rect.left.round();
    final top = rect.top.round();
    final right = (rect.left + rect.width - 1).round();
    final bottom = (rect.top + rect.height - 1).round();

    // Corners
    _drawChar(left, top, border.topLeft, style);
    _drawChar(right, top, border.topRight, style);
    _drawChar(left, bottom, border.bottomLeft, style);
    _drawChar(right, bottom, border.bottomRight, style);

    // Top and bottom borders
    for (int x = left + 1; x < right; x++) {
      _drawChar(x, top, border.horizontal, style);
      _drawChar(x, bottom, border.horizontal, style);
    }

    // Left and right borders
    for (int y = top + 1; y < bottom; y++) {
      _drawChar(left, y, border.vertical, style);
      _drawChar(right, y, border.vertical, style);
    }
  }

  /// Draw a single character
  void _drawChar(int x, int y, String char, TextStyle? style) {
    if (x < 0 || y < 0 || x >= area.width || y >= area.height) {
      return;
    }

    final cellX = area.left.round() + x;
    final cellY = area.top.round() + y;

    // Get existing cell and blend style (handles alpha blending)
    final existingCell = _buffer.getCell(cellX, cellY);
    final effectiveStyle = style ?? const TextStyle();
    final finalStyle = _blendStyle(effectiveStyle, existingCell);

    _buffer.setCell(cellX, cellY, Cell(char: char, style: finalStyle));
  }

  /// Create a clipped canvas for drawing within a sub-region
  TerminalCanvas clip(Rect clipRect) {
    final clippedArea = _intersect(
      Rect.fromLTWH(
        area.left + clipRect.left,
        area.top + clipRect.top,
        clipRect.width,
        clipRect.height,
      ),
      area,
    );
    return TerminalCanvas(_buffer, clippedArea);
  }

  Rect _intersect(Rect a, Rect b) {
    final left = math.max(a.left, b.left);
    final top = math.max(a.top, b.top);
    final right = math.min(a.right, b.right);
    final bottom = math.min(a.bottom, b.bottom);

    if (left >= right || top >= bottom) {
      return const Rect.fromLTWH(0, 0, 0, 0);
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }
}

/// Border style for boxes
class BorderStyle {
  const BorderStyle({
    this.topLeft = '┌',
    this.topRight = '┐',
    this.bottomLeft = '└',
    this.bottomRight = '┘',
    this.horizontal = '─',
    this.vertical = '│',
  });

  final String topLeft;
  final String topRight;
  final String bottomLeft;
  final String bottomRight;
  final String horizontal;
  final String vertical;

  static const BorderStyle single = BorderStyle();

  static const BorderStyle double = BorderStyle(
    topLeft: '╔',
    topRight: '╗',
    bottomLeft: '╚',
    bottomRight: '╝',
    horizontal: '═',
    vertical: '║',
  );

  static const BorderStyle rounded = BorderStyle(
    topLeft: '╭',
    topRight: '╮',
    bottomLeft: '╰',
    bottomRight: '╯',
    horizontal: '─',
    vertical: '│',
  );

  static const BorderStyle thick = BorderStyle(
    topLeft: '┏',
    topRight: '┓',
    bottomLeft: '┗',
    bottomRight: '┛',
    horizontal: '━',
    vertical: '┃',
  );
}
