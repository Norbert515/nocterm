import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:nocterm/src/utils/log_server.dart';
import 'package:nocterm/src/utils/logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('LogServer', () {
    late LogServer logServer;
    late Directory tempDir;

    // Every server gets a port file of its own. The default path is keyed
    // by process id, so servers started concurrently in one process - which
    // is every test in this file - would otherwise overwrite and delete
    // each other's, and each test would read whichever port won the race.
    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('nocterm_log_test_');
      logServer = LogServer(
        maxBufferSize: 100,
        portFilePath: p.join(tempDir.path, 'log_port'),
      );
      await logServer.start();
    });

    tearDown(() async {
      await logServer.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('starts server and assigns port', () {
      expect(logServer.port, isNotNull);
      expect(logServer.port, greaterThan(0));
    });

    test('buffers log messages', () {
      logServer.log('First message');
      logServer.log('Second message');
      logServer.log('Third message');

      expect(logServer.buffer.length, equals(3));
      expect(logServer.buffer[0].message, contains('First message'));
      expect(logServer.buffer[1].message, contains('Second message'));
      expect(logServer.buffer[2].message, contains('Third message'));
    });

    test('enforces max buffer size', () {
      for (int i = 0; i < 150; i++) {
        logServer.log('Message $i');
      }

      expect(logServer.buffer.length, lessThanOrEqualTo(100));
      // Oldest messages should be dropped
      expect(
          logServer.buffer.any((entry) => entry.message.contains('Message 0')),
          isFalse);
      expect(
          logServer.buffer
              .any((entry) => entry.message.contains('Message 149')),
          isTrue);
    });

    test('streams logs to WebSocket client', () async {
      // Add some logs before connecting
      logServer.log('Buffered message 1');
      logServer.log('Buffered message 2');

      // Connect WebSocket client
      final ws =
          await WebSocket.connect('ws://127.0.0.1:${logServer.port}/logs');

      // Collect messages
      final messages = <String>[];
      final completer = Completer<void>();

      ws.listen((message) {
        messages.add(message as String);
        // After receiving 3 messages (2 buffered + 1 new), complete
        if (messages.length >= 3) {
          completer.complete();
        }
      });

      // Add a new log after connecting
      await Future.delayed(const Duration(milliseconds: 50));
      logServer.log('New message');

      // Wait for all messages
      await completer.future.timeout(const Duration(seconds: 2));

      // Verify we received buffered logs first
      expect(messages.length, greaterThanOrEqualTo(3));

      final firstMsg = jsonDecode(messages[0]) as Map<String, dynamic>;
      expect(firstMsg['message'], contains('Buffered message 1'));

      final secondMsg = jsonDecode(messages[1]) as Map<String, dynamic>;
      expect(secondMsg['message'], contains('Buffered message 2'));

      final thirdMsg = jsonDecode(messages[2]) as Map<String, dynamic>;
      expect(thirdMsg['message'], contains('New message'));

      await ws.close();
    });

    test('creates log_port file', () async {
      final portFile = File(logServer.portFilePath);
      expect(await portFile.exists(), isTrue);

      final portString = await portFile.readAsString();
      expect(int.tryParse(portString), equals(logServer.port));
    });

    test('cleans up log_port file on close', () async {
      final portFile = File(logServer.portFilePath);
      expect(await portFile.exists(), isTrue);

      await logServer.close();

      expect(await portFile.exists(), isFalse);
    });
  });

  group('Logger', () {
    late LogServer logServer;
    late Logger logger;
    late Directory tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('nocterm_log_test_');
      logServer = LogServer(
        maxBufferSize: 100,
        portFilePath: p.join(tempDir.path, 'log_port'),
      );
      await logServer.start();
      logger = Logger(logServer: logServer);
    });

    tearDown(() async {
      await logger.close();
      await logServer.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('sends logs to server', () {
      logger.log('Test message');

      expect(logServer.buffer.length, equals(1));
      expect(logServer.buffer.first.message, contains('Test message'));
    });

    test('includes timestamps', () {
      logger.log('Timestamped message');

      expect(logServer.buffer.first.message,
          matches(r'\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'));
      expect(logServer.buffer.first.message, contains('Timestamped message'));
    });

    test('ignores logs after close', () async {
      await logger.close();

      final bufferLengthBefore = logServer.buffer.length;
      logger.log('Should be ignored');

      // Buffer length should not change
      expect(logServer.buffer.length, equals(bufferLengthBefore));
    });

    test('works without log server (null case)', () {
      final standaloneLogger = Logger();

      // Should not throw
      expect(() => standaloneLogger.log('Test'), returnsNormally);
    });
  });
}
