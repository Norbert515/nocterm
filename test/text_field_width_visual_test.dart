import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  test('visual test - TextField width with borders and padding', () async {
    await testNocterm(
      'visual width test',
      (tester) async {
        final controller = TextEditingController(text: 'Hello World! This is a long text that should scroll.');

        await tester.pumpComponent(
          Column(
            children: [
              const Text('TextField with width=30, border, padding:'),
              const SizedBox(height: 1),
              TextField(
                controller: controller,
                width: 30,
                focused: true,
                decoration: const InputDecoration(
                  border: BoxBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 1),
                ),
                showCursor: true,
                cursorBlinkRate: null,
              ),
              const SizedBox(height: 2),
              const Text('Available width = 30 - 2(border) - 2(padding) = 26'),
              const SizedBox(height: 1),
              const Text('Test with emoji:'),
              const SizedBox(height: 1),
              TextField(
                controller: TextEditingController(text: 'Hi 😀👋 World 🌍🎉'),
                width: 20,
                decoration: const InputDecoration(
                  border: BoxBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 1),
                ),
              ),
            ],
          ),
        );

        // Move cursor to end to test scrolling
        controller.selection = TextSelection.collapsed(offset: controller.text.length);
        await tester.pump();

        print('Terminal output:');
        print(tester.terminalState.toString());
      },
      debugPrintAfterPump: true,
    );
  });
}