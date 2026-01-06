import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:nocterm/src/size.dart';
import 'package:nocterm/src/style.dart';
import 'package:nocterm/src/utils/escape_codes.dart';

import 'terminal_backend.dart';

class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);
}

class Terminal {
  final TerminalBackend backend;
  late Size _size;
  Stream<String>? _oscStream;

  /// Whether alternate screen mode is enabled.
  /// Protected for subclass access (e.g., WebTerminal).
  @protected
  bool altScreenEnabled = false;

  /// Write buffer for batching output.
  /// Protected for subclass access (e.g., WebTerminal).
  @protected
  final StringBuffer writeBuffer = StringBuffer();

  // ANSI escape codes for terminal control

  // Regex pattern to match RGB color responses
  static const _rgbPattern =
      'rgb:([0-9a-fA-F]{4})/([0-9a-fA-F]{4})/([0-9a-fA-F]{4})';
  static final _bgRegexp = RegExp('11;$_rgbPattern');
  static final _fgRegexp = RegExp('10;$_rgbPattern');

  Terminal(this.backend, {Size? size}) {
    _size = size ?? backend.getSize();
  }

  Size get size => _size;

  void updateSize(Size newSize) {
    _size = newSize;
  }

  void bindOSCStream(Stream<String> oscStream) {
    _oscStream = oscStream;
  }

  void enterAlternateScreen() {
    if (!altScreenEnabled) {
      // These need immediate effect, so flush any pending writes first
      flush();
      backend.writeRaw(EscapeCodes.alternateBuffer);
      clear();
      altScreenEnabled = true;
    }
  }

  void leaveAlternateScreen() {
    if (altScreenEnabled) {
      // These need immediate effect, so flush any pending writes first
      flush();
      backend.writeRaw(EscapeCodes.mainBuffer);
      altScreenEnabled = false;
    }
  }

  void hideCursor() {
    // Buffer this - will be flushed with frame
    write(EscapeCodes.hideCursor);
  }

  void showCursor() {
    // This needs immediate effect when exiting
    flush();
    backend.writeRaw(EscapeCodes.showCursor);
  }

  void clear() {
    // Buffer this - will be flushed with frame
    write(EscapeCodes.clearScreen);
    write(EscapeCodes.moveCursorHome);
  }

  void clearLine() {
    // Buffer this - will be flushed with frame
    write(EscapeCodes.clearLine);
  }

  void moveCursor(int x, int y) {
    write('\x1b[${y + 1};${x + 1}H');
  }

  void moveToHome() {
    write(EscapeCodes.moveCursorHome);
  }

  void moveTo(int x, int y) {
    moveCursor(x, y);
  }

  void write(String text) {
    writeBuffer.write(text);
  }

  void flush() {
    if (writeBuffer.isNotEmpty) {
      final bufferContent = writeBuffer.toString();
      backend.writeRaw(bufferContent);
      writeBuffer.clear();
    }
  }

  /// Set terminal foreground color
  void setForeground(Color color) {
    write('\x1b]10;#');
    write(color.red.toRadixString(16).padLeft(2, '0'));
    write(color.green.toRadixString(16).padLeft(2, '0'));
    write(color.blue.toRadixString(16).padLeft(2, '0'));
    write('\x07');
  }

  /// Set terminal background color
  void setBackground(Color color) {
    write('\x1b]11;#');
    write(color.red.toRadixString(16).padLeft(2, '0'));
    write(color.green.toRadixString(16).padLeft(2, '0'));
    write(color.blue.toRadixString(16).padLeft(2, '0'));
    write('\x07');
  }

  /// Get the terminal's default foreground color
  Future<Color?> getForegroundColor({
    Duration timeout = const Duration(milliseconds: 100),
  }) async {
    write('\x1b]10;?\x07');
    return _oscStream
        ?.firstWhere(_fgRegexp.hasMatch)
        .timeout(timeout)
        .then((event) {
          final match = _fgRegexp.firstMatch(event);
          if (match == null) return null;
          return Color.fromRGB(
            int.parse(match.group(1)!, radix: 16) ~/ 256,
            int.parse(match.group(2)!, radix: 16) ~/ 256,
            int.parse(match.group(3)!, radix: 16) ~/ 256,
          );
        })
        .catchError((_) => null);
  }

  /// Get the terminal's default background color
  Future<Color?> getBackgroundColor({
    Duration timeout = const Duration(milliseconds: 100),
  }) async {
    write('\x1b]11;?\x07');
    flush();
    return _oscStream
        ?.firstWhere(_bgRegexp.hasMatch)
        .timeout(timeout)
        .then((event) {
          final match = _bgRegexp.firstMatch(event);
          if (match == null) return null;
          return Color.fromRGB(
            int.parse(match.group(1)!, radix: 16) ~/ 256,
            int.parse(match.group(2)!, radix: 16) ~/ 256,
            int.parse(match.group(3)!, radix: 16) ~/ 256,
          );
        })
        .catchError((_) => null);
  }

  /// Restore terminal colors to defaults
  void restoreColors() {
    backend.writeRaw('\x1b]110'); // foreground
    backend.writeRaw('\x1b]111'); // background
  }

  void reset() {
    showCursor();
    restoreColors();
    leaveAlternateScreen();
    backend.writeRaw('\x1b[0m'); // Reset all attributes
  }

  /// Write OSC 52 clipboard sequence to copy text to system clipboard.
  /// This must be written to the write buffer and flushed with the frame
  /// to avoid corrupting the terminal output.
  void writeClipboardCopy(String text) {
    // Encode the text in base64 (base64Encode doesn't add newlines in Dart)
    final base64Text = base64Encode(utf8.encode(text));

    // Build the OSC 52 sequence: ESC ] 52 ; c ; <base64-data> BEL
    // Format: \033]52;c;<base64>\a
    const osc = '\x1b]';
    const bel = '\x07'; // Use BEL terminator (more compatible than ST)
    final sequence = '${osc}52;c;$base64Text$bel';

    // Add to write buffer - will be flushed with next frame
    write(sequence);
  }

  /// Set the terminal window title using OSC 2 sequence.
  /// Uses BEL terminator for maximum compatibility.
  ///
  /// Example: `setWindowTitle('My App')`
  void setWindowTitle(String title) {
    // OSC 2 ; <title> BEL
    const osc = '\x1b]';
    const bel = '\x07';
    write('${osc}2;$title$bel');
  }

  /// Set the terminal icon name using OSC 1 sequence.
  /// Uses BEL terminator for maximum compatibility.
  ///
  /// Example: `setIconName('MyApp')`
  void setIconName(String name) {
    // OSC 1 ; <name> BEL
    const osc = '\x1b]';
    const bel = '\x07';
    write('${osc}1;$name$bel');
  }

  /// Set both terminal window title and icon name using OSC 0 sequence.
  /// Uses BEL terminator for maximum compatibility.
  ///
  /// Example: `setTitleAndIcon('My App')`
  void setTitleAndIcon(String text) {
    // OSC 0 ; <text> BEL
    const osc = '\x1b]';
    const bel = '\x07';
    write('${osc}0;$text$bel');
  }
}
