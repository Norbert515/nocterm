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
      String? key;
      if (data.length == 3 && data[0] == 27 && data[1] == 91) {
        // Arrow keys
        switch (data[2]) {
          case 65:
            key = 'up';
            break;
          case 66:
            key = 'down';
            break;
          case 67:
            key = 'right';
            break;
          case 68:
            key = 'left';
            break;
        }
      } else if (data.length == 1) {
        // Regular keys
        switch (data[0]) {
          case 10:
            key = 'enter';
            break;
          case 32:
            key = 'space';
            break;
          case 9:
            key = 'tab';
            break;
          default:
            key = input;
        }
      }

      if (key != null && onKeyPress != null) {
        onKeyPress!(key);
        // Re-render after key press with previous buffer for optimization
        final frame = Frame(
          size: terminal.size,
          previousBuffer: _previousBuffer,
        );
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
