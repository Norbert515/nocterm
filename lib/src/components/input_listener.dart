import '../framework/framework.dart';

/// A callback that receives raw stdin bytes before nocterm's input
/// parser processes them.
///
/// Return `true` to consume the bytes (nocterm skips parsing for
/// this batch). Return `false` to let nocterm handle them normally.
typedef RawInputHandler = bool Function(List<int> bytes);

/// A component that intercepts raw stdin bytes before they reach
/// nocterm's [InputParser].
///
/// Unlike [Focusable], which receives parsed keyboard events,
/// [InputListener] operates on the raw byte stream. The two
/// widgets serve different purposes:
/// - Use [Focusable] when you need semantic key events (arrow up,
///   Ctrl+C, printable characters).
/// - Use [InputListener] when you need byte-for-byte passthrough.
///
/// Example:
/// ```dart
/// InputListener(
///   onInput: (bytes) {
///     return true; // return true to consume (don't parse), false for
///                  // normal processing with nocterm's input parser.
///   },
///   child: Text('This widget can intercept raw input bytes.'),
/// )
/// ```
class InputListener extends StatelessComponent {
  const InputListener({
    super.key,
    required this.onInput,
    required this.child,
  });

  /// Callback invoked with raw stdin bytes.
  ///
  /// Return `true` to consume the bytes (nocterm will not parse
  /// them into keyboard/mouse events). Return `false` to let
  /// nocterm process them normally.
  final RawInputHandler onInput;

  /// The child component to wrap.
  final Component child;

  @override
  InputListenerElement createElement() => InputListenerElement(this);

  @override
  Component build(BuildContext context) => child;
}

/// Element for [InputListener].
///
/// The binding recognises this element type during raw input
/// dispatch, just as it recognises [FocusableElement] during
/// keyboard event dispatch.
class InputListenerElement extends StatelessElement {
  InputListenerElement(InputListener super.component);

  @override
  InputListener get component => super.component as InputListener;

  /// Forward raw bytes to the widget's callback.
  bool handleRawInput(List<int> bytes) {
    return component.onInput(bytes);
  }
}
