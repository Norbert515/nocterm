import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';

import 'render_text.dart';
import 'render_flex.dart';

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
        DecoratedBox;

/// A run of text with a single style
class Text extends SingleChildRenderObjectComponent {
  const Text(
    this.data, {
    super.key,
    this.style,
  });

  final String data;
  final TextStyle? style;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderText(text: data, style: style);
  }

  @override
  void updateRenderObject(BuildContext context, RenderText renderObject) {
    renderObject
      ..text = data
      ..style = style;
  }
}

/// A box with a specified size
class SizedBox extends SingleChildRenderObjectComponent {
  const SizedBox({
    super.key,
    this.width,
    this.height,
    super.child,
  });

  final double? width;
  final double? height;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderConstrainedBox(
      additionalConstraints: _createConstraints(),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderConstrainedBox renderObject) {
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
  const Padding({
    super.key,
    required this.padding,
    super.child,
  });

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
    this.child,
  });

  final AlignmentGeometry alignment;
  final Component? child;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderPositionedBox(
      alignment: alignment,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPositionedBox renderObject) {
    renderObject.alignment = alignment;
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
  MultiChildRenderObjectElement createElement() => MultiChildRenderObjectElement(this);
}

/// Take up remaining space in a flex container
class Expanded extends ParentDataComponent<FlexParentData> {
  Expanded({
    super.key,
    int flex = 1,
    required Component child,
  }) : super(child: child, data: FlexParentData(flex: flex, fit: FlexFit.tight));
}

/// Flexible widget for flex containers
class Flexible extends ParentDataComponent<FlexParentData> {
  Flexible({
    super.key,
    int flex = 1,
    FlexFit fit = FlexFit.loose,
    required Component child,
  }) : super(child: child, data: FlexParentData(flex: flex, fit: fit));
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
  ParentDataElement<T> createElement() => ParentDataElement<T>(this);
}

/// Proxy component that wraps a single child
abstract class ProxyComponent extends Component {
  const ProxyComponent({super.key, required this.child});

  final Component child;
}

/// Element that manages parent data for its child
class ParentDataElement<T extends ParentData> extends Element {
  ParentDataElement(ParentDataComponent<T> component) : super(component);

  @override
  ParentDataComponent<T> get component => super.component as ParentDataComponent<T>;

  Element? _child;

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _child = updateChild(null, component.child, null);
    _updateParentData();
  }

  @override
  void update(Component newComponent) {
    super.update(newComponent);
    assert(component == newComponent);
    _child = updateChild(_child, (newComponent as ParentDataComponent<T>).child, null);
  }

  void _updateParentData() {
    // Apply parent data to the child's render object
    void applyParentData(Element element) {
      if (element is RenderObjectElement) {
        // Don't override existing parent data, just set it if it's null
        // The parent's setupParentData will be called to ensure correct type
        element.renderObject.parentData = component.data;
      } else {
        element.visitChildren(applyParentData);
      }
    }

    if (_child != null) {
      applyParentData(_child!);
    }
  }

  @override
  void performRebuild() {
    if (_child != null) {
      _child!.performRebuild();
    }
    _updateParentData();
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) {
      visitor(_child!);
    }
  }

  @override
  void detachRenderObject() {
    // Nothing to do
  }

  @override
  void attachRenderObject(dynamic newSlot) {
    // Nothing to do
  }
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

class ConstrainedBox extends StatelessComponent {
  const ConstrainedBox({
    super.key,
    required this.constraints,
    this.child,
  });

  final BoxConstraints constraints;
  final Component? child;

  @override
  Component build(BuildContext context) {
    // For now, just pass through the child
    // In a full implementation, this would apply constraints
    return child ?? const SizedBox();
  }
}

class Transform extends StatelessComponent {
  const Transform({
    super.key,
    required this.transform,
    this.child,
  });

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

// Alignment classes
abstract class AlignmentGeometry {
  const AlignmentGeometry();
}

class Alignment extends AlignmentGeometry {
  const Alignment(this.x, this.y);

  final double x;
  final double y;

  static const Alignment topLeft = Alignment(-1.0, -1.0);
  static const Alignment topCenter = Alignment(0.0, -1.0);
  static const Alignment topRight = Alignment(1.0, -1.0);
  static const Alignment centerLeft = Alignment(-1.0, 0.0);
  static const Alignment center = Alignment(0.0, 0.0);
  static const Alignment centerRight = Alignment(1.0, 0.0);
  static const Alignment bottomLeft = Alignment(-1.0, 1.0);
  static const Alignment bottomCenter = Alignment(0.0, 1.0);
  static const Alignment bottomRight = Alignment(1.0, 1.0);

  /// Returns the offset that is this fraction within the given size.
  Offset alongOffset(Offset other) {
    final double centerX = other.dx / 2.0;
    final double centerY = other.dy / 2.0;
    return Offset(centerX + x * centerX, centerY + y * centerY);
  }
}

// Layout enums
enum Axis { horizontal, vertical }

enum MainAxisAlignment { start, end, center, spaceBetween, spaceAround, spaceEvenly }

enum MainAxisSize { min, max }

enum CrossAxisAlignment { start, end, center, stretch, baseline }

enum TextDirection { ltr, rtl }

enum VerticalDirection { up, down }

enum TextBaseline { alphabetic, ideographic }

enum FlexFit { tight, loose }

class FlexParentData extends BoxParentData {
  FlexParentData({
    this.flex,
    this.fit,
  });
  final int? flex;
  final FlexFit? fit;

  @override
  String toString() => '${super.toString()}; flex=$flex; fit=$fit';
}

// Placeholder render objects - we'll implement these next
class RenderConstrainedBox extends RenderObject with RenderObjectWithChildMixin<RenderObject> {
  RenderConstrainedBox({required this.additionalConstraints});

  BoxConstraints additionalConstraints;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  BoxConstraints _combine(BoxConstraints a, BoxConstraints b) {
    return BoxConstraints(
      minWidth: a.minWidth.clamp(b.minWidth, b.maxWidth),
      maxWidth: a.maxWidth.clamp(b.minWidth, b.maxWidth),
      minHeight: a.minHeight.clamp(b.minHeight, b.maxHeight),
      maxHeight: a.maxHeight.clamp(b.minHeight, b.maxHeight),
    );
  }

  @override
  void performLayout() {
    if (child != null) {
      // Combine the incoming constraints with additional constraints
      final combinedConstraints = _combine(additionalConstraints, constraints);
      child!.layout(combinedConstraints, parentUsesSize: true);

      // Position child at origin
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      childParentData.offset = Offset.zero;

      // Set our size to child's size
      size = constraints.constrain(child!.size);
    } else {
      // If no child, try to be as small as possible while respecting additional constraints
      size = _combine(additionalConstraints, constraints).constrain(Size.zero);
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
}

class RenderPadding extends RenderObject with RenderObjectWithChildMixin<RenderObject> {
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
    size = constraints.constrain(Size(
      childSize.width + padding.left + padding.right,
      childSize.height + padding.top + padding.bottom,
    ));
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
}

class RenderPositionedBox extends RenderObject with RenderObjectWithChildMixin<RenderObject> {
  RenderPositionedBox({
    required this.alignment,
  });

  AlignmentGeometry alignment;

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

    // Calculate our size first
    final double width = constraints.hasBoundedWidth ? constraints.maxWidth : child?.size.width ?? 0.0;
    final double height = constraints.hasBoundedHeight ? constraints.maxHeight : child?.size.height ?? 0.0;
    size = constraints.constrain(Size(width, height));

    // Calculate and store the child's position in parent data
    if (child != null) {
      final Alignment align = alignment is Alignment ? alignment as Alignment : Alignment.center;
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      childParentData.offset =
          align.alongOffset(Offset(size.width - child!.size.width, size.height - child!.size.height));
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
}

/// A widget that centers its child within itself
class Center extends StatelessComponent {
  const Center({
    super.key,
    required this.child,
  });

  final Component child;

  @override
  Component build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: child,
    );
  }
}
