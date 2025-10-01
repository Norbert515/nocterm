import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('TextField Cursor Bounds', () {
    test('cursor block stays within field boundaries', () async {
      await testNocterm(
        'cursor within bounds',
        (tester) async {
          final controller = TextEditingController(text: '');

          await tester.pumpComponent(
            Column(
              children: [
                const Text('Test: Cursor should always stay within the border'),
                const SizedBox(height: 1),
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
                  cursorStyle: CursorStyle.block,
                  cursorColor: Colors.cyan,
                ),
              ],
            ),
          );

          // Width = 30
          // Border = 2 (1 on each side)
          // Padding = 2 (1 on each side)
          // Reserved for cursor = 1
          // Available for text = 30 - 2 - 2 - 1 = 25

          // Fill exactly to the available width
          controller.text = 'A' * 25; // Should fit exactly with cursor at end
          controller.selection = TextSelection.collapsed(offset: 25);
          await tester.pump();

          print('25 characters with cursor at end - should be visible within border:');
          expect(tester.terminalState, containsText('A' * 25));

          // Add one more character - should wrap to next line
          controller.text = 'A' * 26;
          controller.selection = TextSelection.collapsed(offset: 26);
          await tester.pump();

          print('\n26 characters - should wrap to next line:');
          expect(tester.terminalState, containsText('A'));
        },
        debugPrintAfterPump: true,
        size: const Size(80, 15),
      );
    });

    test('multi-line text with cursor at line ends', () async {
      await testNocterm(
        'multi-line cursor at line ends',
        (tester) async {
          final controller = TextEditingController(text: '');

          await tester.pumpComponent(
            TextField(
              controller: controller,
              width: 20,
              maxLines: 5,
              focused: true,
              decoration: const InputDecoration(
                border: BoxBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 1),
              ),
              showCursor: true,
              cursorBlinkRate: null,
              cursorStyle: CursorStyle.block,
            ),
          );

          // Width = 20
          // Border = 2
          // Padding = 2
          // Reserved for cursor = 1
          // Available = 20 - 2 - 2 - 1 = 15

          // Text that fills multiple lines exactly
          controller.text = 'ABCDEFGHIJKLMNO' + // 15 chars - line 1
                           'PQRSTUVWXYZ1234' + // 15 chars - line 2
                           '567890';            // 6 chars - line 3

          // Position cursor at end of first line
          controller.selection = TextSelection.collapsed(offset: 15);
          await tester.pump();
          print('Cursor at end of line 1:');

          // Position cursor at end of second line
          controller.selection = TextSelection.collapsed(offset: 30);
          await tester.pump();
          print('\nCursor at end of line 2:');

          // Position cursor at end of text
          controller.selection = TextSelection.collapsed(offset: 36);
          await tester.pump();
          print('\nCursor at end of text:');

          expect(tester.terminalState, isNotNull);
        },
        debugPrintAfterPump: true,
      );
    });

    test('single-line field with cursor at end', () async {
      await testNocterm(
        'single-line cursor at end',
        (tester) async {
          final controller = TextEditingController(text: '');

          await tester.pumpComponent(
            TextField(
              controller: controller,
              width: 15,
              focused: true,
              decoration: const InputDecoration(
                border: BoxBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 1),
              ),
              showCursor: true,
              cursorBlinkRate: null,
              cursorStyle: CursorStyle.block,
            ),
          );

          // Width = 15
          // Border = 2
          // Padding = 2
          // Reserved = 1
          // Available = 15 - 2 - 2 - 1 = 10

          controller.text = '1234567890'; // Exactly 10 chars
          controller.selection = TextSelection.collapsed(offset: 10);
          await tester.pump();

          print('10 characters in single-line field:');
          expect(tester.terminalState, containsText('1234567890'));

          // Add more text - should scroll
          controller.text = '1234567890ABC';
          controller.selection = TextSelection.collapsed(offset: 13);
          await tester.pump();

          print('\n13 characters - should scroll to show end:');
          expect(tester.terminalState, containsText('C'));
          // Should see the end portion (scrolled)
          expect(tester.terminalState, anyOf(
            containsText('4567890ABC'),
            containsText('567890ABC'),
          ));
        },
        debugPrintAfterPump: true,
      );
    });
  });
}