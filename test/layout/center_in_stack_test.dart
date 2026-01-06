import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Center in Stack', () {
    test('Center should properly center its child within Stack', () async {
      await testNocterm('center in stack', (tester) async {
        // A 20x10 Stack with a Center containing a small "X" Text
        // The "X" should be centered in the Stack, not at top-left
        await tester.pumpComponent(
          Container(
            width: 20,
            height: 10,
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.solid),
            ),
            child: const Stack(children: [Center(child: Text('X'))]),
          ),
        );

        // Find where X is located
        final matches = tester.terminalState.findText('X');
        expect(
          matches.isNotEmpty,
          isTrue,
          reason: 'Should find X in the output',
        );

        final xMatch = matches.first;
        print('Found X at row=${xMatch.y}, col=${xMatch.x}');

        // The container is 20x10, so center should be around:
        // - Column: ~9-10 (half of 20, accounting for border)
        // - Row: ~4-5 (half of 10, accounting for border)
        // If X is near column 1-2 and row 1-2, centering is broken

        expect(
          xMatch.y,
          greaterThan(2),
          reason: 'X should be centered vertically, not at top',
        );
        expect(
          xMatch.x,
          greaterThan(5),
          reason: 'X should be centered horizontally, not at left',
        );
      }, debugPrintAfterPump: true);
    });

    test('Center should expand to fill bounded constraints', () async {
      await testNocterm('center expands in bounded', (tester) async {
        // When inside a Stack with bounded constraints,
        // Center should expand to fill the Stack, then center its child
        await tester.pumpComponent(
          Container(
            width: 30,
            height: 8,
            child: Stack(
              children: [
                // This Positioned.fill with Center should work correctly
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(style: BoxBorderStyle.double),
                    ),
                    child: const Center(child: Text('CENTERED')),
                  ),
                ),
              ],
            ),
          ),
        );

        // Find where CENTERED is located
        final matches = tester.terminalState.findText('CENTERED');
        expect(
          matches.isNotEmpty,
          isTrue,
          reason: 'Should find CENTERED in output',
        );

        final match = matches.first;
        print('Found CENTERED at row=${match.y}, col=${match.x}');

        // Should be roughly centered in a 30x8 container
        expect(
          match.y,
          greaterThan(1),
          reason: 'Text should be vertically centered',
        );
        expect(
          match.x,
          greaterThan(5),
          reason: 'Text should be horizontally centered',
        );
      }, debugPrintAfterPump: true);
    });

    test('Center without Stack should still work correctly', () async {
      await testNocterm('standalone center', (tester) async {
        // Verify standalone Center still works
        await tester.pumpComponent(
          Container(
            width: 20,
            height: 6,
            decoration: BoxDecoration(border: BoxBorder.all()),
            child: const Center(child: Text('OK')),
          ),
        );

        // Find where OK is located
        final matches = tester.terminalState.findText('OK');
        expect(
          matches.isNotEmpty,
          isTrue,
          reason: 'Should find OK in the output',
        );

        final match = matches.first;
        print('Found OK at row=${match.y}, col=${match.x}');

        // Should be centered
        expect(
          match.y,
          greaterThan(1),
          reason: 'Text should be vertically centered',
        );
        expect(
          match.x,
          greaterThan(5),
          reason: 'Text should be horizontally centered',
        );
      }, debugPrintAfterPump: true);
    });
  });
}
