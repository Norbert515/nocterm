import 'dart:convert';
import 'dart:io';
import '../binding/terminal_binding.dart';

/// Clipboard utility for terminal applications using OSC 52 control sequences.
///
/// OSC 52 is a terminal escape sequence that allows applications to interact
/// with the system clipboard. It's supported by many modern terminals including
/// iTerm2, Terminal.app (with proper configuration), tmux, and screen.
///
/// The sequence format is: ESC ] 52 ; <target> ; <data> ST
/// where:
/// - ESC ] is the OSC (Operating System Command) introducer
/// - 52 is the clipboard manipulation command
/// - <target> is the clipboard selection (c for clipboard, p for primary)
/// - <data> is the base64-encoded text to set, or '?' to query
/// - ST is the String Terminator (ESC \ or BEL)
///
/// Example usage:
/// ```dart
/// // Copy text to clipboard
/// Clipboard.copy('Hello, World!');
///
/// // Copy text to primary selection (X11)
/// Clipboard.copyToPrimary('Selected text');
/// ```
class Clipboard {
  // Control sequence components
  static const String _osc = '\x1b]'; // OSC - Operating System Command
  static const String _st = '\x1b\\'; // ST - String Terminator (ESC \)
  static const String _bel = '\x07'; // BEL - Alternative terminator

  /// The clipboard selection target
  static const String _clipboardTarget = 'c'; // System clipboard
  static const String _primaryTarget = 'p'; // Primary selection (X11)

  /// Copy text to the system clipboard using OSC 52.
  ///
  /// This sends an OSC 52 control sequence to the terminal, which instructs
  /// it to copy the provided text to the system clipboard.
  ///
  /// Parameters:
  /// - [text]: The text to copy to the clipboard
  /// - [useStringTerminator]: If true, uses ESC\ as terminator (default).
  ///   If false, uses BEL (0x07). Some terminals prefer one over the other.
  ///
  /// Returns true if the sequence was written successfully.
  static bool copy(String text, {bool useStringTerminator = true}) {
    return _copyToTarget(text, _clipboardTarget, useStringTerminator: useStringTerminator);
  }

  /// Copy text to the primary selection (X11 systems).
  ///
  /// The primary selection is a Unix/X11 concept where selected text
  /// is automatically copied and can be pasted with middle-click.
  ///
  /// Parameters:
  /// - [text]: The text to copy to the primary selection
  /// - [useStringTerminator]: If true, uses ESC\ as terminator (default).
  ///   If false, uses BEL (0x07).
  ///
  /// Returns true if the sequence was written successfully.
  static bool copyToPrimary(String text, {bool useStringTerminator = true}) {
    return _copyToTarget(text, _primaryTarget, useStringTerminator: useStringTerminator);
  }

  /// Internal method to copy text to a specific target (clipboard or primary).
  static bool _copyToTarget(String text, String target, {required bool useStringTerminator}) {
    try {
      // Encode the text in base64
      final base64Text = base64Encode(utf8.encode(text));

      // Build the OSC 52 sequence
      // Format: ESC ] 52 ; <target> ; <base64-data> ST
      final terminator = useStringTerminator ? _st : _bel;
      final sequence = '$_osc 52;$target;$base64Text$terminator';

      // Write directly to stdout
      stdout.write(sequence);
      stdout.flush();

      return true;
    } catch (e) {
      // If stdout is not available or writing fails, return false
      return false;
    }
  }

  /// Clear the clipboard using OSC 52.
  ///
  /// This sends an OSC 52 sequence with an empty payload, which some
  /// terminals interpret as a clipboard clear operation.
  ///
  /// Returns true if the sequence was written successfully.
  static bool clear({bool useStringTerminator = true}) {
    try {
      final terminator = useStringTerminator ? _st : _bel;
      final sequence = '$_osc 52;$_clipboardTarget;$terminator';

      stdout.write(sequence);
      stdout.flush();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if OSC 52 clipboard support is likely available.
  ///
  /// This performs a heuristic check based on environment variables
  /// and terminal type. Note that this doesn't guarantee OSC 52 will work,
  /// as it depends on terminal configuration and capabilities.
  ///
  /// Returns true if OSC 52 is likely supported.
  static bool isSupported() {
    // Check if we have a terminal
    if (!stdout.hasTerminal) {
      return false;
    }

    // Check common environment variables
    final term = Platform.environment['TERM'] ?? '';
    final termProgram = Platform.environment['TERM_PROGRAM'] ?? '';
    final tmux = Platform.environment['TMUX'];
    final sshConnection = Platform.environment['SSH_CONNECTION'];

    // Known terminals with good OSC 52 support
    if (termProgram == 'iTerm.app' ||
        termProgram == 'Apple_Terminal' ||
        termProgram == 'WezTerm' ||
        termProgram == 'Alacritty') {
      return true;
    }

    // tmux and screen support OSC 52 (with proper configuration)
    if (tmux != null || term.contains('tmux') || term.contains('screen')) {
      return true;
    }

    // xterm-like terminals usually support it
    if (term.contains('xterm') || term.contains('256color')) {
      return true;
    }

    // If we're in an SSH session, OSC 52 might work
    // depending on the local terminal
    if (sshConnection != null) {
      return true;
    }

    // Default to true for modern terminals
    // It's better to try and fail gracefully than not try at all
    return true;
  }

  /// Get a diagnostic string about the current terminal environment.
  ///
  /// This is useful for debugging clipboard issues.
  static String getDiagnostics() {
    final buffer = StringBuffer();
    buffer.writeln('Clipboard Diagnostics:');
    buffer.writeln('  Has Terminal: ${stdout.hasTerminal}');
    buffer.writeln('  TERM: ${Platform.environment['TERM'] ?? 'not set'}');
    buffer.writeln('  TERM_PROGRAM: ${Platform.environment['TERM_PROGRAM'] ?? 'not set'}');
    buffer.writeln('  TMUX: ${Platform.environment['TMUX'] != null ? 'yes' : 'no'}');
    buffer.writeln('  SSH: ${Platform.environment['SSH_CONNECTION'] != null ? 'yes' : 'no'}');
    buffer.writeln('  OSC 52 Likely Supported: ${isSupported()}');
    return buffer.toString();
  }
}

/// Clipboard manager that maintains an internal clipboard buffer
/// in addition to using OSC 52 for system clipboard integration.
///
/// This provides a fallback when OSC 52 is not available and ensures
/// copy/paste operations work within the same application session.
class ClipboardManager {
  static String? _buffer;
  static String? _primaryBuffer;

  /// Copy text to both the internal buffer and system clipboard.
  ///
  /// Returns true if at least the internal buffer was updated.
  static bool copy(String text, {bool useStringTerminator = true}) {
    _buffer = text;

    // Try to also copy to system clipboard via OSC 52
    // Use the Terminal's write buffer to avoid corrupting output
    final binding = TerminalBinding.instance;
    binding.terminal.writeClipboardCopy(text);

    return true;
  }

  /// Copy text to the primary selection.
  static bool copyToPrimary(String text, {bool useStringTerminator = true}) {
    _primaryBuffer = text;

    try {
      Clipboard.copyToPrimary(text, useStringTerminator: useStringTerminator);
    } catch (_) {
      // Silently fail
    }

    return true;
  }

  /// Get the text from the internal clipboard buffer.
  ///
  /// Note: This does NOT query the system clipboard via OSC 52
  /// (as reading from OSC 52 is not reliably supported).
  /// It only returns text that was previously copied using this manager.
  static String? paste() {
    return _buffer;
  }

  /// Get the text from the internal primary buffer.
  static String? pastePrimary() {
    return _primaryBuffer;
  }

  /// Clear both internal buffers and attempt to clear system clipboard.
  static void clear() {
    _buffer = null;
    _primaryBuffer = null;

    try {
      Clipboard.clear();
    } catch (_) {
      // Silently fail
    }
  }

  /// Check if the internal clipboard has content.
  static bool hasContent() {
    return _buffer != null && _buffer!.isNotEmpty;
  }

  /// Check if the internal primary buffer has content.
  static bool hasPrimaryContent() {
    return _primaryBuffer != null && _primaryBuffer!.isNotEmpty;
  }
}
