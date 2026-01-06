import '../framework/framework.dart';
import '../keyboard/mouse_event.dart';
import '../rendering/mouse_region.dart';

/// Signature for mouse event callbacks.
typedef MouseEventCallback = void Function(MouseEvent event);

/// A component that tracks mouse enter, exit, and hover events.
///
/// This component wraps its child and calls the provided callbacks when
/// the mouse enters, exits, or moves within the region.
///
/// Example:
/// ```dart
/// MouseRegion(
///   onEnter: (event) => print('Mouse entered at ${event.x}, ${event.y}'),
///   onExit: (event) => print('Mouse left'),
///   onHover: (event) => print('Mouse moved to ${event.x}, ${event.y}'),
///   child: Container(
///     width: 20,
///     height: 5,
///     child: Text('Hover over me'),
///   ),
/// )
/// ```
class MouseRegion extends SingleChildRenderObjectComponent {
  const MouseRegion({
    super.key,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.opaque = true,
    required super.child,
  });

  /// Called when the mouse enters this region.
  final MouseEventCallback? onEnter;

  /// Called when the mouse exits this region.
  final MouseEventCallback? onExit;

  /// Called when the mouse moves within this region.
  final MouseEventCallback? onHover;

  /// Whether this region should be opaque to hit testing.
  ///
  /// If true, the region will block hit testing from reaching widgets behind it.
  /// If false, hit testing will pass through if the child doesn't handle it.
  final bool opaque;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderMouseRegion(
      onEnter: onEnter,
      onExit: onExit,
      onHover: onHover,
      opaque: opaque,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderMouseRegion renderObject,
  ) {
    renderObject
      ..onEnter = onEnter
      ..onExit = onExit
      ..onHover = onHover
      ..opaque = opaque;
  }
}
