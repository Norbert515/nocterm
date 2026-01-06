import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

void main() {
  group('Text Centering', () {
    test('mathematical centering proof', () async {
      await testNocterm('centering proof', (tester) async {
        await tester.pumpComponent(
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: BoxBorder.all(
                  color: Color.fromRGB(255, 255, 255),
                  width: 1,
                ),
              ),
              child: SizedBox(
                width: 45,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    // Regular text - 12 chars
                    Text('Hello World!'),
                    // Emoji text - also 12 display columns
                    Text('✨ Features:'),
                    // Both should center at same position
                    Text('Both texts are 12 columns wide'),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Hello World!'));
        expect(tester.terminalState, containsText('✨ Features:'));
        expect(
          tester.terminalState,
          containsText('Both texts are 12 columns wide'),
        );
      });
    });

    test('visual centering with emojis', () async {
      await testNocterm('visual centering', (tester) async {
        await tester.pumpComponent(
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: BoxBorder.all(
                  color: Color.fromRGB(255, 255, 255),
                  width: 1,
                ),
              ),
              child: SizedBox(
                width: 45,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text('No emoji here'),
                    Text('✨ Emoji at start'),
                    Text('Emoji at end ✨'),
                    Text('In ✨ middle'),
                    Text('✨ Both ends ✨'),
                    Text('Multiple ✨✨✨ emojis'),
                  ],
                ),
              ),
            ),
          ),
        );

        // All text should be rendered
        expect(tester.terminalState, containsText('No emoji here'));
        expect(tester.terminalState, containsText('✨ Emoji at start'));
        expect(tester.terminalState, containsText('Emoji at end ✨'));
        expect(tester.terminalState, containsText('In ✨ middle'));
        expect(tester.terminalState, containsText('✨ Both ends ✨'));
        expect(tester.terminalState, containsText('Multiple ✨✨✨ emojis'));
      });
    });

    test('centering in different width containers', () async {
      await testNocterm('different widths', (tester) async {
        await tester.pumpComponent(
          Row(
            children: [
              // Narrow container
              Container(
                width: 15,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.blue),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [Text('Short'), Text('✨')],
                ),
              ),
              SizedBox(width: 1),
              // Medium container
              Container(
                width: 25,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.green),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [Text('Medium text'), Text('✨ Emoji')],
                ),
              ),
              SizedBox(width: 1),
              // Wide container
              Container(
                width: 30,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.red),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [Text('Wide text'), Text('✨ Wide')],
                ),
              ),
            ],
          ),
        );

        expect(tester.terminalState, containsText('Short'));
        expect(tester.terminalState, containsText('Medium text'));
        expect(tester.terminalState, containsText('Wide text'));
      });
    });

    test('centering with padding', () async {
      await testNocterm('centering with padding', (tester) async {
        await tester.pumpComponent(
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.cyan),
              ),
              child: Container(
                width: 40,
                padding: const EdgeInsets.all(2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text('Padded center'),
                    Text('✨ With emoji'),
                    Text('Still centered'),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Padded center'));
        expect(tester.terminalState, containsText('✨ With emoji'));
        expect(tester.terminalState, containsText('Still centered'));
      });
    });

    test('ruler alignment test', () async {
      await testNocterm('ruler alignment', (tester) async {
        await tester.pumpComponent(
          DecoratedBox(
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.white),
            ),
            child: SizedBox(
              width: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  // Ruler for visual reference
                  Text('1234567890123456789012345678901234567890'),
                  Text('────────────────────────────────────────'),
                  Text('Centered text'),
                  Text('✨ Emoji center'),
                  Text('12345'),
                  Text('✨✨✨'),
                ],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Centered text'));
        expect(tester.terminalState, containsText('✨ Emoji center'));
        expect(tester.terminalState, containsText('12345'));
      });
    });

    // Visual test for manual inspection
    test(
      'centering visual test',
      skip: 'Run with debugPrintAfterPump for visual inspection',
      () async {
        await testNocterm(
          'centering visual',
          (tester) async {
            await tester.pumpComponent(
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '=== Centering Test ===',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.cyan, width: 1),
                      ),
                      child: SizedBox(
                        width: 40,
                        child: Column(
                          children: [
                            // Show ruler
                            Text(
                              '0123456789012345678901234567890123456789',
                              style: TextStyle(color: Colors.gray),
                            ),
                            Text(
                              '────────────────────────────────────────',
                              style: TextStyle(color: Colors.gray),
                            ),

                            // Center aligned
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: const [
                                Text(
                                  '=== CENTER ===',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('Plain text'),
                                Text('✨ With emoji'),
                                Text('Mixed ✨ text'),
                              ],
                            ),

                            SizedBox(height: 1),

                            // Left aligned
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  '=== LEFT ===',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('Plain text'),
                                Text('✨ With emoji'),
                                Text('Mixed ✨ text'),
                              ],
                            ),

                            SizedBox(height: 1),

                            // Right aligned
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: const [
                                Text(
                                  '=== RIGHT ===',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('Plain text'),
                                Text('✨ With emoji'),
                                Text('Mixed ✨ text'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );

            expect(tester.terminalState, containsText('Centering Test'));
          },
          // debugPrintAfterPump: true, // Uncomment to see visual output
        );
      },
    );
  });
}
