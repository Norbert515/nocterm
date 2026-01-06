import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';

enum DividerStyle { single, double, dashed, dotted, bold, ascii }

class Divider extends SingleChildRenderObjectComponent {
  const Divider({
    super.key,
    this.height = 1.0,
    this.thickness = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.color,
    this.style = DividerStyle.single,
  });

  final double height;
  final double thickness;
  final double indent;
  final double endIndent;

  /// The color of the divider.
  ///
  /// If null, defaults to the theme's [TuiThemeData.outline] color.
  final Color? color;
  final DividerStyle style;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final theme = TuiTheme.of(context);
    return RenderDivider(
      height: height,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: color ?? theme.outline,
      style: style,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderDivider renderObject) {
    final theme = TuiTheme.of(context);
    renderObject
      ..height = height
      ..thickness = thickness
      ..indent = indent
      ..endIndent = endIndent
      ..color = color ?? theme.outline
      ..style = style;
  }
}

class VerticalDivider extends SingleChildRenderObjectComponent {
  const VerticalDivider({
    super.key,
    this.width = 1.0,
    this.thickness = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.color,
    this.style = DividerStyle.single,
  });

  final double width;
  final double thickness;
  final double indent;
  final double endIndent;

  /// The color of the divider.
  ///
  /// If null, defaults to the theme's [TuiThemeData.outline] color.
  final Color? color;
  final DividerStyle style;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final theme = TuiTheme.of(context);
    return RenderVerticalDivider(
      width: width,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: color ?? theme.outline,
      style: style,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderVerticalDivider renderObject,
  ) {
    final theme = TuiTheme.of(context);
    renderObject
      ..width = width
      ..thickness = thickness
      ..indent = indent
      ..endIndent = endIndent
      ..color = color ?? theme.outline
      ..style = style;
  }
}

class RenderDivider extends RenderObject {
  RenderDivider({
    required double height,
    required double thickness,
    required double indent,
    required double endIndent,
    required Color color,
    required DividerStyle style,
  }) : _height = height,
       _thickness = thickness,
       _indent = indent,
       _endIndent = endIndent,
       _color = color,
       _style = style;

  double _height;
  double get height => _height;
  set height(double value) {
    if (_height != value) {
      _height = value;
      markNeedsLayout();
    }
  }

  double _thickness;
  double get thickness => _thickness;
  set thickness(double value) {
    if (_thickness != value) {
      _thickness = value;
      markNeedsLayout();
    }
  }

  double _indent;
  double get indent => _indent;
  set indent(double value) {
    if (_indent != value) {
      _indent = value;
      markNeedsPaint();
    }
  }

  double _endIndent;
  double get endIndent => _endIndent;
  set endIndent(double value) {
    if (_endIndent != value) {
      _endIndent = value;
      markNeedsPaint();
    }
  }

  Color _color;
  Color get color => _color;
  set color(Color value) {
    if (_color != value) {
      _color = value;
      markNeedsPaint();
    }
  }

  DividerStyle _style;
  DividerStyle get style => _style;
  set style(DividerStyle value) {
    if (_style != value) {
      _style = value;
      markNeedsPaint();
    }
  }

  @override
  void performLayout() {
    size = constraints.constrain(Size(double.infinity, height));
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);

    final startX = offset.dx + indent;
    final endX = offset.dx + size.width - endIndent;
    final y = offset.dy + (size.height / 2).floor();

    if (startX >= endX) return;

    String char = _getCharacterForStyle(style, horizontal: true);

    for (double x = startX; x < endX; x += 1) {
      canvas.drawText(Offset(x, y), char, style: TextStyle(color: color));
    }
  }

  String _getCharacterForStyle(DividerStyle style, {required bool horizontal}) {
    switch (style) {
      case DividerStyle.single:
        return horizontal ? '─' : '│';
      case DividerStyle.double:
        return horizontal ? '═' : '║';
      case DividerStyle.dashed:
        return horizontal ? '╌' : '╎';
      case DividerStyle.dotted:
        return horizontal ? '┈' : '┊';
      case DividerStyle.bold:
        return horizontal ? '━' : '┃';
      case DividerStyle.ascii:
        return horizontal ? '-' : '|';
    }
  }
}

class RenderVerticalDivider extends RenderObject {
  RenderVerticalDivider({
    required double width,
    required double thickness,
    required double indent,
    required double endIndent,
    required Color color,
    required DividerStyle style,
  }) : _width = width,
       _thickness = thickness,
       _indent = indent,
       _endIndent = endIndent,
       _color = color,
       _style = style;

  double _width;
  double get width => _width;
  set width(double value) {
    if (_width != value) {
      _width = value;
      markNeedsLayout();
    }
  }

  double _thickness;
  double get thickness => _thickness;
  set thickness(double value) {
    if (_thickness != value) {
      _thickness = value;
      markNeedsLayout();
    }
  }

  double _indent;
  double get indent => _indent;
  set indent(double value) {
    if (_indent != value) {
      _indent = value;
      markNeedsPaint();
    }
  }

  double _endIndent;
  double get endIndent => _endIndent;
  set endIndent(double value) {
    if (_endIndent != value) {
      _endIndent = value;
      markNeedsPaint();
    }
  }

  Color _color;
  Color get color => _color;
  set color(Color value) {
    if (_color != value) {
      _color = value;
      markNeedsPaint();
    }
  }

  DividerStyle _style;
  DividerStyle get style => _style;
  set style(DividerStyle value) {
    if (_style != value) {
      _style = value;
      markNeedsPaint();
    }
  }

  @override
  void performLayout() {
    size = constraints.constrain(Size(width, double.infinity));
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);

    final x = offset.dx + (size.width / 2).floor();
    final startY = offset.dy + indent;
    final endY = offset.dy + size.height - endIndent;

    if (startY >= endY) return;

    String char = _getCharacterForStyle(style, horizontal: false);

    for (double y = startY; y < endY; y += 1) {
      canvas.drawText(Offset(x, y), char, style: TextStyle(color: color));
    }
  }

  String _getCharacterForStyle(DividerStyle style, {required bool horizontal}) {
    switch (style) {
      case DividerStyle.single:
        return horizontal ? '─' : '│';
      case DividerStyle.double:
        return horizontal ? '═' : '║';
      case DividerStyle.dashed:
        return horizontal ? '╌' : '╎';
      case DividerStyle.dotted:
        return horizontal ? '┈' : '┊';
      case DividerStyle.bold:
        return horizontal ? '━' : '┃';
      case DividerStyle.ascii:
        return horizontal ? '-' : '|';
    }
  }
}
