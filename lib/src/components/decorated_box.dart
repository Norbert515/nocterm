import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';

/// Title alignment options for border titles
enum TitleAlignment {
  left,
  center,
  right,
}

/// Configuration for a title embedded in a border
class BorderTitle {
  /// Creates a border title with plain text.
  const BorderTitle({
    required this.text,
    this.alignment = TitleAlignment.left,
    this.style,
  }) : textSpan = null;

  /// Creates a border title with rich text (multiple styles).
  const BorderTitle.rich({
    required InlineSpan this.textSpan,
    this.alignment = TitleAlignment.left,
  })  : text = '',
        style = null;

  /// Plain text for the title. Used when [textSpan] is null.
  final String text;

  /// Rich text for the title. When provided, [text] and [style] are ignored.
  final InlineSpan? textSpan;

  final TitleAlignment alignment;

  /// Style for plain text. Ignored when [textSpan] is provided.
  final TextStyle? style;

  /// Returns the plain text representation of the title.
  String get plainText => textSpan?.toPlainText() ?? text;

  /// Returns the length of the title in characters.
  int get length => plainText.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BorderTitle &&
        other.text == text &&
        other.textSpan == textSpan &&
        other.alignment == alignment &&
        other.style == style;
  }

  @override
  int get hashCode => Object.hash(text, textSpan, alignment, style);
}

/// Sentinel color value that indicates "use theme default".
/// This is used internally to detect when to apply theme colors.
const Color _defaultBorderColor = Color.fromRGB(255, 255, 255);

/// Border side configuration for a box decoration
class BorderSide {
  const BorderSide({
    this.color = _defaultBorderColor,
    this.width = 1.0,
    this.style = BoxBorderStyle.solid,
  });

  final Color color;
  final double width;
  final BoxBorderStyle style;

  static const BorderSide none = BorderSide(style: BoxBorderStyle.none);

  bool get isNone => style == BoxBorderStyle.none || width == 0.0;

  /// Returns true if the color is the default (theme should be used).
  bool get usesDefaultColor => color == _defaultBorderColor;

  /// Creates a copy of this border side with the given color.
  BorderSide copyWith({Color? color, double? width, BoxBorderStyle? style}) {
    return BorderSide(
      color: color ?? this.color,
      width: width ?? this.width,
      style: style ?? this.style,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BorderSide &&
        other.color == color &&
        other.width == width &&
        other.style == style;
  }

  @override
  int get hashCode => Object.hash(color, width, style);
}

/// Border style options
enum BoxBorderStyle {
  none,
  solid,
  dashed,
  dotted,
  double,
  rounded,
}

/// Box border configuration
class BoxBorder {
  const BoxBorder({
    this.top = BorderSide.none,
    this.right = BorderSide.none,
    this.bottom = BorderSide.none,
    this.left = BorderSide.none,
  });

  BoxBorder.all({
    Color color = _defaultBorderColor,
    double width = 1.0,
    BoxBorderStyle style = BoxBorderStyle.solid,
  })  : top = BorderSide(color: color, width: width, style: style),
        right = BorderSide(color: color, width: width, style: style),
        bottom = BorderSide(color: color, width: width, style: style),
        left = BorderSide(color: color, width: width, style: style);

  final BorderSide top;
  final BorderSide right;
  final BorderSide bottom;
  final BorderSide left;

  bool get hasNoBorder =>
      top.isNone && right.isNone && bottom.isNone && left.isNone;

  /// Creates a copy of this border with theme colors applied where defaults are used.
  BoxBorder withThemeColor(Color themeColor) {
    return BoxBorder(
      top: top.usesDefaultColor ? top.copyWith(color: themeColor) : top,
      right: right.usesDefaultColor ? right.copyWith(color: themeColor) : right,
      bottom:
          bottom.usesDefaultColor ? bottom.copyWith(color: themeColor) : bottom,
      left: left.usesDefaultColor ? left.copyWith(color: themeColor) : left,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoxBorder &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom &&
        other.left == left;
  }

  @override
  int get hashCode => Object.hash(top, right, bottom, left);
}

/// Box shadow configuration
class BoxShadow {
  const BoxShadow({
    this.color = const Color.fromRGB(0, 0, 0),
    this.offset = Offset.zero,
    this.blurRadius = 0.0,
    this.spreadRadius = 0.0,
  });

  final Color color;
  final Offset offset;
  final double blurRadius;
  final double spreadRadius;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoxShadow &&
        other.color == color &&
        other.offset == offset &&
        other.blurRadius == blurRadius &&
        other.spreadRadius == spreadRadius;
  }

  @override
  int get hashCode => Object.hash(color, offset, blurRadius, spreadRadius);
}

/// Border radius configuration
class BorderRadius {
  const BorderRadius.only({
    this.topLeft = Radius.zero,
    this.topRight = Radius.zero,
    this.bottomLeft = Radius.zero,
    this.bottomRight = Radius.zero,
  });

  const BorderRadius.all(Radius radius)
      : topLeft = radius,
        topRight = radius,
        bottomLeft = radius,
        bottomRight = radius;

  BorderRadius.circular(double radius)
      : topLeft = Radius.circular(radius),
        topRight = Radius.circular(radius),
        bottomLeft = Radius.circular(radius),
        bottomRight = Radius.circular(radius);

  final Radius topLeft;
  final Radius topRight;
  final Radius bottomLeft;
  final Radius bottomRight;

  static const BorderRadius zero = BorderRadius.all(Radius.zero);

  bool get isZero =>
      topLeft == Radius.zero &&
      topRight == Radius.zero &&
      bottomLeft == Radius.zero &&
      bottomRight == Radius.zero;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BorderRadius &&
        other.topLeft == topLeft &&
        other.topRight == topRight &&
        other.bottomLeft == bottomLeft &&
        other.bottomRight == bottomRight;
  }

  @override
  int get hashCode => Object.hash(topLeft, topRight, bottomLeft, bottomRight);
}

/// Radius configuration
class Radius {
  const Radius.circular(double radius)
      : x = radius,
        y = radius;
  const Radius.elliptical(this.x, this.y);

  final double x;
  final double y;

  static const Radius zero = Radius.circular(0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Radius && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Decoration for a box
class BoxDecoration {
  const BoxDecoration({
    this.color,
    this.image,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.gradient,
    this.backgroundBlendMode,
    this.shape = BoxShape.rectangle,
    this.title,
  });

  final Color? color;
  final DecorationImage? image;
  final BoxBorder? border;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final BlendMode? backgroundBlendMode;
  final BoxShape shape;
  final BorderTitle? title;

  /// Creates a copy of this decoration with theme colors applied to borders
  /// where default colors are used.
  BoxDecoration withThemeColor(Color themeColor) {
    return BoxDecoration(
      color: color,
      image: image,
      border: border?.withThemeColor(themeColor),
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      gradient: gradient,
      backgroundBlendMode: backgroundBlendMode,
      shape: shape,
      title: title,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BoxDecoration) return false;
    // Compare lists element by element
    if (boxShadow != null && other.boxShadow != null) {
      if (boxShadow!.length != other.boxShadow!.length) return false;
      for (int i = 0; i < boxShadow!.length; i++) {
        if (boxShadow![i] != other.boxShadow![i]) return false;
      }
    } else if (boxShadow != other.boxShadow) {
      return false;
    }
    return other.color == color &&
        other.image == image &&
        other.border == border &&
        other.borderRadius == borderRadius &&
        other.gradient == gradient &&
        other.backgroundBlendMode == backgroundBlendMode &&
        other.shape == shape &&
        other.title == title;
  }

  @override
  int get hashCode => Object.hash(
        color,
        image,
        border,
        borderRadius,
        boxShadow != null ? Object.hashAll(boxShadow!) : null,
        gradient,
        backgroundBlendMode,
        shape,
        title,
      );
}

/// Shape of the box
enum BoxShape {
  rectangle,
  circle,
}

/// Decoration image (placeholder for future implementation)
class DecorationImage {
  const DecorationImage({required this.image});
  final Object image;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DecorationImage && other.image == image;
  }

  @override
  int get hashCode => image.hashCode;
}

/// Gradient (placeholder for future implementation)
abstract class Gradient {
  const Gradient();
}

/// Linear gradient
class LinearGradient extends Gradient {
  const LinearGradient({
    this.begin = Alignment.centerLeft,
    this.end = Alignment.centerRight,
    required this.colors,
    this.stops,
  });

  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final List<Color> colors;
  final List<double>? stops;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LinearGradient) return false;
    // Compare colors
    if (colors.length != other.colors.length) return false;
    for (int i = 0; i < colors.length; i++) {
      if (colors[i] != other.colors[i]) return false;
    }
    // Compare stops
    if (stops != null && other.stops != null) {
      if (stops!.length != other.stops!.length) return false;
      for (int i = 0; i < stops!.length; i++) {
        if (stops![i] != other.stops![i]) return false;
      }
    } else if (stops != other.stops) {
      return false;
    }
    return other.begin == begin && other.end == end;
  }

  @override
  int get hashCode => Object.hash(
        begin,
        end,
        Object.hashAll(colors),
        stops != null ? Object.hashAll(stops!) : null,
      );
}

/// Blend mode (placeholder)
enum BlendMode {
  normal,
  multiply,
  screen,
  overlay,
}

/// RenderObject that applies decoration to its child
class RenderDecoratedBox extends RenderObject
    with RenderObjectWithChildMixin<RenderObject> {
  RenderDecoratedBox({
    required BoxDecoration decoration,
    DecorationPosition position = DecorationPosition.background,
  })  : _decoration = decoration,
        _position = position;

  BoxDecoration _decoration;
  BoxDecoration get decoration => _decoration;
  set decoration(BoxDecoration value) {
    if (_decoration != value) {
      final oldInset = _borderInsetFor(_decoration);
      final newInset = _borderInsetFor(value);
      final affectsLayout = oldInset != newInset;
      _decoration = value;
      if (affectsLayout) {
        markNeedsLayout();
      } else {
        markNeedsPaint();
      }
    }
  }

  DecorationPosition _position;
  DecorationPosition get position => _position;
  set position(DecorationPosition value) {
    if (_position != value) {
      _position = value;
      markNeedsPaint();
    }
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    final borderInset = _borderInsetFor(_decoration);

    if (child != null) {
      // Deflate constraints by border width
      final childConstraints = constraints.deflate(EdgeInsets.all(borderInset));

      // Layout child with deflated constraints
      child!.layout(childConstraints, parentUsesSize: true);

      // Our size includes the border
      size = constraints.constrain(
        Size(
          child!.size.width + 2 * borderInset,
          child!.size.height + 2 * borderInset,
        ),
      );

      // Position child inside the border
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      childParentData.offset = Offset(borderInset, borderInset);
    } else {
      // No child, just be the size of the border
      size = constraints.constrain(Size(2 * borderInset, 2 * borderInset));
    }
  }

  double _borderInsetFor(BoxDecoration decoration) {
    if (decoration.border != null && !decoration.border!.hasNoBorder) {
      // In terminal, we can only draw 1-character wide borders, so any
      // visible border reserves one cell regardless of color or style.
      return 1;
    }
    return 0;
  }

  void _paintDecoration(TerminalCanvas canvas, Offset offset) {
    // Skip painting if size is non-finite (e.g. from unconstrained scroll views)
    if (!size.width.isFinite || !size.height.isFinite) return;

    // Create rect in absolute canvas coordinates for background
    final absoluteRect =
        Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

    // Paint background color
    if (_decoration.color != null) {
      _paintBackground(canvas, absoluteRect, _decoration.color!);
    }

    // Paint border - pass the offset for absolute positioning
    if (_decoration.border != null && !_decoration.border!.hasNoBorder) {
      _paintBorder(canvas, offset, _decoration.border!);
    }
  }

  void _paintBackground(TerminalCanvas canvas, Rect rect, Color color) {
    final style = TextStyle(backgroundColor: color);
    // Paint the background by filling the rect area
    canvas.fillRect(rect, ' ', style: style);
  }

  void _setCell(
      TerminalCanvas canvas, int x, int y, String char, TextStyle style) {
    // Use drawText with a single character at the given position
    canvas.drawText(
      Offset(x.toDouble(), y.toDouble()),
      char,
      style: style,
    );
  }

  void _paintBorder(TerminalCanvas canvas, Offset offset, BoxBorder border) {
    // Calculate border positions in absolute coordinates
    final left = offset.dx.round();
    final top = offset.dy.round();
    final right = (offset.dx + size.width).round() - 1;
    final bottom = (offset.dy + size.height).round() - 1;

    // Get border characters based on style
    final chars = _getBorderCharacters(border);

    // Use the decoration's background color for border background
    final borderBackground = _decoration.color;

    // Paint top border
    if (!border.top.isNone) {
      final borderStyle =
          TextStyle(color: border.top.color, backgroundColor: borderBackground);
      if (left == right) {
        // Special case: width is 1
        // Determine which character to use based on what borders exist
        String charToUse;
        if (!border.left.isNone && !border.right.isNone) {
          // Has left and right borders, use appropriate corner
          charToUse = chars
              .topLeft; // Since it's a 1-wide box, topLeft represents the entire top
        } else if (!border.left.isNone) {
          charToUse = chars.topLeft;
        } else if (!border.right.isNone) {
          charToUse = chars.topRight;
        } else {
          charToUse = chars.horizontal;
        }
        _setCell(canvas, left, top, charToUse, borderStyle);
      } else {
        // Use corner only if left border connects, otherwise use horizontal
        final leftTopChar =
            !border.left.isNone ? chars.topLeft : chars.horizontal;
        _setCell(canvas, left, top, leftTopChar, borderStyle);

        // Check if we have a title to render
        final title = _decoration.title;
        final horizontalWidth =
            right - left - 1; // Available width between corners

        if (title != null && horizontalWidth >= 5) {
          // Minimum width: space + 1 char title + space + some border chars
          // Format: ─ Title ─────
          final titleText = title.plainText;
          final titleStyle = title.style ?? borderStyle;

          // Calculate title display with " Title " format (space padding)
          // We need at least 2 horizontal chars for aesthetics
          final maxTitleWidth =
              horizontalWidth - 2; // Reserve 2 chars for border lines
          String displayTitle;
          if (titleText.length + 2 > maxTitleWidth) {
            // Truncate with ellipsis
            final truncateLen =
                maxTitleWidth - 3; // -3 for "..." and space padding
            if (truncateLen > 0) {
              displayTitle = ' ${titleText.substring(0, truncateLen)}… ';
            } else {
              // Not enough space even for ellipsis, skip title
              displayTitle = '';
            }
          } else {
            displayTitle = ' $titleText ';
          }

          if (displayTitle.isNotEmpty) {
            final titleWidth = displayTitle.length;
            final remainingWidth = horizontalWidth - titleWidth;

            int titleStartX;
            int leftBorderLen;
            int rightBorderLen;

            switch (title.alignment) {
              case TitleAlignment.left:
                leftBorderLen = 1; // Single horizontal char before title
                titleStartX = left + 1 + leftBorderLen;
                rightBorderLen = remainingWidth - leftBorderLen;
                break;
              case TitleAlignment.center:
                leftBorderLen = remainingWidth ~/ 2;
                titleStartX = left + 1 + leftBorderLen;
                rightBorderLen = remainingWidth - leftBorderLen;
                break;
              case TitleAlignment.right:
                rightBorderLen = 1; // Single horizontal char after title
                leftBorderLen = remainingWidth - rightBorderLen;
                titleStartX = left + 1 + leftBorderLen;
                break;
            }

            // Paint left horizontal chars
            for (int i = 0; i < leftBorderLen; i++) {
              _setCell(
                  canvas, left + 1 + i, top, chars.horizontal, borderStyle);
            }

            // Paint title
            if (title.textSpan != null) {
              // Rich text - paint with per-character styles
              final styledSegments =
                  title.textSpan!.toStyledSegments(titleStyle);
              // Paint leading space
              _setCell(canvas, titleStartX, top, ' ', titleStyle);
              // Paint styled characters
              final contentLen =
                  displayTitle.length - 2; // Minus padding spaces
              int charIndex = 0;
              for (final segment in styledSegments) {
                for (int i = 0;
                    i < segment.text.length && charIndex < contentLen;
                    i++) {
                  _setCell(canvas, titleStartX + 1 + charIndex, top,
                      segment.text[i], segment.style ?? titleStyle);
                  charIndex++;
                }
                if (charIndex >= contentLen) break;
              }
              // Paint trailing space
              _setCell(canvas, titleStartX + displayTitle.length - 1, top, ' ',
                  titleStyle);
            } else {
              // Plain text - use single style
              for (int i = 0; i < displayTitle.length; i++) {
                _setCell(
                    canvas, titleStartX + i, top, displayTitle[i], titleStyle);
              }
            }

            // Paint right horizontal chars
            final rightStartX = titleStartX + titleWidth;
            for (int i = 0; i < rightBorderLen; i++) {
              _setCell(
                  canvas, rightStartX + i, top, chars.horizontal, borderStyle);
            }
          } else {
            // Title too short, render normal border
            for (int x = left + 1; x < right; x++) {
              _setCell(canvas, x, top, chars.horizontal, borderStyle);
            }
          }
        } else {
          // No title or not enough space, render normal horizontal line
          for (int x = left + 1; x < right; x++) {
            _setCell(canvas, x, top, chars.horizontal, borderStyle);
          }
        }

        // Use corner only if right border connects, otherwise use horizontal
        final rightTopChar =
            !border.right.isNone ? chars.topRight : chars.horizontal;
        _setCell(canvas, right, top, rightTopChar, borderStyle);
      }
    }

    // Paint bottom border
    if (!border.bottom.isNone && bottom > top) {
      final style = TextStyle(
          color: border.bottom.color, backgroundColor: borderBackground);
      if (left == right) {
        // Special case: width is 1
        // Determine which character to use based on what borders exist
        String charToUse;
        if (!border.left.isNone && !border.right.isNone) {
          // Has left and right borders, use appropriate corner
          charToUse = chars
              .bottomLeft; // Since it's a 1-wide box, bottomLeft represents the entire bottom
        } else if (!border.left.isNone) {
          charToUse = chars.bottomLeft;
        } else if (!border.right.isNone) {
          charToUse = chars.bottomRight;
        } else {
          charToUse = chars.horizontal;
        }
        _setCell(canvas, left, bottom, charToUse, style);
      } else {
        // Use corner only if left border connects, otherwise use horizontal
        final leftBottomChar =
            !border.left.isNone ? chars.bottomLeft : chars.horizontal;
        _setCell(canvas, left, bottom, leftBottomChar, style);
        for (int x = left + 1; x < right; x++) {
          _setCell(canvas, x, bottom, chars.horizontal, style);
        }
        // Use corner only if right border connects, otherwise use horizontal
        final rightBottomChar =
            !border.right.isNone ? chars.bottomRight : chars.horizontal;
        _setCell(canvas, right, bottom, rightBottomChar, style);
      }
    }

    // Paint left border
    if (!border.left.isNone) {
      final style = TextStyle(
          color: border.left.color, backgroundColor: borderBackground);
      // Only paint vertical lines if there's space between top and bottom
      if (bottom > top) {
        for (int y = top + 1; y < bottom; y++) {
          _setCell(canvas, left, y, chars.vertical, style);
        }
      }
    }

    // Paint right border
    if (!border.right.isNone && right > left) {
      final style = TextStyle(
          color: border.right.color, backgroundColor: borderBackground);
      // Only paint vertical lines if there's space between top and bottom
      if (bottom > top) {
        for (int y = top + 1; y < bottom; y++) {
          _setCell(canvas, right, y, chars.vertical, style);
        }
      }
    }
  }

  _BorderCharacters _getBorderCharacters(BoxBorder border) {
    // Determine the predominant border style
    BoxBorderStyle? style;
    for (final side in [border.top, border.right, border.bottom, border.left]) {
      if (!side.isNone) {
        style = side.style;
        break;
      }
    }

    switch (style) {
      case BoxBorderStyle.double:
        return _BorderCharacters.double;
      case BoxBorderStyle.rounded:
        return _BorderCharacters.rounded;
      case BoxBorderStyle.dashed:
        return _BorderCharacters.dashed;
      case BoxBorderStyle.dotted:
        return _BorderCharacters.dotted;
      case BoxBorderStyle.solid:
      case BoxBorderStyle.none:
      case null:
        return _BorderCharacters.single;
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    if (_position == DecorationPosition.background) {
      _paintDecoration(canvas, offset);
      if (child != null) {
        final BoxParentData childParentData =
            child!.parentData as BoxParentData;
        child!.paintWithContext(canvas, offset + childParentData.offset);
      }
    } else {
      if (child != null) {
        final BoxParentData childParentData =
            child!.parentData as BoxParentData;
        child!.paintWithContext(canvas, offset + childParentData.offset);
      }
      _paintDecoration(canvas, offset);
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    if (child != null) {
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      final childPosition = position - childParentData.offset;
      return child!.hitTest(result, position: childPosition);
    }
    return false;
  }
}

/// Border characters for different styles
class _BorderCharacters {
  const _BorderCharacters({
    required this.horizontal,
    required this.vertical,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  final String horizontal;
  final String vertical;
  final String topLeft;
  final String topRight;
  final String bottomLeft;
  final String bottomRight;

  static const single = _BorderCharacters(
    horizontal: '─',
    vertical: '│',
    topLeft: '┌',
    topRight: '┐',
    bottomLeft: '└',
    bottomRight: '┘',
  );

  static const double = _BorderCharacters(
    horizontal: '═',
    vertical: '║',
    topLeft: '╔',
    topRight: '╗',
    bottomLeft: '╚',
    bottomRight: '╝',
  );

  static const rounded = _BorderCharacters(
    horizontal: '─',
    vertical: '│',
    topLeft: '╭',
    topRight: '╮',
    bottomLeft: '╰',
    bottomRight: '╯',
  );

  static const dashed = _BorderCharacters(
    horizontal: '╌',
    vertical: '╎',
    topLeft: '┌',
    topRight: '┐',
    bottomLeft: '└',
    bottomRight: '┘',
  );

  static const dotted = _BorderCharacters(
    horizontal: '┅',
    vertical: '┇',
    topLeft: '┌',
    topRight: '┐',
    bottomLeft: '└',
    bottomRight: '┘',
  );
}

/// Position of the decoration relative to the child
enum DecorationPosition {
  background,
  foreground,
}

/// Widget that paints a decoration either before or after its child
class DecoratedBox extends SingleChildRenderObjectComponent {
  const DecoratedBox({
    super.key,
    required this.decoration,
    this.position = DecorationPosition.background,
    super.child,
  });

  final BoxDecoration decoration;
  final DecorationPosition position;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final theme = TuiTheme.of(context);
    return RenderDecoratedBox(
      decoration: decoration.withThemeColor(theme.outline),
      position: position,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderDecoratedBox renderObject) {
    final theme = TuiTheme.of(context);
    renderObject
      ..decoration = decoration.withThemeColor(theme.outline)
      ..position = position;
  }
}

/// Simplified Container widget that uses the new DecoratedBox
class Container extends StatelessComponent {
  const Container({
    super.key,
    this.alignment,
    this.padding,
    this.color,
    this.decoration,
    this.foregroundDecoration,
    this.width,
    this.height,
    this.constraints,
    this.margin,
    this.transform,
    this.clipBehavior = Clip.none,
    this.child,
  });

  final Component? child;
  final AlignmentGeometry? alignment;
  final EdgeInsets? padding;
  final Color? color;
  final BoxDecoration? decoration;
  final BoxDecoration? foregroundDecoration;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final EdgeInsets? margin;
  final Matrix4? transform;

  /// The clip behavior when [Container.decoration] has a clip.
  ///
  /// Defaults to [Clip.none]. Must be [Clip.none] if [decoration] is null.
  ///
  /// Unlike with other widgets, if a clip is to be used to avoid visual
  /// overflow of the container, you should explicitly set [clipBehavior] to
  /// [Clip.hardEdge] rather than relying on any default behavior.
  final Clip clipBehavior;

  @override
  Component build(BuildContext context) {
    Component? current = child;

    if (child == null &&
        (constraints == null ||
            !constraints!.hasBoundedWidth ||
            !constraints!.hasBoundedHeight)) {
      current = const LimitedBox(
        maxWidth: 0.0,
        maxHeight: 0.0,
      );
    }

    if (alignment != null) {
      current = Align(alignment: alignment!, child: current);
    }

    if (padding != null) {
      current = Padding(padding: padding!, child: current);
    }

    if (decoration != null || color != null) {
      current = DecoratedBox(
        decoration: decoration ?? BoxDecoration(color: color),
        child: current,
      );
    }

    if (foregroundDecoration != null) {
      current = DecoratedBox(
        decoration: foregroundDecoration!,
        position: DecorationPosition.foreground,
        child: current,
      );
    }

    if (constraints != null) {
      current = ConstrainedBox(constraints: constraints!, child: current);
    }

    if (width != null || height != null) {
      current = SizedBox(width: width, height: height, child: current);
    }

    if (margin != null) {
      current = Padding(padding: margin!, child: current);
    }

    if (transform != null) {
      current = Transform(transform: transform!, child: current);
    }

    if (clipBehavior != Clip.none) {
      current = ClipRect(clipBehavior: clipBehavior, child: current);
    }

    return current!;
  }
}
