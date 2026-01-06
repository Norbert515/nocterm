import '../framework/framework.dart';

/// A widget that blocks keyboard events from reaching its children.
///
/// This widget is explicitly handled by the terminal binding to stop
/// keyboard event propagation to child widgets. It's useful for preventing
/// background content from receiving keyboard input when modal dialogs
/// or overlays are shown.
class BlockFocus extends StatelessComponent {
  /// Whether to block keyboard events.
  ///
  /// When true, keyboard events will not reach child widgets.
  final bool blocking;

  /// The child widget tree.
  final Component child;

  const BlockFocus({super.key, this.blocking = true, required this.child});

  @override
  Component build(BuildContext context) {
    // We don't modify the tree structure, just mark this element
    // for special handling in the terminal binding
    return child;
  }

  @override
  StatelessElement createElement() => BlockFocusElement(this);
}

/// Element for BlockFocus that can be detected by the terminal binding.
class BlockFocusElement extends StatelessElement {
  BlockFocusElement(BlockFocus super.component);

  @override
  BlockFocus get component => super.component as BlockFocus;

  /// Whether this element is currently blocking focus.
  bool get isBlocking => component.blocking;
}
