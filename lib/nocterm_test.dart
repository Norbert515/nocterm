/// Testing utilities for TUI applications.
///
/// Provides a Flutter-like testing framework for terminal user interfaces.
library tui_test;

export 'src/test/nocterm_tester.dart' show NoctermTester, TuiTestCallback, testNocterm;
export 'src/test/terminal_state.dart' show TerminalState, TextMatch, StyledText;
export 'src/test/matchers.dart' show containsText, hasTextAt, hasStyledText, matchesSnapshot, isEmpty, isNotEmpty;

// Re-export commonly used types
export 'src/keyboard/keyboard_event.dart' show KeyboardEvent, ModifierKeys;
export 'src/keyboard/logical_key.dart' show LogicalKey;
