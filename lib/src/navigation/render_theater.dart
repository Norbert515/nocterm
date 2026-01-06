import 'dart:collection';

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import 'package:nocterm/src/components/stack.dart' as stack_lib;

/// Parent data for children in a RenderTheater.
class TheaterParentData extends stack_lib.StackParentData {
  /// The OverlayEntry that directly created this child.
  OverlayEntry? overlayEntry;

  /// Linked list of overlay portal children managed by this entry.
  LinkedList<OverlayEntryLocation>? sortedTheaterSiblings;

  /// Iterator for paint order traversal.
  Iterator<RenderDeferredLayoutBox>? get paintOrderIterator =>
      overlayEntry?.paintOrderIterable?.iterator;

  /// Iterator for hit test order traversal.
  Iterator<RenderDeferredLayoutBox>? get hitTestOrderIterator =>
      overlayEntry?.hitTestOrderIterable?.iterator;

  /// Visit overlay portal children on this overlay entry.
  void visitOverlayPortalChildrenOnOverlayEntry(
    void Function(RenderObject) visitor,
  ) {
    final iterable = overlayEntry?.paintOrderIterable;
    if (iterable != null) {
      for (final child in iterable) {
        visitor(child);
      }
    }
  }
}

/// A render object that implements the theater pattern for overlays.
///
/// This is similar to a Stack but with optimizations for overlay management:
/// - Supports skipping offstage children that don't need to be laid out
/// - Manages paint order efficiently
/// - Supports deferred layout for overlay portal children
class RenderTheater extends RenderObject
    with ContainerRenderObjectMixin<RenderObject> {
  RenderTheater({
    List<RenderObject>? children,
    required TextDirection textDirection,
    int skipCount = 0,
    stack_lib.Clip clipBehavior = stack_lib.Clip.hardEdge,
  }) : _textDirection = textDirection,
       _skipCount = skipCount,
       _clipBehavior = clipBehavior {
    if (children != null) {
      for (final child in children) {
        addChild(child);
      }
    }
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! TheaterParentData) {
      child.parentData = TheaterParentData();
    }
  }

  stack_lib.Alignment? _alignmentCache;
  stack_lib.Alignment get resolvedAlignment => _alignmentCache ??= stack_lib
      .AlignmentDirectional
      .topStart
      .resolve(textDirection);

  void _markNeedResolution() {
    _alignmentCache = null;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _markNeedResolution();
  }

  /// Number of children to skip (consider offstage).
  int get skipCount => _skipCount;
  int _skipCount;
  set skipCount(int value) {
    if (_skipCount != value) {
      _skipCount = value;
      markNeedsLayout();
    }
  }

  stack_lib.Clip get clipBehavior => _clipBehavior;
  stack_lib.Clip _clipBehavior = stack_lib.Clip.hardEdge;
  set clipBehavior(stack_lib.Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
    }
  }

  /// Get the first onstage child (skipping offstage children).
  RenderObject? get _firstOnstageChild {
    if (skipCount >= children.length) {
      return null;
    }
    final childrenList = children.toList();
    return skipCount < childrenList.length ? childrenList[skipCount] : null;
  }

  /// Get the last onstage child.
  RenderObject? get _lastOnstageChild =>
      skipCount >= children.length ? null : children.last;

  /// Flag to prevent layout loops when adding deferred children.
  bool _skipMarkNeedsLayout = false;

  /// Add a deferred child (from overlay portal).
  void addDeferredChild(RenderDeferredLayoutBox child) {
    assert(!_skipMarkNeedsLayout);
    _skipMarkNeedsLayout = true;
    adoptChild(child);
    markNeedsPaint();
    _skipMarkNeedsLayout = false;

    // Mark the child for layout
    child.layoutSurrogate?.markNeedsLayout();
  }

  /// Remove a deferred child.
  void removeDeferredChild(RenderDeferredLayoutBox child) {
    assert(!_skipMarkNeedsLayout);
    _skipMarkNeedsLayout = true;
    dropChild(child);
    markNeedsPaint();
    _skipMarkNeedsLayout = false;
  }

  @override
  void markNeedsLayout() {
    if (!_skipMarkNeedsLayout) {
      super.markNeedsLayout();
    }
  }

  /// Find the child that determines the size when constraints are infinite.
  RenderObject? _findSizeDeterminingChild() {
    RenderObject? child = _lastOnstageChild;
    while (child != null) {
      final TheaterParentData childParentData =
          child.parentData! as TheaterParentData;
      if (!childParentData.isPositioned) {
        return child;
      }
      final index = children.toList().indexOf(child);
      if (index <= skipCount) break;
      child = index > 0 ? children.toList()[index - 1] : null;
    }
    return null;
  }

  /// Layout a child with the given constraints.
  void layoutChild(
    RenderObject child,
    BoxConstraints nonPositionedChildConstraints,
  ) {
    final TheaterParentData childParentData =
        child.parentData! as TheaterParentData;
    final stack_lib.Alignment alignment = resolvedAlignment;

    if (!childParentData.isPositioned) {
      child.layout(nonPositionedChildConstraints, parentUsesSize: true);
      childParentData.offset = Offset.zero;
    } else {
      // Layout positioned child
      layoutPositionedChild(child, childParentData, size, alignment);
    }
  }

  /// Layout a positioned child.
  static void layoutPositionedChild(
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

    double? constraintWidth;
    double? constraintHeight;

    if (left != null && right != null) {
      constraintWidth = size.width - right - left;
    } else if (width != null) {
      constraintWidth = width;
    }

    if (top != null && bottom != null) {
      constraintHeight = size.height - bottom - top;
    } else if (height != null) {
      constraintHeight = height;
    }

    final BoxConstraints childConstraints = BoxConstraints(
      minWidth: constraintWidth ?? 0.0,
      maxWidth: constraintWidth ?? double.infinity,
      minHeight: constraintHeight ?? 0.0,
      maxHeight: constraintHeight ?? double.infinity,
    );

    child.layout(childConstraints, parentUsesSize: true);

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

  /// Get children in paint order (bottom to top).
  Iterable<RenderObject> get childrenInPaintOrder sync* {
    RenderObject? child = _firstOnstageChild;
    final childrenList = children.toList();
    int index = skipCount;

    while (child != null && index < childrenList.length) {
      yield child;

      // Also yield overlay portal children if any
      final TheaterParentData childParentData =
          child.parentData! as TheaterParentData;
      final Iterator<RenderDeferredLayoutBox>? innerIterator =
          childParentData.paintOrderIterator;
      if (innerIterator != null) {
        while (innerIterator.moveNext()) {
          yield innerIterator.current;
        }
      }

      index++;
      child = index < childrenList.length ? childrenList[index] : null;
    }
  }

  /// Get children in hit test order (top to bottom).
  Iterable<RenderObject> get childrenInHitTestOrder sync* {
    RenderObject? child = _lastOnstageChild;
    final childrenList = children.toList();
    int childLeft = childrenList.length - skipCount;

    while (child != null && childLeft > 0) {
      final TheaterParentData childParentData =
          child.parentData! as TheaterParentData;

      // First yield overlay portal children if any
      final Iterator<RenderDeferredLayoutBox>? innerIterator =
          childParentData.hitTestOrderIterator;
      if (innerIterator != null) {
        while (innerIterator.moveNext()) {
          yield innerIterator.current;
        }
      }

      yield child;
      childLeft -= 1;

      final index = childrenList.indexOf(child);
      child = index > skipCount ? childrenList[index - 1] : null;
    }
  }

  @override
  void performLayout() {
    RenderObject? sizeDeterminingChild;

    if (constraints.maxWidth.isFinite && constraints.maxHeight.isFinite) {
      size = Size(constraints.maxWidth, constraints.maxHeight);
    } else {
      sizeDeterminingChild = _findSizeDeterminingChild();
      if (sizeDeterminingChild != null) {
        layoutChild(sizeDeterminingChild, constraints);
        size = sizeDeterminingChild.size;
      } else {
        size = Size.zero;
      }
    }

    final BoxConstraints nonPositionedChildConstraints = BoxConstraints.tight(
      size,
    );

    for (final child in childrenInPaintOrder) {
      if (child != sizeDeterminingChild) {
        layoutChild(child, nonPositionedChildConstraints);
      }
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);

    for (final child in childrenInPaintOrder) {
      final stack_lib.StackParentData childParentData =
          child.parentData! as stack_lib.StackParentData;
      child.paintWithContext(canvas, offset + childParentData.offset);
    }
  }

  @override
  bool hitTest(HitTestResult result, {required Offset position}) {
    if (position.dx >= 0 &&
        position.dx < size.width &&
        position.dy >= 0 &&
        position.dy < size.height) {
      for (final child in childrenInHitTestOrder) {
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

  @override
  void visitChildren(void Function(RenderObject) visitor) {
    for (final child in children) {
      visitor(child);
      final TheaterParentData childParentData =
          child.parentData! as TheaterParentData;
      childParentData.visitOverlayPortalChildrenOnOverlayEntry(visitor);
    }
  }
}

/// Location in an overlay for overlay portal children.
base class OverlayEntryLocation extends LinkedListEntry<OverlayEntryLocation> {
  OverlayEntryLocation(this.zOrderIndex, this.overlayEntry, this.theater);

  final int zOrderIndex;
  final OverlayEntry overlayEntry;
  final RenderTheater theater;

  RenderDeferredLayoutBox? overlayChildRenderBox;

  void addToChildModel(RenderDeferredLayoutBox child) {
    overlayChildRenderBox = child;
    overlayEntry.addOverlayPortalChild(this);
    theater.markNeedsPaint();
  }

  void removeFromChildModel(RenderDeferredLayoutBox child) {
    assert(child == overlayChildRenderBox);
    overlayChildRenderBox = null;
    overlayEntry.removeOverlayPortalChild(this);
    theater.markNeedsPaint();
  }
}

/// Base class for deferred layout boxes (placeholder for now).
abstract class RenderDeferredLayoutBox extends RenderObject {
  RenderObject? get layoutSurrogate;
}

/// Extension to OverlayEntry to support overlay portal children.
extension OverlayEntryPortalSupport on OverlayEntry {
  LinkedList<OverlayEntryLocation>? get sortedTheaterSiblings => null;

  Iterable<RenderDeferredLayoutBox>? get paintOrderIterable => null;

  Iterable<RenderDeferredLayoutBox>? get hitTestOrderIterable => null;

  void addOverlayPortalChild(OverlayEntryLocation location) {
    // To be implemented when overlay portal support is added
  }

  void removeOverlayPortalChild(OverlayEntryLocation location) {
    // To be implemented when overlay portal support is added
  }
}
