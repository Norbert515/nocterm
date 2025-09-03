part of 'framework.dart';

/// The glue between the component layer and the terminal rendering layer
abstract class NoctermBinding {
  static NoctermBinding? _instance;
  static NoctermBinding get instance => _instance!;

  NoctermBinding() {
    assert(_instance == null, 'Only one TuiBinding instance allowed');
    _instance = this;
  }

  /// Clear the singleton instance - only for testing
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  BuildOwner? _buildOwner;
  BuildOwner get buildOwner => _buildOwner ??= createBuildOwner();

  Element? _rootElement;
  Element? get rootElement => _rootElement;

  @protected
  BuildOwner createBuildOwner() {
    return BuildOwner(onNeedsBuild);
  }

  void attachRootComponent(Component rootComponent) {
    if (_rootElement != null) {
      _rootElement!.deactivate();
      _rootElement!.unmount();
    }
    _rootElement = rootComponent.createElement();
    // Set the owner before mounting (root has no parent to inherit from)
    _rootElement!._owner = buildOwner;
    _rootElement!.mount(null, null);
  }

  void scheduleFrame() {
    // Schedule frame to be drawn asynchronously
    // This allows batching of updates
    scheduleMicrotask(() => drawFrame());
  }

  void onNeedsBuild() {
    scheduleFrame();
  }

  void drawFrame() {
    buildOwner.buildScope(rootElement!, () {
      // Layout phase would go here
      // Paint phase would go here
    });
    buildOwner.finalizeTree();
  }

  /// Cause the entire subtree rooted at the root element to be entirely
  /// rebuilt. This is used by development tools when the application code has
  /// changed and is being hot-reloaded, to cause the component tree to pick up any
  /// changed implementations.
  ///
  /// This is expensive and should not be called except during development.
  void reassemble() {
    if (rootElement != null) {
      rootElement!.reassemble();
    }
  }

  /// Called to actually cause the application to reassemble, e.g. after a hot reload.
  ///
  /// This method is called by the hot reload mechanism to trigger a full rebuild
  /// of the component tree with the new code.
  @protected
  @mustCallSuper
  Future<void> performReassemble() async {
    reassemble();
    scheduleFrame();
    return Future<void>.value();
  }
}

/// InheritedComponent provides a way to pass data down the component tree
abstract class InheritedComponent extends Component {
  const InheritedComponent({super.key, required this.child});

  final Component child;

  @override
  InheritedElement createElement() => InheritedElement(this);

  /// Whether the framework should notify components that inherit from this component.
  @protected
  bool updateShouldNotify(covariant InheritedComponent oldComponent);
}

/// Element for InheritedComponent
class InheritedElement extends BuildableElement {
  InheritedElement(InheritedComponent super.component);

  @override
  InheritedComponent get component => super.component as InheritedComponent;

  final Map<Element, Object?> _dependents = HashMap<Element, Object?>();

  @override
  void mount(Element? parent, dynamic newSlot) {
    _updateInheritance();
    super.mount(parent, newSlot);
  }

  @override
  void update(Component newComponent) {
    final InheritedComponent oldComponent = component;
    super.update(newComponent);
    if (component.updateShouldNotify(oldComponent)) {
      notifyClients();
    }
  }

  void _updateInheritance() {
    final Map<Type, InheritedElement>? parentInheritedElements = parent?._inheritedElements;
    if (parentInheritedElements != null) {
      _inheritedElements = HashMap<Type, InheritedElement>.from(parentInheritedElements);
    } else {
      _inheritedElements = HashMap<Type, InheritedElement>();
    }
    _inheritedElements![component.runtimeType] = this;
  }

  @override
  void activate() {
    super.activate();
    _updateInheritance();
  }

  void updateDependencies(Element dependent, Object? aspect) {
    _dependents[dependent] = aspect;
  }

  void notifyClients() {
    for (final Element dependent in _dependents.keys) {
      notifyDependent(dependent);
    }
  }

  void notifyDependent(Element dependent) {
    dependent.didChangeDependencies();
  }

  @override
  Component build() => component.child;
}
