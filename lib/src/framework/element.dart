part of 'framework.dart';

enum _ElementLifecycle {
  initial,
  active,
  inactive,
  defunct,
}

/// Represents a node in the component tree
abstract class Element implements BuildContext {
  Element(this._component);

  Component _component;
  Component get component => _component;

  Element? _parent;
  @override
  Element? get parent => _parent;

  _ElementLifecycle _lifecycleState = _ElementLifecycle.initial;

  dynamic _slot;
  dynamic get slot => _slot;

  int _depth = 0;
  int get depth => _depth;

  bool _dirty = true;
  bool get dirty => _dirty;

  bool _inDirtyList = false;

  BuildOwner? _owner;
  BuildOwner? get owner => _owner;

  @override
  NoctermBinding get binding => NoctermBinding.instance;

  void mount(Element? parent, dynamic newSlot) {
    assert(_lifecycleState == _ElementLifecycle.initial);
    assert(parent == null || parent._lifecycleState == _ElementLifecycle.active);
    _parent = parent;
    _slot = newSlot;
    _depth = parent != null ? parent.depth + 1 : 1;
    _lifecycleState = _ElementLifecycle.active;
    if (parent != null) {
      _owner = parent.owner;
    }
    final Key? key = component.key;
    if (key is GlobalKey) {
      owner!._registerGlobalKey(key, this);
    }
  }

  void update(Component newComponent) {
    assert(_lifecycleState == _ElementLifecycle.active);
    assert(Component.canUpdate(component, newComponent));
    _component = newComponent;
  }

  void updateSlot(dynamic newSlot) {
    assert(_lifecycleState == _ElementLifecycle.active);
    assert(parent != null);
    assert(parent!._lifecycleState == _ElementLifecycle.active);
    _slot = newSlot;
  }

  void detachRenderObject() {
    visitChildren((Element child) {
      child.detachRenderObject();
    });
  }

  void attachRenderObject(dynamic newSlot) {}

  void unmount() {
    assert(_lifecycleState == _ElementLifecycle.inactive);
    final Key? key = component.key;
    if (key is GlobalKey) {
      owner!._unregisterGlobalKey(key, this);
    }
    _lifecycleState = _ElementLifecycle.defunct;
  }

  @protected
  Element? updateChild(Element? child, Component? newComponent, dynamic newSlot) {
    if (newComponent == null) {
      if (child != null) {
        deactivateChild(child);
      }
      return null;
    }

    final Element newChild;
    if (child != null) {
      bool hasSameSuperclass = true;

      if (hasSameSuperclass && Component.canUpdate(child.component, newComponent)) {
        child.update(newComponent);
        newChild = child;
      } else {
        deactivateChild(child);
        newChild = inflateComponent(newComponent, newSlot);
      }
    } else {
      newChild = inflateComponent(newComponent, newSlot);
    }

    return newChild;
  }

  @protected
  Element inflateComponent(Component newComponent, dynamic newSlot) {
    final Element newChild = newComponent.createElement();
    newChild.mount(this, newSlot);
    return newChild;
  }

  @protected
  void deactivateChild(Element child) {
    assert(child._parent == this);
    child._parent = null;
    child.detachRenderObject();
    owner!._inactiveElements.add(child);
  }

  void activate() {
    assert(_lifecycleState == _ElementLifecycle.inactive);
    assert(parent != null);
    assert(parent!._lifecycleState == _ElementLifecycle.active);
    assert(depth > 0);
    _lifecycleState = _ElementLifecycle.active;
    visitChildren((Element child) {
      child.activate();
    });
  }

  void deactivate() {
    assert(_lifecycleState == _ElementLifecycle.active);
    // Remove parent assertion - parent can be null when called from _InactiveElements
    _lifecycleState = _ElementLifecycle.inactive;
  }

  void markNeedsBuild() {
    assert(_lifecycleState == _ElementLifecycle.active);
    if (_dirty) {
      return;
    }
    _dirty = true;
    owner!.scheduleBuildFor(this);
  }

  void rebuild() {
    assert(_lifecycleState == _ElementLifecycle.active);
    performRebuild();
  }

  @protected
  void performRebuild();

  void visitChildren(ElementVisitor visitor);

  void visitChildElements(ElementVisitor visitor) {
    visitChildren(visitor);
  }

  @protected
  List<Element> updateChildren(List<Element> oldChildren, List<Component> newComponents) {
    Element? replaceWithNullIfForgotten(Element child) {
      return _owner!._forgottenChildren.contains(child) ? null : child;
    }

    int newChildrenTop = 0;
    int oldChildrenTop = 0;
    int newChildrenBottom = newComponents.length - 1;
    int oldChildrenBottom = oldChildren.length - 1;

    final List<Element?> newChildren = List<Element?>.filled(newComponents.length, null);

    Element? previousChild;

    // Update the top of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final Element? oldChild = replaceWithNullIfForgotten(oldChildren[oldChildrenTop]);
      final Component newComponent = newComponents[newChildrenTop];
      assert(oldChild == null || oldChild._lifecycleState == _ElementLifecycle.active);
      if (oldChild == null || !Component.canUpdate(oldChild.component, newComponent)) {
        break;
      }
      final Element newChild = updateChild(oldChild, newComponent, previousChild)!;
      assert(newChild._lifecycleState == _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    // Scan the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final Element? oldChild = replaceWithNullIfForgotten(oldChildren[oldChildrenBottom]);
      final Component newComponent = newComponents[newChildrenBottom];
      assert(oldChild == null || oldChild._lifecycleState == _ElementLifecycle.active);
      if (oldChild == null || !Component.canUpdate(oldChild.component, newComponent)) {
        break;
      }
      oldChildrenBottom -= 1;
      newChildrenBottom -= 1;
    }

    // Scan the old children in the middle of the list.
    final bool haveOldChildren = oldChildrenTop <= oldChildrenBottom;
    Map<Key, Element>? oldKeyedChildren;
    if (haveOldChildren) {
      oldKeyedChildren = <Key, Element>{};
      while (oldChildrenTop <= oldChildrenBottom) {
        final Element? oldChild = replaceWithNullIfForgotten(oldChildren[oldChildrenTop]);
        assert(oldChild == null || oldChild._lifecycleState == _ElementLifecycle.active);
        if (oldChild != null) {
          if (oldChild.component.key != null) {
            oldKeyedChildren[oldChild.component.key!] = oldChild;
          } else {
            deactivateChild(oldChild);
          }
        }
        oldChildrenTop += 1;
      }
    }

    // Update the middle of the list.
    while (newChildrenTop <= newChildrenBottom) {
      Element? oldChild;
      final Component newComponent = newComponents[newChildrenTop];
      if (newComponent.key != null) {
        final Key key = newComponent.key!;
        if (oldKeyedChildren != null) {
          oldChild = oldKeyedChildren[key];
          if (oldChild != null) {
            if (Component.canUpdate(oldChild.component, newComponent)) {
              oldKeyedChildren.remove(key);
            } else {
              oldChild = null;
            }
          }
        }
      }
      assert(oldChild == null || Component.canUpdate(oldChild.component, newComponent));
      final Element newChild = updateChild(oldChild, newComponent, previousChild)!;
      assert(newChild._lifecycleState == _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
    }

    // We've scanned the whole list.
    assert(oldChildrenTop == oldChildrenBottom + 1);
    assert(newChildrenTop == newChildrenBottom + 1);
    assert(newComponents.length - newChildrenTop == oldChildren.length - oldChildrenTop);
    newChildrenBottom = newComponents.length - 1;
    oldChildrenBottom = oldChildren.length - 1;

    // Update the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final Element oldChild = oldChildren[oldChildrenTop];
      assert(replaceWithNullIfForgotten(oldChild) != null);
      assert(oldChild._lifecycleState == _ElementLifecycle.active);
      final Component newComponent = newComponents[newChildrenTop];
      assert(Component.canUpdate(oldChild.component, newComponent));
      final Element newChild = updateChild(oldChild, newComponent, previousChild)!;
      assert(newChild._lifecycleState == _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    // Clean up any of the remaining middle nodes from the old list.
    if (oldKeyedChildren != null && oldKeyedChildren.isNotEmpty) {
      for (final Element oldChild in oldKeyedChildren.values) {
        if (replaceWithNullIfForgotten(oldChild) != null) {
          deactivateChild(oldChild);
        }
      }
    }

    assert(newChildren.every((Element? element) => element != null));
    return newChildren.cast<Element>();
  }

  void forgetChild(Element child) {
    assert(child._parent == this);
    _owner?._forgottenChildren.add(child);
  }

  @override
  T? dependOnInheritedComponentOfExactType<T extends InheritedComponent>({Object? aspect}) {
    final InheritedElement? ancestor = _inheritedElements?[T];
    if (ancestor != null) {
      return dependOnInheritedElement(ancestor, aspect: aspect) as T;
    }
    return null;
  }

  @override
  InheritedComponent dependOnInheritedElement(InheritedElement ancestor, {Object? aspect}) {
    _dependencies ??= HashSet<InheritedElement>();
    _dependencies!.add(ancestor);
    ancestor.updateDependencies(this, aspect);
    return ancestor.component;
  }

  Map<Type, InheritedElement>? _inheritedElements;
  Set<InheritedElement>? _dependencies;

  void didChangeDependencies() {
    markNeedsBuild();
  }

  bool get debugDoingBuild => false;

  @override
  T? findAncestorComponentOfExactType<T extends Component>() {
    Element? ancestor = parent;
    while (ancestor != null && ancestor.component.runtimeType != T) {
      ancestor = ancestor.parent;
    }
    return ancestor?.component as T?;
  }

  @override
  T? findAncestorStateOfType<T extends State>() {
    Element? ancestor = parent;
    while (ancestor != null) {
      if (ancestor is StatefulElement && ancestor.state is T) {
        return ancestor.state as T;
      }
      ancestor = ancestor.parent;
    }
    return null;
  }

  @override
  T? findAncestorRenderObjectOfType<T extends RenderObject>() {
    Element? ancestor = parent;
    while (ancestor != null) {
      if (ancestor is RenderObjectElement && ancestor.renderObject is T) {
        return ancestor.renderObject as T;
      }
      ancestor = ancestor.parent;
    }
    return null;
  }

  @override
  BoxConstraints get constraints {
    final renderObject = findAncestorRenderObjectOfType<RenderObject>();
    return renderObject?.constraints ?? const BoxConstraints();
  }

  /// Called whenever the application is reassembled during debugging, for
  /// example during hot reload.
  ///
  /// This method should rerun any initialization logic that depends on global
  /// state. The method will mark this element as needing to be rebuilt and
  /// then recursively call reassemble on all child elements.
  @protected
  @mustCallSuper
  void reassemble() {
    markNeedsBuild();
    visitChildren((Element child) {
      child.reassemble();
    });
  }
}
