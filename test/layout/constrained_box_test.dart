import 'package:nocterm/nocterm.dart' hide isNotEmpty;
import 'package:test/test.dart';

void main() {
  group('ConstrainedBox', () {
    test('applies minimum constraints', () async {
      await testNocterm('minimum constraints', (tester) async {
        await tester.pumpComponent(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 20, minHeight: 10),
            child: Container(color: Colors.blue, child: const Text('Small')),
          ),
        );

        // Verify it renders without error
        final snapshot = tester.toSnapshot();
        expect(snapshot.isNotEmpty, isTrue);

        // The container should be at least 20x10
        // We can check this visually in the output
      }, debugPrintAfterPump: false);
    });

    test('applies maximum constraints', () async {
      await testNocterm('maximum constraints', (tester) async {
        await tester.pumpComponent(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 15, maxHeight: 3),
            child: Container(
              color: Colors.green,
              child: const Text(
                'This is a very long text that should be constrained',
              ),
            ),
          ),
        );

        // Verify it renders without error
        final snapshot = tester.toSnapshot();
        expect(snapshot.isNotEmpty, isTrue);
      }, debugPrintAfterPump: false);
    });

    test('combines with parent constraints using enforce()', () async {
      await testNocterm('enforce combines constraints', (tester) async {
        await tester.pumpComponent(
          SizedBox(
            width: 50,
            height: 25,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 20,
                maxWidth: 40,
                minHeight: 10,
                maxHeight: 20,
              ),
              child: Container(
                color: Colors.yellow,
                child: const Text('Constrained'),
              ),
            ),
          ),
        );

        // Verify it renders without error
        final snapshot = tester.toSnapshot();
        expect(snapshot.isNotEmpty, isTrue);
      }, debugPrintAfterPump: false);
    });

    test('handles null child', () async {
      await testNocterm('null child', (tester) async {
        await tester.pumpComponent(
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.cyan),
                ),
                child: const ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 15, minHeight: 3),
                  // No child - should still size itself to minimum constraints
                ),
              ),
            ],
          ),
        );

        // Should not throw - even with null child, ConstrainedBox still sizes itself
        final snapshot = tester.toSnapshot();
        // The border should render showing the constrained box size
        expect(snapshot.isNotEmpty, isTrue);
      }, debugPrintAfterPump: false);
    });

    test('visual test - see constrained boxes in action', () async {
      await testNocterm('visual constrained box', (tester) async {
        await tester.pumpComponent(
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: Colors.red,
                  child: const Text('No constraints'),
                ),
                const SizedBox(height: 1),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 3),
                  child: Container(
                    color: Colors.blue,
                    child: const Text('Min 30x3'),
                  ),
                ),
                const SizedBox(height: 1),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 20, maxHeight: 2),
                  child: Container(
                    color: Colors.green,
                    child: const Text('Max 20x2 - this text will be clipped'),
                  ),
                ),
                const SizedBox(height: 1),
                ConstrainedBox(
                  constraints: const BoxConstraints.expand(
                    width: 25,
                    height: 4,
                  ),
                  child: Container(
                    color: Colors.yellow,
                    child: const Center(child: Text('Fixed 25x4')),
                  ),
                ),
              ],
            ),
          ),
        );

        // Print the visual output to see the constraints in action
        print('\nVisual output of constrained boxes:');
        print(tester.toSnapshot());
      }, debugPrintAfterPump: false);
    });
  });
}
