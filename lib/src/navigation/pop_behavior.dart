import 'package:nocterm/nocterm_test.dart';

import 'route.dart';

/// Configuration for how the navigator handles pop requests
class PopBehavior {
  /// Whether the Escape key triggers pop
  final bool escapeEnabled;

  /// Whether the Backspace key triggers pop
  final bool backspaceEnabled;

  /// Custom key that triggers pop (e.g., 'q' for quit)
  final String? customPopKey;

  /// Custom logic to determine if a route can be popped
  /// Return false to prevent popping
  final bool Function(Route route)? canPop;

  /// Whether to show a confirmation dialog before popping
  /// Useful for forms with unsaved changes
  final Future<bool> Function(Route route)? onPopInvoked;

  const PopBehavior({
    this.escapeEnabled = true,
    this.backspaceEnabled = false,
    this.customPopKey,
    this.canPop,
    this.onPopInvoked,
  });

  /// Default pop behavior with Escape enabled
  static const PopBehavior defaultBehavior = PopBehavior();

  /// Strict pop behavior that prevents accidental navigation
  static const PopBehavior strict = PopBehavior(
    escapeEnabled: false,
    backspaceEnabled: false,
  );

  /// Check if the given key should trigger a pop
  bool shouldPop(LogicalKey key) {
    if (key == LogicalKey.escape && escapeEnabled) return true;
    if (key == LogicalKey.backspace && backspaceEnabled) return true;
    if (customPopKey != null && key.debugName == customPopKey) return true;
    return false;
  }
}
