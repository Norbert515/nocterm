import 'dart:async';
import 'dart:io';
import 'package:nocterm/nocterm.dart';

import 'pty_handler.dart';

/// A controller for managing a PTY (pseudo-terminal) process.
///
/// This controller follows the same pattern as Flutter's [TextEditingController],
/// providing a clean separation between the terminal's state management and UI.
///
/// Example usage:
/// ```dart
/// final controller = PtyController(
///   command: '/bin/bash',
///   onOutput: (data) => print('Terminal output: $data'),
/// );
///
/// // Start the terminal
/// await controller.start(columns: 80, rows: 24);
///
/// // Send input
/// controller.write('ls -la\n');
///
/// // Dispose when done
/// controller.dispose();
/// ```
class PtyController {
  /// The command to execute in the terminal.
  final String command;

  /// Command arguments.
  final List<String> arguments;

  /// Working directory for the process.
  final String? workingDirectory;

  /// Environment variables for the process.
  final Map<String, String>? environment;

  // Callbacks
  final List<void Function(String)> _outputCallbacks = [];
  final List<void Function(int)> _exitCallbacks = [];
  final List<void Function(Object)> _errorCallbacks = [];

  /// Maximum number of lines to buffer.
  final int maxBufferLines;

  // Internal state
  PtyHandler? _ptyHandler;
  StreamSubscription<String>? _outputSubscription;
  StreamSubscription<int>? _exitSubscription;
  final List<String> _outputBuffer = [];
  PtyStatus _status = PtyStatus.notStarted;
  int _rows = 24;
  int _columns = 80;
  int? _exitCode;

  // Change notification
  final List<VoidCallback> _listeners = [];

  /// Creates a new PTY controller.
  PtyController({
    String? command,
    this.arguments = const [],
    this.workingDirectory,
    this.environment,
    void Function(String)? onOutput,
    void Function(int)? onExit,
    void Function(Object)? onError,
    this.maxBufferLines = 10000,
  }) : command = command ?? _getDefaultShell() {
    if (onOutput != null) _outputCallbacks.add(onOutput);
    if (onExit != null) _exitCallbacks.add(onExit);
    if (onError != null) _errorCallbacks.add(onError);
  }

  /// Gets the default shell for the current platform.
  static String _getDefaultShell() {
    if (Platform.isWindows) {
      return Platform.environment['COMSPEC'] ?? 'cmd.exe';
    } else {
      return Platform.environment['SHELL'] ?? '/bin/bash';
    }
  }

  /// Current status of the PTY process.
  PtyStatus get status => _status;

  /// Whether the terminal is running.
  bool get isRunning => _status == PtyStatus.running;

  /// Process ID of the running terminal, or null if not running.
  int? get pid => _ptyHandler?.pid;

  /// Exit code of the process, or null if still running.
  int? get exitCode => _exitCode;

  /// Current number of terminal rows.
  int get rows => _rows;

  /// Current number of terminal columns.
  int get columns => _columns;

  /// Output buffer containing recent terminal output.
  List<String> get outputBuffer => List.unmodifiable(_outputBuffer);

  /// Starts the PTY process with the specified dimensions.
  Future<void> start({
    required int columns,
    required int rows,
  }) async {
    if (_status == PtyStatus.running) {
      throw StateError('Terminal is already running');
    }

    _rows = rows;
    _columns = columns;
    _exitCode = null;

    try {
      _status = PtyStatus.starting;
      _notifyListeners();

      // Create the PTY handler
      _ptyHandler = PtyHandlerFactory.create(
        command: command,
        arguments: arguments,
        workingDirectory: workingDirectory,
        environment: environment,
      );

      // Start the process
      await _ptyHandler!.start(columns: columns, rows: rows);

      // Subscribe to output
      _outputSubscription = _ptyHandler!.output.listen(
        (data) {
          _addToBuffer(data);
          for (final callback in _outputCallbacks) {
            callback(data);
          }
        },
        onError: (error) {
          for (final callback in _errorCallbacks) {
            callback(error);
          }
        },
      );

      // Subscribe to exit
      _exitSubscription = _ptyHandler!.exitCode.asStream().listen(
        (code) {
          _exitCode = code;
          _status = PtyStatus.exited;
          _notifyListeners();
          for (final callback in _exitCallbacks) {
            callback(code);
          }
        },
      );

      _status = PtyStatus.running;
      _notifyListeners();
    } catch (e) {
      _status = PtyStatus.error;
      _exitCode = -1;
      _notifyListeners();
      for (final callback in _errorCallbacks) {
        callback(e);
      }
      rethrow;
    }
  }

  /// Writes text data to the terminal.
  void write(String data) {
    if (!isRunning) {
      throw StateError('Terminal is not running');
    }
    _ptyHandler?.write(data);
  }

  /// Writes raw bytes to the terminal.
  void writeBytes(List<int> bytes) {
    if (!isRunning) {
      throw StateError('Terminal is not running');
    }
    _ptyHandler?.writeBytes(bytes);
  }

  /// Resizes the terminal.
  void resize(int columns, int rows) {
    if (!isRunning) return;

    _columns = columns;
    _rows = rows;
    _ptyHandler?.resize(rows, columns);
    _notifyListeners();
  }

  /// Kills the terminal process.
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    if (!isRunning) return false;

    final killed = _ptyHandler?.kill(signal) ?? false;
    if (killed) {
      _status = PtyStatus.exited;
      _notifyListeners();
    }
    return killed;
  }

  /// Clears the output buffer.
  void clearBuffer() {
    _outputBuffer.clear();
    _notifyListeners();
  }

  /// Adds output to the buffer, maintaining max size.
  void _addToBuffer(String data) {
    // Split by lines and add to buffer
    final lines = data.split('\n');
    for (final line in lines) {
      if (line.isNotEmpty || lines.length > 1) {
        _outputBuffer.add(line);
      }
    }

    // Trim buffer if needed
    while (_outputBuffer.length > maxBufferLines) {
      _outputBuffer.removeAt(0);
    }

    _notifyListeners();
  }

  /// Restarts the terminal with the same configuration.
  Future<void> restart() async {
    if (isRunning) {
      kill();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await dispose();
    await start(columns: _columns, rows: _rows);
  }

  /// Adds an output callback.
  void addOutputCallback(void Function(String) callback) {
    _outputCallbacks.add(callback);
  }

  /// Removes an output callback.
  void removeOutputCallback(void Function(String) callback) {
    _outputCallbacks.remove(callback);
  }

  /// Adds an exit callback.
  void addExitCallback(void Function(int) callback) {
    _exitCallbacks.add(callback);
  }

  /// Removes an exit callback.
  void removeExitCallback(void Function(int) callback) {
    _exitCallbacks.remove(callback);
  }

  /// Adds an error callback.
  void addErrorCallback(void Function(Object) callback) {
    _errorCallbacks.add(callback);
  }

  /// Removes an error callback.
  void removeErrorCallback(void Function(Object) callback) {
    _errorCallbacks.remove(callback);
  }

  /// Adds a listener that will be called when the controller changes.
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Removes a listener.
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notifies all listeners of a change.
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Disposes of the controller and releases all resources.
  Future<void> dispose() async {
    await _outputSubscription?.cancel();
    await _exitSubscription?.cancel();
    await _ptyHandler?.dispose();
    _ptyHandler = null;
    _status = PtyStatus.disposed;
    _listeners.clear();
  }
}

/// Status of the PTY process.
enum PtyStatus {
  /// Terminal has not been started yet.
  notStarted,

  /// Terminal is starting up.
  starting,

  /// Terminal is running.
  running,

  /// Terminal has exited.
  exited,

  /// Terminal encountered an error.
  error,

  /// Terminal has been disposed.
  disposed,
}
