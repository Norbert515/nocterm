import 'log_server.dart';

/// A logger that streams log messages via WebSocket using [LogServer].
///
/// This logger is designed for TUI applications where logging to stdout
/// would interfere with the terminal UI. Instead, logs are streamed via
/// WebSocket and can be viewed using the `nocterm logs` CLI command.
///
/// Features:
/// - **WebSocket streaming**: Logs are sent to connected clients in real-time
/// - **No file I/O**: All logging happens in memory and over the network
/// - **Automatic timestamps**: Each log entry includes an ISO 8601 timestamp
/// - **Nullable server**: Can be used without a server for testing
///
/// Example:
/// ```dart
/// final logServer = LogServer();
/// await logServer.start();
///
/// final logger = Logger(logServer: logServer);
/// logger.log('Application started');
/// logger.log('Processing data...');
///
/// await logServer.close();
/// ```
///
/// The logger is used automatically by [runApp] to capture print statements
/// and errors without blocking the TUI.
class Logger {
  Logger({LogServer? logServer}) : _logServer = logServer;

  /// The log server to stream messages to (nullable for testing)
  final LogServer? _logServer;

  /// Whether the logger has been closed
  bool _closed = false;

  /// Add a log message to the server
  void log(String message) {
    if (_closed) return;

    final timestamp = DateTime.now().toIso8601String();
    final entry = '[$timestamp] $message';

    // Stream to log server if available
    _logServer?.log(entry);
  }

  /// Close the logger (no-op, kept for API compatibility)
  Future<void> close() async {
    _closed = true;
  }

  /// Flush logs (no-op, kept for API compatibility)
  Future<void> flush() async {
    // No-op: logs are streamed immediately
  }
}
