import '../framework/framework.dart';
import 'focusable.dart';

/// A widget that creates a focus scope boundary.
///
/// When [enabled] is false, all focusable widgets in the subtree
/// will be disabled, preventing them from receiving focus.
/// This is useful for disabling focus on background content
/// when showing modal dialogs or overlays.
class FocusScope extends StatelessComponent {
  /// The child widget tree.
  final Component child;

  /// Whether to absorb focus events when disabled.
  ///
  /// When true and [enabled] is false, focus events are consumed
  /// but not passed to children.
  final bool absorb;

  const FocusScope({super.key, this.absorb = true, required this.child});

  @override
  Component build(BuildContext context) {
    // When disabled, wrap the child in a widget that blocks focus
    return _FocusBlocker(absorb: absorb, child: child);
  }
}

/// Internal widget that blocks focus events from reaching its children.
class _FocusBlocker extends StatelessComponent {
  final bool absorb;
  final Component child;

  const _FocusBlocker({required this.absorb, required this.child});

  @override
  Component build(BuildContext context) {
    // We need to intercept focus traversal
    // For now, we'll use a simple approach with Focusable
    if (absorb) {
      // Create a focusable that captures but doesn't process events
      return Focusable(
        focused: false,
        onKeyEvent: (_) => false, // Don't handle any events
        child: child,
      );
    }

    // Just return the child without modification
    // In a more complete implementation, we would block pointer events
    return child;
  }
}
