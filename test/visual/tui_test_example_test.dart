// ignore_for_file: unused_element

import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart' hide isEmpty;

// Example component for testing
class Counter extends StatefulComponent {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  void _increment() {
    setState(() {
      _count++;
    });
  }

  void _decrement() {
    setState(() {
      _count--;
    });
  }

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Counter Demo',
            style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 1),
          Text('Count: $_count'),
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('[+] Increment  ', style: TextStyle(color: Colors.green)),
              Text('[-] Decrement', style: TextStyle(color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }
}

void main() {
  group('TUI Testing Framework', () {
    test('can render simple text', () async {
      await testNocterm('simple text', (tester) async {
        await tester.pumpComponent(Container(child: const Text('Hello, TUI!')));

        // Check that text is rendered
        expect(tester.terminalState, containsText('Hello, TUI!'));
      });
    });

    test('can find text at specific position', () async {
      await testNocterm('positioned text', (tester) async {
        await tester.pumpComponent(
          Container(
            padding: const EdgeInsets.only(left: 5, top: 3),
            child: const Text('Positioned'),
          ),
        );

        // Check text at specific position
        expect(tester.terminalState, hasTextAt(5, 3, 'Positioned'));
      });
    });

    test('can detect styled text', () async {
      await testNocterm('styled text', (tester) async {
        await tester.pumpComponent(
          Container(
            child: Text(
              'Styled Text',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        );

        // Check for styled text
        expect(
          tester.terminalState,
          hasStyledText(
            'Styled Text',
            TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        );
      });
    });

    test('can handle multiple pumps', () async {
      await testNocterm('multiple pumps', (tester) async {
        await tester.pumpComponent(const Counter());

        // Initial state
        expect(tester.terminalState, containsText('Count: 0'));

        // Simulate keyboard input (would need keyboard handling in Counter)
        // For now, just pump again to show multiple pumps work
        await tester.pump();

        // State should remain the same
        expect(tester.terminalState, containsText('Count: 0'));
      });
    });

    test('can use snapshot testing', () async {
      await testNocterm('snapshot test', (tester) async {
        await tester.pumpComponent(
          Container(
            padding: const EdgeInsets.all(1),
            child: Column(
              children: const [Text('Line 1'), Text('Line 2'), Text('Line 3')],
            ),
          ),
        );

        final snapshot = tester.toSnapshot();

        // Snapshot should contain the lines
        expect(snapshot, contains('Line'));
        expect(snapshot, contains('1'));
        expect(snapshot, contains('2'));
        expect(snapshot, contains('3'));

        // Can also match entire snapshot
        expect(tester.terminalState, matchesSnapshot(snapshot));
      });
    });

    test('can render complex layouts', () async {
      await testNocterm('complex layout', (tester) async {
        await tester.pumpComponent(
          Container(
            padding: const EdgeInsets.all(2),
            child: Column(
              children: [
                Text('Header', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 1),
                Row(children: const [Text('Left'), Spacer(), Text('Right')]),
                const SizedBox(height: 1),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: const Text('Indented content'),
                ),
              ],
            ),
          ),
        );

        // Verify all parts are rendered
        expect(tester.terminalState, containsText('Header'));
        expect(tester.terminalState, containsText('Left'));
        expect(tester.terminalState, containsText('Right'));
        expect(tester.terminalState, containsText('Indented content'));
      });
    });

    test('can debug render output', () async {
      await testNocterm('debug output', (tester) async {
        await tester.pumpComponent(
          Container(
            padding: const EdgeInsets.all(1),
            child: const Text('Debug Me'),
          ),
        );

        // Get debug output
        final output = tester.renderToString(showBorders: true);
        print('Terminal output:');
        print(output);

        // Output should contain the text
        expect(output, contains('Debug Me'));
      });
    });

    test('detects empty terminal', () async {
      await testNocterm('empty terminal', (tester) async {
        await tester.pumpComponent(Container());

        // Terminal should be empty
        expect(tester.terminalState, isEmpty);
      });
    });

    test('can find components', () async {
      await testNocterm('find components', (tester) async {
        await tester.pumpComponent(
          Column(
            children: [
              const Text('First'),
              Container(child: const Text('Second')),
              const Text('Third'),
            ],
          ),
        );

        // Find specific component types
        final texts = tester.findAllComponents<Text>();
        expect(texts.length, 3);

        final container = tester.findComponent<Container>();
        expect(container, isNotNull);
      });
    });

    test('can specify terminal size', () async {
      await testNocterm('custom size', (tester) async {
        await tester.pumpComponent(
          Container(child: const Text('Small Terminal')),
        );

        // Verify terminal size
        expect(tester.terminalState.size.width, 40);
        expect(tester.terminalState.size.height, 10);
      }, size: const Size(40, 10));
    });
  });
}
