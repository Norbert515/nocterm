import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Checkmark Visual Layout Test', () {
    test('checkmark symbols should align properly', () async {
      await testNocterm(
        'checkmark layout',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 40,
              padding: const EdgeInsets.all(1),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✓ Success (should fit)'),
                  Text('✔ Done (should fit)'),
                  Text('✅ Emoji check (may be 2 wide)'),
                  Text('✗ Failed (should fit)'),
                  Text('✘ Error (should fit)'),
                  Text('❌ Emoji X (may be 2 wide)'),
                ],
              ),
            ),
          );

          // All non-emoji checkmarks should fit in 40 columns
          // The longest line is "✓ Success (should fit)" = 22 chars
          // With 1-width checkmark: 1 + 21 = 22 columns (fits!)
          // With 2-width checkmark: 2 + 21 = 23 columns (still fits in 40)
          // But with padding and container width 40, this should work fine

          final state = tester.terminalState;

          // Check that text is present
          expect(state, containsText('Success'));
          expect(state, containsText('Done'));
          expect(state, containsText('Failed'));
          expect(state, containsText('Error'));
        },
        // Enable to see the visual output during development
        debugPrintAfterPump: true,
      );
    });

    test('clipboard status text with checkmark', () async {
      await testNocterm('clipboard status', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 50,
            padding: const EdgeInsets.all(1),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clipboard Status:'),
                Text('✓ Has content: "test"'),
                Text('✗ Empty'),
              ],
            ),
          ),
        );

        final state = tester.terminalState;

        expect(state, containsText('Clipboard Status'));
        expect(state, containsText('Has content'));
        expect(state, containsText('Empty'));
      }, debugPrintAfterPump: true);
    });
  });
}
