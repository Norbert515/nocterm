part of 'framework.dart';

/// Base class for Elements that wrap a single child.
///
/// This class provides proper lifecycle management for elements that have
/// exactly one child, ensuring render objects are correctly attached and
/// detached when the element tree changes.
abstract class ProxyElement extends Element {
  ProxyElement(super.component);

  @override
  ProxyComponent get component => super.component as ProxyComponent;

  Element? _child;

  /// The element's unique child, if it has one.
  Element? get child => _child;

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    // Pass through the slot so child render objects get inserted at the correct position
    _child = updateChild(null, component.child, slot);
  }

  @override
  void update(Component newComponent) {
    super.update(newComponent);
    assert(component == newComponent);
    // Pass through the slot so child render objects get inserted at the correct position
    _child = updateChild(_child, (newComponent as ProxyComponent).child, slot);
    updated(component);
  }

  @override
  void performRebuild() {
    if (_child != null) {
      _child!.performRebuild();
    }
  }

  /// Called after the widget has been updated.
  /// Subclasses can override this to perform actions after the child has been updated.
  @protected
  void updated(ProxyComponent oldComponent) {
    notifyClients(oldComponent);
  }

  /// Notify other objects that the widget associated with this element has changed.
  @protected
  void notifyClients(ProxyComponent oldComponent);

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

  void insertRenderObjectChild(RenderObject child, dynamic slot) {
    final RenderObjectElement? renderObjectElement =
        _findAncestorRenderObjectElement();
    renderObjectElement?.insertRenderObjectChild(child, slot);
  }

  void moveRenderObjectChild(
    RenderObject child,
    dynamic oldSlot,
    dynamic newSlot,
  ) {
    final RenderObjectElement? renderObjectElement =
        _findAncestorRenderObjectElement();
    renderObjectElement?.moveRenderObjectChild(child, oldSlot, newSlot);
  }

  void removeRenderObjectChild(RenderObject child, dynamic slot) {
    final RenderObjectElement? renderObjectElement =
        _findAncestorRenderObjectElement();
    renderObjectElement?.removeRenderObjectChild(child, slot);
  }

  RenderObjectElement? _findAncestorRenderObjectElement() {
    Element? ancestor = parent;
    while (ancestor != null && ancestor is! RenderObjectElement) {
      ancestor = ancestor.parent;
    }
    return ancestor as RenderObjectElement?;
  }
}

/// An Element that uses a ParentDataWidget as its configuration.
///
/// This properly manages the lifecycle of its child and ensures parent data
/// is correctly applied to render objects.
class ParentDataElement<T extends ParentData> extends ProxyElement {
  ParentDataElement(super.component);

  @override
  ParentDataComponent<T> get component =>
      super.component as ParentDataComponent<T>;

  void _applyParentData(ParentDataComponent<T> component) {
    void applyParentDataToChild(Element child) {
      if (child is RenderObjectElement) {
        // Apply parent data to the render object
        child.renderObject.parentData = component.data;
      } else {
        // Recursively apply to children if this isn't a render object element
        child.visitChildren(applyParentDataToChild);
      }
    }

    if (_child != null) {
      applyParentDataToChild(_child!);
    }
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _applyParentData(component);
  }

  @override
  void attachRenderObject(dynamic newSlot) {
    super.attachRenderObject(newSlot);
    _applyParentData(component);
  }

  @override
  void notifyClients(ProxyComponent oldComponent) {
    _applyParentData(component);
  }
}
