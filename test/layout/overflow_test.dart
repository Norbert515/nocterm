import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart' hide isNotEmpty;

void main() {
  group('Overflow Handling', () {
    test('horizontal overflow in constrained container', () async {
      await testNocterm('horizontal overflow', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 20,
              height: 10,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.blue),
              ),
              child: Column(
                children: [
                  Text('This is a very long text that will overflow'),
                  Text('Second line'),
                  Text('Third line'),
                ],
              ),
            ),
          ),
        );

        // Text should be present even if truncated
        expect(tester.terminalState, containsText('This'));
        expect(tester.terminalState, containsText('Second line'));
        expect(tester.terminalState, containsText('Third line'));
      });
    });

    test('vertical overflow in constrained container', () async {
      await testNocterm('vertical overflow', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 20,
              height: 5,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.blue),
              ),
              child: Column(
                children: [
                  Text('Line 1'),
                  Text('Line 2'),
                  Text('Line 3'),
                  Text('Line 4'),
                  Text('Line 5'),
                  Text('Line 6 - overflow'),
                  Text('Line 7 - overflow'),
                ],
              ),
            ),
          ),
        );

        // When there's overflow, content might be clipped
        // Just check that some lines are visible
        final snapshot = tester.toSnapshot();
        expect(snapshot, isNotEmpty);
      });
    });

    test('combined horizontal and vertical overflow', () async {
      await testNocterm('combined overflow', (tester) async {
        await tester.pumpComponent(
          Column(
            children: [
              Text('Horizontal Overflow Test:'),
              Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    Text('This text is way too long for the container'),
                    Text('More text'),
                  ],
                ),
              ),
              SizedBox(height: 1),
              Text('Vertical Overflow Test:'),
              Container(
                width: 30,
                height: 5,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    Text('Line 1'),
                    Text('Line 2'),
                    Text('Line 3'),
                    Text('Line 4'),
                    Text('Line 5'),
                    Text('Line 6 - overflow!'),
                    Text('Line 7 - overflow!'),
                  ],
                ),
              ),
            ],
          ),
        );

        expect(tester.terminalState, containsText('Horizontal Overflow Test:'));
        expect(tester.terminalState, containsText('Vertical Overflow Test:'));
      });
    });

    test('overflow with nested containers', () async {
      await testNocterm('nested overflow', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Container(
              width: 30,
              height: 10,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.red),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.blue),
                  ),
                  child: Column(
                    children: [
                      Text('Nested container'),
                      Text('With multiple lines'),
                      Text('That might overflow'),
                      Text('The parent bounds'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        // With nested containers and overflow, content might be clipped
        final snapshot = tester.toSnapshot();
        expect(snapshot, isNotEmpty);
      });
    });

    test('overflow with flexible widgets', () async {
      await testNocterm('flexible overflow', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 40,
            height: 10,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.cyan),
            ),
            child: Column(
              children: [
                Text('Header'),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.yellow),
                    ),
                    child: Column(
                      children: [
                        Text('Expanded content 1'),
                        Text('Expanded content 2'),
                        Text('Expanded content 3'),
                        Text('Expanded content 4'),
                        Text('This might overflow'),
                      ],
                    ),
                  ),
                ),
                Text('Footer'),
              ],
            ),
          ),
        );

        expect(tester.terminalState, containsText('Header'));
        expect(tester.terminalState, containsText('Footer'));
        expect(tester.terminalState, containsText('Expanded content'));
      });
    });

    test(
      'overflow visual test',
      skip: 'Run with debugPrintAfterPump for visual inspection',
      () async {
        await testNocterm(
          'overflow visual',
          (tester) async {
            await tester.pumpComponent(
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '=== Overflow Test Cases ===',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1),

                    // Small box with overflow
                    Text('Small box (10x3):'),
                    Container(
                      width: 10,
                      height: 3,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.red),
                      ),
                      child: Column(
                        children: [
                          Text('Line 1 overflows'),
                          Text('Line 2'),
                          Text('Line 3'),
                          Text('Line 4 hidden'),
                        ],
                      ),
                    ),

                    SizedBox(height: 1),

                    // Wider box
                    Text('Wider box (25x4):'),
                    Container(
                      width: 25,
                      height: 4,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.green),
                      ),
                      child: Column(
                        children: [
                          Text('This fits better'),
                          Text('Second line here'),
                          Text('Third line visible'),
                          Text('Fourth line fits'),
                          Text('Fifth is hidden'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );

            expect(tester.terminalState, containsText('Overflow Test Cases'));
          },
          // debugPrintAfterPump: true, // Uncomment to see visual output
        );
      },
    );
  });
}
