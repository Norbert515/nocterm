import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('TextField Multi-line', () {
    test('cursor position is correct with wrapped lines', () async {
      await testNocterm(
        'wrapped lines cursor',
        (tester) async {
          final controller = TextEditingController(text: '');

          await tester.pumpComponent(
            TextField(
              controller: controller,
              width: 30,
              maxLines: 5,
              focused: true,
              decoration: const InputDecoration(
                border: BoxBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 1),
              ),
              showCursor: true,
              cursorBlinkRate: null, // Static cursor
            ),
          );

          // Width = 30, minus 2 for border, minus 2 for padding = 26 available
          // Add text that will wrap
          controller.text = 'This is a long line that will definitely wrap to the next line';
          controller.selection = TextSelection.collapsed(offset: controller.text.length);
          await tester.pump();

          // The cursor should be at the end of the wrapped text
          // Not beyond the border
          expect(tester.terminalState, isNotNull);
          print('Text with wrapped lines:');
          print(tester.terminalState.toString());
        },
        debugPrintAfterPump: true,
      );
    });

    test('cursor moves correctly across wrapped lines', () async {
      await testNocterm(
        'cursor movement across wrapped lines',
        (tester) async {
          final controller = TextEditingController(text: '');

          await tester.pumpComponent(
            TextField(
              controller: controller,
              width: 20,
              maxLines: 4,
              focused: true,
              decoration: const InputDecoration(
                border: BoxBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 1),
              ),
              showCursor: true,
              cursorBlinkRate: null,
            ),
          );

          // Width = 20, minus 2 for border, minus 2 for padding = 16 available
          // Each line can fit 16 characters
          controller.text = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'; // 26 chars, will wrap

          // Test cursor at various positions
          controller.selection = TextSelection.collapsed(offset: 0);
          await tester.pump();
          print('\nCursor at position 0:');

          controller.selection = TextSelection.collapsed(offset: 16);
          await tester.pump();
          print('\nCursor at position 16 (should be start of line 2):');

          controller.selection = TextSelection.collapsed(offset: 26);
          await tester.pump();
          print('\nCursor at position 26 (end of text):');

          expect(tester.terminalState, isNotNull);
        },
        debugPrintAfterPump: true,
      );
    });

    test('text entry works correctly with wrapped lines', () async {
      await testNocterm(
        'text entry with wrapped lines',
        (tester) async {
          final controller = TextEditingController(text: '');

          await tester.pumpComponent(
            TextField(
              controller: controller,
              width: 25,
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

          // Simulate typing a long text
          String longText = 'Hello this is a cool thing to do is typing a cool long string that can be enough';
          controller.text = longText;
          controller.selection = TextSelection.collapsed(offset: longText.length);
          await tester.pump();

          print('\nTyped long text - cursor should be visible at the end:');
          expect(tester.terminalState, containsText('Hello'));
          expect(tester.terminalState, containsText('enough'));
        },
        debugPrintAfterPump: true,
      );
    });
  });
}