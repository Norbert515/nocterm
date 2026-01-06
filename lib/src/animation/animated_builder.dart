import 'package:nocterm/src/framework/framework.dart';
import 'package:nocterm/src/framework/listenable.dart';

/// Signature for the builder callback used by [AnimatedBuilder].
typedef AnimatedComponentBuilder =
    Component Function(BuildContext context, Component? child);

/// A general-purpose component for building animations.
///
/// [AnimatedBuilder] is useful for simple animations where you need to rebuild
/// a component whenever an animation changes. It listens to the [animation]
/// and rebuilds the subtree whenever the animation's value changes.
///
/// For more complex animations, consider using [AnimatedWidget] (if available)
/// or creating a custom [StatefulComponent] with a [State] that uses a
/// [TickerProviderStateMixin].
///
/// The [child] parameter is optional. If provided, it will be passed to the
/// [builder] callback. This is an optimization: if part of the widget subtree
/// does not depend on the animation, you can pass it as [child] to avoid
/// rebuilding that part on every animation frame.
///
/// ## Example
///
/// ```dart
/// AnimatedBuilder(
///   animation: _controller,
///   builder: (BuildContext context, Component? child) {
///     return Transform.rotate(
///       angle: _controller.value * 2.0 * math.pi,
///       child: child,
///     );
///   },
///   child: Container(
///     width: 200.0,
///     height: 200.0,
///     child: Text('Whee!'),
///   ),
/// )
/// ```
///
/// In this example, the [Text] widget would be passed to the [builder] as
/// [child], and would not be rebuilt on every animation frame.
class AnimatedBuilder extends StatefulComponent {
  /// Creates an animated builder.
  ///
  /// The [animation] and [builder] arguments are required.
  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  /// The [Listenable] to which this component is listening.
  ///
  /// Commonly an [Animation] or a [ChangeNotifier].
  final Listenable animation;

  /// Called every time the animation changes value.
  ///
  /// The child given to the builder should typically be part of the returned
  /// component tree, and should typically be constructed once and passed
  /// to the [AnimatedBuilder] as a child rather than constructed in the
  /// builder callback.
  final AnimatedComponentBuilder builder;

  /// The child component to pass to the [builder].
  ///
  /// If a builder callback's return value contains a subtree that does not
  /// depend on the animation, it's more efficient to build that subtree once
  /// instead of rebuilding it on every animation tick.
  ///
  /// If the pre-built subtree is passed as the [child] parameter, the
  /// [AnimatedBuilder] will pass it back to the [builder] function so that it
  /// can be incorporated into the build.
  ///
  /// Using this pre-built child is entirely optional, but can improve
  /// performance significantly in some cases and is therefore a good practice.
  final Component? child;

  @override
  State<AnimatedBuilder> createState() => _AnimatedBuilderState();
}

class _AnimatedBuilderState extends State<AnimatedBuilder> {
  @override
  void initState() {
    super.initState();
    component.animation.addListener(_handleChange);
  }

  @override
  void didUpdateComponent(AnimatedBuilder oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.animation != oldComponent.animation) {
      oldComponent.animation.removeListener(_handleChange);
      component.animation.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    component.animation.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    setState(() {
      // The animation changed, rebuild.
    });
  }

  @override
  Component build(BuildContext context) {
    return component.builder(context, component.child);
  }
}

/// A component that rebuilds when a [Listenable] notifies its listeners.
///
/// [ListenableBuilder] is similar to [AnimatedBuilder], but is designed to
/// work with any [Listenable], not just animations. It's useful when you need
/// to rebuild a component in response to notifications from a [ChangeNotifier]
/// or similar object.
///
/// ## Example
///
/// ```dart
/// ListenableBuilder(
///   listenable: myChangeNotifier,
///   builder: (BuildContext context, Component? child) {
///     return Text('Current value: ${myChangeNotifier.value}');
///   },
/// )
/// ```
class ListenableBuilder extends StatefulComponent {
  /// Creates a listenable builder.
  ///
  /// The [listenable] and [builder] arguments are required.
  const ListenableBuilder({
    super.key,
    required this.listenable,
    required this.builder,
    this.child,
  });

  /// The [Listenable] to which this component is listening.
  final Listenable listenable;

  /// Called every time the listenable notifies its listeners.
  final AnimatedComponentBuilder builder;

  /// The child component to pass to the [builder].
  final Component? child;

  @override
  State<ListenableBuilder> createState() => _ListenableBuilderState();
}

class _ListenableBuilderState extends State<ListenableBuilder> {
  @override
  void initState() {
    super.initState();
    component.listenable.addListener(_handleChange);
  }

  @override
  void didUpdateComponent(ListenableBuilder oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.listenable != oldComponent.listenable) {
      oldComponent.listenable.removeListener(_handleChange);
      component.listenable.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    component.listenable.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    setState(() {
      // The listenable changed, rebuild.
    });
  }

  @override
  Component build(BuildContext context) {
    return component.builder(context, component.child);
  }
}
