import 'dart:math' as math;

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import '../rendering/scrollable_render_object.dart';

/// A box in which a single widget can be scrolled.
///
/// This widget is useful when you have a single box that will normally be
/// entirely visible, but you need to make sure it can be scrolled if the
/// container gets too small in one axis.
///
/// Set [keyboardScrollable] to true to enable keyboard navigation with
/// arrow keys, Page Up/Down, and Home/End.
class SingleChildScrollView extends StatefulComponent {
  const SingleChildScrollView({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.padding,
    this.child,
    this.keyboardScrollable = false,
  });

  /// The axis along which the scroll view scrolls.
  final Axis scrollDirection;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  final ScrollController? controller;

  /// The amount of space by which to inset the child.
  final EdgeInsets? padding;

  /// The widget that scrolls.
  final Component? child;

  /// Whether to enable keyboard scrolling with arrow keys, Page Up/Down, etc.
  ///
  /// When true, the scroll view will be wrapped in a [Focusable] that handles:
  /// - Arrow Up/Down (or Left/Right for horizontal): scroll by 1 line
  /// - Page Up/Down: scroll by viewport height
  /// - Home/End: scroll to start/end
  final bool keyboardScrollable;

  @override
  State<SingleChildScrollView> createState() => _SingleChildScrollViewState();
}

class _SingleChildScrollViewState extends State<SingleChildScrollView> {
  ScrollController? _controller;

  ScrollController get _effectiveController =>
      component.controller ?? _controller!;

  @override
  void initState() {
    super.initState();
    if (component.controller == null) {
      _controller = ScrollController();
    }
  }

  @override
  void didUpdateComponent(SingleChildScrollView oldWidget) {
    super.didUpdateComponent(oldWidget);
    if (component.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _controller?.dispose();
        _controller = null;
      }
      if (component.controller == null) {
        _controller = ScrollController();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyboardEvent event) {
    final controller = _effectiveController;
    final isVertical = component.scrollDirection == Axis.vertical;

    // Arrow keys for single line scroll
    if (isVertical) {
      if (event.logicalKey == LogicalKey.arrowUp) {
        controller.scrollUp(1.0);
        return true;
      } else if (event.logicalKey == LogicalKey.arrowDown) {
        controller.scrollDown(1.0);
        return true;
      }
    } else {
      if (event.logicalKey == LogicalKey.arrowLeft) {
        controller.scrollUp(1.0);
        return true;
      } else if (event.logicalKey == LogicalKey.arrowRight) {
        controller.scrollDown(1.0);
        return true;
      }
    }

    // Page Up/Down for viewport-sized scroll
    if (event.logicalKey == LogicalKey.pageUp) {
      controller.scrollUp(controller.viewportDimension);
      return true;
    } else if (event.logicalKey == LogicalKey.pageDown) {
      controller.scrollDown(controller.viewportDimension);
      return true;
    }

    // Home/End for scroll to start/end
    if (event.logicalKey == LogicalKey.home) {
      controller.jumpTo(0);
      return true;
    } else if (event.logicalKey == LogicalKey.end) {
      controller.jumpTo(controller.maxScrollExtent);
      return true;
    }

    return false;
  }

  @override
  Component build(BuildContext context) {
    Component? child = component.child;

    if (component.padding != null && child != null) {
      child = Padding(
        padding: component.padding!,
        child: child,
      );
    }

    Component viewport = _SingleChildViewport(
      scrollDirection: component.scrollDirection,
      controller: _effectiveController,
      child: child,
    );

    // Wrap with Focusable for keyboard scrolling if enabled
    if (component.keyboardScrollable) {
      viewport = Focusable(
        focused: true,
        onKeyEvent: _handleKeyEvent,
        child: viewport,
      );
    }

    return viewport;
  }
}

/// Internal widget that handles the viewport and clipping.
class _SingleChildViewport extends SingleChildRenderObjectComponent {
  const _SingleChildViewport({
    required this.scrollDirection,
    required this.controller,
    super.child,
  });

  final Axis scrollDirection;
  final ScrollController controller;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSingleChildViewport(
      scrollDirection: scrollDirection,
      controller: controller,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSingleChildViewport renderObject) {
    renderObject
      ..scrollDirection = scrollDirection
      ..controller = controller;
  }
}

/// Render object for a scrollable single child viewport.
class RenderSingleChildViewport extends RenderObject
    with RenderObjectWithChildMixin<RenderObject>, ScrollableRenderObjectMixin {
  RenderSingleChildViewport({
    required Axis scrollDirection,
    required ScrollController controller,
  })  : _scrollDirection = scrollDirection,
        _controller = controller {
    _controller.addListener(_handleScrollUpdate);
  }

  Axis _scrollDirection;
  Axis get scrollDirection => _scrollDirection;
  set scrollDirection(Axis value) {
    if (_scrollDirection != value) {
      _scrollDirection = value;
      markNeedsLayout();
    }
  }

  ScrollController _controller;
  ScrollController get controller => _controller;
  set controller(ScrollController value) {
    if (_controller != value) {
      _controller.removeListener(_handleScrollUpdate);
      _controller = value;
      _controller.addListener(_handleScrollUpdate);
      markNeedsLayout();
    }
  }

  void _handleScrollUpdate() {
    markNeedsPaint();
  }

  @override
  bool handleMouseWheel(MouseEvent event) {
    // Only handle vertical scroll for vertical ScrollViews
    // and horizontal scroll for horizontal ScrollViews
    if (_scrollDirection == Axis.vertical) {
      if (event.button == MouseButton.wheelUp) {
        _controller.scrollUp(3.0); // Scroll 3 lines
        return true;
      } else if (event.button == MouseButton.wheelDown) {
        _controller.scrollDown(3.0); // Scroll 3 lines
        return true;
      }
    } else {
      // For horizontal scroll, we might want to handle horizontal wheel events
      // but for now just handle vertical wheel as horizontal scroll
      if (event.button == MouseButton.wheelUp) {
        _controller.scrollUp(3.0);
        return true;
      } else if (event.button == MouseButton.wheelDown) {
        _controller.scrollDown(3.0);
        return true;
      }
    }

    return false;
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScrollUpdate);
    super.dispose();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    if (child == null) {
      size = constraints.constrain(Size.zero);
      return;
    }

    // Let the child lay itself out without size constraints in the scroll direction
    final childConstraints = scrollDirection == Axis.vertical
        ? BoxConstraints(
            minWidth: constraints.minWidth,
            maxWidth: constraints.maxWidth,
            minHeight: 0,
            maxHeight: double.infinity,
          )
        : BoxConstraints(
            minHeight: constraints.minHeight,
            maxHeight: constraints.maxHeight,
            minWidth: 0,
            maxWidth: double.infinity,
          );

    child!.layout(childConstraints, parentUsesSize: true);

    // Shrink-wrap to child size, clamped by parent constraints
    size = constraints.constrain(child!.size);

    // Update scroll controller metrics
    final double viewportExtent =
        scrollDirection == Axis.vertical ? size.height : size.width;
    final double scrollExtent = scrollDirection == Axis.vertical
        ? child!.size.height
        : child!.size.width;

    _controller.updateMetrics(
      minScrollExtent: 0,
      maxScrollExtent: math.max(0, scrollExtent - viewportExtent),
      viewportDimension: viewportExtent,
    );

    // Store scroll offset in child's parent data so globalPaintOffset
    // traversals can see the scroll translation.
    final childParentData = child!.parentData as BoxParentData;
    final scrollOffset = scrollDirection == Axis.vertical
        ? Offset(0, -_controller.offset)
        : Offset(-_controller.offset, 0);
    childParentData.offset = scrollOffset;
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    if (child == null) return;

    // Calculate the scroll offset
    final scrollOffset = scrollDirection == Axis.vertical
        ? Offset(0, -_controller.offset)
        : Offset(-_controller.offset, 0);

    // Create a clipped canvas for the viewport
    final clippedCanvas = canvas.clip(
      Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
    );

    // Paint the child at the combined offset (viewport offset + scroll offset)
    final childParentData = child!.parentData as BoxParentData?;
    if (childParentData != null) {
      childParentData.offset = scrollOffset;
    }
    child!.paint(clippedCanvas, Offset.zero + scrollOffset);
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    if (child != null) {
      // Account for scroll offset when hit testing
      final scrollOffset = scrollDirection == Axis.vertical
          ? Offset(0, -_controller.offset)
          : Offset(-_controller.offset, 0);
      final childPosition = position - scrollOffset;
      return child!.hitTest(result, position: childPosition);
    }
    return false;
  }
}
