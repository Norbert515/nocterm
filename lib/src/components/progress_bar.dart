import 'dart:math' as math;
import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';

enum ProgressBarBorderStyle {
  single,
  double,
  rounded,
  bold,
  ascii,
  doubleHorizontal,
  doubleVertical,
}

class ProgressBar extends SingleChildRenderObjectComponent {
  const ProgressBar({
    super.key,
    this.value,
    this.minHeight = 1,
    this.backgroundColor,
    this.valueColor,
    this.borderStyle,
    this.fillCharacter = '█',
    this.emptyCharacter = '░',
    this.showPercentage = false,
    this.label,
    this.indeterminate = false,
  }) : assert(value == null || (value >= 0.0 && value <= 1.0));

  final double? value;
  final double minHeight;

  /// The background color for the progress bar.
  ///
  /// If null, defaults to the theme's [TuiThemeData.outline] color.
  final Color? backgroundColor;

  /// The color for the filled portion of the progress bar.
  ///
  /// If null, defaults to the theme's [TuiThemeData.primary] color.
  final Color? valueColor;
  final ProgressBarBorderStyle? borderStyle;
  final String fillCharacter;
  final String emptyCharacter;
  final bool showPercentage;
  final String? label;
  final bool indeterminate;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final theme = TuiTheme.of(context);
    return RenderProgressBar(
      value: value,
      minHeight: minHeight,
      backgroundColor: backgroundColor ?? theme.outline,
      valueColor: valueColor ?? theme.primary,
      borderStyle: borderStyle,
      fillCharacter: fillCharacter,
      emptyCharacter: emptyCharacter,
      showPercentage: showPercentage,
      label: label,
      indeterminate: indeterminate,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderProgressBar renderObject,
  ) {
    final theme = TuiTheme.of(context);
    renderObject
      ..value = value
      ..minHeight = minHeight
      ..backgroundColor = backgroundColor ?? theme.outline
      ..valueColor = valueColor ?? theme.primary
      ..borderStyle = borderStyle
      ..fillCharacter = fillCharacter
      ..emptyCharacter = emptyCharacter
      ..showPercentage = showPercentage
      ..label = label
      ..indeterminate = indeterminate;
  }
}

class RenderProgressBar extends RenderObject {
  RenderProgressBar({
    double? value,
    double minHeight = 1,
    Color backgroundColor = Colors.grey,
    Color valueColor = Colors.green,
    ProgressBarBorderStyle? borderStyle,
    String fillCharacter = '█',
    String emptyCharacter = '░',
    bool showPercentage = false,
    String? label,
    bool indeterminate = false,
  }) : _value = value,
       _minHeight = minHeight,
       _backgroundColor = backgroundColor,
       _valueColor = valueColor,
       _borderStyle = borderStyle,
       _fillCharacter = fillCharacter,
       _emptyCharacter = emptyCharacter,
       _showPercentage = showPercentage,
       _label = label,
       _indeterminate = indeterminate;

  double? _value;
  double _minHeight;
  Color _backgroundColor;
  Color _valueColor;
  ProgressBarBorderStyle? _borderStyle;
  String _fillCharacter;
  String _emptyCharacter;
  bool _showPercentage;
  String? _label;
  bool _indeterminate;

  double _animationValue = 0.0;
  int _animationFrame = 0;

  double? get value => _value;
  set value(double? newValue) {
    if (_value != newValue) {
      _value = newValue;
      markNeedsPaint();
    }
  }

  double get minHeight => _minHeight;
  set minHeight(double newValue) {
    if (_minHeight != newValue) {
      _minHeight = newValue;
      markNeedsLayout();
    }
  }

  Color get backgroundColor => _backgroundColor;
  set backgroundColor(Color newValue) {
    if (_backgroundColor != newValue) {
      _backgroundColor = newValue;
      markNeedsPaint();
    }
  }

  Color get valueColor => _valueColor;
  set valueColor(Color newValue) {
    if (_valueColor != newValue) {
      _valueColor = newValue;
      markNeedsPaint();
    }
  }

  ProgressBarBorderStyle? get borderStyle => _borderStyle;
  set borderStyle(ProgressBarBorderStyle? newValue) {
    if (_borderStyle != newValue) {
      _borderStyle = newValue;
      markNeedsPaint();
    }
  }

  String get fillCharacter => _fillCharacter;
  set fillCharacter(String newValue) {
    if (_fillCharacter != newValue) {
      _fillCharacter = newValue;
      markNeedsPaint();
    }
  }

  String get emptyCharacter => _emptyCharacter;
  set emptyCharacter(String newValue) {
    if (_emptyCharacter != newValue) {
      _emptyCharacter = newValue;
      markNeedsPaint();
    }
  }

  bool get showPercentage => _showPercentage;
  set showPercentage(bool newValue) {
    if (_showPercentage != newValue) {
      _showPercentage = newValue;
      markNeedsPaint();
    }
  }

  String? get label => _label;
  set label(String? newValue) {
    if (_label != newValue) {
      _label = newValue;
      markNeedsPaint();
    }
  }

  bool get indeterminate => _indeterminate;
  set indeterminate(bool newValue) {
    if (_indeterminate != newValue) {
      _indeterminate = newValue;
      markNeedsPaint();
    }
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void performLayout() {
    final desiredHeight = minHeight.clamp(1.0, constraints.maxHeight);
    size = constraints.constrain(Size(constraints.maxWidth, desiredHeight));
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    final int barWidth = size.width.floor();
    final int barHeight = size.height.floor();

    if (barWidth <= 0 || barHeight <= 0) return;

    // Handle border if specified
    int contentStartX = 0;
    int contentEndX = barWidth;
    int contentStartY = 0;
    int contentEndY = barHeight;

    if (borderStyle != null) {
      // Draw border
      final borderChars = _getBorderCharacters(borderStyle!);

      // Top border
      if (barHeight > 1) {
        canvas.drawText(
          offset,
          borderChars['topLeft']!,
          style: TextStyle(color: valueColor),
        );
        for (int x = 1; x < barWidth - 1; x++) {
          canvas.drawText(
            offset + Offset(x.toDouble(), 0),
            borderChars['horizontal']!,
            style: TextStyle(color: valueColor),
          );
        }
        if (barWidth > 1) {
          canvas.drawText(
            offset + Offset((barWidth - 1).toDouble(), 0),
            borderChars['topRight']!,
            style: TextStyle(color: valueColor),
          );
        }
      }

      // Side borders and bottom
      if (barHeight > 2) {
        for (int y = 1; y < barHeight - 1; y++) {
          canvas.drawText(
            offset + Offset(0, y.toDouble()),
            borderChars['vertical']!,
            style: TextStyle(color: valueColor),
          );
          if (barWidth > 1) {
            canvas.drawText(
              offset + Offset((barWidth - 1).toDouble(), y.toDouble()),
              borderChars['vertical']!,
              style: TextStyle(color: valueColor),
            );
          }
        }

        // Bottom border
        canvas.drawText(
          offset + Offset(0, (barHeight - 1).toDouble()),
          borderChars['bottomLeft']!,
          style: TextStyle(color: valueColor),
        );
        for (int x = 1; x < barWidth - 1; x++) {
          canvas.drawText(
            offset + Offset(x.toDouble(), (barHeight - 1).toDouble()),
            borderChars['horizontal']!,
            style: TextStyle(color: valueColor),
          );
        }
        if (barWidth > 1) {
          canvas.drawText(
            offset +
                Offset((barWidth - 1).toDouble(), (barHeight - 1).toDouble()),
            borderChars['bottomRight']!,
            style: TextStyle(color: valueColor),
          );
        }
      } else if (barHeight == 2) {
        // Simple two-line border
        canvas.drawText(
          offset + Offset(0, 1),
          borderChars['bottomLeft']!,
          style: TextStyle(color: valueColor),
        );
        for (int x = 1; x < barWidth - 1; x++) {
          canvas.drawText(
            offset + Offset(x.toDouble(), 1),
            borderChars['horizontal']!,
            style: TextStyle(color: valueColor),
          );
        }
        if (barWidth > 1) {
          canvas.drawText(
            offset + Offset((barWidth - 1).toDouble(), 1),
            borderChars['bottomRight']!,
            style: TextStyle(color: valueColor),
          );
        }
      }

      // Adjust content area for border
      if (borderStyle != null) {
        contentStartX = 1;
        contentEndX = math.max(1, barWidth - 1);
        contentStartY = barHeight > 1 ? 1 : 0;
        contentEndY = barHeight > 2 ? barHeight - 1 : (barHeight > 1 ? 1 : 1);
      }
    }

    // Calculate progress bar content area
    final contentWidth = contentEndX - contentStartX;
    final contentHeight = contentEndY - contentStartY;

    if (contentWidth <= 0 || contentHeight <= 0) return;

    // Draw progress bar content
    if (indeterminate) {
      // Animated indeterminate progress
      _animationFrame = (_animationFrame + 1) % (contentWidth * 2);
      _animationValue = _animationFrame / (contentWidth * 2);

      final pulseWidth = math.max(1, (contentWidth * 0.3).floor());
      final pulsePosition = (_animationValue * contentWidth * 2).floor();

      for (int y = contentStartY; y < contentEndY; y++) {
        for (int x = contentStartX; x < contentEndX; x++) {
          final relativeX = x - contentStartX;
          final isPulse =
              (relativeX >= pulsePosition - pulseWidth &&
                  relativeX <= pulsePosition) ||
              (pulsePosition > contentWidth &&
                  relativeX >= pulsePosition - contentWidth - pulseWidth &&
                  relativeX <= pulsePosition - contentWidth);

          canvas.drawText(
            offset + Offset(x.toDouble(), y.toDouble()),
            isPulse ? fillCharacter : emptyCharacter,
            style: TextStyle(color: isPulse ? valueColor : backgroundColor),
          );
        }
      }
    } else if (value != null) {
      // Determinate progress
      final filledWidth = (value!.clamp(0.0, 1.0) * contentWidth).floor();

      for (int y = contentStartY; y < contentEndY; y++) {
        for (int x = contentStartX; x < contentEndX; x++) {
          final relativeX = x - contentStartX;
          final isFilled = relativeX < filledWidth;

          canvas.drawText(
            offset + Offset(x.toDouble(), y.toDouble()),
            isFilled ? fillCharacter : emptyCharacter,
            style: TextStyle(color: isFilled ? valueColor : backgroundColor),
          );
        }
      }
    } else {
      // Empty bar
      for (int y = contentStartY; y < contentEndY; y++) {
        for (int x = contentStartX; x < contentEndX; x++) {
          canvas.drawText(
            offset + Offset(x.toDouble(), y.toDouble()),
            emptyCharacter,
            style: TextStyle(color: backgroundColor),
          );
        }
      }
    }

    // Draw percentage or label in the center if requested
    if ((showPercentage || label != null) && contentHeight > 0) {
      String text = '';
      if (label != null) {
        text = label!;
      } else if (showPercentage && value != null) {
        text = '${(value! * 100).toInt()}%';
      }

      if (text.isNotEmpty && text.length <= contentWidth) {
        final textX = contentStartX + ((contentWidth - text.length) ~/ 2);
        final textY = contentStartY + (contentHeight ~/ 2);

        for (int i = 0; i < text.length; i++) {
          final charX = textX + i;
          if (charX >= contentStartX && charX < contentEndX) {
            // Determine if this character position is in filled or unfilled area
            final relativeX = charX - contentStartX;
            final isFilled = value != null
                ? relativeX < (value! * contentWidth).floor()
                : false;

            canvas.drawText(
              offset + Offset(charX.toDouble(), textY.toDouble()),
              text[i],
              style: TextStyle(
                color: isFilled ? backgroundColor : valueColor,
                decoration: TextDecoration.underline,
              ),
            );
          }
        }
      }
    }
  }

  Map<String, String> _getBorderCharacters(ProgressBarBorderStyle style) {
    switch (style) {
      case ProgressBarBorderStyle.single:
        return {
          'horizontal': '─',
          'vertical': '│',
          'topLeft': '┌',
          'topRight': '┐',
          'bottomLeft': '└',
          'bottomRight': '┘',
        };
      case ProgressBarBorderStyle.double:
        return {
          'horizontal': '═',
          'vertical': '║',
          'topLeft': '╔',
          'topRight': '╗',
          'bottomLeft': '╚',
          'bottomRight': '╝',
        };
      case ProgressBarBorderStyle.rounded:
        return {
          'horizontal': '─',
          'vertical': '│',
          'topLeft': '╭',
          'topRight': '╮',
          'bottomLeft': '╰',
          'bottomRight': '╯',
        };
      case ProgressBarBorderStyle.bold:
        return {
          'horizontal': '━',
          'vertical': '┃',
          'topLeft': '┏',
          'topRight': '┓',
          'bottomLeft': '┗',
          'bottomRight': '┛',
        };
      case ProgressBarBorderStyle.ascii:
        return {
          'horizontal': '-',
          'vertical': '|',
          'topLeft': '+',
          'topRight': '+',
          'bottomLeft': '+',
          'bottomRight': '+',
        };
      case ProgressBarBorderStyle.doubleHorizontal:
        return {
          'horizontal': '═',
          'vertical': '│',
          'topLeft': '╒',
          'topRight': '╕',
          'bottomLeft': '╘',
          'bottomRight': '╛',
        };
      case ProgressBarBorderStyle.doubleVertical:
        return {
          'horizontal': '─',
          'vertical': '║',
          'topLeft': '╓',
          'topRight': '╖',
          'bottomLeft': '╙',
          'bottomRight': '╜',
        };
    }
  }
}
