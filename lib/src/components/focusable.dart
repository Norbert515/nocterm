import '../framework/framework.dart';
import '../keyboard/keyboard_event.dart';

/// A callback that handles keyboard events with character data.
/// Returns true if the event was handled, false otherwise.
typedef KeyEventHandler = bool Function(KeyboardEvent event);

/// A component that can receive keyboard focus and handle keyboard events.
///
/// This component wraps its child and, when focused, receives keyboard events
/// from the framework. Events that are not handled (onKeyEvent returns false) will
/// bubble up to parent Focusable components.
///
/// Example:
/// ```dart
/// Focusable(
///   focused: hasFocus,
///   onKeyEvent: (event) {
///     if (event.logicalKey == LogicalKey.enter) {
///       // Handle enter key
///       return true;
///     }
///     if (event.character != null) {
///       // Handle character input
///       insertText(event.character!);
///       return true;
///     }
///     return false; // Let unhandled keys bubble up
///   },
///   child: Container(child: Text('Press Enter')),
/// )
/// ```
class Focusable extends StatelessComponent {
  const Focusable({
    super.key,
    required this.focused,
    required this.onKeyEvent,
    required this.child,
  });

  /// Whether this component currently has focus.
  final bool focused;

  /// Callback to handle keyboard events with character data.
  /// Should return true if the event was handled, false otherwise.
  final KeyEventHandler onKeyEvent;

  /// The child component to wrap.
  final Component child;

  @override
  FocusableElement createElement() => FocusableElement(this);

  @override
  Component build(BuildContext context) => child;
}

/// Element for the Focusable component.
class FocusableElement extends StatelessElement {
  FocusableElement(Focusable super.component);

  @override
  Focusable get component => super.component as Focusable;

  /// Handle a keyboard event if this element is focused.
  bool handleKeyEvent(KeyboardEvent event) {
    if (!component.focused) {
      return false;
    }
    return component.onKeyEvent(event);
  }
}
