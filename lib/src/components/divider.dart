import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';

enum DividerStyle {
  single,
  double,
  dashed,
  dotted,
  bold,
  ascii,
}

/// A horizontal rule.
///
/// The divider merges with box-drawing characters it overlaps, forming
/// junctions instead of overwriting them. With a negative [indent] or
/// [endIndent] it reaches outside its own bounds; those cells paint half-arm
/// characters (`╶`/`╴`), so an end landing on a box border becomes a tee
/// (`├`/`┤`). An end landing on a cell that is not a box-drawing character
/// keeps the half-arm stub, so only reach into cells known to hold borders.
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

/// A vertical rule.
///
/// The divider merges with box-drawing characters it overlaps, forming
/// junctions instead of overwriting them. With a negative [indent] or
/// [endIndent] it reaches outside its own bounds; those cells paint half-arm
/// characters (`╷`/`╵`), so an end landing on a box border becomes a tee
/// (`┬`/`┴`). An end landing on a cell that is not a box-drawing character
/// keeps the half-arm stub, so only reach into cells known to hold borders.
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
      BuildContext context, RenderVerticalDivider renderObject) {
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

/// The half-arm characters painted at a blended divider's end cells, so an
/// end landing on a border merges into a tee instead of a cross.
///
/// Returns null for styles without half-arm characters (no blending caps).
String? _capForStyle(
  DividerStyle style, {
  required bool horizontal,
  required bool start,
}) {
  switch (style) {
    case DividerStyle.single:
    case DividerStyle.dashed:
    case DividerStyle.dotted:
      return horizontal ? (start ? '╶' : '╴') : (start ? '╷' : '╵');
    case DividerStyle.bold:
      return horizontal ? (start ? '╺' : '╸') : (start ? '╻' : '╹');
    case DividerStyle.double:
    case DividerStyle.ascii:
      return null;
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
  })  : _height = height,
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

    // Work in whole cells: layout can produce fractional offsets, and the
    // end caps must land on exactly the cells the characters are drawn to.
    final startX = (offset.dx + indent).round();
    final endX = (offset.dx + size.width - endIndent).round();
    final y = offset.dy + (size.height / 2).floor();

    if (startX >= endX) return;

    final char = _getCharacterForStyle(style, horizontal: true);
    // Box-line merging has no effect for the ascii style (its characters
    // are not box-drawing characters).
    final blendLines = style != DividerStyle.ascii;
    // Cells reached via a negative indent lie outside the divider's own
    // bounds, on top of foreign content such as a border. They contribute
    // only the arm pointing into the segment, so a border cell forms a tee
    // (├/┤) rather than a cross. Cells within bounds keep the full line
    // character.
    final useCaps = blendLines && endX - startX > 1;
    final startCap =
        indent < 0 ? _capForStyle(style, horizontal: true, start: true) : null;
    final endCap = endIndent < 0
        ? _capForStyle(style, horizontal: true, start: false)
        : null;

    for (var x = startX; x < endX; x++) {
      var cellChar = char;
      if (useCaps) {
        if (x == startX) {
          cellChar = startCap ?? char;
        } else if (x == endX - 1) {
          cellChar = endCap ?? char;
        }
      }
      canvas.drawText(
        Offset(x.toDouble(), y),
        cellChar,
        style: TextStyle(color: color),
        blendBoxLines: blendLines,
      );
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
  })  : _width = width,
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

    // Work in whole cells: layout can produce fractional offsets, and the
    // end caps must land on exactly the cells the characters are drawn to.
    final x = offset.dx + (size.width / 2).floor();
    final startY = (offset.dy + indent).round();
    final endY = (offset.dy + size.height - endIndent).round();

    if (startY >= endY) return;

    final char = _getCharacterForStyle(style, horizontal: false);
    // Box-line merging has no effect for the ascii style (its characters
    // are not box-drawing characters).
    final blendLines = style != DividerStyle.ascii;
    // Cells reached via a negative indent lie outside the divider's own
    // bounds, on top of foreign content such as a border. They contribute
    // only the arm pointing into the segment, so a border cell forms a tee
    // (┬/┴) rather than a cross. Cells within bounds keep the full line
    // character.
    final useCaps = blendLines && endY - startY > 1;
    final startCap =
        indent < 0 ? _capForStyle(style, horizontal: false, start: true) : null;
    final endCap = endIndent < 0
        ? _capForStyle(style, horizontal: false, start: false)
        : null;

    for (var y = startY; y < endY; y++) {
      var cellChar = char;
      if (useCaps) {
        if (y == startY) {
          cellChar = startCap ?? char;
        } else if (y == endY - 1) {
          cellChar = endCap ?? char;
        }
      }
      canvas.drawText(
        Offset(x, y.toDouble()),
        cellChar,
        style: TextStyle(color: color),
        blendBoxLines: blendLines,
      );
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
