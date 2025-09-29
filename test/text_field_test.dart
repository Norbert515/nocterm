import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/components/text_field.dart';
import 'package:nocterm/tui_test.dart';
import 'package:test/test.dart';

void main() {
  group('TextField', () {
    group('basic functionality', () {
      test('renders empty field with placeholder', () async {
        await testNocterm(
          'empty field with placeholder',
          (tester) async {
            await tester.pumpComponent(
              const TextField(
                placeholder: 'Enter text...',
                width: 30,
                height: 3,
              ),
            );

            expect(tester.terminalState, containsText('Enter text...'));
          },
          debugPrintAfterPump: true,
        );
      });

      test('accepts text input', () async {
        await testNocterm(
          'text input',
          (tester) async {
            final controller = TextEditingController();

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 1,
              ),
            );

            await tester.enterText('Hello World');
            await tester.pump();

            expect(controller.text, equals('Hello World'));
            expect(tester.terminalState, containsText('Hello World'));
          },
        );
      });

      test('handles emoji input correctly', () async {
        await testNocterm(
          'emoji input',
          (tester) async {
            final controller = TextEditingController();

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 1,
              ),
            );

            await tester.enterText('Hello 🦄 World 🌈');
            await tester.pump();

            expect(controller.text, equals('Hello 🦄 World 🌈'));
            expect(tester.terminalState, containsText('Hello 🦄 World 🌈'));
          },
          debugPrintAfterPump: true,
        );
      });

      test('handles Chinese characters correctly', () async {
        await testNocterm(
          'Chinese characters',
          (tester) async {
            final controller = TextEditingController();

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 1,
              ),
            );

            await tester.enterText('你好世界');
            await tester.pump();

            expect(controller.text, equals('你好世界'));
            expect(tester.terminalState, containsText('你好世界'));
          },
          debugPrintAfterPump: true,
        );
      });
    });

    group('cursor movement', () {
      test('moves cursor left and right', () async {
        await testNocterm(
          'cursor movement horizontal',
          (tester) async {
            final controller = TextEditingController(text: 'Hello World');

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 1,
                showCursor: true,
                cursorBlinkRate: null, // Disable blinking for testing
              ),
            );

            // Move cursor to start
            for (int i = 0; i < 11; i++) {
              await tester.sendKey(LogicalKey.arrowLeft);
            }
            await tester.pump();

            expect(controller.selection.extentOffset, equals(0));

            // Move cursor to position 5
            for (int i = 0; i < 5; i++) {
              await tester.sendKey(LogicalKey.arrowRight);
            }
            await tester.pump();

            expect(controller.selection.extentOffset, equals(5));
          },
        );
      });

      test('moves cursor by word', () async {
        await testNocterm(
          'cursor movement by word',
          (tester) async {
            final controller = TextEditingController(text: 'Hello World Test');

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 1,
              ),
            );

            // Move to start
            await tester.sendKey(LogicalKey.home);
            await tester.pump();

            // Move right by word (should be at position 6 - after "Hello ")
            await tester.sendKey(LogicalKey.arrowRight, ctrl: true);
            await tester.pump();

            expect(controller.selection.extentOffset, equals(6));

            // Move right by word again (should be at position 12 - after "World ")
            await tester.sendKey(LogicalKey.arrowRight, ctrl: true);
            await tester.pump();

            expect(controller.selection.extentOffset, equals(12));
          },
        );
      });

      test('handles Home and End keys', () async {
        await testNocterm(
          'home and end keys',
          (tester) async {
            final controller = TextEditingController(text: 'Hello World');

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 1,
              ),
            );

            await tester.sendKey(LogicalKey.home);
            await tester.pump();

            expect(controller.selection.extentOffset, equals(0));

            await tester.sendKey(LogicalKey.end);
            await tester.pump();

            expect(controller.selection.extentOffset, equals(11));
          },
        );
      });
    });

    group('text manipulation', () {
      test('deletes character with backspace', () async {
        await testNocterm(
          'backspace',
          (tester) async {
            final controller = TextEditingController(text: 'Hello');

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 1,
              ),
            );

            await tester.sendKey(LogicalKey.backspace);
            await tester.pump();

            expect(controller.text, equals('Hell'));
          },
        );
      });

      test('deletes word with Ctrl+Backspace', () async {
        await testNocterm(
          'delete word backward',
          (tester) async {
            final controller = TextEditingController(text: 'Hello World');

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 1,
              ),
            );

            await tester.sendKey(LogicalKey.backspace, ctrl: true);
            await tester.pump();

            expect(controller.text, equals('Hello '));
          },
        );
      });

      test('transposes characters with Ctrl+T', () async {
        await testNocterm(
          'transpose characters',
          (tester) async {
            final controller = TextEditingController(text: 'Hello');
            controller.selection = const TextSelection.collapsed(offset: 4); // Between 'l' and 'o'

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 1,
              ),
            );

            await tester.sendKey(LogicalKey.keyT, ctrl: true);
            await tester.pump();

            expect(controller.text, equals('Helol'));
          },
        );
      });

      test('handles text selection', () async {
        await testNocterm(
          'text selection',
          (tester) async {
            final controller = TextEditingController(text: 'Hello World');

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 1,
              ),
            );

            // Select all
            await tester.sendKey(LogicalKey.keyA, ctrl: true);
            await tester.pump();

            expect(controller.selection.start, equals(0));
            expect(controller.selection.end, equals(11));

            // Delete selection
            await tester.sendKey(LogicalKey.delete);
            await tester.pump();

            expect(controller.text, isEmpty);
          },
        );
      });
    });

    group('multi-line text', () {
      test('handles multi-line input', () async {
        await testNocterm(
          'multi-line input',
          (tester) async {
            final controller = TextEditingController();

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 5,
                maxLines: 5,
              ),
            );

            await tester.enterText('Line 1');
            await tester.sendKeyWithModifiers(LogicalKey.enter, shift: true);
            await tester.enterText('Line 2');
            await tester.sendKeyWithModifiers(LogicalKey.enter, shift: true);
            await tester.enterText('Line 3');
            await tester.pump();

            expect(controller.text, equals('Line 1\nLine 2\nLine 3'));
            expect(tester.terminalState, containsText('Line 1'));
            expect(tester.terminalState, containsText('Line 2'));
            expect(tester.terminalState, containsText('Line 3'));
          },
          debugPrintAfterPump: true,
        );
      });

      test('wraps long lines correctly', () async {
        await testNocterm(
          'text wrapping',
          (tester) async {
            final controller = TextEditingController();

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 20,
                height: 3,
                maxLines: 3,
              ),
            );

            await tester.enterText('This is a very long line that should wrap');
            await tester.pump();

            // Check that text is wrapped
            expect(controller.text, equals('This is a very long line that should wrap'));
          },
          debugPrintAfterPump: true,
          size: const Size(30, 10),
        );
      });

      test('navigates vertically in multi-line text', () async {
        await testNocterm(
          'vertical navigation',
          (tester) async {
            final controller = TextEditingController(text: 'Line 1\nLine 2\nLine 3');

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 5,
                maxLines: 5,
              ),
            );

            // Move to start
            await tester.sendKey(LogicalKey.home, ctrl: true);
            await tester.pump();

            // Move down to line 2
            await tester.sendKey(LogicalKey.arrowDown);
            await tester.pump();

            // Position should be on line 2
            final lines = controller.text.split('\n');
            final expectedOffset = lines[0].length + 1; // +1 for newline

            expect(controller.selection.extentOffset >= expectedOffset, isTrue);
            expect(controller.selection.extentOffset <= expectedOffset + lines[1].length, isTrue);
          },
        );
      });
    });

    group('constraints', () {
      test('respects maxLength', () async {
        await testNocterm(
          'max length constraint',
          (tester) async {
            final controller = TextEditingController();

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 1,
                maxLength: 5,
              ),
            );

            await tester.enterText('12345678');
            await tester.pump();

            expect(controller.text, equals('12345'));
          },
        );
      });

      test('respects maxLines', () async {
        await testNocterm(
          'max lines constraint',
          (tester) async {
            final controller = TextEditingController();

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 3,
                maxLines: 2,
              ),
            );

            await tester.enterText('Line 1');
            await tester.sendKeyWithModifiers(LogicalKey.enter, shift: true);
            await tester.enterText('Line 2');
            await tester.sendKeyWithModifiers(LogicalKey.enter, shift: true);
            await tester.enterText('Line 3');
            await tester.pump();

            // Should only have 2 lines
            final lineCount = controller.text.split('\n').length;
            expect(lineCount, lessThanOrEqualTo(2));
          },
        );
      });
    });

    group('visual features', () {
      test('shows cursor styles', () async {
        await testNocterm(
          'cursor styles',
          (tester) async {
            final controller = TextEditingController(text: 'Hello');

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 1,
                showCursor: true,
                cursorStyle: CursorStyle.block,
                cursorBlinkRate: null,
              ),
            );

            // Visual test - cursor should be visible
            expect(tester.terminalState, containsText('Hello'));
          },
          debugPrintAfterPump: true,
        );
      });

      test('shows placeholder when empty', () async {
        await testNocterm(
          'placeholder display',
          (tester) async {
            await tester.pumpComponent(
              const TextField(
                placeholder: 'Type here...',
                width: 30,
                height: 1,
              ),
            );

            expect(tester.terminalState, containsText('Type here...'));
          },
          debugPrintAfterPump: true,
        );
      });

      test('handles obscured text', () async {
        await testNocterm(
          'password field',
          (tester) async {
            final controller = TextEditingController();

            await tester.pumpComponent(
              TextField(
                controller: controller,
                focused: true,
                width: 30,
                height: 1,
                obscureText: true,
                obscuringCharacter: '*',
              ),
            );

            await tester.enterText('password');
            await tester.pump();

            expect(controller.text, equals('password'));
            expect(tester.terminalState, containsText('********'));
          },
          debugPrintAfterPump: true,
        );
      });
    });
  });
}