import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

void main() {
  group('Keyboard Navigation', () {
    test('ESC key should close dialog', () async {
      await testNocterm('esc key test', (tester) async {
        print('\n=== Testing ESC Key ===\n');

        final navigator = Navigator(
          home: Container(child: const Text('Main Page')),
          popBehavior: const PopBehavior(escapeEnabled: true),
        );

        await tester.pumpComponent(navigator);
        final navState = tester.findState<NavigatorState>();

        print('Showing dialog...');
        final dialogFuture = navState.showDialog<String>(
          builder: (context) => Container(child: const Text('Dialog')),
          width: 10,
          height: 3,
          barrierDismissible: true,
        );

        await tester.pump();
        expect(tester.terminalState, containsText('Dialog'));

        print('Sending ESC key...');
        // Try to send ESC key to close the dialog
        await tester.sendKey(LogicalKey.escape);
        await tester.pump();

        print('After ESC key:');

        // Dialog should be closed
        expect(tester.terminalState, isNot(containsText('Dialog')));
        expect(tester.terminalState, containsText('Main Page'));

        // Check the future result
        final result = await dialogFuture;
        expect(result, isNull); // Should be null when dismissed
      }, debugPrintAfterPump: true);
    });

    test(
      'custom pop key should work',
      skip: 'Known bug: PopBehavior.shouldPop compares LogicalKey with String',
      () async {
        await testNocterm('custom pop key test', (tester) async {
          print('\n=== Testing Custom Pop Key (Q) ===\n');

          final navigator = Navigator(
            home: Container(child: const Text('Home')),
            routes: {
              '/page2': (context) => Container(child: const Text('Page 2')),
            },
            popBehavior: const PopBehavior(
              escapeEnabled: false,
              customPopKey: 'q',
            ),
          );

          await tester.pumpComponent(navigator);
          final navState = tester.findState<NavigatorState>();

          // Navigate to page 2
          navState.pushNamed('/page2');
          await tester.pump();
          expect(tester.terminalState, containsText('Page 2'));

          print('Sending Q key...');
          // Try to pop with 'q'
          await tester.sendKey(LogicalKey.keyQ);
          await tester.pump();

          print('After Q key:');

          // Should be back at home
          expect(tester.terminalState, containsText('Home'));
          expect(tester.terminalState, isNot(containsText('Page 2')));
        }, debugPrintAfterPump: true);
      },
    );

    test('canPop callback should prevent popping', () async {
      await testNocterm('canPop callback test', (tester) async {
        print('\n=== Testing canPop Callback ===\n');

        final navigator = Navigator(
          home: Container(child: const Text('Home')),
          routes: {
            '/locked': (context) => Container(child: const Text('Locked Page')),
          },
          popBehavior: PopBehavior(
            escapeEnabled: true,
            canPop: (route) {
              // Don't allow popping from /locked
              return route.settings.name != '/locked';
            },
          ),
        );

        await tester.pumpComponent(navigator);
        final navState = tester.findState<NavigatorState>();

        // Navigate to locked page
        navState.pushNamed('/locked');
        await tester.pump();
        expect(tester.terminalState, containsText('Locked Page'));

        print('Trying to pop from locked page...');
        // Try to pop with ESC
        await tester.sendKey(LogicalKey.escape);
        await tester.pump();

        print('After ESC (should still be on locked page):');

        // Should still be on locked page
        expect(tester.terminalState, containsText('Locked Page'));
      }, debugPrintAfterPump: true);
    });
  });
}
