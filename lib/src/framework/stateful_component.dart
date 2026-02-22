part of 'framework.dart';

/// A component that has mutable state.
abstract class StatefulComponent extends Component {
  const StatefulComponent({super.key});

  @override
  StatefulElement createElement() => StatefulElement(this);

  /// Creates the mutable state for this component.
  @protected
  State createState();
}

/// The logic and internal state for a [StatefulComponent].
abstract class State<T extends StatefulComponent> {
  T get component => _component!;
  T? _component;

  BuildContext get context => _element!;
  StatefulElement? _element;

  bool get mounted => _element != null;

  /// Initialize state. Called once when the State object is created.
  @protected
  void initState() {}

  /// Called whenever the component configuration changes.
  @protected
  void didUpdateComponent(covariant T oldComponent) {}

  /// Called when dependencies of this object change.
  @protected
  void didChangeDependencies() {}

  /// Called when this State is temporarily removed from the tree.
  ///
  /// The framework calls this method when this [State] object is removed from
  /// the tree temporarily. It may be reinserted into another part of the tree
  /// (e.g., if the subtree containing this [State] object is grafted from one
  /// location to another due to the use of a [GlobalKey]).
  ///
  /// If the State is reinserted into the tree, [activate] will be called.
  /// Otherwise, [dispose] will be called.
  ///
  /// Subclasses should override this method to release any resources that will
  /// be reallocated if the State is reactivated (via [activate]).
  @protected
  void deactivate() {}

  /// Called when this State is reinserted into the tree after being removed
  /// via [deactivate].
  ///
  /// In most cases, after a [State] object has been deactivated, it is not
  /// reinserted into the tree, and its [dispose] method will be called.
  ///
  /// In some cases, however, after a [State] object has been deactivated, the
  /// framework will reinsert it into another part of the tree (e.g., if the
  /// subtree containing this [State] object is grafted from one location in
  /// the tree to another due to the use of a [GlobalKey]). If that happens,
  /// the framework will call [activate] to give the [State] object a chance to
  /// reacquire any resources that it released in [deactivate].
  @protected
  void activate() {}

  /// Clean up resources. Called when the State object is removed permanently.
  @protected
  void dispose() {}

  /// Called whenever the application is reassembled during debugging, for
  /// example during hot reload.
  ///
  /// This provides an opportunity to reinitialize any data that was computed
  /// in the initState method or to reset any state.
  @protected
  @mustCallSuper
  void reassemble() {}

  /// Describes the part of the user interface represented by this component.
  @protected
  Component build(BuildContext context);

  /// Notify the framework that the internal state has changed.
  @protected
  void setState(VoidCallback fn) {
    assert(_element != null);
    assert(_element!._lifecycleState == _ElementLifecycle.active,
        'Element is not active but ${_element!._lifecycleState} instead');

    fn();
    _element!.markNeedsBuild();
  }
}

/// Element for StatefulComponent
class StatefulElement extends BuildableElement {
  StatefulElement(super.component) {
    _state = component.createState();
    assert(_state._element == null, 'State object was already used');
    _state._element = this;
    assert(_state._component == null, 'State object was already initialized');
    _state._component = component;
  }

  @override
  StatefulComponent get component => super.component as StatefulComponent;

  late final State _state;
  State get state => _state;

  @override
  Component build() => _state.build(this);

  @override
  void _firstBuild() {
    final Object? debugCheckForReturnedFuture = state.initState() as dynamic;
    assert(() {
      if (debugCheckForReturnedFuture is Future) {
        throw FlutterError([
          '${state.runtimeType}.initState() returned a Future.',
          'State.initState() must be a void method without an `async` keyword.',
          'Rather than awaiting on asynchronous work directly inside of initState, '
              'call a separate method to do this work without awaiting it.',
        ].join('\n'));
      }
      return true;
    }());

    state.didChangeDependencies();
    super._firstBuild();
  }

  @override
  void update(Component newComponent) {
    super.update(newComponent);
    assert(component == newComponent);
    final StatefulComponent oldComponent = _state._component!;
    _state._component = component;
    final Object? debugCheckForReturnedFuture =
        _state.didUpdateComponent(oldComponent) as dynamic;
    assert(() {
      if (debugCheckForReturnedFuture is Future) {
        throw FlutterError(
            '${_state.runtimeType}.didUpdateComponent() returned a Future.');
      }
      return true;
    }());
    rebuild();
  }

  @override
  void activate() {
    super.activate();
    _state.activate();
    // Since the State could have observed the deactivate() and thus disposed of
    // resources allocated in the build method, we have to rebuild the widget
    // so that its State can reallocate its resources.
    markNeedsBuild();
  }

  @override
  void deactivate() {
    _state.deactivate();
    super.deactivate();
  }

  @override
  void unmount() {
    super.unmount();
    _state.dispose();
    _state._element = null;
    // Release resources to reduce the severity of memory leaks caused by
    // defunct, but accidentally retained Elements.
    _state._component = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state.didChangeDependencies();
  }

  @override
  void reassemble() {
    _state.reassemble();
    super.reassemble();
  }
}

/// Error thrown by the framework
class FlutterError extends Error {
  FlutterError(this.message);
  final String message;
  @override
  String toString() => message;
}
