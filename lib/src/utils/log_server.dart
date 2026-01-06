import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'nocterm_paths.dart';

/// A WebSocket-based log server that streams log messages to connected clients.
///
/// This server maintains a circular buffer of recent log entries and streams
/// them to WebSocket clients. When a client connects, it receives all buffered
/// logs first, then receives new logs as they arrive.
///
/// Features:
/// - **Circular buffer**: Stores last N log entries in memory
/// - **WebSocket streaming**: Multiple clients can connect simultaneously
/// - **Port discovery**: Writes port to `~/.nocterm/<hash>/log_port` for CLI discovery
/// - **Graceful shutdown**: Cleans up connections and port file on close
///
/// Example:
/// ```dart
/// final server = LogServer(maxBufferSize: 10000);
/// await server.start();
///
/// server.log('Application started');
/// server.log('Processing data...');
///
/// await server.close();
/// ```
class LogServer {
  LogServer({this.maxBufferSize = 10000});

  /// Maximum number of log entries to keep in buffer
  final int maxBufferSize;

  /// Circular buffer of log entries
  final Queue<LogEntry> _buffer = Queue<LogEntry>();

  /// Set of connected WebSocket clients
  final Set<WebSocket> _clients = <WebSocket>{};

  /// HTTP server for WebSocket connections
  HttpServer? _server;

  /// Port the server is listening on (null if not started)
  int? get port => _server?.port;

  /// Whether the server has been closed
  bool _closed = false;

  /// Start the WebSocket server
  Future<void> start() async {
    if (_closed) {
      throw StateError('LogServer has been closed');
    }

    if (_server != null) {
      throw StateError('LogServer is already started');
    }

    try {
      // Start server on localhost with random port
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

      // Handle WebSocket upgrade requests
      _server!.listen((HttpRequest request) {
        if (request.uri.path == '/logs') {
          _handleWebSocketConnection(request);
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found')
            ..close();
        }
      });

      // Write port to file for CLI discovery
      await _writePortFile();
    } catch (e) {
      stderr.writeln('Failed to start log server: $e');
      _server = null;
      rethrow;
    }
  }

  /// Handle a new WebSocket connection
  Future<void> _handleWebSocketConnection(HttpRequest request) async {
    try {
      final ws = await WebSocketTransformer.upgrade(request);

      // Add to clients set
      _clients.add(ws);

      // Send all buffered logs to new client
      for (final entry in _buffer) {
        if (!_closed && !_clients.contains(ws)) break;

        try {
          ws.add(
            jsonEncode({
              'timestamp': entry.timestamp.toIso8601String(),
              'message': entry.message,
            }),
          );
        } catch (_) {
          // Client may have disconnected
          break;
        }
      }

      // Listen for client disconnect
      ws.listen(
        (_) {
          // We don't expect any messages from client
        },
        onDone: () {
          _clients.remove(ws);
        },
        onError: (_) {
          _clients.remove(ws);
        },
        cancelOnError: true,
      );
    } catch (e) {
      // Failed to upgrade to WebSocket
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('WebSocket upgrade failed')
        ..close();
    }
  }

  /// Add a log message to the buffer and broadcast to clients
  void log(String message) {
    if (_closed) return;

    final entry = LogEntry(timestamp: DateTime.now(), message: message);

    // Add to buffer
    _buffer.add(entry);

    // Enforce max buffer size (drop oldest entries)
    while (_buffer.length > maxBufferSize) {
      _buffer.removeFirst();
    }

    // Broadcast to all connected clients
    _broadcastEntry(entry);
  }

  /// Broadcast a log entry to all connected clients
  void _broadcastEntry(LogEntry entry) {
    final json = jsonEncode({
      'timestamp': entry.timestamp.toIso8601String(),
      'message': entry.message,
    });

    // Send to all clients, removing any that fail
    final failedClients = <WebSocket>[];

    for (final client in _clients) {
      try {
        client.add(json);
      } catch (_) {
        // Client disconnected or error sending
        failedClients.add(client);
      }
    }

    // Remove failed clients
    for (final client in failedClients) {
      _clients.remove(client);
      try {
        client.close();
      } catch (_) {
        // Ignore close errors
      }
    }
  }

  /// Write port number to global log_port file
  Future<void> _writePortFile() async {
    try {
      await ensureNoctermDirectoryExists();

      final portFile = File(getLogPortPath());
      await portFile.writeAsString('$port');
    } catch (e) {
      stderr.writeln('Warning: Failed to write log_port file: $e');
    }
  }

  /// Close the server and clean up resources
  Future<void> close() async {
    if (_closed) return;

    _closed = true;

    // Close all client connections
    for (final client in _clients) {
      try {
        await client.close();
      } catch (_) {
        // Ignore close errors
      }
    }
    _clients.clear();

    // Close server
    if (_server != null) {
      try {
        await _server!.close(force: true);
      } catch (_) {
        // Ignore close errors
      }
      _server = null;
    }

    // Clean up port file
    try {
      final portFile = File(getLogPortPath());
      if (await portFile.exists()) {
        await portFile.delete();
      }
    } catch (e) {
      stderr.writeln('Warning: Failed to delete log_port file: $e');
    }

    // Clear buffer
    _buffer.clear();
  }

  /// Get a copy of the current buffer (for debugging/testing)
  List<LogEntry> get buffer => List.unmodifiable(_buffer);
}

/// A log entry with timestamp and message
class LogEntry {
  LogEntry({required this.timestamp, required this.message});

  final DateTime timestamp;
  final String message;
}
