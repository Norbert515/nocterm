import 'package:nocterm/nocterm.dart';

import "package:nocterm/src/framework/terminal_canvas.dart";

enum BoxFit {
  contain,
  cover,
  fill,
  fitWidth,
  fitHeight,
  none,
  scaleDown,
}

class FittedBox extends SingleChildRenderObjectComponent {
  const FittedBox({
    super.key,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    super.child,
  });

  final BoxFit fit;
  final Alignment alignment;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderFittedBox(
      fit: fit,
      alignment: alignment,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFittedBox renderObject) {
    renderObject
      ..fit = fit
      ..alignment = alignment;
  }
}

class RenderFittedBox extends RenderObject
    with RenderObjectWithChildMixin<RenderObject> {
  RenderFittedBox({required BoxFit fit, required Alignment alignment});
  BoxFit fit = BoxFit.contain;
  Alignment alignment = Alignment.center;

  @override
  void performLayout() {
    if (child == null) {
      size = constraints.constrain(Size.zero);
      return;
    }

    // Layout child with unbounded constraints to determine its intrinsic size
    child!.layout(const BoxConstraints(), parentUsesSize: true);
    final childSize = child!.size;

    // Calculate the aspect ratio of the child and the available space
    final double childAspectRatio = childSize.width / childSize.height;
    final double availableWidth = constraints.maxWidth;
    final double availableHeight = constraints.maxHeight;
    final double availableAspectRatio = availableWidth / availableHeight;

    // Determine the fitted size based on the BoxFit
    late Size fittedSize;

    switch (fit) {
      case BoxFit.contain:
        if (childAspectRatio > availableAspectRatio) {
          // Child is wider than the available space, fit to width
          fittedSize = Size(availableWidth, availableWidth / childAspectRatio);
        } else {
          // Child is taller than the available space, fit to height
          fittedSize =
              Size(availableHeight * childAspectRatio, availableHeight);
        }
        break;
      case BoxFit.cover:
        if (childAspectRatio > availableAspectRatio) {
          // Child is wider than the available space, fit to height
          fittedSize =
              Size(availableHeight * childAspectRatio, availableHeight);
        } else {
          // Child is taller than the available space, fit to width
          fittedSize = Size(availableWidth, availableWidth / childAspectRatio);
        }
        break;
      case BoxFit.fill:
        fittedSize = Size(availableWidth, availableHeight);
        break;
      case BoxFit.fitWidth:
        fittedSize = Size(availableWidth, availableWidth / childAspectRatio);
        break;
      case BoxFit.fitHeight:
        fittedSize = Size(availableHeight * childAspectRatio, availableHeight);
        break;
      case BoxFit.none:
        fittedSize = childSize;
        break;
      case BoxFit.scaleDown:
        if (childSize.width <= availableWidth &&
            childSize.height <= availableHeight) {
          fittedSize = childSize;
        } else {
          if (childAspectRatio > availableAspectRatio) {
            fittedSize =
                Size(availableWidth, availableWidth / childAspectRatio);
          } else {
            fittedSize =
                Size(availableHeight * childAspectRatio, availableHeight);
          }
        }
        break;
    }

    // Constrain the fitted size and set the render object size
    size = constraints.constrain(fittedSize);

    // Calculate the alignment offset
    final double xOffset = alignment.x * (size.width - childSize.width) / 2;
    final double yOffset = alignment.y * (size.height - childSize.height) / 2;

    // Set the child's parent data offset
    final BoxParentData childParentData = child!.parentData as BoxParentData;
    childParentData.offset = Offset(xOffset, yOffset);
  }

  @override
  void paint(TerminalCanvas context, Offset offset) {
    super.paint(context, offset);
    if (child == null) {
      return;
    }

    // Create a clip rect
    final clipRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Get a new canvas that is clipped to the rect
    final clippedCanvas = context.clip(clipRect);

    // Paint the child
    child!.paintWithContext(clippedCanvas, offset);
  }
}
