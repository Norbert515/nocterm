import 'dart:math' as math;

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';

/// A scrollbar that can be optionally shown for scrollable widgets.
///
/// Typically used by wrapping a scrollable widget like [SingleChildScrollView]
/// or [ListView].
class Scrollbar extends StatefulComponent {
  const Scrollbar({
    super.key,
    required this.child,
    this.controller,
    this.thumbVisibility = false,
    this.thickness = 1.0,
    this.radius,
  });

  /// The widget below this widget in the tree.
  ///
  /// The scrollbar will be painted on top of this child. The child should be
  /// a scrollable widget.
  final Component child;

  /// The [ScrollController] used to control the scrollable widget.
  ///
  /// If null, the scrollbar will attempt to find a controller from the child.
  final ScrollController? controller;

  /// Indicates whether the scrollbar thumb should be always visible.
  ///
  /// When false, the scrollbar will only be visible while scrolling.
  /// When true, the scrollbar will always be visible.
  final bool thumbVisibility;

  /// The thickness of the scrollbar in the cross axis of the scrollable.
  final double thickness;

  /// The radius of the scrollbar thumb.
  final double? radius;

  @override
  State<Scrollbar> createState() => _ScrollbarState();
}

class _ScrollbarState extends State<Scrollbar> {
  ScrollController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = component.controller;
  }

  @override
  void didUpdateComponent(Scrollbar oldWidget) {
    super.didUpdateComponent(oldWidget);
    if (component.controller != oldWidget.controller) {
      _controller = component.controller;
    }
  }

  @override
  Component build(BuildContext context) {
    return _ScrollbarRenderObjectWidget(
      controller: _controller,
      thumbVisibility: component.thumbVisibility,
      thickness: component.thickness,
      child: component.child,
    );
  }
}

class _ScrollbarRenderObjectWidget extends SingleChildRenderObjectComponent {
  const _ScrollbarRenderObjectWidget({
    required this.controller,
    required this.thumbVisibility,
    required this.thickness,
    required super.child,
  });

  final ScrollController? controller;
  final bool thumbVisibility;
  final double thickness;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderScrollbar(
      controller: controller,
      thumbVisibility: thumbVisibility,
      thickness: thickness,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderScrollbar renderObject) {
    renderObject
      ..controller = controller
      ..thumbVisibility = thumbVisibility
      ..thickness = thickness;
  }
}

/// Render object for a scrollbar.
class RenderScrollbar extends RenderObject with RenderObjectWithChildMixin<RenderObject> {
  RenderScrollbar({
    ScrollController? controller,
    required bool thumbVisibility,
    required double thickness,
  })  : _controller = controller,
        _thumbVisibility = thumbVisibility,
        _thickness = thickness {
    _controller?.addListener(_handleScrollUpdate);
  }

  ScrollController? _controller;
  ScrollController? get controller => _controller;
  set controller(ScrollController? value) {
    if (_controller != value) {
      _controller?.removeListener(_handleScrollUpdate);
      _controller = value;
      _controller?.addListener(_handleScrollUpdate);
      markNeedsPaint();
    }
  }

  bool _thumbVisibility;
  bool get thumbVisibility => _thumbVisibility;
  set thumbVisibility(bool value) {
    if (_thumbVisibility != value) {
      _thumbVisibility = value;
      markNeedsPaint();
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

  void _handleScrollUpdate() {
    markNeedsPaint();
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleScrollUpdate);
    super.dispose();
  }

  @override
  void performLayout() {
    if (child == null) {
      size = constraints.constrain(Size.zero);
      return;
    }

    // Layout child with slightly reduced width to make room for scrollbar
    final childConstraints = BoxConstraints(
      minWidth: math.max(0, constraints.minWidth - thickness),
      maxWidth: math.max(0, constraints.maxWidth - thickness),
      minHeight: constraints.minHeight,
      maxHeight: constraints.maxHeight,
    );

    child!.layout(childConstraints, parentUsesSize: true);

    // Our size includes the scrollbar
    size = constraints.constrain(Size(
      child!.size.width + thickness,
      child!.size.height,
    ));
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    if (child == null) return;

    // Paint the child first
    child!.paint(canvas, offset);

    // Paint scrollbar if we have a controller and should show it
    if (_controller != null && thumbVisibility) {
      _paintScrollbar(canvas, offset);
    }
  }

  void _paintScrollbar(TerminalCanvas canvas, Offset offset) {
    final controller = _controller!;

    // Don't show scrollbar if there's nothing to scroll
    if (controller.maxScrollExtent <= 0) return;

    final scrollbarX = offset.dx + size.width - thickness;
    final scrollbarHeight = size.height;

    // Calculate thumb size and position
    final scrollFraction = controller.viewportDimension / (controller.maxScrollExtent + controller.viewportDimension);
    final thumbHeight = math.max(1.0, scrollbarHeight * scrollFraction);

    final scrollOffset = controller.offset / controller.maxScrollExtent;
    final thumbOffset = scrollOffset * (scrollbarHeight - thumbHeight);

    // Draw scrollbar track
    for (int y = 0; y < scrollbarHeight.toInt(); y++) {
      canvas.drawText(
        offset + Offset(scrollbarX, y.toDouble()),
        '│',
        style: TextStyle(color: Colors.gray),
      );
    }

    // Draw scrollbar thumb
    final thumbStart = thumbOffset.toInt();
    final thumbEnd = math.min(
      (thumbOffset + thumbHeight).toInt(),
      scrollbarHeight.toInt(),
    );

    for (int y = thumbStart; y < thumbEnd; y++) {
      canvas.drawText(
        offset + Offset(scrollbarX, y.toDouble()),
        '█',
        style: TextStyle(color: Colors.brightWhite),
      );
    }

    // Draw arrows at top and bottom
    if (scrollbarHeight >= 3) {
      canvas.drawText(
        offset + Offset(scrollbarX, 0),
        '▲',
        style: TextStyle(
          color: controller.atStart ? Colors.gray : Colors.brightWhite,
        ),
      );

      canvas.drawText(
        offset + Offset(scrollbarX, scrollbarHeight - 1),
        '▼',
        style: TextStyle(
          color: controller.atEnd ? Colors.gray : Colors.brightWhite,
        ),
      );
    }
  }

  // Hit testing removed for now
  // @override
  // bool hitTestChildren(HitTestResult result, {required Offset position}) {
  //   if (child == null) return false;
  //
  //   // Check if the position is in the scrollbar area
  //   if (position.dx >= size.width - thickness) {
  //     // Click is on scrollbar, don't pass to child
  //     return false;
  //   }
  //
  //   return child!.hitTest(result, position: position);
  // }
}
