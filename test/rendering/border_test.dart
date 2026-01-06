import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart' hide isNotEmpty;

void main() {
  group('Border Rendering', () {
    test('minimum width border containers', () async {
      await testNocterm('minimum width borders', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Width of 1 - edge case
                Container(
                  width: 1,
                  height: 3,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.cyan),
                  ),
                ),
                SizedBox(height: 1),
                // Width of 2
                Container(
                  width: 2,
                  height: 3,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.green),
                  ),
                ),
                SizedBox(height: 1),
                // Width of 3
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.yellow),
                  ),
                ),
              ],
            ),
          ),
        );

        // All containers should render without errors
        final snapshot = tester.toSnapshot();
        expect(snapshot, isNotEmpty);
      });
    });

    test('different border widths', () async {
      await testNocterm('border widths', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Single line border
                Container(
                  width: 20,
                  height: 5,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.blue, width: 1),
                  ),
                  child: Center(child: Text('Single')),
                ),
                SizedBox(height: 1),
                // Double line border
                Container(
                  width: 20,
                  height: 5,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.red, width: 2),
                  ),
                  child: Center(child: Text('Double')),
                ),
              ],
            ),
          ),
        );

        expect(tester.terminalState, containsText('Single'));
        expect(tester.terminalState, containsText('Double'));
      });
    });

    test('nested borders', () async {
      await testNocterm('nested borders', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 30,
              height: 10,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.red),
              ),
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.green),
                ),
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.blue),
                  ),
                  child: Center(child: Text('Nested')),
                ),
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Nested'));
      });
    });

    test('borders with different colors', () async {
      await testNocterm('colored borders', (tester) async {
        await tester.pumpComponent(
          Column(
            children: [
              Container(
                width: 15,
                height: 3,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.red),
                ),
                child: Center(child: Text('Red')),
              ),
              Container(
                width: 15,
                height: 3,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.green),
                ),
                child: Center(child: Text('Green')),
              ),
              Container(
                width: 15,
                height: 3,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.blue),
                ),
                child: Center(child: Text('Blue')),
              ),
              Container(
                width: 15,
                height: 3,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.cyan),
                ),
                child: Center(child: Text('Cyan')),
              ),
            ],
          ),
        );

        expect(tester.terminalState, containsText('Red'));
        expect(tester.terminalState, containsText('Green'));
        expect(tester.terminalState, containsText('Blue'));
        expect(tester.terminalState, containsText('Cyan'));
      });
    });

    test('border with background color', () async {
      await testNocterm('border with background', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 25,
              height: 7,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.white),
                color: Color.fromRGB(0, 0, 64), // Dark blue background
              ),
              child: Center(
                child: Text(
                  'Background',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Background'));
      });
    });

    test('asymmetric border containers', () async {
      await testNocterm('asymmetric borders', (tester) async {
        await tester.pumpComponent(
          Column(
            children: [
              // Very wide and short
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.magenta),
                ),
              ),
              SizedBox(height: 1),
              // Very tall and narrow
              Container(
                width: 5,
                height: 8,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.yellow),
                ),
              ),
            ],
          ),
        );

        final snapshot = tester.toSnapshot();
        expect(snapshot, isNotEmpty);
      });
    });

    // Visual test for manual inspection
    test(
      'border visual test',
      skip: 'Run with debugPrintAfterPump for visual inspection',
      () async {
        await testNocterm(
          'border visual',
          (tester) async {
            await tester.pumpComponent(
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '=== Border Test ===',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Minimum sizes
                        Column(
                          children: [
                            Text('Min sizes:'),
                            Container(
                              width: 1,
                              height: 1,
                              decoration: BoxDecoration(
                                border: BoxBorder.all(color: Colors.red),
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 2,
                              decoration: BoxDecoration(
                                border: BoxBorder.all(color: Colors.green),
                              ),
                            ),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                border: BoxBorder.all(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(width: 3),

                        // Different widths
                        Column(
                          children: [
                            Text('Border widths:'),
                            Container(
                              width: 15,
                              height: 3,
                              decoration: BoxDecoration(
                                border: BoxBorder.all(
                                  color: Colors.cyan,
                                  width: 1,
                                ),
                              ),
                              child: Center(child: Text('W=1')),
                            ),
                            SizedBox(height: 1),
                            Container(
                              width: 15,
                              height: 3,
                              decoration: BoxDecoration(
                                border: BoxBorder.all(
                                  color: Colors.magenta,
                                  width: 2,
                                ),
                              ),
                              child: Center(child: Text('W=2')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );

            expect(tester.terminalState, containsText('Border Test'));
          },
          // debugPrintAfterPump: true, // Uncomment to see visual output
        );
      },
    );
  });
}
