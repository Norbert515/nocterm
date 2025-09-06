import 'dart:math' as math;

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import 'package:nocterm/src/rectangle.dart';
import '../keyboard/mouse_event.dart';
import 'scrollable_element.dart';

/// A box in which a single widget can be scrolled.
///
/// This widget is useful when you have a single box that will normally be
/// entirely visible, but you need to make sure it can be scrolled if the
/// container gets too small in one axis.
class SingleChildScrollView extends StatefulComponent {
  const SingleChildScrollView({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.padding,
    this.child,
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

  @override
  State<SingleChildScrollView> createState() => _SingleChildScrollViewState();
}

class _SingleChildScrollViewState extends State<SingleChildScrollView> implements ScrollableElement {
  ScrollController? _controller;

  ScrollController get _effectiveController => component.controller ?? _controller!;

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
    final key = event.logicalKey;

    if (component.scrollDirection == Axis.vertical) {
      if (key == LogicalKey.arrowUp) {
        controller.scrollUp();
        return true;
      } else if (key == LogicalKey.arrowDown) {
        controller.scrollDown();
        return true;
      } else if (key == LogicalKey.pageUp) {
        controller.pageUp();
        return true;
      } else if (key == LogicalKey.pageDown) {
        controller.pageDown();
        return true;
      } else if (key == LogicalKey.home) {
        controller.scrollToStart();
        return true;
      } else if (key == LogicalKey.end) {
        controller.scrollToEnd();
        return true;
      }
    } else {
      if (key == LogicalKey.arrowLeft) {
        controller.scrollUp();
        return true;
      } else if (key == LogicalKey.arrowRight) {
        controller.scrollDown();
        return true;
      } else if (key == LogicalKey.home) {
        controller.scrollToStart();
        return true;
      } else if (key == LogicalKey.end) {
        controller.scrollToEnd();
        return true;
      }
    }
    return false;
  }
  
  @override
  bool handleMouseWheel(MouseEvent event) {
    final controller = _effectiveController;
    
    // Only handle vertical scroll for vertical ScrollViews
    // and horizontal scroll for horizontal ScrollViews
    if (component.scrollDirection == Axis.vertical) {
      if (event.button == MouseButton.wheelUp) {
        controller.scrollUp(3.0); // Scroll 3 lines
        return true;
      } else if (event.button == MouseButton.wheelDown) {
        controller.scrollDown(3.0); // Scroll 3 lines
        return true;
      }
    } else {
      // For horizontal scroll, we might want to handle horizontal wheel events
      // but for now just handle vertical wheel as horizontal scroll
      if (event.button == MouseButton.wheelUp) {
        controller.scrollUp(3.0);
        return true;
      } else if (event.button == MouseButton.wheelDown) {
        controller.scrollDown(3.0);
        return true;
      }
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

    return Focusable(
      focused: true,
      onKeyEvent: _handleKeyEvent,
      child: _SingleChildViewport(
        scrollDirection: component.scrollDirection,
        controller: _effectiveController,
        child: child,
      ),
    );
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
  void updateRenderObject(BuildContext context, RenderSingleChildViewport renderObject) {
    renderObject
      ..scrollDirection = scrollDirection
      ..controller = controller;
  }
}

/// Render object for a scrollable single child viewport.
class RenderSingleChildViewport extends RenderObject with RenderObjectWithChildMixin<RenderObject> {
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
  void dispose() {
    _controller.removeListener(_handleScrollUpdate);
    super.dispose();
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

    // Our size is constrained by our parent
    size = constraints.constrain(Size(
      constraints.maxWidth,
      constraints.maxHeight,
    ));

    // Update scroll controller metrics
    final double viewportExtent = scrollDirection == Axis.vertical ? size.height : size.width;
    final double scrollExtent = scrollDirection == Axis.vertical ? child!.size.height : child!.size.width;

    _controller.updateMetrics(
      minScrollExtent: 0,
      maxScrollExtent: math.max(0, scrollExtent - viewportExtent),
      viewportDimension: viewportExtent,
    );
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    if (child == null) return;

    // Calculate the scroll offset
    final scrollOffset =
        scrollDirection == Axis.vertical ? Offset(0, -_controller.offset) : Offset(-_controller.offset, 0);

    // Create a clipped canvas for the viewport
    final clippedCanvas = canvas.clip(
      Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
    );

    // Paint the child at the combined offset (viewport offset + scroll offset)
    child!.paint(clippedCanvas, Offset.zero + scrollOffset);
  }
}
