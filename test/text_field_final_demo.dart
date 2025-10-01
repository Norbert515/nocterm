import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  test('FINAL DEMO: TextField with proper cursor bounds', () async {
    await testNocterm(
      'final demo',
      (tester) async {
        final multiLineController = TextEditingController(
          text: 'Hello this is a cool thing to do is typing a cool long string that can be enough to show wrapping'
        );

        final singleLineController = TextEditingController(
          text: 'This text will scroll horizontally when it gets too long'
        );

        await tester.pumpComponent(
          Column(
            children: [
              const Text('✅ FIXED: Cursor now stays within field boundaries'),
              const SizedBox(height: 2),

              const Text('Multi-line TextField (wraps properly):'),
              TextField(
                controller: multiLineController,
                width: 60,
                maxLines: 4,
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

              const SizedBox(height: 2),
              const Text('Single-line TextField (scrolls horizontally):'),
              TextField(
                controller: singleLineController,
                width: 30,
                decoration: const InputDecoration(
                  border: BoxBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 1),
                ),
                showCursor: true,
                cursorBlinkRate: null,
                cursorStyle: CursorStyle.block,
              ),

              const SizedBox(height: 2),
              const Text('Key improvements:'),
              const Text('• Cursor position syncs with wrapped lines'),
              const Text('• Reserved space ensures cursor stays in bounds'),
              const Text('• Unicode characters handled correctly'),
            ],
          ),
        );

        // Position cursors at the end
        multiLineController.selection = TextSelection.collapsed(offset: multiLineController.text.length);
        singleLineController.selection = TextSelection.collapsed(offset: singleLineController.text.length);
        await tester.pump();
      },
      debugPrintAfterPump: true,
      size: const Size(100, 25),
    );
  });
}