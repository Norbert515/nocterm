import 'binding/terminal_binding.dart';

/// Safely shut down the nocterm application with proper terminal cleanup.
///
/// This function ensures that all terminal state (cursor visibility, mouse tracking,
/// alternate screen) is properly restored before the application exits.
///
/// ## Why use this instead of dart:io's exit()?
///
/// Calling `dart:io`'s `exit()` directly will immediately terminate the process
/// without running cleanup code. This can leave the terminal in a broken state where:
/// - Mouse movements produce visible escape sequences
/// - The cursor remains hidden
/// - The alternate screen buffer is not restored
///
/// ## Usage
///
/// ```dart
/// import 'package:nocterm/nocterm.dart';
///
/// Focusable(
///   onKeyEvent: (event) {
///     if (event.logicalKey == LogicalKey.keyQ) {
///       shutdownApp(); // Safe exit with cleanup
///       return true;
///     }
///     return false;
///   },
///   // ...
/// )
/// ```
///
/// ## Parameters
///
/// - [exitCode]: The exit code to return to the shell (default: 0)
///
void shutdownApp([int exitCode = 0]) {
  TerminalBinding.instance.requestShutdown(exitCode);
}
