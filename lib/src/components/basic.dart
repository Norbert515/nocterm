import 'package:nocterm/nocterm.dart' hide TextAlign;
import 'package:nocterm/src/framework/terminal_canvas.dart';

import 'render_text.dart';

// Re-export text related enums
export 'render_text.dart' show TextOverflow, TextAlign;
import 'render_flex.dart';

// Export keyboard listener
export 'keyboard_listener.dart' show KeyboardListener;

// Container is now defined in decorated_box.dart with full decoration support
export 'decorated_box.dart'
    show
        Container,
        BoxDecoration,
        BoxBorder,
        BorderSide,
        BoxBorderStyle,
        BorderRadius,
        Radius,
        BoxShape,
        BoxShadow,
        DecorationPosition,
        DecoratedBox,
        BorderTitle,
        TitleAlignment;

/// A run of text with a single style
class Text extends SingleChildRenderObjectComponent {
  const Text(
    this.data, {
    super.key,
    this.style,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textAlign = TextAlign.left,
    this.maxLines,
  });

  final String data;
  final TextStyle? style;
  final bool softWrap;
  final TextOverflow overflow;
  final TextAlign textAlign;
  final int? maxLines;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderText(
      text: data,
      style: style,
      softWrap: softWrap,
      overflow: overflow,
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderText renderObject) {
    renderObject
      ..text = data
      ..style = style
      ..softWrap = softWrap
      ..overflow = overflow
      ..textAlign = textAlign
      ..maxLines = maxLines;
  }
}

/// A box with a specified size
class SizedBox extends SingleChildRenderObjectComponent {
  const SizedBox({super.key, this.width, this.height, super.child});

  final double? width;
  final double? height;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderConstrainedBox(additionalConstraints: _createConstraints());
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderConstrainedBox renderObject,
  ) {
    renderObject.additionalConstraints = _createConstraints();
  }

  BoxConstraints _createConstraints() {
    return BoxConstraints(
      minWidth: width ?? 0.0,
      maxWidth: width ?? double.infinity,
      minHeight: height ?? 0.0,
      maxHeight: height ?? double.infinity,
    );
  }
}

/// Apply padding around a child
class Padding extends SingleChildRenderObjectComponent {
  const Padding({super.key, required this.padding, super.child});

  final EdgeInsets padding;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderPadding(padding: padding);
  }

  @override
  void updateRenderObject(BuildContext context, RenderPadding renderObject) {
    renderObject.padding = padding;
  }
}

/// Align a child within its parent
class Align extends SingleChildRenderObjectComponent {
  const Align({
    super.key,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    super.child,
  });

  final AlignmentGeometry alignment;
  final double? widthFactor;
  final double? heightFactor;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderPositionedBox(
      alignment: alignment,
      widthFactor: widthFactor,
      heightFactor: heightFactor,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderPositionedBox renderObject,
  ) {
    renderObject
      ..alignment = alignment
      ..widthFactor = widthFactor
      ..heightFactor = heightFactor;
  }
}

/// Display children in a horizontal array
class Row extends Flex {
  const Row({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    super.children,
  }) : super(direction: Axis.horizontal);
}

/// Display children in a vertical array
class Column extends Flex {
  const Column({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    super.children,
  }) : super(direction: Axis.vertical);
}

/// Display children in a one-dimensional array
class Flex extends RenderObjectComponent {
  const Flex({
    super.key,
    required this.direction,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.children = const [],
  });

  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final List<Component> children;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderFlex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection ?? TextDirection.ltr,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFlex renderObject) {
    renderObject
      ..direction = direction
      ..mainAxisAlignment = mainAxisAlignment
      ..mainAxisSize = mainAxisSize
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = textDirection ?? TextDirection.ltr
      ..verticalDirection = verticalDirection
      ..textBaseline = textBaseline;
  }

  @override
  MultiChildRenderObjectElement createElement() =>
      MultiChildRenderObjectElement(this);
}

/// Take up remaining space in a flex container
class Expanded extends ParentDataComponent<FlexParentData> {
  Expanded({super.key, int flex = 1, required super.child})
    : super(
        data: FlexParentData(flex: flex, fit: FlexFit.tight),
      );
}

/// Flexible widget for flex containers
class Flexible extends ParentDataComponent<FlexParentData> {
  Flexible({
    super.key,
    int flex = 1,
    FlexFit fit = FlexFit.loose,
    required super.child,
  }) : super(
         data: FlexParentData(flex: flex, fit: fit),
       );
}

/// Proxy component that wraps a single child
abstract class ProxyComponent extends Component {
  const ProxyComponent({super.key, required this.child});

  final Component child;
}

/// Component that applies parent data to its child
class ParentDataComponent<T extends ParentData> extends ProxyComponent {
  const ParentDataComponent({
    super.key,
    required super.child,
    required this.data,
  });

  final T data;

  @override
  Element createElement() => ParentDataElement<T>(this);
}

// BoxDecoration and related classes are now in decorated_box.dart

class LimitedBox extends StatelessComponent {
  const LimitedBox({
    super.key,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
    this.child,
  });

  final double maxWidth;
  final double maxHeight;
  final Component? child;

  @override
  Component build(BuildContext context) {
    // For now, just pass through the child
    // In a full implementation, this would limit the size
    return child ?? const SizedBox();
  }
}

// DecoratedBox is now fully implemented in decorated_box.dart

/// A widget that imposes additional constraints on its child.
///
/// This widget gives its child a set of constraints to adhere to, in addition
/// to the constraints it receives from its parent. The constraints are applied
/// using the [BoxConstraints.enforce] method, which ensures the final constraints
/// respect both the additional constraints and the parent's constraints.
class ConstrainedBox extends SingleChildRenderObjectComponent {
  /// Creates a widget that imposes additional constraints on its child.
  const ConstrainedBox({super.key, required this.constraints, super.child});

  /// The additional constraints to impose on the child.
  final BoxConstraints constraints;

  @override
  RenderConstrainedBox createRenderObject(BuildContext context) {
    return RenderConstrainedBox(additionalConstraints: constraints);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderConstrainedBox renderObject,
  ) {
    renderObject.additionalConstraints = constraints;
  }
}

class Transform extends StatelessComponent {
  const Transform({super.key, required this.transform, this.child});

  final Matrix4 transform;
  final Component? child;

  @override
  Component build(BuildContext context) {
    // For now, just pass through the child
    // In a full implementation, this would apply transform
    return child ?? const SizedBox();
  }
}

class Matrix4 {
  const Matrix4.identity();
}

// Alignment classes are now exported from stack.dart

// Layout enums
enum Axis { horizontal, vertical }

enum MainAxisAlignment {
  start,
  end,
  center,
  spaceBetween,
  spaceAround,
  spaceEvenly,
}

enum MainAxisSize { min, max }

enum CrossAxisAlignment { start, end, center, stretch, baseline }

enum VerticalDirection { up, down }

enum TextBaseline { alphabetic, ideographic }

enum FlexFit { tight, loose }

class FlexParentData extends BoxParentData {
  FlexParentData({this.flex, this.fit});
  final int? flex;
  final FlexFit? fit;

  @override
  String toString() => '${super.toString()}; flex=$flex; fit=$fit';
}

/// RenderObject that constrains its child using additional constraints.
class RenderConstrainedBox extends RenderObject
    with RenderObjectWithChildMixin<RenderObject> {
  RenderConstrainedBox({required BoxConstraints additionalConstraints})
    : _additionalConstraints = additionalConstraints;

  BoxConstraints get additionalConstraints => _additionalConstraints;
  BoxConstraints _additionalConstraints;
  set additionalConstraints(BoxConstraints value) {
    if (_additionalConstraints == value) {
      return;
    }
    _additionalConstraints = value;
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
    if (child != null) {
      // Apply additional constraints using enforce method
      child!.layout(
        _additionalConstraints.enforce(constraints),
        parentUsesSize: true,
      );

      // Position child at origin
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      childParentData.offset = Offset.zero;

      // Our size is the child's size
      size = child!.size;
    } else {
      // If no child, constrain to smallest size allowed by enforced constraints
      size = _additionalConstraints.enforce(constraints).constrain(Size.zero);
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    if (child != null) {
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      child!.paint(canvas, offset + childParentData.offset);
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    if (child != null) {
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      final childPosition = position - childParentData.offset;
      return child!.hitTest(result, position: childPosition);
    }
    return false;
  }
}

class RenderPadding extends RenderObject
    with RenderObjectWithChildMixin<RenderObject> {
  RenderPadding({required this.padding});

  EdgeInsets padding;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    final innerConstraints = constraints.deflate(padding);
    child?.layout(innerConstraints, parentUsesSize: true);

    // Set our size
    final childSize = child?.size ?? Size.zero;
    size = constraints.constrain(
      Size(
        childSize.width + padding.left + padding.right,
        childSize.height + padding.top + padding.bottom,
      ),
    );
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    if (child != null) {
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      childParentData.offset = Offset(padding.left, padding.top);
      child!.paint(canvas, offset + childParentData.offset);
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    if (child != null) {
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      final childPosition = position - childParentData.offset;
      return child!.hitTest(result, position: childPosition);
    }
    return false;
  }
}

class RenderPositionedBox extends RenderObject
    with RenderObjectWithChildMixin<RenderObject> {
  RenderPositionedBox({
    required this.alignment,
    this.widthFactor,
    this.heightFactor,
  });

  AlignmentGeometry alignment;
  double? widthFactor;
  double? heightFactor;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    // Layout child with loosened constraints so it can be smaller
    child?.layout(constraints.loosen(), parentUsesSize: true);

    // Calculate our size based on widthFactor and heightFactor
    // This matches Flutter's RenderPositionedBox behavior
    final double width;
    final double height;

    if (child == null) {
      // No child - size to constraints
      width = constraints.hasBoundedWidth ? constraints.maxWidth : 0.0;
      height = constraints.hasBoundedHeight ? constraints.maxHeight : 0.0;
    } else {
      // With child - use factors to determine size
      if (widthFactor != null || heightFactor != null) {
        // If factors are provided, use child size multiplied by factors
        width = widthFactor == null
            ? child!.size.width
            : widthFactor! * child!.size.width;
        height = heightFactor == null
            ? child!.size.height
            : heightFactor! * child!.size.height;
      } else {
        // No factors - shrinkWrap if constraints are unbounded, expand if bounded
        // This matches Flutter's RenderPositionedBox behavior
        final bool shrinkWrapWidth = constraints.maxWidth == double.infinity;
        final bool shrinkWrapHeight = constraints.maxHeight == double.infinity;
        width = shrinkWrapWidth ? child!.size.width : double.infinity;
        height = shrinkWrapHeight ? child!.size.height : double.infinity;
      }
    }

    size = constraints.constrain(Size(width, height));

    // Calculate and store the child's position in parent data
    if (child != null) {
      final Alignment align = alignment is Alignment
          ? alignment as Alignment
          : Alignment.center;
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      childParentData.offset = align.alongOffset(
        Offset(
          size.width - child!.size.width,
          size.height - child!.size.height,
        ),
      );
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    if (child != null) {
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      child!.paint(canvas, offset + childParentData.offset);
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    if (child != null) {
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      final childPosition = position - childParentData.offset;
      return child!.hitTest(result, position: childPosition);
    }
    return false;
  }
}

/// A widget that centers its child within itself
class Center extends StatelessComponent {
  const Center({
    super.key,
    this.widthFactor,
    this.heightFactor,
    required this.child,
  });

  final double? widthFactor;
  final double? heightFactor;
  final Component child;

  @override
  Component build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      widthFactor: widthFactor,
      heightFactor: heightFactor,
      child: child,
    );
  }
}
