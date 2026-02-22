part of 'framework.dart';

/// Base class for Elements that wrap a single child.
///
/// Unlike [StatelessElement] and [StatefulElement], proxy elements do not
/// call [build] during updates. Instead, they directly update their child
/// via [updateChild] in [update], and provide the [updated] hook for
/// subclasses to react to component changes.
///
/// This mirrors Flutter's `ProxyElement` which extends `ComponentElement`.
abstract class ProxyElement extends BuildableElement {
  ProxyElement(super.component);

  @override
  ProxyComponent get component => super.component as ProxyComponent;

  @override
  Component build() => component.child;

  @override
  void update(Component newComponent) {
    final oldComponent = component;
    super.update(newComponent);
    assert(component == newComponent);
    // Pass through the slot so child render objects get inserted at the correct position
    _child = updateChild(_child, component.child, slot);
    updated(oldComponent);
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

  void insertRenderObjectChild(RenderObject child, dynamic slot) {
    final RenderObjectElement? renderObjectElement =
        _findAncestorRenderObjectElement();
    renderObjectElement?.insertRenderObjectChild(child, slot);
  }

  void moveRenderObjectChild(
      RenderObject child, dynamic oldSlot, dynamic newSlot) {
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
        final renderObject = child.renderObject;
        final existingData = renderObject.parentData;
        final newData = component.data;

        // If the existing parent data is a subtype that extends the new data's type,
        // copy properties instead of replacing. This handles cases like
        // TheaterParentData (extends StackParentData) where we want to
        // preserve the subtype but copy positioning values from StackParentData.
        if (existingData != null && existingData is T) {
          // Check if existingData is a subtype of StackParentData and newData is StackParentData
          // If so, copy the positioning properties instead of replacing
          if (existingData.runtimeType != newData.runtimeType &&
              _copyStackParentDataIfApplicable(existingData, newData)) {
            // Properties were copied, don't replace
            return;
          }
        }

        // Default: Apply parent data to the render object
        renderObject.parentData = newData;
      } else {
        // Recursively apply to children if this isn't a render object element
        child.visitChildren(applyParentDataToChild);
      }
    }

    if (_child != null) {
      applyParentDataToChild(_child!);
    }
  }

  /// Attempts to copy StackParentData properties from source to target.
  /// Returns true if the copy was performed, false otherwise.
  bool _copyStackParentDataIfApplicable(ParentData target, ParentData source) {
    // Import the StackParentData type check dynamically
    // We check if both are StackParentData-like by checking for the positioning properties
    try {
      final targetDynamic = target as dynamic;
      final sourceDynamic = source as dynamic;

      // Check if source has the StackParentData properties
      if (sourceDynamic.left != null ||
          sourceDynamic.top != null ||
          sourceDynamic.right != null ||
          sourceDynamic.bottom != null ||
          sourceDynamic.width != null ||
          sourceDynamic.height != null) {
        // Copy the positioning properties
        targetDynamic.left = sourceDynamic.left;
        targetDynamic.top = sourceDynamic.top;
        targetDynamic.right = sourceDynamic.right;
        targetDynamic.bottom = sourceDynamic.bottom;
        targetDynamic.width = sourceDynamic.width;
        targetDynamic.height = sourceDynamic.height;
        return true;
      }
    } catch (_) {
      // If dynamic access fails, fall back to replacing
    }
    return false;
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
