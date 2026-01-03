import 'dart:async';
import 'dart:io';

import 'package:nocterm/src/size.dart';

import 'terminal_backend.dart';

/// Backend for native terminal I/O via stdin/stdout.
/// Handles Unix signals (SIGWINCH, SIGINT, SIGTERM) for resize and shutdown.
/// On Windows, uses polling for resize detection and SIGINT for Ctrl+C.
class StdioBackend implements TerminalBackend {
  StreamController<Size>? _resizeController;
  StreamController<void>? _shutdownController;
  StreamSubscription? _sigwinchSubscription;
  StreamSubscription? _sigintSubscription;
  StreamSubscription? _sigtermSubscription;
  Timer? _windowsResizeTimer;
  Size? _lastKnownSize;
  bool _disposed = false;

  StdioBackend() {
    _initializeSignalHandling();
  }

  void _initializeSignalHandling() {
    _resizeController = StreamController<Size>.broadcast();
    _shutdownController = StreamController<void>.broadcast();

    if (Platform.isWindows) {
      // Windows: Use polling for resize detection since SIGWINCH is not available
      _lastKnownSize = getSize();
      _windowsResizeTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (!_disposed && stdout.hasTerminal) {
          final currentSize = getSize();
          if (_lastKnownSize != currentSize) {
            _lastKnownSize = currentSize;
            _resizeController?.add(currentSize);
          }
        }
      });

      // Windows: SIGINT works for Ctrl+C
      try {
        _sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
          if (!_disposed) {
            _shutdownController?.add(null);
          }
        });
      } catch (e) {
        // SIGINT may not be available in all Windows environments
      }
    } else if (Platform.isLinux || Platform.isMacOS) {
      // Unix: Use signals
      _sigwinchSubscription = ProcessSignal.sigwinch.watch().listen((_) {
        if (!_disposed && stdout.hasTerminal) {
          final size = Size(
            stdout.terminalColumns.toDouble(),
            stdout.terminalLines.toDouble(),
          );
          _resizeController?.add(size);
        }
      });

      _sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
        if (!_disposed) {
          _shutdownController?.add(null);
        }
      });
      _sigtermSubscription = ProcessSignal.sigterm.watch().listen((_) {
        if (!_disposed) {
          _shutdownController?.add(null);
        }
      });
    }
  }

  @override
  void writeRaw(String data) {
    stdout.write(data);
  }

  @override
  Size getSize() {
    if (stdout.hasTerminal) {
      return Size(
        stdout.terminalColumns.toDouble(),
        stdout.terminalLines.toDouble(),
      );
    }
    return const Size(80, 24);
  }

  @override
  bool get supportsSize => stdout.hasTerminal;

  @override
  Stream<List<int>>? get inputStream => stdin;

  @override
  Stream<Size>? get resizeStream => _resizeController?.stream;

  @override
  Stream<void>? get shutdownStream => _shutdownController?.stream;

  @override
  void enableRawMode() {
    try {
      if (stdin.hasTerminal) {
        stdin.echoMode = false;
        stdin.lineMode = false;
      }
    } catch (e) {
      // Ignore errors in CI/CD or when piping
    }
  }

  @override
  void disableRawMode() {
    try {
      if (stdin.hasTerminal) {
        stdin.echoMode = true;
        stdin.lineMode = true;
      }
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  bool get isAvailable => !_disposed;

  @override
  void notifySizeChanged(Size newSize) {
    // StdioBackend doesn't track size via protocol, so this is a no-op.
    // Size changes are detected via SIGWINCH signal (Unix) or polling (Windows).
  }

  @override
  void requestExit([int exitCode = 0]) {
    exit(exitCode);
  }

  @override
  void dispose() {
    _disposed = true;
    _windowsResizeTimer?.cancel();
    _sigwinchSubscription?.cancel();
    _sigintSubscription?.cancel();
    _sigtermSubscription?.cancel();
    _resizeController?.close();
    _shutdownController?.close();
  }
}
