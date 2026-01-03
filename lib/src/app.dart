import 'dart:io';
import 'dart:async';
import 'backend/terminal.dart';
import 'backend/stdio_backend.dart';
import 'frame.dart';
import 'buffer.dart';

typedef RenderFunction = void Function(Frame frame);
typedef KeyHandler = void Function(String key);

class App {
  final Terminal terminal;
  final RenderFunction onRender;
  final KeyHandler? onKeyPress;
  bool _running = false;
  StreamSubscription? _stdinSubscription;
  Buffer? _previousBuffer;
  bool _forceFullRedraw = false;

  App({required this.onRender, this.onKeyPress})
      : terminal = Terminal(StdioBackend());

  Future<void> run() async {
    _running = true;

    // Setup terminal
    terminal.enterAlternateScreen();
    terminal.hideCursor();
    terminal.clear();

    // Setup input handling
    try {
      stdin.echoMode = false;
      stdin.lineMode = false;
    } catch (e) {
      // If stdin doesn't support these modes (e.g., when piped), continue anyway
    }

    _stdinSubscription = stdin.listen((data) {
      final input = String.fromCharCodes(data);

      // Exit on 'q' or Ctrl+C
      if (input == 'q' || (data.isNotEmpty && data[0] == 3)) {
        stop();
        return;
      }

      // Handle arrow keys and other special keys
      String? key = _parseKeyInput(data, input);

      if (key != null && onKeyPress != null) {
        onKeyPress!(key);
        // Re-render after key press with previous buffer for optimization
        final frame =
            Frame(size: terminal.size, previousBuffer: _previousBuffer);
        if (_forceFullRedraw) {
          frame.forceFullRedraw();
          _forceFullRedraw = false;
        }
        onRender(frame);
        frame.render(terminal);
        _previousBuffer = _cloneBuffer(frame.buffer);
      }
    });

    // Initial render
    final frame = Frame(size: terminal.size);
    onRender(frame);
    frame.render(terminal);
    _previousBuffer = _cloneBuffer(frame.buffer);

    // Main render loop
    while (_running) {
      await Future.delayed(const Duration(milliseconds: 100));

      // Check if still running after delay
      if (!_running) break;

      // Re-render with previous buffer for optimization
      final frame = Frame(size: terminal.size, previousBuffer: _previousBuffer);
      if (_forceFullRedraw) {
        frame.forceFullRedraw();
        _forceFullRedraw = false;
      }
      onRender(frame);
      frame.render(terminal);
      _previousBuffer = _cloneBuffer(frame.buffer);
    }

    // Clean up when loop exits
    stop();
  }

  /// Parse keyboard input and return the key name.
  /// Handles both Unix ANSI escape sequences and Windows-specific codes.
  String? _parseKeyInput(List<int> data, String input) {
    // Unix ANSI escape sequences: ESC [ <code>
    if (data.length == 3 && data[0] == 27 && data[1] == 91) {
      switch (data[2]) {
        case 65: return 'up';
        case 66: return 'down';
        case 67: return 'right';
        case 68: return 'left';
      }
    }

    // Windows: Arrow keys can be sent as 0xE0 followed by code
    // or as 0x00 followed by code (extended keys)
    if (data.length == 2 && (data[0] == 0xE0 || data[0] == 0x00)) {
      switch (data[1]) {
        case 72: return 'up';     // 0xE0 0x48
        case 80: return 'down';   // 0xE0 0x50
        case 75: return 'left';   // 0xE0 0x4B
        case 77: return 'right';  // 0xE0 0x4D
      }
    }

    // Windows Terminal / PowerShell may send ANSI sequences differently
    // Check for \x1b[A style sequences in the input string
    if (input.length >= 3 && input.startsWith('\x1b[')) {
      final code = input.substring(2);
      if (code.startsWith('A')) return 'up';
      if (code.startsWith('B')) return 'down';
      if (code.startsWith('C')) return 'right';
      if (code.startsWith('D')) return 'left';
    }

    // Regular single-byte keys
    if (data.length == 1) {
      switch (data[0]) {
        case 10: return 'enter';  // Unix newline
        case 13: return 'enter';  // Windows carriage return
        case 32: return 'space';
        case 9:  return 'tab';
        case 27: return 'escape';
        case 127: return 'backspace'; // Unix backspace
        case 8:  return 'backspace';  // Windows backspace
        default: return input;
      }
    }

    return null;
  }

  Buffer _cloneBuffer(Buffer original) {
    final clone = Buffer(original.width, original.height);
    for (int y = 0; y < original.height; y++) {
      for (int x = 0; x < original.width; x++) {
        final cell = original.getCell(x, y);
        clone.setCell(x, y, cell.copyWith());
      }
    }
    return clone;
  }

  void forceFullRedraw() {
    _forceFullRedraw = true;
  }

  void stop() {
    if (!_running) return; // Already stopped

    _running = false;
    _stdinSubscription?.cancel();

    // Restore terminal
    terminal.reset();

    // Restore stdin settings safely
    try {
      stdin.echoMode = true;
      stdin.lineMode = true;
    } catch (e) {
      // Ignore errors if stdin is already closed
    }
  }
}
