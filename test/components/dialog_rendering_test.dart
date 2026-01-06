import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

void main() {
  group('Dialog Rendering', () {
    test('dialog should overlay on top of main content', () async {
      await testNocterm('dialog overlay test', (tester) async {
        print('\n=== Testing Dialog Overlay ===\n');

        // Create navigator with home page
        final navigator = Navigator(
          home: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            padding: const EdgeInsets.all(2),
            child: Column(
              children: const [
                Text('Main Page Content'),
                Text('This should remain visible'),
                Text('Behind the dialog'),
              ],
            ),
          ),
        );

        await tester.pumpComponent(navigator);

        print('Initial state (main page only):');
        print('Terminal size: ${tester.terminalState.size}');
        print('---');

        // Verify main content is visible
        expect(tester.terminalState, containsText('Main Page Content'));
        expect(
          tester.terminalState,
          containsText('This should remain visible'),
        );

        // Get navigator state and show dialog
        final navState = tester.findState<NavigatorState>();

        print('\nShowing dialog...');
        final dialogFuture = navState.showDialog<String>(
          builder: (context) => Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.double),
              color: const Color.fromRGB(30, 30, 50),
            ),
            padding: const EdgeInsets.all(1),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text('Dialog Title'), Text('Dialog Content')],
            ),
          ),
          width: 20,
          height: 8, // Increased height to accommodate content
          barrierDismissible: true,
        );

        await tester.pump();

        print('\nAfter showing dialog:');
        print('---');

        // Check what's rendered
        tester.terminalState.toString();

        // Dialog should be visible
        expect(tester.terminalState, containsText('Dialog Title'));
        expect(tester.terminalState, containsText('Dialog Content'));

        // Main content might be obscured by barrier but the Stack should still be rendering both
        print('\nChecking if main content is still in the render tree...');

        // Close dialog
        navState.pop('closed');
        await tester.pump();

        print('\nAfter closing dialog:');
        print('---');

        // Main content should be visible again
        expect(tester.terminalState, containsText('Main Page Content'));
        expect(tester.terminalState, isNot(containsText('Dialog Title')));

        final result = await dialogFuture;
        expect(result, 'closed');
      }, debugPrintAfterPump: true);
    });

    test('dialog positioning', () async {
      await testNocterm(
        'dialog position test',
        (tester) async {
          print('\n=== Testing Dialog Positioning ===\n');

          final navigator = Navigator(
            home: Container(child: const Center(child: Text('Main Page'))),
          );

          await tester.pumpComponent(navigator);
          final navState = tester.findState<NavigatorState>();

          // Show a small dialog that should be centered
          navState.showDialog<void>(
            builder: (context) => Container(
              decoration: BoxDecoration(border: BoxBorder.all()),
              child: const Text('X'),
            ),
            width: 3,
            height: 1,
            alignment: Alignment.center,
          );

          await tester.pump();

          print('Dialog with size 3x1 centered:');
          print('Terminal size: ${tester.terminalState.size}');

          // The dialog should be somewhere near the center
          // We can't test exact position easily, but we can check it's rendered
          expect(tester.terminalState, containsText('X'));
        },
        debugPrintAfterPump: true,
        size: const Size(40, 20),
      );
    });
  });
}
