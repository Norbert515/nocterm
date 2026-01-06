import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('TerminalXterm', () {
    test('requires a controller', () {
      final controller = PtyController(
        command: '/bin/echo',
        arguments: ['test'],
      );

      // Should be able to create with required controller
      final terminal = TerminalXterm(controller: controller);

      expect(terminal.controller, equals(controller));
      expect(terminal.focused, isFalse);
      expect(terminal.maxLines, equals(10000));
      expect(terminal.autoStart, isTrue);

      controller.dispose();
    });

    test('accepts optional parameters', () {
      final controller = PtyController(
        command: '/bin/echo',
        arguments: ['test'],
      );

      bool keyEventCalled = false;
      final terminal = TerminalXterm(
        controller: controller,
        focused: true,
        maxLines: 5000,
        autoStart: false,
        onKeyEvent: (event) {
          keyEventCalled = true;
          return true;
        },
      );

      expect(terminal.controller, equals(controller));
      expect(terminal.focused, isTrue);
      expect(terminal.maxLines, equals(5000));
      expect(terminal.autoStart, isFalse);
      expect(terminal.onKeyEvent, isNotNull);

      // Test that onKeyEvent callback works
      terminal.onKeyEvent!(KeyboardEvent(logicalKey: LogicalKey.enter));
      expect(keyEventCalled, isTrue);

      controller.dispose();
    });

    test('controller manages all process configuration', () {
      // All process configuration is now in the controller
      final controller = PtyController(
        command: '/bin/bash',
        arguments: ['-c', 'echo hello'],
        workingDirectory: '/tmp',
        environment: {'TEST': 'value'},
        maxBufferLines: 1000,
      );

      // Terminal only needs the controller
      final terminal = TerminalXterm(controller: controller);

      // Process configuration is in the controller
      expect(controller.command, equals('/bin/bash'));
      expect(controller.arguments, equals(['-c', 'echo hello']));
      expect(controller.workingDirectory, equals('/tmp'));
      expect(controller.environment, equals({'TEST': 'value'}));
      expect(controller.maxBufferLines, equals(1000));

      // Terminal has no process configuration
      expect(terminal.controller, equals(controller));

      controller.dispose();
    });
  });
}
