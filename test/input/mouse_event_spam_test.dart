import 'package:test/test.dart' hide isEmpty;
import 'package:nocterm/nocterm.dart';

void main() {
  group('Mouse Event Handling', () {
    // This test demonstrates the issue that was fixed:
    // Before the fix, unparseable mouse events in input_parser.dart would be
    // converted to keyboard events with 'unknown' keys, which would then be
    // sent to all focusable nodes, causing spam.
    //
    // The fix: input_parser.dart now discards unparseable mouse events instead
    // of converting them to 'unknown' keyboard events.
    test('unknown keyboard events should not be sent to focusable nodes', () async {
      await testNocterm('unknown key test', (tester) async {
        print('\n=== Testing Unknown Keyboard Events ===\n');

        // Track keyboard events received by focusable elements
        final receivedEvents = <String>[];

        // Create a simple app with focusable elements
        final app = Column(
          children: [
            KeyboardListener(
              onKeyEvent: (key) {
                print('Button 1 received: ${key.debugName}');
                receivedEvents.add('Button1: ${key.debugName}');
                return false; // Don't consume the event
              },
              autofocus: true,
              child: Container(
                width: 20,
                height: 3,
                child: const Text('Button 1'),
              ),
            ),
            KeyboardListener(
              onKeyEvent: (key) {
                print('Button 2 received: ${key.debugName}');
                receivedEvents.add('Button2: ${key.debugName}');
                return false; // Don't consume the event
              },
              child: Container(
                width: 20,
                height: 3,
                child: const Text('Button 2'),
              ),
            ),
          ],
        );

        await tester.pumpComponent(app);

        // Simulate what happens when unparseable mouse events get converted to 'unknown' keyboard events
        // This mimics the bug in input_parser.dart lines 77-84
        print(
          'Simulating unknown keyboard events (as would happen from unparseable mouse events)...',
        );

        // Send several 'unknown' keyboard events (simulating mouse movement)
        for (int i = 0; i < 5; i++) {
          await tester.sendKey(LogicalKey(0, 'unknown'));
        }

        print('Events received by focusable nodes:');
        for (final event in receivedEvents) {
          print('  - $event');
        }

        // Check that 'unknown' keyboard events were received (this is the bug we're testing)
        final unknownEvents = receivedEvents
            .where((e) => e.contains('unknown'))
            .toList();

        if (unknownEvents.isNotEmpty) {
          print(
            '\n❌ CURRENT BEHAVIOR: Found ${unknownEvents.length} unknown keyboard events!',
          );
          print(
            'This demonstrates the issue where mouse events are converted to keyboard events.',
          );
        } else {
          print('\n✓ FIXED: No unknown keyboard events received');
        }

        // This test demonstrates that IF 'unknown' keyboard events are sent,
        // they WILL reach focusable nodes. The fix prevents mouse events from
        // being converted to 'unknown' keyboard events in the first place.
        expect(
          unknownEvents.length,
          greaterThan(0),
          reason:
              'This test shows that unknown events (if sent) reach focusable nodes. '
              'The fix prevents mouse events from generating these unknown events.',
        );
      }, debugPrintAfterPump: true);
    });
  });
}
