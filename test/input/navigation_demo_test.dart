import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

void main() {
  test(
    'navigation demo dialog receives focus correctly',
    skip: 'Known issue: Dialog focus management not working correctly',
    () async {
      await testNocterm('navigation demo test', (tester) async {
        print('\n=== Testing Navigation Demo Focus ===\n');

        // Track which component received events
        final List<String> eventLog = [];

        // Create a modified navigation demo
        final navigator = Navigator(
          home: Container(
            padding: const EdgeInsets.all(2),
            child: Column(
              children: [
                const Text('Main Page'),
                KeyboardListener(
                  onKeyEvent: (key) {
                    eventLog.add('Main: $key');
                    print('Main page received: $key');
                    if (key == LogicalKey.keyD) {
                      // Show dialog
                      final navState = tester.findState<NavigatorState>();
                      navState.showDialog<void>(
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(border: BoxBorder.all()),
                          child: KeyboardListener(
                            onKeyEvent: (key) {
                              eventLog.add('Dialog: $key');
                              print('Dialog received: $key');
                              if (key == LogicalKey.keyX) {
                                Navigator.of(context).pop();
                                return true;
                              }
                              return false;
                            },
                            autofocus: true,
                            child: const Column(
                              children: [
                                Text('Dialog'),
                                Text('Press X to close'),
                              ],
                            ),
                          ),
                        ),
                        width: 20,
                        height: 6,
                      );
                      return true;
                    }
                    return false;
                  },
                  autofocus: true,
                  child: const Text('Press D to show dialog'),
                ),
              ],
            ),
          ),
          popBehavior: const PopBehavior(escapeEnabled: true),
        );

        await tester.pumpComponent(navigator);

        // Clear log
        eventLog.clear();

        print('Sending D key to show dialog...');
        await tester.sendKey(LogicalKey.keyD);
        await tester.pump();

        // Verify dialog is shown
        expect(tester.terminalState, containsText('Dialog'));
        expect(eventLog, contains('Main: ${LogicalKey.keyD}'));

        // Clear log for next test
        eventLog.clear();

        print('Sending A key to test focus...');
        await tester.sendKey(LogicalKey.keyA);
        await tester.pump();

        // Check which component received the event
        print('Event log after A key: $eventLog');

        // The dialog should receive the event, NOT the main page
        expect(eventLog, isNot(contains('Main: ${LogicalKey.keyA}')));
        // But since dialog doesn't handle A, it won't be in the log either

        // Send X to close dialog
        print('Sending X key to close dialog...');
        await tester.sendKey(LogicalKey.keyX);
        await tester.pump();

        expect(eventLog, contains('Dialog: ${LogicalKey.keyX}'));

        // Dialog should be closed
        expect(tester.terminalState, isNot(containsText('Dialog')));
        expect(tester.terminalState, containsText('Main Page'));

        // Clear log
        eventLog.clear();

        // Now main page should receive events again
        print('Sending A key after dialog closed...');
        await tester.sendKey(LogicalKey.keyA);
        await tester.pump();

        expect(eventLog, contains('Main: ${LogicalKey.keyA}'));
      }, debugPrintAfterPump: false);
    },
  );
}
