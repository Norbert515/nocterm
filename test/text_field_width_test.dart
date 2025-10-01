import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('TextField Width Calculations', () {
    test('correctly calculates available width with padding and borders', () async {
      await testNocterm(
        'width with padding and borders',
        (tester) async {
          final controller = TextEditingController(text: '');

          await tester.pumpComponent(
            TextField(
              controller: controller,
              width: 20,
              decoration: const InputDecoration(
                border: BoxBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 1),
              ),
            ),
          );

          // Width = 20
          // Border = 2 (1 on each side)
          // Padding = 2 (1 on each side)
          // Reserved for cursor = 1
          // Available content width = 20 - 2 - 2 - 1 = 15

          // Test that we can fit exactly 15 regular characters
          controller.text = 'ABCDEFGHIJKLMNO'; // 15 characters
          await tester.pump();

          // All characters should be visible
          expect(tester.terminalState, containsText('ABCDEFGHIJKLMNO'));

          // Add one more character - should trigger scrolling or wrapping
          controller.text = 'ABCDEFGHIJKLMNOP'; // 16 characters
          controller.selection = TextSelection.collapsed(offset: 16);
          await tester.pump();

          // Should scroll to show cursor at end (or wrap if multi-line)
          // The field should still show 15 characters, scrolled to show the end
          expect(tester.terminalState, containsText('P')); // End character visible
        },
        debugPrintAfterPump: false,
      );
    });

    test('handles Unicode characters with correct visual width', () async {
      await testNocterm(
        'unicode width handling',
        (tester) async {
          final controller = TextEditingController(text: '');

          await tester.pumpComponent(
            TextField(
              controller: controller,
              width: 10,
              decoration: const InputDecoration(
                border: BoxBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 1),
              ),
            ),
          );

          // Available width = 10 - 2 (border) - 2 (padding) - 1 (cursor) = 5

          // Test with emoji (width 2)
          controller.text = '😀😀'; // 2 emojis = 4 visual columns (fits with cursor)
          await tester.pump();

          // All emojis should fit
          expect(tester.terminalState, containsText('😀😀'));

          // Add one more emoji - should trigger scrolling or wrapping
          controller.text = '😀😀😀'; // 3 emojis = 6 visual columns (exceeds 5)
          controller.selection = TextSelection.collapsed(offset: 3);
          await tester.pump();

          // Should scroll, last emoji should be visible
          expect(tester.terminalState, containsText('😀'));
        },
        debugPrintAfterPump: false,
      );
    });

    test('scrolls correctly with mixed width characters', () async {
      await testNocterm(
        'mixed width scrolling',
        (tester) async {
          final controller = TextEditingController(text: '');

          await tester.pumpComponent(
            TextField(
              controller: controller,
              width: 12,
              decoration: const InputDecoration(
                border: BoxBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 1),
              ),
            ),
          );

          // Available width = 12 - 2 (border) - 2 (padding) - 1 (cursor) = 7

          // Mix of ASCII and emoji
          controller.text = 'AB😀CD'; // A(1) + B(1) + 😀(2) + C(1) + D(1) = 6
          await tester.pump();

          // Should fit exactly
          expect(tester.terminalState, containsText('AB😀CD'));

          // Move cursor to beginning and add character
          controller.text = 'XAB😀CD'; // Now 7 visual columns
          controller.selection = TextSelection.collapsed(offset: 0);
          await tester.pump();

          // Should scroll to show cursor at beginning
          // The display should start from the beginning
          expect(tester.terminalState, containsText('X'));
        },
        debugPrintAfterPump: false,
      );
    });

    test('horizontal scrolling maintains cursor visibility', () async {
      await testNocterm(
        'cursor visibility during scrolling',
        (tester) async {
          final controller = TextEditingController(text: '');

          await tester.pumpComponent(
            TextField(
              controller: controller,
              width: 8,
              focused: true,
              decoration: const InputDecoration(
                border: BoxBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 1),
              ),
              showCursor: true,
              cursorBlinkRate: null, // Static cursor
            ),
          );

          // Available width = 8 - 2 (border) - 2 (padding) - 1 (cursor) = 3

          // Add text longer than visible area
          controller.text = 'ABCDEFGHIJ'; // 10 characters
          controller.selection = TextSelection.collapsed(offset: 10);
          await tester.pump();

          // Cursor should be at the end and visible
          // Should show the last 3 characters plus cursor
          expect(tester.terminalState, containsText('J')); // Last character visible

          // Move cursor to middle
          controller.selection = TextSelection.collapsed(offset: 5);
          await tester.pump();

          // Should scroll to show cursor in middle
          // Character at position 5 is 'F' (0-indexed)
          expect(tester.terminalState, containsText('F'));

          // Move cursor to beginning
          controller.selection = TextSelection.collapsed(offset: 0);
          await tester.pump();

          // Should scroll to show cursor at beginning
          expect(tester.terminalState, containsText('A'));
        },
        debugPrintAfterPump: false,
      );
    });
  });
}