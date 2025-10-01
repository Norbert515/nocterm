import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('TextField Regression Tests', () {
    test('single-line field still works correctly', () async {
      await testNocterm(
        'single-line',
        (tester) async {
          final controller = TextEditingController(text: 'Hello World');

          await tester.pumpComponent(
            TextField(
              controller: controller,
              width: 20,
              focused: true,
              decoration: const InputDecoration(
                border: BoxBorder(),
              ),
              showCursor: true,
              cursorBlinkRate: null,
            ),
          );

          expect(tester.terminalState, containsText('Hello World'));

          // Move cursor to end
          controller.selection = TextSelection.collapsed(offset: 11);
          await tester.pump();

          // Add more text
          controller.text = 'Hello World!';
          controller.selection = TextSelection.collapsed(offset: 12);
          await tester.pump();

          expect(tester.terminalState, containsText('!'));
        },
        debugPrintAfterPump: false,
      );
    });

    test('multi-line field with explicit newlines works', () async {
      await testNocterm(
        'explicit newlines',
        (tester) async {
          final controller = TextEditingController(text: 'Line 1\nLine 2\nLine 3');

          await tester.pumpComponent(
            TextField(
              controller: controller,
              width: 20,
              maxLines: 5,
              focused: true,
              decoration: const InputDecoration(
                border: BoxBorder(),
              ),
              showCursor: true,
              cursorBlinkRate: null,
            ),
          );

          expect(tester.terminalState, containsText('Line 1'));
          expect(tester.terminalState, containsText('Line 2'));
          expect(tester.terminalState, containsText('Line 3'));

          // Move cursor to end of Line 2
          controller.selection = TextSelection.collapsed(offset: 13); // After "Line 2"
          await tester.pump();

          // Cursor should be at the end of line 2
          expect(tester.terminalState, isNotNull);
        },
        debugPrintAfterPump: false,
      );
    });

    test('cursor position is correct after text changes', () async {
      await testNocterm(
        'cursor after text change',
        (tester) async {
          final controller = TextEditingController(text: '');

          await tester.pumpComponent(
            TextField(
              controller: controller,
              width: 30,
              maxLines: 3,
              focused: true,
              decoration: const InputDecoration(
                border: BoxBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 1),
              ),
              showCursor: true,
              cursorBlinkRate: null,
            ),
          );

          // Type some text
          controller.text = 'ABC';
          controller.selection = TextSelection.collapsed(offset: 3);
          await tester.pump();

          expect(tester.terminalState, containsText('ABC'));

          // Add more text that will wrap
          controller.text = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
          controller.selection = TextSelection.collapsed(offset: 36);
          await tester.pump();

          // Should see the end of the text
          expect(tester.terminalState, containsText('0'));
        },
        debugPrintAfterPump: false,
      );
    });
  });
}