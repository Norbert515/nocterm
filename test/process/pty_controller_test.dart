import 'package:nocterm/src/process/pty_controller.dart';
import 'package:test/test.dart';
import 'dart:async';
import 'dart:io';
import 'package:nocterm/nocterm.dart' hide isNotEmpty;

void main() {
  group('PtyController', () {
    test('creates with default shell', () {
      final controller = PtyController();
      expect(controller.command, isNotEmpty);
      expect(controller.status, equals(PtyStatus.notStarted));
      expect(controller.isRunning, isFalse);
      controller.dispose();
    });

    test('creates with custom command', () {
      final controller = PtyController(
        command: '/bin/echo',
        arguments: ['hello', 'world'],
      );
      expect(controller.command, equals('/bin/echo'));
      expect(controller.arguments, equals(['hello', 'world']));
      controller.dispose();
    });

    test('starts and runs echo command', () async {
      final outputCompleter = Completer<String>();
      final exitCompleter = Completer<int>();
      final output = <String>[];

      final controller = PtyController(
        command: '/bin/echo',
        arguments: ['test output'],
        onOutput: (data) {
          output.add(data);
          if (!outputCompleter.isCompleted) {
            outputCompleter.complete(data);
          }
        },
        onExit: (code) {
          if (!exitCompleter.isCompleted) {
            exitCompleter.complete(code);
          }
        },
      );

      expect(controller.status, equals(PtyStatus.notStarted));

      await controller.start(columns: 80, rows: 24);
      expect(controller.status, equals(PtyStatus.running));
      expect(controller.isRunning, isTrue);
      expect(controller.pid, isNotNull);

      // Wait for output and exit
      await outputCompleter.future.timeout(const Duration(seconds: 5));
      final exitCode = await exitCompleter.future.timeout(
        const Duration(seconds: 5),
      );

      expect(output.join(), contains('test output'));
      expect(exitCode, equals(0));
      expect(controller.exitCode, equals(0));
      expect(controller.status, equals(PtyStatus.exited));

      await controller.dispose();
    });

    test('handles write operations', () async {
      final outputCompleter = Completer<String>();
      final outputs = <String>[];

      final controller = PtyController(
        command: Platform.isWindows ? 'cmd' : '/bin/cat',
        onOutput: (data) {
          outputs.add(data);
          if (data.contains('hello') && !outputCompleter.isCompleted) {
            outputCompleter.complete(data);
          }
        },
      );

      await controller.start(columns: 80, rows: 24);
      expect(controller.isRunning, isTrue);

      // Write to the terminal
      controller.write('hello\n');

      // Wait for echo back
      await outputCompleter.future.timeout(const Duration(seconds: 5));

      // Kill the process
      controller.kill();

      // Give it time to shut down
      await Future.delayed(const Duration(milliseconds: 100));

      await controller.dispose();
    });

    test('handles resize operations', () async {
      final controller = PtyController(
        command: Platform.isWindows ? 'cmd' : '/bin/sh',
      );

      await controller.start(columns: 80, rows: 24);
      expect(controller.columns, equals(80));
      expect(controller.rows, equals(24));

      controller.resize(100, 30);
      expect(controller.columns, equals(100));
      expect(controller.rows, equals(30));

      controller.kill();
      await controller.dispose();
    });

    test('manages output buffer', () async {
      final controller = PtyController(
        command: '/bin/echo',
        arguments: ['line1', '&&', 'echo', 'line2', '&&', 'echo', 'line3'],
        maxBufferLines: 2,
      );

      await controller.start(columns: 80, rows: 24);

      // Wait for process to complete
      await Future.delayed(const Duration(seconds: 1));

      // Buffer should be limited to maxBufferLines
      expect(controller.outputBuffer.length, lessThanOrEqualTo(2));

      await controller.dispose();
    });

    test('clears buffer', () async {
      final controller = PtyController(
        command: '/bin/echo',
        arguments: ['test'],
      );

      await controller.start(columns: 80, rows: 24);

      // Wait for output
      await Future.delayed(const Duration(milliseconds: 500));

      expect(controller.outputBuffer.isNotEmpty, isTrue);

      controller.clearBuffer();
      expect(controller.outputBuffer.isEmpty, isTrue);

      await controller.dispose();
    });

    test('notifies listeners on state changes', () async {
      final controller = PtyController(
        command: '/bin/echo',
        arguments: ['test'],
      );

      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      await controller.start(columns: 80, rows: 24);

      // Wait for process to complete
      await Future.delayed(const Duration(seconds: 1));

      // Should have received notifications for start, output, and exit
      expect(notificationCount, greaterThan(0));

      await controller.dispose();
    });

    test('throws when starting already running process', () async {
      final controller = PtyController(
        command: Platform.isWindows ? 'cmd' : '/bin/sh',
      );

      await controller.start(columns: 80, rows: 24);
      expect(controller.isRunning, isTrue);

      // Should throw when trying to start again
      expect(() => controller.start(columns: 80, rows: 24), throwsStateError);

      controller.kill();
      await controller.dispose();
    });

    test('throws when writing to non-running process', () {
      final controller = PtyController();

      expect(() => controller.write('test'), throwsStateError);

      controller.dispose();
    });

    test('handles error callback', () async {
      final errorCompleter = Completer<Object>();

      final controller = PtyController(
        command: '/non/existent/command/that/definitely/does/not/exist',
        onError: (error) {
          if (!errorCompleter.isCompleted) {
            errorCompleter.complete(error);
          }
        },
      );

      try {
        await controller.start(columns: 80, rows: 24);
        // If it doesn't throw, wait a bit for the process to fail
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        // Expected to fail
      }

      // The error status might be set either way
      expect(
        controller.status,
        anyOf(equals(PtyStatus.error), equals(PtyStatus.exited)),
      );

      await controller.dispose();
    });

    test('restarts process', () async {
      final controller = PtyController(
        command: '/bin/echo',
        arguments: ['test'],
      );

      await controller.start(columns: 80, rows: 24);
      final firstPid = controller.pid;

      // Wait for process to exit
      await Future.delayed(const Duration(seconds: 1));

      await controller.restart();

      // Should have a new process
      expect(controller.isRunning, isTrue);
      expect(controller.pid, isNot(equals(firstPid)));

      await controller.dispose();
    }, skip: 'Restart may not work reliably with echo command');
  });
}
