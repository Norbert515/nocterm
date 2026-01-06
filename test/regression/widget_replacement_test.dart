import 'dart:async';
import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Widget Replacement', () {
    test('can replace widget with different type', () async {
      await testNocterm('widget replacement', (tester) async {
        // Initial state with Text widget
        await tester.pumpComponent(TestReplacementComponent(phase: 0));
        expect(tester.terminalState, containsText('Initial Text Widget'));
        expect(tester.terminalState, containsText('Phase: 0'));

        // Change to DecoratedBox
        await tester.pumpComponent(TestReplacementComponent(phase: 1));
        expect(tester.terminalState, containsText('Decorated Box'));
        expect(tester.terminalState, containsText('Phase: 1'));

        // Change back to Text
        await tester.pumpComponent(TestReplacementComponent(phase: 2));
        expect(tester.terminalState, containsText('Back to Text Widget'));
        expect(tester.terminalState, containsText('Phase: 2'));
      });
    });

    test('stateful widget replacement', () async {
      await testNocterm('stateful replacement', (tester) async {
        await tester.pumpComponent(const StatefulReplacementTest());

        // Initial state
        expect(tester.terminalState, containsText('State: 0'));
        expect(tester.terminalState, containsText('Text Widget'));

        // After multiple pumps, the state should change
        // Note: In a real test environment, we'd need to trigger state changes
        // through user input or timers
      });
    });

    test('conditional widget rendering', () async {
      await testNocterm('conditional rendering', (tester) async {
        // Show first widget
        await tester.pumpComponent(ConditionalWidget(showFirst: true));
        expect(tester.terminalState, containsText('First Widget'));

        // Switch to second widget
        await tester.pumpComponent(ConditionalWidget(showFirst: false));
        expect(tester.terminalState, containsText('Second Widget'));
        expect(tester.terminalState, isNot(containsText('First Widget')));
      });
    });

    test('list widget replacement', () async {
      await testNocterm('list replacement', (tester) async {
        // Initial list
        await tester.pumpComponent(
          Column(children: [Text('Item 1'), Text('Item 2'), Text('Item 3')]),
        );
        expect(tester.terminalState, containsText('Item 1'));
        expect(tester.terminalState, containsText('Item 2'));
        expect(tester.terminalState, containsText('Item 3'));

        // Replace with different widgets
        await tester.pumpComponent(
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.blue),
                ),
                child: Text('New Item 1'),
              ),
              Text('Item 2'), // Keep this one
              Container(
                color: Color.fromRGB(0, 64, 0),
                child: Text('New Item 3'),
              ),
            ],
          ),
        );
        expect(tester.terminalState, containsText('New Item 1'));
        expect(tester.terminalState, containsText('Item 2'));
        expect(tester.terminalState, containsText('New Item 3'));
      });
    });

    test('nested widget replacement', () async {
      await testNocterm('nested replacement', (tester) async {
        // Initial nested structure
        await tester.pumpComponent(
          Container(
            child: Column(
              children: [
                Row(children: [Text('A'), Text('B')]),
              ],
            ),
          ),
        );
        expect(tester.terminalState, containsText('A'));
        expect(tester.terminalState, containsText('B'));

        // Replace inner structure
        await tester.pumpComponent(
          Container(
            child: Column(children: [Center(child: Text('Replaced'))]),
          ),
        );
        expect(tester.terminalState, containsText('Replaced'));
        expect(tester.terminalState, isNot(containsText('A')));
        expect(tester.terminalState, isNot(containsText('B')));
      });
    });

    // Visual test for manual inspection
    test(
      'replacement visual test',
      skip: 'Run with debugPrintAfterPump for visual inspection',
      () async {
        await testNocterm(
          'replacement visual',
          (tester) async {
            // Show different phases visually
            print('Phase 0 - Text Widget:');
            await tester.pumpComponent(TestReplacementComponent(phase: 0));

            await Future.delayed(Duration(milliseconds: 100));

            print('\nPhase 1 - DecoratedBox:');
            await tester.pumpComponent(TestReplacementComponent(phase: 1));

            await Future.delayed(Duration(milliseconds: 100));

            print('\nPhase 2 - Back to Text:');
            await tester.pumpComponent(TestReplacementComponent(phase: 2));
          },
          // debugPrintAfterPump: true, // Uncomment to see visual output
        );
      },
    );
  });
}

// Test helper components
class TestReplacementComponent extends StatelessComponent {
  final int phase;

  const TestReplacementComponent({required this.phase});

  @override
  Component build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Phase: $phase'),
          const SizedBox(height: 2),

          // This child changes type during rebuild
          if (phase == 0)
            const Text('Initial Text Widget')
          else if (phase == 1)
            DecoratedBox(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.green),
                color: Color.fromRGB(0, 64, 0),
              ),
              child: const Text('Decorated Box'),
            )
          else
            const Text('Back to Text Widget'),
        ],
      ),
    );
  }
}

class StatefulReplacementTest extends StatefulComponent {
  const StatefulReplacementTest({super.key});

  @override
  State<StatefulReplacementTest> createState() =>
      _StatefulReplacementTestState();
}

class _StatefulReplacementTestState extends State<StatefulReplacementTest> {
  int state = 0;

  @override
  Component build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('State: $state'),
          if (state % 2 == 0)
            const Text('Text Widget')
          else
            Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.cyan),
              ),
              child: const Text('Container Widget'),
            ),
        ],
      ),
    );
  }
}

class ConditionalWidget extends StatelessComponent {
  final bool showFirst;

  const ConditionalWidget({required this.showFirst});

  @override
  Component build(BuildContext context) {
    return Center(
      child: showFirst
          ? const Text('First Widget')
          : Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.blue),
              ),
              child: const Text('Second Widget'),
            ),
    );
  }
}
