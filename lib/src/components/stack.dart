import 'package:nocterm/nocterm.dart';

/// The direction in which text flows.
enum TextDirection {
  /// The text flows from left to right (e.g., English, French).
  ltr,

  /// The text flows from right to left (e.g., Arabic, Hebrew).
  rtl,
}

/// Parent data for use with [RenderStack].
class StackParentData extends BoxParentData {
  /// The distance by which the child's top edge is inset from the top of the stack.
  double? top;

  /// The distance by which the child's right edge is inset from the right of the stack.
  double? right;

  /// The distance by which the child's bottom edge is inset from the bottom of the stack.
  double? bottom;

  /// The distance by which the child's left edge is inset from the left of the stack.
  double? left;

  /// The child's width.
  ///
  /// Ignored if both left and right are non-null.
  double? width;

  /// The child's height.
  ///
  /// Ignored if both top and bottom are non-null.
  double? height;

  /// The previous sibling in the linked list of children.
  StackParentData? previousSibling;

  /// The next sibling in the linked list of children.
  StackParentData? nextSibling;

  /// Whether this child is considered positioned.
  ///
  /// A child is positioned if any of the top, right, bottom, left, width,
  /// or height properties are non-null. Positioned children do not factor
  /// into determining the size of the stack but are instead placed relative
  /// to the non-positioned children in the stack.
  bool get isPositioned =>
      top != null ||
      right != null ||
      bottom != null ||
      left != null ||
      width != null ||
      height != null;

  @override
  String toString() {
    final List<String> values = <String>[
      if (top != null) 'top=${top!.toStringAsFixed(1)}',
      if (right != null) 'right=${right!.toStringAsFixed(1)}',
      if (bottom != null) 'bottom=${bottom!.toStringAsFixed(1)}',
      if (left != null) 'left=${left!.toStringAsFixed(1)}',
      if (width != null) 'width=${width!.toStringAsFixed(1)}',
      if (height != null) 'height=${height!.toStringAsFixed(1)}',
    ];
    if (values.isEmpty) {
      return 'StackParentData#$hashCode(not positioned)';
    }
    return 'StackParentData#$hashCode(${values.join(', ')})';
  }
}

/// An immutable 2D, axis-aligned, floating-point rectangle whose coordinates
/// are given relative to another rectangle's edges, known as the container.
class RelativeRect {
  /// Creates a RelativeRect with the given values.
  const RelativeRect.fromLTRB(this.left, this.top, this.right, this.bottom);

  /// Creates a RelativeRect from a Rect and a Size.
  factory RelativeRect.fromSize(Rect rect, Size container) {
    return RelativeRect.fromLTRB(
      rect.left,
      rect.top,
      container.width - rect.right,
      container.height - rect.bottom,
    );
  }

  /// Creates a RelativeRect from two Rects.
  factory RelativeRect.fromRect(Rect rect, Rect container) {
    return RelativeRect.fromLTRB(
      rect.left - container.left,
      rect.top - container.top,
      container.right - rect.right,
      container.bottom - rect.bottom,
    );
  }

  /// A rect that covers the entire container.
  static const RelativeRect fill = RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0);

  /// Distance from the left side of the container to the left side of this rectangle.
  final double left;

  /// Distance from the top side of the container to the top side of this rectangle.
  final double top;

  /// Distance from the right side of the container to the right side of this rectangle.
  final double right;

  /// Distance from the bottom side of the container to the bottom side of this rectangle.
  final double bottom;

  /// Returns whether any of the values are greater than zero.
  bool get hasInsets => left > 0.0 || top > 0.0 || right > 0.0 || bottom > 0.0;

  /// Convert this [RelativeRect] to a [Rect], in the coordinate space of the container.
  Rect toRect(Rect container) {
    return Rect.fromLTWH(
      left,
      top,
      container.width - left - right,
      container.height - top - bottom,
    );
  }

  /// Convert this [RelativeRect] to a [Size], assuming a container with the given size.
  Size toSize(Size container) {
    return Size(
      container.width - left - right,
      container.height - top - bottom,
    );
  }

  @override
  String toString() => 'RelativeRect.fromLTRB($left, $top, $right, $bottom)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelativeRect &&
        other.left == left &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom;
  }

  @override
  int get hashCode => Object.hash(left, top, right, bottom);
}

/// Base class for alignment geometry.
abstract class AlignmentGeometry {
  const AlignmentGeometry();

  /// Convert this instance to an [Alignment], which uses literal
  /// coordinates (the `x` coordinate being explicitly a distance from the
  /// left).
  Alignment resolve(TextDirection? direction);
}

/// A point within a rectangle.
///
/// `Alignment(0.0, 0.0)` represents the center of the rectangle.
/// The distance from -1.0 to +1.0 is the distance from one side of the
/// rectangle to the other side of the rectangle.
class Alignment extends AlignmentGeometry {
  /// Creates an alignment.
  const Alignment(this.x, this.y);

  /// The distance fraction in the horizontal direction.
  final double x;

  /// The distance fraction in the vertical direction.
  final double y;

  /// The top left corner.
  static const Alignment topLeft = Alignment(-1.0, -1.0);

  /// The center point along the top edge.
  static const Alignment topCenter = Alignment(0.0, -1.0);

  /// The top right corner.
  static const Alignment topRight = Alignment(1.0, -1.0);

  /// The center point along the left edge.
  static const Alignment centerLeft = Alignment(-1.0, 0.0);

  /// The center point, both horizontally and vertically.
  static const Alignment center = Alignment(0.0, 0.0);

  /// The center point along the right edge.
  static const Alignment centerRight = Alignment(1.0, 0.0);

  /// The bottom left corner.
  static const Alignment bottomLeft = Alignment(-1.0, 1.0);

  /// The center point along the bottom edge.
  static const Alignment bottomCenter = Alignment(0.0, 1.0);

  /// The bottom right corner.
  static const Alignment bottomRight = Alignment(1.0, 1.0);

  @override
  Alignment resolve(TextDirection? direction) => this;

  /// Returns the offset that is this fraction in the direction of the given offset.
  Offset alongOffset(Offset other) {
    final double centerX = other.dx / 2.0;
    final double centerY = other.dy / 2.0;
    return Offset(centerX + x * centerX, centerY + y * centerY);
  }

  /// Returns the offset that is this fraction within the given size.
  Offset alongSize(Size other) {
    final double centerX = other.width / 2.0;
    final double centerY = other.height / 2.0;
    return Offset(centerX + x * centerX, centerY + y * centerY);
  }

  /// Returns the point that is this fraction within the given rect.
  Offset withinRect(Rect rect) {
    final double halfWidth = rect.width / 2.0;
    final double halfHeight = rect.height / 2.0;
    return Offset(
      rect.left + halfWidth + x * halfWidth,
      rect.top + halfHeight + y * halfHeight,
    );
  }

  /// Returns a rect of the given size, aligned within the given rect
  /// as specified by this alignment.
  Rect inscribe(Size size, Rect rect) {
    final double halfWidthDelta = (rect.width - size.width) / 2.0;
    final double halfHeightDelta = (rect.height - size.height) / 2.0;
    return Rect.fromLTWH(
      rect.left + halfWidthDelta + x * halfWidthDelta,
      rect.top + halfHeightDelta + y * halfHeightDelta,
      size.width,
      size.height,
    );
  }

  @override
  String toString() {
    if (this == topLeft) return 'Alignment.topLeft';
    if (this == topCenter) return 'Alignment.topCenter';
    if (this == topRight) return 'Alignment.topRight';
    if (this == centerLeft) return 'Alignment.centerLeft';
    if (this == center) return 'Alignment.center';
    if (this == centerRight) return 'Alignment.centerRight';
    if (this == bottomLeft) return 'Alignment.bottomLeft';
    if (this == bottomCenter) return 'Alignment.bottomCenter';
    if (this == bottomRight) return 'Alignment.bottomRight';
    return 'Alignment($x, $y)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Alignment && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}

/// An offset that's expressed as a fraction of a [Size], but whose horizontal
/// component is dependent on the writing direction.
class AlignmentDirectional extends AlignmentGeometry {
  /// Creates a directional alignment.
  const AlignmentDirectional(this.start, this.y);

  /// The distance fraction in the horizontal direction.
  ///
  /// A value of -1.0 corresponds to the edge on the "start" side, which is the
  /// left side in [TextDirection.ltr] contexts and the right side in
  /// [TextDirection.rtl] contexts. A value of 1.0 corresponds to the opposite
  /// edge, the "end" side. Values are not limited to that range; values less
  /// than -1.0 represent positions beyond the start edge, and values greater than
  /// 1.0 represent positions beyond the end edge.
  final double start;

  /// The distance fraction in the vertical direction.
  final double y;

  /// The top corner on the "start" side.
  static const AlignmentDirectional topStart = AlignmentDirectional(-1.0, -1.0);

  /// The center point along the top edge.
  static const AlignmentDirectional topCenter = AlignmentDirectional(0.0, -1.0);

  /// The top corner on the "end" side.
  static const AlignmentDirectional topEnd = AlignmentDirectional(1.0, -1.0);

  /// The center point along the "start" edge.
  static const AlignmentDirectional centerStart = AlignmentDirectional(
    -1.0,
    0.0,
  );

  /// The center point, both horizontally and vertically.
  static const AlignmentDirectional center = AlignmentDirectional(0.0, 0.0);

  /// The center point along the "end" edge.
  static const AlignmentDirectional centerEnd = AlignmentDirectional(1.0, 0.0);

  /// The bottom corner on the "start" side.
  static const AlignmentDirectional bottomStart = AlignmentDirectional(
    -1.0,
    1.0,
  );

  /// The center point along the bottom edge.
  static const AlignmentDirectional bottomCenter = AlignmentDirectional(
    0.0,
    1.0,
  );

  /// The bottom corner on the "end" side.
  static const AlignmentDirectional bottomEnd = AlignmentDirectional(1.0, 1.0);

  @override
  Alignment resolve(TextDirection? direction) {
    assert(
      direction != null,
      'Cannot resolve $runtimeType without a TextDirection.',
    );
    switch (direction!) {
      case TextDirection.rtl:
        return Alignment(-start, y);
      case TextDirection.ltr:
        return Alignment(start, y);
    }
  }

  @override
  String toString() {
    if (this == topStart) return 'AlignmentDirectional.topStart';
    if (this == topCenter) return 'AlignmentDirectional.topCenter';
    if (this == topEnd) return 'AlignmentDirectional.topEnd';
    if (this == centerStart) return 'AlignmentDirectional.centerStart';
    if (this == center) return 'AlignmentDirectional.center';
    if (this == centerEnd) return 'AlignmentDirectional.centerEnd';
    if (this == bottomStart) return 'AlignmentDirectional.bottomStart';
    if (this == bottomCenter) return 'AlignmentDirectional.bottomCenter';
    if (this == bottomEnd) return 'AlignmentDirectional.bottomEnd';
    return 'AlignmentDirectional($start, $y)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlignmentDirectional &&
        other.start == start &&
        other.y == y;
  }

  @override
  int get hashCode => Object.hash(start, y);
}

/// How to size the non-positioned children of a [Stack].
enum StackFit {
  /// The constraints passed to the stack from its parent are loosened.
  ///
  /// For example, if the stack has constraints that force it to 350x600, then
  /// this would allow the non-positioned children of the stack to have any
  /// width from zero to 350 and any height from zero to 600.
  loose,

  /// The constraints passed to the stack from its parent are tightened to the
  /// biggest size allowed.
  ///
  /// For example, if the stack has loose constraints with a width in the range
  /// 10 to 100 and a height in the range 0 to 600, then the non-positioned
  /// children of the stack would all be sized as 100 pixels wide and 600 high.
  expand,

  /// The constraints passed to the stack from its parent are passed unmodified
  /// to the non-positioned children.
  passthrough,
}

/// Whether to clip overflowing children.
enum Clip {
  /// No clipping.
  none,

  /// Clip, but do not apply anti-aliasing.
  hardEdge,

  /// Clip with anti-aliasing. (Not applicable in terminal, treated as hardEdge)
  antiAlias,

  /// Clip with anti-aliasing and save layer. (Not applicable in terminal, treated as hardEdge)
  antiAliasWithSaveLayer,
}

/// A widget that controls where a child of a [Stack] is positioned.
///
/// A [Positioned] widget must be a descendant of a [Stack], and the path from
/// the [Positioned] widget to its enclosing [Stack] must contain only
/// [StatelessWidget]s or [StatefulWidget]s (not other kinds of widgets, like
/// [RenderObjectWidget]s).
class Positioned extends ParentDataComponent<StackParentData> {
  /// Creates a widget that controls where a child of a [Stack] is positioned.
  ///
  /// Only two out of the three horizontal values ([left], [right], [width]), and only
  /// two out of the three vertical values ([top], [bottom], [height]), can be set. In each
  /// case, at least one of the three must be null.
  Positioned({
    super.key,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    required super.child,
  }) : assert(left == null || right == null || width == null),
       assert(top == null || bottom == null || height == null),
       super(
         data: StackParentData()
           ..left = left
           ..top = top
           ..right = right
           ..bottom = bottom
           ..width = width
           ..height = height,
       );

  /// Creates a Positioned object with the values from the given [Rect].
  ///
  /// This sets the [left], [top], [width], and [height] properties
  /// from the given [Rect]. The [right] and [bottom] properties are
  /// set to null.
  Positioned.fromRect({super.key, required Rect rect, required super.child})
    : left = rect.left,
      top = rect.top,
      width = rect.width,
      height = rect.height,
      right = null,
      bottom = null,
      super(
        data: StackParentData()
          ..left = rect.left
          ..top = rect.top
          ..width = rect.width
          ..height = rect.height,
      );

  /// Creates a Positioned object with the values from the given [RelativeRect].
  ///
  /// This sets the [left], [top], [right], and [bottom] properties from the
  /// given [RelativeRect]. The [height] and [width] properties are set to null.
  Positioned.fromRelativeRect({
    super.key,
    required RelativeRect rect,
    required super.child,
  }) : left = rect.left,
       top = rect.top,
       right = rect.right,
       bottom = rect.bottom,
       width = null,
       height = null,
       super(
         data: StackParentData()
           ..left = rect.left
           ..top = rect.top
           ..right = rect.right
           ..bottom = rect.bottom,
       );

  /// Creates a Positioned object with [left], [top], [right], and [bottom] set
  /// to 0.0 unless a value for them is passed.
  Positioned.fill({
    super.key,
    this.left = 0.0,
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
    required super.child,
  }) : width = null,
       height = null,
       super(
         data: StackParentData()
           ..left = left
           ..top = top
           ..right = right
           ..bottom = bottom,
       );

  /// Creates a widget that controls where a child of a [Stack] is positioned.
  ///
  /// Only two out of the three horizontal values (`start`, `end`,
  /// [width]), and only two out of the three vertical values ([top],
  /// [bottom], [height]), can be set. In each case, at least one of
  /// the three must be null.
  ///
  /// If `textDirection` is [TextDirection.rtl], then the `start` argument is
  /// used for the [right] property and the `end` argument is used for the
  /// [left] property. Otherwise, if `textDirection` is [TextDirection.ltr],
  /// then the `start` argument is used for the [left] property and the `end`
  /// argument is used for the [right] property.
  factory Positioned.directional({
    Key? key,
    required TextDirection textDirection,
    double? start,
    double? top,
    double? end,
    double? bottom,
    double? width,
    double? height,
    required Component child,
  }) {
    final (double? left, double? right) = switch (textDirection) {
      TextDirection.rtl => (end, start),
      TextDirection.ltr => (start, end),
    };
    return Positioned(
      key: key,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: child,
    );
  }

  /// The distance that the child's left edge is inset from the left of the stack.
  final double? left;

  /// The distance that the child's top edge is inset from the top of the stack.
  final double? top;

  /// The distance that the child's right edge is inset from the right of the stack.
  final double? right;

  /// The distance that the child's bottom edge is inset from the bottom of the stack.
  final double? bottom;

  /// The child's width.
  final double? width;

  /// The child's height.
  final double? height;
}
