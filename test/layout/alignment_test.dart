import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

void main() {
  group('Text Alignment', () {
    test('center alignment', () async {
      await testNocterm('center aligned text', (tester) async {
        await tester.pumpComponent(
          DecoratedBox(
            decoration: BoxDecoration(
              border: BoxBorder.all(
                color: Color.fromRGB(255, 255, 255),
                width: 1,
              ),
            ),
            child: SizedBox(
              width: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text('No emoji text here'),
                  Text('✨ With emoji here'),
                  Text('Regular text again'),
                  Text('🚀 Another emoji'),
                  Text('Mixed 💻 text'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('No emoji text here'));
        expect(tester.terminalState, containsText('✨ With emoji here'));
        expect(tester.terminalState, containsText('Regular text again'));
        expect(tester.terminalState, containsText('🚀 Another emoji'));
        expect(tester.terminalState, containsText('Mixed 💻 text'));
      });
    });

    test('left alignment', () async {
      await testNocterm('left aligned text', (tester) async {
        await tester.pumpComponent(
          DecoratedBox(
            decoration: BoxDecoration(
              border: BoxBorder.all(
                color: Color.fromRGB(255, 255, 255),
                width: 1,
              ),
            ),
            child: SizedBox(
              width: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Left aligned'),
                  Text('✨ With emoji'),
                  Text('Regular text'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Left aligned'));
        expect(tester.terminalState, containsText('✨ With emoji'));
        expect(tester.terminalState, containsText('Regular text'));
      });
    });

    test('right alignment', () async {
      await testNocterm('right aligned text', (tester) async {
        await tester.pumpComponent(
          DecoratedBox(
            decoration: BoxDecoration(
              border: BoxBorder.all(
                color: Color.fromRGB(255, 255, 255),
                width: 1,
              ),
            ),
            child: SizedBox(
              width: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('Right aligned'),
                  Text('✨ With emoji'),
                  Text('Regular text'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Right aligned'));
        expect(tester.terminalState, containsText('✨ With emoji'));
        expect(tester.terminalState, containsText('Regular text'));
      });
    });

    test('all alignments visual test', () async {
      await testNocterm(
        'all alignments visual',
        (tester) async {
          await tester.pumpComponent(
            Row(
              children: [
                // Center alignment
                Container(
                  width: 15,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.white),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [Text('Center'), Text('✨')],
                  ),
                ),
                SizedBox(width: 1),
                // Left alignment
                Container(
                  width: 15,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.white),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [Text('Left'), Text('✨')],
                  ),
                ),
                SizedBox(width: 1),
                // Right alignment
                Container(
                  width: 15,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.white),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [Text('Right'), Text('✨')],
                  ),
                ),
              ],
            ),
          );

          // Verify all sections are rendered
          expect(tester.terminalState, containsText('Center'));
          expect(tester.terminalState, containsText('Left'));
          expect(tester.terminalState, containsText('Right'));
        },
        // debugPrintAfterPump: true, // Uncomment for visual debugging
      );
    });
  });
}
