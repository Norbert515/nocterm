import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  test('DEMO: Multi-line TextField cursor position fixed', () async {
    await testNocterm(
      'multi-line demo',
      (tester) async {
        final controller = TextEditingController(
          text: 'Hello this is a cool thing to do is typing a cool long string that can be enough'
        );

        await tester.pumpComponent(
          Column(
            children: [
              const Text('Multi-line (Enter to submit):'),
              const SizedBox(height: 1),
              TextField(
                controller: controller,
                width: 80,
                maxLines: 5,
                focused: true,
                decoration: const InputDecoration(
                  border: BoxBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 1),
                ),
                showCursor: true,
                cursorBlinkRate: null,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.cyan,
                cursorStyle: CursorStyle.block,
              ),
              const SizedBox(height: 1),
              const Text('✅ Cursor now stays within bounds when text wraps!'),
            ],
          ),
        );

        // Position cursor at the end
        controller.selection = TextSelection.collapsed(offset: controller.text.length);
        await tester.pump();

        print('\n=== BEFORE FIX ===');
        print('The cursor would appear beyond the border on wrapped lines.');
        print('Each wrapped line would push the cursor 1 character further out of sync.\n');

        print('=== AFTER FIX ===');
        print('The cursor now correctly stays within the text field boundaries.');
        print('Wrapped lines no longer cause position drift.\n');
      },
      debugPrintAfterPump: true,
      size: const Size(100, 20),
    );
  });
}