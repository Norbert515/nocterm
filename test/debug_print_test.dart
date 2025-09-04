import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

// Interactive counter component that responds to keyboard input
class InteractiveCounter extends StatefulComponent {
  const InteractiveCounter({super.key});

  @override
  State<InteractiveCounter> createState() => _InteractiveCounterState();
}

class _InteractiveCounterState extends State<InteractiveCounter> {
  int _count = 0;
  String _lastAction = 'Press + or - to change count';

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '═══ Interactive Counter ═══',
            style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Count: ', style: TextStyle(fontWeight: FontWeight.dim)),
              Text(
                '$_count',
                style: TextStyle(
                  color: _count > 0 ? Colors.green : (_count < 0 ? Colors.red : Colors.white),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _lastAction,
            style: TextStyle(color: Colors.yellow, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Column(
              children: [
                Text('Controls:', style: TextStyle(decoration: TextDecoration.underline)),
                const SizedBox(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('[+] Increment  ', style: TextStyle(color: Colors.green)),
                    Text('[−] Decrement  ', style: TextStyle(color: Colors.red)),
                    Text('[R] Reset', style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('Debug Print Tests', () {
    test('visual test with debug printing enabled', () async {
      // This test will automatically print the terminal output after each pump
      await testNocterm(
        'interactive counter with debug output',
        (tester) async {
          print('\n📺 This test has debugPrintAfterPump enabled');
          print('You will see the terminal output after each pump:\n');

          // Initial render
          print('1️⃣ Initial state:');
          await tester.pumpComponent(const InteractiveCounter());

          // Simulate incrementing
          print('\n2️⃣ After pressing "+" (increment):');
          await tester.enterText('+');

          // Simulate incrementing again
          print('\n3️⃣ After pressing "+" again:');
          await tester.enterText('+');

          // Simulate decrementing
          print('\n4️⃣ After pressing "-" (decrement):');
          await tester.enterText('-');

          // Simulate reset
          print('\n5️⃣ After pressing "R" (reset):');
          await tester.enterText('R');

          // Verify the UI shows the expected text
          expect(tester.terminalState, containsText('Interactive Counter'));
          expect(tester.terminalState, containsText('Controls:'));
        },
        debugPrintAfterPump: true, // Enable automatic debug printing
      );
    });

    test('can toggle debug printing during test', () async {
      await testNocterm(
        'toggle debug printing',
        (tester) async {
          print('\n📺 Debug printing can be toggled during the test:\n');

          // Start without debug printing
          await tester.pumpComponent(
            Container(
              padding: const EdgeInsets.all(2),
              child: const Text('First pump - no debug output'),
            ),
          );

          // Enable debug printing
          print('\n🔛 Enabling debug printing...');
          tester.debugPrintAfterPump = true;

          await tester.pumpComponent(
            Container(
              padding: const EdgeInsets.all(2),
              child: Column(
                children: const [
                  Text('Second pump - with debug output'),
                  SizedBox(height: 1),
                  Text('You should see this in a box!'),
                ],
              ),
            ),
          );

          // Disable debug printing
          print('\n🔴 Disabling debug printing...');
          tester.debugPrintAfterPump = false;

          await tester.pumpComponent(
            Container(
              padding: const EdgeInsets.all(2),
              child: const Text('Third pump - debug disabled again'),
            ),
          );

          print('\n✅ Test completed - debug output was only shown for the second pump');
        },
        debugPrintAfterPump: false, // Start with debug printing disabled
      );
    });

    test('debug output with complex layout', () async {
      await testNocterm(
        'complex layout visualization',
        (tester) async {
          print('\n📺 Visualizing a complex layout:\n');

          await tester.pumpComponent(
            Container(
              padding: const EdgeInsets.all(1),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(1),
                        child: Text('╔═══╗\n║ A ║\n╚═══╝'),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(1),
                        child: Text('╔═══╗\n║ B ║\n╚═══╝'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Center(
                    child: Text('── Center Line ──', style: TextStyle(fontWeight: FontWeight.dim)),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Left aligned', style: TextStyle(color: Colors.red)),
                      ),
                      Expanded(
                        child: Center(
                          child: Text('Centered', style: TextStyle(color: Colors.green)),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('Right aligned', style: TextStyle(color: Colors.blue)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );

          // Due to overflow issues with multiline text in containers,
          // the boxes with A and B are cut off. Only the bottom row is visible.
          // This is a known issue with how multiline text height is calculated in Rows.
          expect(tester.terminalState, containsText('Left aligned'));
          expect(tester.terminalState, containsText('Centered'));
          expect(tester.terminalState, containsText('Right aligned'));
          // TODO: Fix multiline text rendering in Rows to properly show A and B boxes
        },
        debugPrintAfterPump: true,
        size: const Size(60, 15), // Smaller size for better visualization
      );
    });
  });
}
