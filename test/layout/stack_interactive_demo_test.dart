import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';
import '../../example/stack_interactive_demo.dart';

void main() {
  group('Stack Interactive Demo', () {
    test('visual test - initial state', () async {
      await testNocterm('initial rendering', (tester) async {
        await tester.pumpComponent(const StackInteractiveDemo());

        // Verify initial state
        expect(tester.terminalState, containsText('Interactive Stack Demo'));
        expect(tester.terminalState, containsText('Counter: 0'));
        expect(tester.terminalState, containsText('Selected: None'));
        expect(
          tester.terminalState,
          containsText('Count: 0'),
        ); // Floating counter
        expect(tester.terminalState, containsText('Normal Mode'));

        // Verify menu items are shown
        expect(tester.terminalState, containsText('1. Apple'));
        expect(tester.terminalState, containsText('2. Banana'));
        expect(tester.terminalState, containsText('3. Cherry'));
        expect(tester.terminalState, containsText('4. Date'));
      }, debugPrintAfterPump: true);
    });

    test('counter interaction', () async {
      await testNocterm('counter up/down', (tester) async {
        await tester.pumpComponent(const StackInteractiveDemo());

        // Initial counter
        expect(tester.terminalState, containsText('Counter: 0'));

        // Press up arrow to increment
        await tester.sendKey(LogicalKey.arrowUp);
        await tester.pump();
        expect(tester.terminalState, containsText('Counter: 1'));
        expect(tester.terminalState, containsText('Count: 1'));

        // Press up arrow again
        await tester.sendKey(LogicalKey.arrowUp);
        await tester.pump();
        expect(tester.terminalState, containsText('Counter: 2'));

        // Press down arrow to decrement
        await tester.sendKey(LogicalKey.arrowDown);
        await tester.pump();
        expect(tester.terminalState, containsText('Counter: 1'));

        // Press down arrow again
        await tester.sendKey(LogicalKey.arrowDown);
        await tester.pump();
        expect(tester.terminalState, containsText('Counter: 0'));

        // Counter shouldn't go below 0
        await tester.sendKey(LogicalKey.arrowDown);
        await tester.pump();
        expect(tester.terminalState, containsText('Counter: 0'));
      });
    });

    test('item selection', () async {
      await testNocterm('select items with number keys', (tester) async {
        await tester.pumpComponent(const StackInteractiveDemo());

        // Initially no item selected
        expect(tester.terminalState, containsText('Selected: None'));

        // Press 1 to select Apple
        await tester.sendKey(LogicalKey.digit1);
        await tester.pump();
        expect(tester.terminalState, containsText('Selected: Apple'));

        // Press 2 to select Banana
        await tester.sendKey(LogicalKey.digit2);
        await tester.pump();
        expect(tester.terminalState, containsText('Selected: Banana'));

        // Press 3 to select Cherry
        await tester.sendKey(LogicalKey.digit3);
        await tester.pump();
        expect(tester.terminalState, containsText('Selected: Cherry'));

        // Press 4 to select Date
        await tester.sendKey(LogicalKey.digit4);
        await tester.pump();
        expect(tester.terminalState, containsText('Selected: Date'));
      });
    });

    test('overlay toggle', () async {
      await testNocterm('toggle overlay with O key', (tester) async {
        await tester.pumpComponent(const StackInteractiveDemo());

        // Initially overlay is not shown
        expect(tester.terminalState, containsText('Normal Mode'));
        expect(tester.terminalState, isNot(containsText('OVERLAY ACTIVE')));

        // Press O to show overlay
        await tester.sendKey(LogicalKey.keyO);
        await tester.pump();
        expect(tester.terminalState, containsText('OVERLAY ACTIVE'));
        expect(tester.terminalState, containsText('Overlay Mode'));
        expect(tester.terminalState, containsText('Press O to close'));

        // Press O again to hide overlay
        await tester.sendKey(LogicalKey.keyO);
        await tester.pump();
        expect(tester.terminalState, isNot(containsText('OVERLAY ACTIVE')));
        expect(tester.terminalState, containsText('Normal Mode'));
      });
    });

    test('combined interactions', () async {
      await testNocterm('test multiple features together', (tester) async {
        await tester.pumpComponent(const StackInteractiveDemo());

        // Set counter to 3
        await tester.sendKey(LogicalKey.arrowUp);
        await tester.pump();
        await tester.sendKey(LogicalKey.arrowUp);
        await tester.pump();
        await tester.sendKey(LogicalKey.arrowUp);
        await tester.pump();

        // Select Banana
        await tester.sendKey(LogicalKey.digit2);
        await tester.pump();

        // Show overlay - it should display current values
        await tester.sendKey(LogicalKey.keyO);
        await tester.pump();
        expect(tester.terminalState, containsText('OVERLAY ACTIVE'));
        expect(tester.terminalState, containsText('Counter: 3'));
        expect(tester.terminalState, containsText('Selected: Banana'));

        // Values should persist after closing overlay
        await tester.sendKey(LogicalKey.keyO);
        await tester.pump();
        expect(tester.terminalState, containsText('Counter: 3'));
        expect(tester.terminalState, containsText('Selected: Banana'));
      }, debugPrintAfterPump: true);
    });
  });
}
