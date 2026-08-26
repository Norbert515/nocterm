import 'package:nocterm/nocterm.dart';

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
/// [endIndent] it reaches outside its own bounds; those cells contribute
/// only the arm pointing back into the rule, so an end landing on a box
/// border becomes a tee (`├`/`┤`). An end with nothing to join is left
/// unpainted, so reaching out is safe even where no border turns up.
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
/// [endIndent] it reaches outside its own bounds; those cells contribute
/// only the arm pointing back into the rule, so an end landing on a box
/// border becomes a tee (`┬`/`┴`). An end with nothing to join is left
/// unpainted, so reaching out is safe even where no border turns up.
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

/// The arms a blended divider's end cell contributes: just the one arm
/// pointing back into the segment, so an end landing on a border merges
/// into a tee instead of a cross.
///
/// Arms rather than a character: a lone double arm has no glyph, though
/// the junctions it forms do. See [mergeArmsIntoCharacter].
///
/// Returns null for the ascii style, which never merges.
BoxCharArms? _capForStyle(
  DividerStyle style, {
  required bool horizontal,
  required bool start,
}) {
  final LineArm weight;
  switch (style) {
    case DividerStyle.single:
    case DividerStyle.dashed:
    case DividerStyle.dotted:
      weight = LineArm.light;
    case DividerStyle.bold:
      weight = LineArm.heavy;
    case DividerStyle.double:
      weight = LineArm.double;
    case DividerStyle.ascii:
      return null;
  }
  const none = LineArm.none;
  // (up, right, down, left)
  if (horizontal) {
    return start ? (none, weight, none, none) : (none, none, none, weight);
  }
  return start ? (none, none, weight, none) : (weight, none, none, none);
}

/// The line character for [style] along the given axis.
String _characterForStyle(DividerStyle style, {required bool horizontal}) {
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

/// Paints one run of divider cells along an axis, shared by both dividers.
///
/// [mainOrigin] and [mainExtent] are the offset and size along the axis the
/// divider runs on; [cross] is the fixed coordinate on the other.
void _paintRun(
  TerminalCanvas canvas, {
  required double mainOrigin,
  required double mainExtent,
  required double cross,
  required double indent,
  required double endIndent,
  required DividerStyle style,
  required Color color,
  required bool horizontal,
}) {
  // An unbounded parent leaves the extent infinite, and rounding a
  // non-finite value throws.
  if (!mainExtent.isFinite) return;

  // Whole cells: layout offsets can be fractional, and an end has to land
  // on exactly the cell it is drawn to.
  final ownStart = mainOrigin.round();
  final ownEnd = (mainOrigin + mainExtent).round();
  // A rule with no cells of its own has nothing for an end to join it to,
  // so it draws nothing at all.
  if (ownStart >= ownEnd) return;

  final start = (mainOrigin + indent).round();
  final end = (mainOrigin + mainExtent - endIndent).round();
  if (start >= end) return;

  final char = _characterForStyle(style, horizontal: horizontal);
  // The ascii style has no box-drawing characters to merge.
  final blendLines = style != DividerStyle.ascii;
  // Cells outside the divider's own bounds contribute only the arm pointing
  // back into it, so a border cell forms a tee (├/┤) rather than a cross.
  // Which cells those are comes from the run's rounded bounds: an indent of
  // -0.5 rounds back onto the divider's own first cell, so it is not an end.
  final startCap = blendLines && start < ownStart
      ? _capForStyle(style, horizontal: horizontal, start: true)
      : null;
  final endCap = blendLines && end > ownEnd
      ? _capForStyle(style, horizontal: horizontal, start: false)
      : null;

  for (var i = start; i < end; i++) {
    BoxCharArms? cap;
    if (i == start) {
      cap = startCap;
    } else if (i == end - 1) {
      cap = endCap;
    }
    final at =
        horizontal ? Offset(i.toDouble(), cross) : Offset(cross, i.toDouble());
    if (cap != null) {
      canvas.drawJunction(at, cap, style: TextStyle(color: color));
    } else {
      canvas.drawText(
        at,
        char,
        style: TextStyle(color: color),
        blendBoxLines: blendLines,
      );
    }
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

    _paintRun(
      canvas,
      mainOrigin: offset.dx,
      mainExtent: size.width,
      cross: offset.dy + (size.height / 2).floor(),
      indent: indent,
      endIndent: endIndent,
      style: style,
      color: color,
      horizontal: true,
    );
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

    _paintRun(
      canvas,
      mainOrigin: offset.dy,
      mainExtent: size.height,
      cross: offset.dx + (size.width / 2).floor(),
      indent: indent,
      endIndent: endIndent,
      style: style,
      color: color,
      horizontal: false,
    );
  }
}
