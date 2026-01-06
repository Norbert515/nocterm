import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Flex error cases', () {
    test('Column with Expanded child in unbounded height should error', () async {
      await testNocterm(
        'expanded in unbounded column',
        (tester) async {
          print(
            '\n=== Testing Expanded in unbounded Column (should error) ===',
          );
          print(
            'Note: Error is caught by RenderObject and displayed as layout error',
          );

          await tester.pumpComponent(
            Column(
              children: [
                Container(
                  width: 20,
                  height: 3,
                  color: Colors.red,
                  child: Text('Top', style: TextStyle(color: Colors.white)),
                ),
                // This inner Column has an Expanded child and receives unbounded height
                Column(
                  children: [
                    Container(
                      width: 20,
                      height: 2,
                      color: Colors.green,
                      child: Text('A', style: TextStyle(color: Colors.white)),
                    ),
                    // This Expanded should cause an error
                    Expanded(
                      child: Container(
                        width: 20,
                        color: Colors.yellow,
                        child: Text(
                          'Expanded',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 20,
                  height: 3,
                  color: Colors.magenta,
                  child: Text('Bot', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );

          // The error is caught and handled, showing "Layout Error" box
          // This is expected behavior
          expect(tester.terminalState, containsText('Layout'));
          expect(tester.terminalState, containsText('Error'));
        },
        debugPrintAfterPump: true, // Show the error display
      );
    });

    test('Row with Expanded child in unbounded width should error', () async {
      await testNocterm(
        'expanded in unbounded row',
        (tester) async {
          print('\n=== Testing Expanded in unbounded Row (should error) ===');
          print(
            'Note: Error is caught by RenderObject and displayed as layout error',
          );

          await tester.pumpComponent(
            Row(
              children: [
                Container(
                  width: 5,
                  height: 10,
                  color: Colors.red,
                  child: Text('L', style: TextStyle(color: Colors.white)),
                ),
                // This inner Row has an Expanded child and receives unbounded width
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 10,
                      color: Colors.green,
                      child: Text('A', style: TextStyle(color: Colors.white)),
                    ),
                    // This Expanded should cause an error
                    Expanded(
                      child: Container(
                        height: 10,
                        color: Colors.yellow,
                        child: Text(
                          'Exp',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 5,
                  height: 10,
                  color: Colors.magenta,
                  child: Text('R', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );

          // The error is caught and handled, showing "Layout Error" box
          // This is expected behavior
          expect(tester.terminalState, containsText('Layout'));
          expect(tester.terminalState, containsText('Error'));
        },
        debugPrintAfterPump: true, // Show the error display
      );
    });

    test(
      'Column with MainAxisSize.max in unbounded height should error',
      () async {
        await testNocterm('mainAxisSize.max in unbounded', (tester) async {
          print(
            '\n=== Testing MainAxisSize.max in unbounded Column (should error) ===',
          );

          bool errorThrown = false;
          String? errorMessage;

          try {
            await tester.pumpComponent(
              Column(
                children: [
                  // Inner Column with MainAxisSize.max (default) should error
                  Column(
                    mainAxisSize:
                        MainAxisSize.max, // Explicit, but this is the default
                    children: [
                      Container(
                        width: 20,
                        height: 3,
                        color: Colors.red,
                        child: Text(
                          'Child',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          } catch (e) {
            errorThrown = true;
            errorMessage = e.toString();
            print('Expected error thrown: $errorMessage');
          }

          // In Flutter, this would NOT error because there are no flex children
          // Our implementation currently allows this too
          expect(
            errorThrown,
            isFalse,
            reason: 'Should NOT error when no flex children',
          );
        }, debugPrintAfterPump: true);
      },
    );

    test(
      'Column with MainAxisSize.min in unbounded height should work',
      () async {
        await testNocterm('mainAxisSize.min in unbounded', (tester) async {
          print(
            '\n=== Testing MainAxisSize.min in unbounded Column (should work) ===',
          );

          await tester.pumpComponent(
            Column(
              children: [
                Container(
                  width: 20,
                  height: 3,
                  color: Colors.red,
                  child: Text('Top', style: TextStyle(color: Colors.white)),
                ),
                // Inner Column with MainAxisSize.min should shrink-wrap
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 2,
                      color: Colors.green,
                      child: Text('A', style: TextStyle(color: Colors.white)),
                    ),
                    Container(
                      width: 20,
                      height: 2,
                      color: Colors.yellow,
                      child: Text('B', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                Container(
                  width: 20,
                  height: 3,
                  color: Colors.magenta,
                  child: Text('Bot', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );

          // Should render without errors
          expect(tester.terminalState, containsText('Top'));
          expect(tester.terminalState, containsText('A'));
          expect(tester.terminalState, containsText('B'));
          expect(tester.terminalState, containsText('Bot'));
        }, debugPrintAfterPump: true);
      },
    );
  });
}
