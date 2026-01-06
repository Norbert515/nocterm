import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

void main() {
  group('TextField Cursor Styles', () {
    test('visual development - all cursor styles', () async {
      await testNocterm(
        'cursor styles visual test',
        (tester) async {
          // Create a column with different cursor styles
          await tester.pumpComponent(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TextField Cursor Styles Demo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
                const SizedBox(height: 2),

                // Block cursor (default)
                Text(
                  'Block Cursor (default):',
                  style: TextStyle(color: Colors.yellow),
                ),
                TextField(
                  controller: TextEditingController(text: 'Block cursor'),
                  focused: true,
                  cursorStyle: CursorStyle.block,
                  cursorColor: Colors.white,
                  width: 30,
                  decoration: InputDecoration(
                    border: BoxBorder.all(color: Colors.gray),
                    focusedBorder: BoxBorder.all(color: Colors.green),
                  ),
                ),
                const SizedBox(height: 2),

                // Underline cursor
                Text(
                  'Underline Cursor:',
                  style: TextStyle(color: Colors.yellow),
                ),
                TextField(
                  controller: TextEditingController(text: 'Underline cursor'),
                  cursorStyle: CursorStyle.underline,
                  cursorColor: Colors.cyan,
                  width: 30,
                  decoration: InputDecoration(
                    border: BoxBorder.all(color: Colors.gray),
                  ),
                ),
                const SizedBox(height: 2),

                // Block outline cursor
                Text(
                  'Block Outline Cursor:',
                  style: TextStyle(color: Colors.yellow),
                ),
                TextField(
                  controller: TextEditingController(text: 'Block outline'),
                  cursorStyle: CursorStyle.blockOutline,
                  cursorColor: Colors.red,
                  width: 30,
                  decoration: InputDecoration(
                    border: BoxBorder.all(color: Colors.gray),
                  ),
                ),
              ],
            ),
          );
        },
        debugPrintAfterPump: true, // Enable visual output during development
      );
    });

    test('cursor renders correctly at different positions', () async {
      await testNocterm('cursor position test', (tester) async {
        final controller = TextEditingController(text: 'Hello World');

        // Test cursor at beginning
        controller.selection = const TextSelection.collapsed(offset: 0);
        await tester.pumpComponent(
          TextField(
            controller: controller,
            focused: true,
            cursorStyle: CursorStyle.underline,
            width: 20,
          ),
        );

        print('Cursor at position 0:');
        expect(tester.terminalState, isNotNull);

        // Test cursor at middle
        controller.selection = const TextSelection.collapsed(offset: 5);
        await tester.pumpComponent(
          TextField(
            controller: controller,
            focused: true,
            cursorStyle: CursorStyle.underline,
            width: 20,
          ),
        );

        print('Cursor at position 5:');
        expect(tester.terminalState, isNotNull);

        // Test cursor at end
        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
        await tester.pumpComponent(
          TextField(
            controller: controller,
            focused: true,
            cursorStyle: CursorStyle.underline,
            width: 20,
          ),
        );

        print('Cursor at end:');
        expect(tester.terminalState, isNotNull);
      }, debugPrintAfterPump: true);
    });

    test('empty field shows cursor correctly', () async {
      await testNocterm('empty field cursor test', (tester) async {
        await tester.pumpComponent(
          Column(
            children: [
              Text('Empty fields with different cursor styles:'),
              const SizedBox(height: 1),
              TextField(
                focused: true,
                cursorStyle: CursorStyle.block,
                placeholder: 'Block cursor...',
                width: 25,
              ),
              TextField(
                cursorStyle: CursorStyle.underline,
                placeholder: 'Underline cursor...',
                width: 25,
              ),
              TextField(
                cursorStyle: CursorStyle.blockOutline,
                placeholder: 'Outline cursor...',
                width: 25,
              ),
            ],
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test('cursor style changes dynamically', () async {
      await testNocterm('dynamic cursor style test', (tester) async {
        final controller = TextEditingController(text: 'Dynamic cursor');

        // Start with block cursor
        await tester.pumpComponent(
          TextField(
            controller: controller,
            focused: true,
            cursorStyle: CursorStyle.block,
            width: 20,
          ),
        );

        print('Initial: Block cursor');

        // Change to underline cursor
        await tester.pumpComponent(
          TextField(
            controller: controller,
            focused: true,
            cursorStyle: CursorStyle.underline,
            width: 20,
          ),
        );

        print('Changed to: Underline cursor');
      }, debugPrintAfterPump: true);
    });

    test('non-blinking cursor', () async {
      await testNocterm('non-blinking cursor test', (tester) async {
        await tester.pumpComponent(
          Column(
            children: [
              Text(
                'Non-blinking cursors:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 1),
              Text('Static block cursor:'),
              TextField(
                controller: TextEditingController(text: 'No blinking'),
                focused: true,
                cursorStyle: CursorStyle.block,
                cursorBlinkRate: null, // Non-blinking
                width: 25,
                decoration: InputDecoration(
                  border: BoxBorder.all(color: Colors.gray),
                  focusedBorder: BoxBorder.all(color: Colors.green),
                ),
              ),
              const SizedBox(height: 1),
              Text('Fast blinking cursor (400ms):'),
              TextField(
                controller: TextEditingController(text: 'Fast blink'),
                cursorStyle: CursorStyle.underline,
                cursorBlinkRate: const Duration(milliseconds: 400),
                width: 25,
                decoration: InputDecoration(
                  border: BoxBorder.all(color: Colors.gray),
                ),
              ),
              const SizedBox(height: 1),
              Text('Slow blinking cursor (1500ms):'),
              TextField(
                controller: TextEditingController(text: 'Slow blink'),
                cursorStyle: CursorStyle.block,
                cursorBlinkRate: const Duration(milliseconds: 1500),
                width: 25,
                decoration: InputDecoration(
                  border: BoxBorder.all(color: Colors.gray),
                ),
              ),
            ],
          ),
        );
      }, debugPrintAfterPump: true);
    });
  });
}
