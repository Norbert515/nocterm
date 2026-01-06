import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';

/// A widget that clips its child using a rectangle.
///
/// By default, [ClipRect] prevents its child from painting outside its
/// bounds, but the size and location of the clip rect can be customized.
class ClipRect extends SingleChildRenderObjectComponent {
  /// Creates a rectangular clip.
  ///
  /// If [clipBehavior] is [Clip.none], no clipping will be applied.
  const ClipRect({super.key, this.clipBehavior = Clip.hardEdge, super.child});

  /// Controls how to clip.
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  @override
  RenderClipRect createRenderObject(BuildContext context) {
    return RenderClipRect(clipBehavior: clipBehavior);
  }

  @override
  void updateRenderObject(BuildContext context, RenderClipRect renderObject) {
    renderObject.clipBehavior = clipBehavior;
  }
}

/// A render object that clips its child to its bounds.
class RenderClipRect extends RenderObject
    with RenderObjectWithChildMixin<RenderObject> {
  /// Creates a rectangular clip.
  RenderClipRect({Clip clipBehavior = Clip.hardEdge})
    : _clipBehavior = clipBehavior;

  Clip _clipBehavior;

  /// Controls how to clip.
  Clip get clipBehavior => _clipBehavior;
  set clipBehavior(Clip value) {
    if (_clipBehavior == value) return;
    _clipBehavior = value;
    markNeedsPaint();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    if (child != null) {
      child!.layout(constraints, parentUsesSize: true);
      size = child!.size;
    } else {
      size = constraints.constrain(Size.zero);
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    if (child == null) return;

    if (_clipBehavior != Clip.none) {
      final clippedCanvas = canvas.clip(
        Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
      );
      child!.paintWithContext(clippedCanvas, Offset.zero);
    } else {
      child!.paintWithContext(canvas, offset);
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    if (child != null) {
      return child!.hitTest(result, position: position);
    }
    return false;
  }
}

/// A widget that imposes different constraints on its child than it gets
/// from its parent, possibly allowing the child to overflow the parent.
///
/// This is useful when you want a child to be larger than its parent and
/// have the overflow clipped or just want to lay out a child with different
/// constraints than those received from the parent.
class OverflowBox extends SingleChildRenderObjectComponent {
  /// Creates a widget that lets its child overflow itself.
  const OverflowBox({
    super.key,
    this.alignment = Alignment.center,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    super.child,
  });

  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  ///
  /// Defaults to [Alignment.center].
  final AlignmentGeometry alignment;

  /// The minimum width constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double? minWidth;

  /// The maximum width constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double? maxWidth;

  /// The minimum height constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double? minHeight;

  /// The maximum height constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double? maxHeight;

  @override
  RenderOverflowBox createRenderObject(BuildContext context) {
    return RenderOverflowBox(
      alignment: alignment,
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderOverflowBox renderObject,
  ) {
    renderObject
      ..alignment = alignment
      ..minWidth = minWidth
      ..maxWidth = maxWidth
      ..minHeight = minHeight
      ..maxHeight = maxHeight;
  }
}

/// A render object that imposes different constraints on its child than it
/// gets from its parent, possibly allowing the child to overflow the parent.
class RenderOverflowBox extends RenderObject
    with RenderObjectWithChildMixin<RenderObject> {
  /// Creates a render object that lets its child overflow itself.
  RenderOverflowBox({
    AlignmentGeometry alignment = Alignment.center,
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  }) : _alignment = alignment,
       _minWidth = minWidth,
       _maxWidth = maxWidth,
       _minHeight = minHeight,
       _maxHeight = maxHeight;

  AlignmentGeometry _alignment;

  /// How to align the child.
  AlignmentGeometry get alignment => _alignment;
  set alignment(AlignmentGeometry value) {
    if (_alignment == value) return;
    _alignment = value;
    markNeedsLayout();
  }

  double? _minWidth;

  /// The minimum width constraint to give the child.
  double? get minWidth => _minWidth;
  set minWidth(double? value) {
    if (_minWidth == value) return;
    _minWidth = value;
    markNeedsLayout();
  }

  double? _maxWidth;

  /// The maximum width constraint to give the child.
  double? get maxWidth => _maxWidth;
  set maxWidth(double? value) {
    if (_maxWidth == value) return;
    _maxWidth = value;
    markNeedsLayout();
  }

  double? _minHeight;

  /// The minimum height constraint to give the child.
  double? get minHeight => _minHeight;
  set minHeight(double? value) {
    if (_minHeight == value) return;
    _minHeight = value;
    markNeedsLayout();
  }

  double? _maxHeight;

  /// The maximum height constraint to give the child.
  double? get maxHeight => _maxHeight;
  set maxHeight(double? value) {
    if (_maxHeight == value) return;
    _maxHeight = value;
    markNeedsLayout();
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: _minWidth ?? constraints.minWidth,
      maxWidth: _maxWidth ?? constraints.maxWidth,
      minHeight: _minHeight ?? constraints.minHeight,
      maxHeight: _maxHeight ?? constraints.maxHeight,
    );
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    if (child != null) {
      child!.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      size = constraints.constrain(child!.size);

      // Position child based on alignment
      final resolvedAlignment = _alignment.resolve(TextDirection.ltr);
      final childParentData = child!.parentData as BoxParentData;

      // Calculate the offset to center the child within our bounds
      // when the child may be larger or smaller than us
      final double dx = (size.width - child!.size.width) / 2.0;
      final double dy = (size.height - child!.size.height) / 2.0;
      childParentData.offset = Offset(
        dx + resolvedAlignment.x * dx,
        dy + resolvedAlignment.y * dy,
      );
    } else {
      size = constraints.constrain(Size.zero);
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    if (child != null) {
      final childParentData = child!.parentData as BoxParentData;
      child!.paintWithContext(canvas, offset + childParentData.offset);
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    if (child != null) {
      final childParentData = child!.parentData as BoxParentData;
      final childPosition = position - childParentData.offset;
      return child!.hitTest(result, position: childPosition);
    }
    return false;
  }
}

/// A widget that sizes its child to a fraction of the total available space.
///
/// See also:
///
///  * [Align], which sizes itself based on its child's size and positions
///    the child according to an [Alignment] value.
///  * [OverflowBox], a widget that imposes different constraints on its child
///    than it gets from its parent, possibly allowing the child to overflow
///    the parent.
class SizedOverflowBox extends SingleChildRenderObjectComponent {
  /// Creates a widget of a given size that lets its child overflow.
  const SizedOverflowBox({
    super.key,
    required this.size,
    this.alignment = Alignment.center,
    super.child,
  });

  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent.
  ///
  /// Defaults to [Alignment.center].
  final AlignmentGeometry alignment;

  /// The size this widget should attempt to be.
  final Size size;

  @override
  RenderSizedOverflowBox createRenderObject(BuildContext context) {
    return RenderSizedOverflowBox(alignment: alignment, requestedSize: size);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSizedOverflowBox renderObject,
  ) {
    renderObject
      ..alignment = alignment
      ..requestedSize = size;
  }
}

/// A render object that is a specific size but passes its original constraints
/// through to its child, which may then overflow.
class RenderSizedOverflowBox extends RenderObject
    with RenderObjectWithChildMixin<RenderObject> {
  /// Creates a render object that is a specific size.
  RenderSizedOverflowBox({
    AlignmentGeometry alignment = Alignment.center,
    required Size requestedSize,
  }) : _alignment = alignment,
       _requestedSize = requestedSize;

  AlignmentGeometry _alignment;

  /// How to align the child.
  AlignmentGeometry get alignment => _alignment;
  set alignment(AlignmentGeometry value) {
    if (_alignment == value) return;
    _alignment = value;
    markNeedsLayout();
  }

  Size _requestedSize;

  /// The size this render object should attempt to be.
  Size get requestedSize => _requestedSize;
  set requestedSize(Size value) {
    if (_requestedSize == value) return;
    _requestedSize = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.constrain(_requestedSize);
    if (child != null) {
      child!.layout(constraints, parentUsesSize: true);

      // Position child based on alignment
      final resolvedAlignment = _alignment.resolve(TextDirection.ltr);
      final childParentData = child!.parentData as BoxParentData;

      final double dx = (size.width - child!.size.width) / 2.0;
      final double dy = (size.height - child!.size.height) / 2.0;
      childParentData.offset = Offset(
        dx + resolvedAlignment.x * dx,
        dy + resolvedAlignment.y * dy,
      );
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    if (child != null) {
      final childParentData = child!.parentData as BoxParentData;
      child!.paintWithContext(canvas, offset + childParentData.offset);
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    if (child != null) {
      final childParentData = child!.parentData as BoxParentData;
      final childPosition = position - childParentData.offset;
      return child!.hitTest(result, position: childPosition);
    }
    return false;
  }
}
