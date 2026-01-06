part of 'framework.dart';

/// A signature for the builder function used by [LayoutBuilder].
typedef LayoutBuilderCallback =
    Component Function(BuildContext context, BoxConstraints constraints);

/// A component that defers building its child until layout time.
///
/// This allows the builder function to access the actual constraints
/// that will be used for layout, enabling responsive designs.
///
/// The builder function is called during the layout phase, not during the
/// build phase. This means that the constraints passed to the builder are
/// the actual constraints that will be used to lay out the child.
///
/// Example:
/// ```dart
/// LayoutBuilder(
///   builder: (context, constraints) {
///     if (constraints.maxWidth > 80) {
///       return WideLayout();
///     } else {
///       return NarrowLayout();
///     }
///   },
/// )
/// ```
class LayoutBuilder extends RenderObjectComponent {
  /// Creates a component that defers building until layout time.
  const LayoutBuilder({super.key, required this.builder});

  /// Builder function called during layout with the actual constraints.
  final LayoutBuilderCallback builder;

  @override
  LayoutBuilderElement createElement() => LayoutBuilderElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderLayoutBuilder();

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderLayoutBuilder renderObject,
  ) {
    // Nothing to update on the render object itself
  }
}

/// Element for [LayoutBuilder] that manages building the child during layout.
class LayoutBuilderElement extends RenderObjectElement {
  /// Creates an element for a [LayoutBuilder].
  LayoutBuilderElement(LayoutBuilder super.component);

  @override
  LayoutBuilder get component => super.component as LayoutBuilder;

  @override
  RenderLayoutBuilder get renderObject =>
      super.renderObject as RenderLayoutBuilder;

  Element? _child;
  BoxConstraints? _previousConstraints;
  bool _needsBuild = true;

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    renderObject.updateLayoutCallback(_layoutCallback);
  }

  @override
  void update(Component newComponent) {
    super.update(newComponent);
    // Mark that we need to rebuild with the new builder function
    _needsBuild = true;
    renderObject.markNeedsLayout();
  }

  @override
  void performRebuild() {
    // Don't do a normal rebuild - we rebuild during layout
    _dirty = false;
    // Mark layout as needed so our _layoutCallback gets called
    renderObject.markNeedsLayout();
  }

  @override
  void markNeedsBuild() {
    _needsBuild = true;
    super.markNeedsBuild();
  }

  void _layoutCallback(BoxConstraints constraints) {
    // Only rebuild if constraints changed or we explicitly need a build
    if (_previousConstraints != constraints || _needsBuild) {
      _previousConstraints = constraints;
      _needsBuild = false;

      // Use owner to invoke the build
      owner!.buildScope(this, () {
        Component? builtComponent;
        try {
          builtComponent = component.builder(this, constraints);
        } catch (e, stackTrace) {
          // On error, create an error display component
          builtComponent = ErrorComponent(error: e, stackTrace: stackTrace);
        }
        _child = updateChild(_child, builtComponent, null);
      });
    }
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) {
      visitor(_child!);
    }
  }

  @override
  void forgetChild(Element child) {
    assert(child == _child);
    _child = null;
    super.forgetChild(child);
  }

  @override
  void insertRenderObjectChild(RenderObject child, dynamic slot) {
    renderObject.child = child;
  }

  @override
  void moveRenderObjectChild(
    RenderObject child,
    dynamic oldSlot,
    dynamic newSlot,
  ) {
    // SingleChild never moves - slot is always null
    assert(false, 'LayoutBuilderElement should never move children');
  }

  @override
  void removeRenderObjectChild(RenderObject child, dynamic slot) {
    assert(slot == null);
    assert(renderObject.child == child);
    renderObject.child = null;
  }
}

/// Render object for [LayoutBuilder] that calls back during layout.
class RenderLayoutBuilder extends RenderObject
    with RenderObjectWithChildMixin<RenderObject> {
  /// Callback to rebuild child during layout.
  void Function(BoxConstraints constraints)? _layoutCallback;

  /// Updates the layout callback used to build children.
  void updateLayoutCallback(
    void Function(BoxConstraints constraints)? callback,
  ) {
    _layoutCallback = callback;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    // Wrap the layout callback in invokeLayoutCallback to properly handle
    // widget tree mutations during layout. This ensures newly created render
    // objects are properly merged into the layout pipeline.
    if (_layoutCallback != null) {
      invokeLayoutCallback<BoxConstraints>((constraints) {
        _layoutCallback!.call(constraints);
      });
    }

    if (child != null) {
      child!.layout(constraints, parentUsesSize: true);
      final childParentData = child!.parentData as BoxParentData;
      childParentData.offset = Offset.zero;
      size = constraints.constrain(child!.size);
    } else {
      size = Size(constraints.minWidth, constraints.minHeight);
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
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      final childPosition = position - childParentData.offset;
      return child!.hitTest(result, position: childPosition);
    }
    return false;
  }
}
