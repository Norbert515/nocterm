import 'package:nocterm/nocterm.dart';
import '../framework/terminal_canvas.dart';

/// Applies a color tint over its child content.
///
/// This widget blends the specified [color] over whatever is rendered beneath
/// it, preserving the underlying text characters while darkening or tinting
/// their colors.
///
/// This is useful for:
/// - Dimming background content when showing dialogs/overlays
/// - Creating colored overlays for visual effects
/// - Highlighting or de-emphasizing regions of the UI
///
/// The tint effect uses alpha blending, so the [color]'s alpha value controls
/// the intensity of the effect:
/// - `alpha = 0`: No effect (fully transparent)
/// - `alpha = 128`: 50% blend
/// - `alpha = 255`: Fully opaque (replaces underlying colors)
///
/// Example:
/// ```dart
/// // Dim the background with 50% black
/// Tint(
///   color: Colors.black.withOpacity(0.5),
///   child: MyBackgroundContent(),
/// )
///
/// // Apply a subtle blue tint
/// Tint(
///   color: Colors.blue.withOpacity(0.2),
///   child: MyContent(),
/// )
/// ```
///
/// For animated tints, use [AnimatedTint] or [FadeTint].
///
/// See also:
///
///  * [ModalBarrier], which uses tinting for dialog backgrounds.
///  * [ColoredBox], which fills an area with a solid color.
class Tint extends SingleChildRenderObjectComponent {
  /// Creates a widget that applies a color tint over its child.
  const Tint({
    super.key,
    required this.color,
    super.child,
  });

  /// The color to blend over the child content.
  ///
  /// Use [Color.withOpacity] or [Color.withAlpha] to control the tint intensity.
  final Color color;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTint(color: color);
  }

  @override
  void updateRenderObject(BuildContext context, RenderTint renderObject) {
    renderObject.color = color;
  }
}

/// A render object that applies a color tint over its child.
class RenderTint extends RenderObject
    with RenderObjectWithChildMixin<RenderObject> {
  RenderTint({required Color color}) : _color = color;

  Color _color;
  Color get color => _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
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
      child!.layout(constraints, parentUsesSize: true);
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      childParentData.offset = Offset.zero;
      size = child!.size;
    } else {
      // Take up available space if no child
      size = constraints.constrain(Size.zero);
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    // First, paint the child
    super.paint(canvas, offset);
    if (child != null) {
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      child!.paint(canvas, offset + childParentData.offset);
    }

    // Then apply the tint on top (only if there's some opacity)
    if (_color.alpha > 0) {
      final rect = Rect.fromLTWH(
        offset.dx,
        offset.dy,
        size.width,
        size.height,
      );
      canvas.applyTint(rect, _color);
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

/// An animated version of [Tint] that smoothly transitions its color.
///
/// This is useful for creating fade-in/fade-out tint effects.
///
/// Example:
/// ```dart
/// AnimatedTint(
///   color: _animation.drive(
///     ColorTween(
///       begin: Colors.transparent,
///       end: Colors.black.withOpacity(0.5),
///     ),
///   ),
///   child: MyContent(),
/// )
/// ```
class AnimatedTint extends AnimatedComponent {
  /// Creates an animated tint widget.
  const AnimatedTint({
    super.key,
    required Animation<Color?> color,
    this.child,
  }) : super(listenable: color);

  /// The animated color of the tint.
  Animation<Color?> get color => listenable as Animation<Color?>;

  /// The child widget to tint.
  final Component? child;

  @override
  Component build(BuildContext context) {
    final currentColor = color.value;
    if (currentColor == null || currentColor.alpha == 0) {
      return child ?? const SizedBox.shrink();
    }
    return Tint(
      color: currentColor,
      child: child,
    );
  }
}

/// A convenience widget that fades a tint in when created.
///
/// This combines [AnimatedTint] with an [AnimationController] for easy use.
///
/// Example:
/// ```dart
/// // Fade in a 50% black tint over 200ms
/// FadeTint(
///   color: Colors.black.withOpacity(0.5),
///   child: MyContent(),
/// )
/// ```
class FadeTint extends StatefulComponent {
  /// Creates a fade tint widget.
  const FadeTint({
    super.key,
    required this.color,
    this.duration = const Duration(milliseconds: 200),
    this.child,
  });

  /// The target color when fully faded in.
  final Color color;

  /// The duration of the fade animation.
  final Duration duration;

  /// The child widget to tint.
  final Component? child;

  @override
  State<FadeTint> createState() => _FadeTintState();
}

class _FadeTintState extends State<FadeTint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: component.duration,
      vsync: this,
    );

    _setupAnimation();
    _controller.forward();
  }

  void _setupAnimation() {
    final transparentColor = component.color.withAlpha(0);

    _colorAnimation = ColorTween(
      begin: transparentColor,
      end: component.color,
    ).animate(_controller);
  }

  @override
  void didUpdateComponent(FadeTint oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.color != oldComponent.color ||
        component.duration != oldComponent.duration) {
      _controller.duration = component.duration;
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return AnimatedTint(
      color: _colorAnimation,
      child: component.child,
    );
  }
}

/// A widget that prevents the user from interacting with widgets behind itself.
///
/// The modal barrier is the scrim that is rendered behind each overlay entry,
/// which generally prevents the user from interacting with the content below.
///
/// For example, when a dialog is on the screen, the page below the dialog is
/// usually darkened by the modal barrier.
///
/// Set [obscure] to true to completely hide the content behind the barrier
/// (fills with spaces). When false, the barrier will only tint the colors of
/// the underlying content, preserving the text characters.
///
/// See also:
///
///  * [AnimatedModalBarrier], which animates the barrier color for smooth
///    fade-in/fade-out effects.
class ModalBarrier extends StatelessComponent {
  /// Creates a widget that blocks user interaction.
  const ModalBarrier({
    super.key,
    this.color,
    this.dismissible = true,
    this.onDismiss,
    this.obscure = true,
  });

  /// If non-null, fill the barrier with this color.
  ///
  /// A typical value is `Colors.black.withOpacity(0.5)` for a 50% black scrim.
  /// Using colors with alpha < 255 will show the content behind dimmed (if [obscure] is false).
  final Color? color;

  /// Whether tapping/clicking the barrier will dismiss it.
  ///
  /// If true and [onDismiss] is non-null, [onDismiss] will be called.
  ///
  /// If false, tapping on the barrier will do nothing.
  final bool dismissible;

  /// Called when the barrier is dismissed.
  ///
  /// If non-null and [dismissible] is true, this will be called when the
  /// user taps on the barrier.
  final VoidCallback? onDismiss;

  /// When true (default), fills the barrier area with spaces, completely hiding
  /// any content underneath.
  ///
  /// When false, semi-transparent colors will only tint the underlying content
  /// without erasing the text characters.
  final bool obscure;

  @override
  Component build(BuildContext context) {
    // Use a GestureDetector if dismissible, otherwise just the colored box
    Component barrier = SizedBox.expand(
      child: color != null
          ? ColoredBox(color: color!, obscure: obscure)
          : const SizedBox.shrink(),
    );

    if (dismissible && onDismiss != null) {
      barrier = GestureDetector(
        onTap: onDismiss,
        behavior: HitTestBehavior.opaque,
        child: barrier,
      );
    }

    return barrier;
  }
}

/// A widget that fills its parent with a solid color.
///
/// This is a simple render object that paints a solid color over its entire
/// area, supporting alpha blending for semi-transparent effects.
///
/// Set [obscure] to true to fill with spaces, completely hiding any content
/// underneath. When false (default), semi-transparent colors will tint the
/// underlying content without erasing the text.
class ColoredBox extends SingleChildRenderObjectComponent {
  /// Creates a widget that paints its area with the specified [color].
  const ColoredBox({
    super.key,
    required this.color,
    this.foregroundColor,
    this.obscure = false,
    super.child,
  });

  /// The background color to paint.
  final Color color;

  /// Optional foreground color to set on filled cells.
  ///
  /// When non-null, cells filled by this box will have this as their
  /// explicit foreground color. Child text widgets that don't specify
  /// their own color will inherit it.
  final Color? foregroundColor;

  /// When true, fills the area with spaces to completely hide underlying content.
  /// When false (default), semi-transparent colors only tint the underlying content.
  final bool obscure;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderColoredBox(
      color: color,
      foregroundColor: foregroundColor,
      obscure: obscure,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderColoredBox renderObject) {
    renderObject
      ..color = color
      ..foregroundColor = foregroundColor
      ..obscure = obscure;
  }
}

/// A render object that paints a solid color.
class RenderColoredBox extends RenderObject
    with RenderObjectWithChildMixin<RenderObject> {
  RenderColoredBox({
    required Color color,
    Color? foregroundColor,
    bool obscure = false,
  })  : _color = color,
        _foregroundColor = foregroundColor,
        _obscure = obscure;

  Color _color;
  Color get color => _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  Color? _foregroundColor;
  Color? get foregroundColor => _foregroundColor;
  set foregroundColor(Color? value) {
    if (_foregroundColor == value) return;
    _foregroundColor = value;
    markNeedsPaint();
  }

  /// When true, fills the area with spaces (blocking underlying content).
  /// When false (default), semi-transparent colors only tint the underlying content.
  bool _obscure;
  bool get obscure => _obscure;
  set obscure(bool value) {
    if (_obscure == value) return;
    _obscure = value;
    markNeedsPaint();
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
      child!.layout(constraints, parentUsesSize: true);
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      childParentData.offset = Offset.zero;
      size = child!.size;
    } else {
      // Fill parent if no child - use the max constrained size
      size = Size(
        constraints.maxWidth.isFinite ? constraints.maxWidth : 80,
        constraints.maxHeight.isFinite ? constraints.maxHeight : 24,
      );
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    final rect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      size.width,
      size.height,
    );

    // If obscure is true or color is fully opaque, fill with spaces to hide content
    // Otherwise, use applyTint to preserve underlying content (just change colors)
    if (_obscure || _color.alpha >= 255) {
      // Obscure mode or fully opaque: fill with spaces and the background color
      // This completely hides any underlying text
      canvas.fillRect(
        rect,
        ' ',
        style: TextStyle(
          color: _foregroundColor,
          backgroundColor: _color,
        ),
      );
    } else {
      // Semi-transparent without obscure: apply as a tint overlay, preserving characters
      canvas.applyTint(rect, _color);
    }

    // Paint child on top
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

/// An animated version of [ModalBarrier] that smoothly transitions its color.
///
/// This is useful for creating fade-in/fade-out effects when showing or
/// hiding overlays and dialogs.
///
/// Example usage:
/// ```dart
/// AnimatedModalBarrier(
///   color: _animation.drive(
///     ColorTween(
///       begin: Colors.transparent,
///       end: Colors.black.withOpacity(0.5),
///     ),
///   ),
///   dismissible: true,
///   onDismiss: () => _hideOverlay(),
/// )
/// ```
class AnimatedModalBarrier extends AnimatedComponent {
  /// Creates a widget that blocks user interaction with an animated color.
  const AnimatedModalBarrier({
    super.key,
    required Animation<Color?> color,
    this.dismissible = true,
    this.onDismiss,
    this.obscure = true,
  }) : super(listenable: color);

  /// The animated color of the barrier.
  Animation<Color?> get color => listenable as Animation<Color?>;

  /// Whether tapping/clicking the barrier will dismiss it.
  final bool dismissible;

  /// Called when the barrier is dismissed.
  final VoidCallback? onDismiss;

  /// When true (default), completely hides content behind the barrier.
  final bool obscure;

  @override
  Component build(BuildContext context) {
    return ModalBarrier(
      color: color.value,
      dismissible: dismissible,
      onDismiss: onDismiss,
      obscure: obscure,
    );
  }
}

/// A widget that provides a standard modal barrier with animation support.
///
/// This is a convenience widget that combines [AnimatedModalBarrier] with
/// an [AnimationController] for easy use in dialogs and overlays.
///
/// The barrier will fade in when shown and fade out when dismissed.
class FadeModalBarrier extends StatefulComponent {
  /// Creates a fade modal barrier.
  const FadeModalBarrier({
    super.key,
    this.color,
    this.dismissible = true,
    this.onDismiss,
    this.duration = const Duration(milliseconds: 200),
    this.obscure = true,
  });

  /// The target color of the barrier when fully visible.
  ///
  /// Defaults to a semi-transparent black if not specified.
  final Color? color;

  /// Whether tapping/clicking the barrier will dismiss it.
  final bool dismissible;

  /// Called when the barrier is dismissed.
  final VoidCallback? onDismiss;

  /// The duration of the fade animation.
  final Duration duration;

  /// When true (default), completely hides content behind the barrier.
  final bool obscure;

  @override
  State<FadeModalBarrier> createState() => _FadeModalBarrierState();
}

class _FadeModalBarrierState extends State<FadeModalBarrier>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: component.duration,
      vsync: this,
    );

    _setupAnimation();
    _controller.forward();
  }

  void _setupAnimation() {
    final targetColor = component.color ?? Colors.black.withOpacity(0.5);
    final transparentColor = targetColor.withAlpha(0);

    _colorAnimation = ColorTween(
      begin: transparentColor,
      end: targetColor,
    ).animate(_controller);
  }

  @override
  void didUpdateComponent(FadeModalBarrier oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.color != oldComponent.color ||
        component.duration != oldComponent.duration) {
      _controller.duration = component.duration;
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return AnimatedModalBarrier(
      color: _colorAnimation,
      dismissible: component.dismissible,
      onDismiss: component.onDismiss,
      obscure: component.obscure,
    );
  }
}
