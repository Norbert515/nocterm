import 'dart:math' as math;

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import 'stack.dart' as stack_lib;

/// Implements the stack layout algorithm.
///
/// In a stack layout, the children are positioned on top of each other in the
/// order in which they appear in the child list. First, the non-positioned
/// children (those with null values for top, right, bottom, and left) are
/// laid out and initially placed in the upper-left corner of the stack. The
/// stack is then sized to enclose all of the non-positioned children. If there
/// are no non-positioned children, the stack becomes as large as possible.
class RenderStack extends RenderObject
    with ContainerRenderObjectMixin<RenderObject> {
  RenderStack({
    List<RenderObject>? children,
    stack_lib.AlignmentGeometry alignment =
        stack_lib.AlignmentDirectional.topStart,
    TextDirection? textDirection,
    stack_lib.StackFit fit = stack_lib.StackFit.loose,
    stack_lib.Clip clipBehavior = stack_lib.Clip.hardEdge,
  }) : _alignment = alignment,
       _textDirection = textDirection,
       _fit = fit,
       _clipBehavior = clipBehavior {
    if (children != null) {
      for (final child in children) {
        addChild(child);
      }
    }
  }

  bool _hasVisualOverflow = false;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! stack_lib.StackParentData) {
      child.parentData = stack_lib.StackParentData();
    }
  }

  stack_lib.Alignment? _resolvedAlignment;

  stack_lib.Alignment get resolvedAlignment {
    _resolvedAlignment ??= alignment.resolve(textDirection);
    return _resolvedAlignment!;
  }

  void _markNeedResolution() {
    _resolvedAlignment = null;
    markNeedsLayout();
  }

  /// How to align the non-positioned or partially-positioned children in the stack.
  stack_lib.AlignmentGeometry get alignment => _alignment;
  stack_lib.AlignmentGeometry _alignment;
  set alignment(stack_lib.AlignmentGeometry value) {
    if (_alignment == value) return;
    _alignment = value;
    _markNeedResolution();
  }

  /// The text direction with which to resolve [alignment].
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) return;
    _textDirection = value;
    _markNeedResolution();
  }

  /// How to size the non-positioned children in the stack.
  stack_lib.StackFit get fit => _fit;
  stack_lib.StackFit _fit;
  set fit(stack_lib.StackFit value) {
    if (_fit != value) {
      _fit = value;
      markNeedsLayout();
    }
  }

  /// Whether to clip overflowing children.
  stack_lib.Clip get clipBehavior => _clipBehavior;
  stack_lib.Clip _clipBehavior = stack_lib.Clip.hardEdge;
  set clipBehavior(stack_lib.Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
    }
  }

  /// Get first child with proper type handling
  RenderObject? get firstChild => children.isNotEmpty ? children.first : null;

  /// Get last child with proper type handling
  RenderObject? get lastChild => children.isNotEmpty ? children.last : null;

  /// Compute constraints for non-positioned children.
  BoxConstraints _computeNonPositionedChildConstraints(
    BoxConstraints constraints,
  ) {
    switch (fit) {
      case stack_lib.StackFit.loose:
        return constraints.loosen();
      case stack_lib.StackFit.expand:
        return BoxConstraints.tight(
          Size(constraints.maxWidth, constraints.maxHeight),
        );
      case stack_lib.StackFit.passthrough:
        return constraints;
    }
  }

  /// Get the biggest size if bounded
  Size get _biggestSize {
    return Size(
      constraints.hasBoundedWidth ? constraints.maxWidth : 0.0,
      constraints.hasBoundedHeight ? constraints.maxHeight : 0.0,
    );
  }

  /// Create tightened box constraints
  BoxConstraints _tighten({double? width, double? height}) {
    return BoxConstraints(
      minWidth: width ?? 0.0,
      maxWidth: width ?? double.infinity,
      minHeight: height ?? 0.0,
      maxHeight: height ?? double.infinity,
    );
  }

  /// Layout a positioned child.
  void _layoutPositionedChild(
    RenderObject child,
    stack_lib.StackParentData childParentData,
    Size size,
    stack_lib.Alignment alignment,
  ) {
    assert(childParentData.isPositioned);

    final double? left = childParentData.left;
    final double? top = childParentData.top;
    final double? right = childParentData.right;
    final double? bottom = childParentData.bottom;
    final double? width = childParentData.width;
    final double? height = childParentData.height;

    // Calculate horizontal and vertical constraints
    double? constraintWidth;
    double? constraintHeight;

    // Calculate horizontal constraints
    if (left != null && right != null) {
      constraintWidth = size.width - right - left;
    } else if (width != null) {
      constraintWidth = width;
    }

    // Calculate vertical constraints
    if (top != null && bottom != null) {
      constraintHeight = size.height - bottom - top;
    } else if (height != null) {
      constraintHeight = height;
    }

    final BoxConstraints childConstraints = _tighten(
      width: constraintWidth,
      height: constraintHeight,
    );

    child.layout(childConstraints, parentUsesSize: true);

    // Calculate position
    double x;
    if (left != null) {
      x = left;
    } else if (right != null) {
      x = size.width - right - child.size.width;
    } else {
      x = alignment.alongSize(size).dx - alignment.alongSize(child.size).dx;
    }

    double y;
    if (top != null) {
      y = top;
    } else if (bottom != null) {
      y = size.height - bottom - child.size.height;
    } else {
      y = alignment.alongSize(size).dy - alignment.alongSize(child.size).dy;
    }

    childParentData.offset = Offset(x, y);
  }

  @override
  void performLayout() {
    _hasVisualOverflow = false;

    // First pass: layout non-positioned children and compute stack size
    double width = 0.0;
    double height = 0.0;
    bool hasNonPositionedChildren = false;

    final BoxConstraints nonPositionedConstraints =
        _computeNonPositionedChildConstraints(constraints);

    for (final child in children) {
      final stack_lib.StackParentData childParentData =
          child.parentData! as stack_lib.StackParentData;

      if (!childParentData.isPositioned) {
        hasNonPositionedChildren = true;
        child.layout(nonPositionedConstraints, parentUsesSize: true);

        final Size childSize = child.size;
        width = math.max(width, childSize.width);
        height = math.max(height, childSize.height);
      }
    }

    // Determine the stack size
    if (hasNonPositionedChildren) {
      size = constraints.constrain(Size(width, height));
    } else {
      size = _biggestSize;
    }

    // Second pass: position non-positioned children
    for (final child in children) {
      final stack_lib.StackParentData childParentData =
          child.parentData! as stack_lib.StackParentData;

      if (!childParentData.isPositioned) {
        final stack_lib.Alignment alignment = resolvedAlignment;
        childParentData.offset =
            alignment.alongSize(size) - alignment.alongSize(child.size);
      }
    }

    // Third pass: layout and position positioned children
    for (final child in children) {
      final stack_lib.StackParentData childParentData =
          child.parentData! as stack_lib.StackParentData;

      if (childParentData.isPositioned) {
        _layoutPositionedChild(child, childParentData, size, resolvedAlignment);
      }

      // Check for overflow
      if (clipBehavior != stack_lib.Clip.none) {
        final Offset offset = childParentData.offset;
        final Size childSize = child.size;
        if (offset.dx < 0 ||
            offset.dy < 0 ||
            offset.dx + childSize.width > size.width ||
            offset.dy + childSize.height > size.height) {
          _hasVisualOverflow = true;
        }
      }
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);

    if (_hasVisualOverflow && clipBehavior != stack_lib.Clip.none) {
      // Create a clipped canvas for painting children
      final clippedCanvas = canvas.clip(
        Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
      );

      // Paint children with clipped canvas at Offset.zero since clip already accounts for offset
      for (final child in children) {
        final stack_lib.StackParentData childParentData =
            child.parentData! as stack_lib.StackParentData;
        child.paintWithContext(clippedCanvas, childParentData.offset);
      }
    } else {
      // No clipping needed - paint children normally
      for (final child in children) {
        final stack_lib.StackParentData childParentData =
            child.parentData! as stack_lib.StackParentData;
        child.paintWithContext(canvas, offset + childParentData.offset);
      }
    }
  }

  @override
  bool hitTest(HitTestResult result, {required Offset position}) {
    // Check if position is within bounds
    if (position.dx >= 0 &&
        position.dx < size.width &&
        position.dy >= 0 &&
        position.dy < size.height) {
      // Hit test children in reverse order (topmost first)
      for (final child in children.reversed) {
        final stack_lib.StackParentData childParentData =
            child.parentData! as stack_lib.StackParentData;

        final Offset childPosition = position - childParentData.offset;
        if (child.hitTest(result, position: childPosition)) {
          return true;
        }
      }

      result.add(this);
      return true;
    }
    return false;
  }
}

/// A widget that positions its children relative to the edges of its box.
///
/// This class is useful if you want to overlap several children in a simple
/// way, for example having some text and an image, overlaid with a gradient
/// and a button attached to the bottom.
class Stack extends MultiChildRenderObjectComponent {
  /// Creates a stack layout widget.
  const Stack({
    super.key,
    this.alignment = stack_lib.AlignmentDirectional.topStart,
    this.textDirection,
    this.fit = stack_lib.StackFit.loose,
    this.clipBehavior = stack_lib.Clip.hardEdge,
    super.children = const <Component>[],
  });

  /// How to align the non-positioned and partially-positioned children in the stack.
  final stack_lib.AlignmentGeometry alignment;

  /// The text direction with which to resolve [alignment].
  final TextDirection? textDirection;

  /// How to size the non-positioned children in the stack.
  final stack_lib.StackFit fit;

  /// Whether to clip overflowing children.
  final stack_lib.Clip clipBehavior;

  @override
  RenderStack createRenderObject(BuildContext context) {
    return RenderStack(
      alignment: alignment,
      textDirection: textDirection ?? TextDirection.ltr,
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderStack renderObject) {
    renderObject
      ..alignment = alignment
      ..textDirection = textDirection ?? TextDirection.ltr
      ..fit = fit
      ..clipBehavior = clipBehavior;
  }
}
