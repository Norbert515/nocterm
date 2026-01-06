import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

void main() {
  group('Navigation', () {
    test('basic push and pop', () async {
      await testNocterm('push and pop navigation', (tester) async {
        final navigator = Navigator(
          home: Container(child: const Text('Home Page')),
          routes: {
            '/settings': (context) =>
                Container(child: const Text('Settings Page')),
          },
        );

        await tester.pumpComponent(navigator);
        expect(tester.terminalState, containsText('Home Page'));

        // Navigate to settings
        final navState = tester.findState<NavigatorState>();
        navState.pushNamed('/settings');
        await tester.pump();

        expect(tester.terminalState, containsText('Settings Page'));
        expect(tester.terminalState, isNot(containsText('Home Page')));

        // Pop back to home
        navState.pop();
        await tester.pump();

        expect(tester.terminalState, containsText('Home Page'));
        expect(tester.terminalState, isNot(containsText('Settings Page')));
      });
    });

    test('deep linking', () async {
      await testNocterm('deep linking navigation', (tester) async {
        final navigator = Navigator(
          initialRoute: '/settings/profile',
          routes: {
            '/': (context) => Container(child: const Text('Home')),
            '/settings': (context) => Container(child: const Text('Settings')),
            '/settings/profile': (context) =>
                Container(child: const Text('Profile')),
          },
        );

        await tester.pumpComponent(navigator);

        // Should start at profile page
        expect(tester.terminalState, containsText('Profile'));

        final navState = tester.findState<NavigatorState>();

        // Should be able to pop to settings
        navState.pop();
        await tester.pump();
        expect(tester.terminalState, containsText('Settings'));

        // Should be able to pop to home
        navState.pop();
        await tester.pump();
        expect(tester.terminalState, containsText('Home'));

        // Can't pop anymore
        expect(navState.canPop(), false);
      });
    });

    test('push replacement', () async {
      await testNocterm('push replacement navigation', (tester) async {
        final navigator = Navigator(
          home: Container(child: const Text('Home')),
          routes: {
            '/page1': (context) => Container(child: const Text('Page 1')),
            '/page2': (context) => Container(child: const Text('Page 2')),
          },
        );

        await tester.pumpComponent(navigator);
        final navState = tester.findState<NavigatorState>();

        // Navigate to page 1
        navState.pushNamed('/page1');
        await tester.pump();
        expect(tester.terminalState, containsText('Page 1'));

        // Replace with page 2
        navState.pushReplacementNamed('/page2');
        await tester.pump();
        expect(tester.terminalState, containsText('Page 2'));

        // Pop should go back to home, not page 1
        navState.pop();
        await tester.pump();
        expect(tester.terminalState, containsText('Home'));
      });
    });

    test(
      'modal dialog',
      skip: 'Known issue: Dialog content visibility in overlay system',
      () async {
        await testNocterm('modal dialog navigation', (tester) async {
          final navigator = Navigator(
            home: Container(child: const Text('Main Content')),
          );

          await tester.pumpComponent(navigator);
          final navState = tester.findState<NavigatorState>();

          expect(tester.terminalState, containsText('Main Content'));

          // Show dialog
          final dialogFuture = navState.showDialog<bool>(
            builder: (context) => Container(
              decoration: BoxDecoration(border: BoxBorder.all()),
              padding: const EdgeInsets.all(2),
              child: const Text('Dialog Content'),
            ),
            width: 20,
            height: 5,
          );

          await tester.pump();

          // Dialog should be visible (main content might be covered)
          expect(tester.terminalState, containsText('Dialog Content'));

          // Close dialog with result
          navState.pop(true);
          await tester.pump();

          // Dialog should be gone
          expect(tester.terminalState, containsText('Main Content'));
          expect(tester.terminalState, isNot(containsText('Dialog Content')));

          // Check dialog result
          final result = await dialogFuture;
          expect(result, true);
        });
      },
    );

    test('pop behavior configuration', () async {
      await testNocterm('pop behavior test', (tester) async {
        bool canPopCalled = false;

        final navigator = Navigator(
          home: Container(child: const Text('Home')),
          routes: {
            '/locked': (context) => Container(child: const Text('Locked Page')),
          },
          popBehavior: PopBehavior(
            escapeEnabled: true,
            customPopKey: 'q',
            canPop: (route) {
              canPopCalled = true;
              // Don't allow popping from locked page
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

        // Try to pop - should be blocked
        expect(navState.canPop(), false);
        expect(canPopCalled, true);

        // Pop should not work
        navState.pop();
        await tester.pump();
        expect(tester.terminalState, containsText('Locked Page'));
      });
    });

    test('navigator observers', () async {
      await testNocterm('navigator observers test', (tester) async {
        final events = <String>[];

        final observer = TestNavigatorObserver(
          onPush: (route, previousRoute) {
            events.add('push:${route.settings.name}');
          },
          onPop: (route, previousRoute) {
            events.add('pop:${route.settings.name}');
          },
          onReplace: (newRoute, oldRoute) {
            events.add(
              'replace:${oldRoute?.settings.name}->${newRoute?.settings.name}',
            );
          },
        );

        final navigator = Navigator(
          home: Container(child: const Text('Home')),
          routes: {
            '/page1': (context) => Container(child: const Text('Page 1')),
            '/page2': (context) => Container(child: const Text('Page 2')),
          },
          observers: [observer],
        );

        await tester.pumpComponent(navigator);
        final navState = tester.findState<NavigatorState>();

        // Initial route should be pushed
        expect(events, ['push:/']);
        events.clear();

        // Push page 1
        navState.pushNamed('/page1');
        await tester.pump();
        expect(events, ['push:/page1']);
        events.clear();

        // Replace with page 2
        navState.pushReplacementNamed('/page2');
        await tester.pump();
        expect(events, ['replace:/page1->/page2']);
        events.clear();

        // Pop back
        navState.pop();
        await tester.pump();
        expect(events, ['pop:/page2']);
      });
    });

    test('return values from pushed routes', () async {
      await testNocterm('return values test', (tester) async {
        final navigator = Navigator(home: Container(child: const Text('Home')));

        await tester.pumpComponent(navigator);
        final navState = tester.findState<NavigatorState>();

        // Push a page and get result
        final resultFuture = navState.pushComponent<String>(
          Container(child: const Text('Input Page')),
        );

        await tester.pump();
        expect(tester.terminalState, containsText('Input Page'));

        // Pop with result
        navState.pop('user input');
        await tester.pump();

        final result = await resultFuture;
        expect(result, 'user input');
      });
    });
  });
}

// Test helper for navigator observer
class TestNavigatorObserver extends NavigatorObserver {
  final void Function(Route route, Route? previousRoute)? onPush;
  final void Function(Route route, Route? previousRoute)? onPop;
  final void Function(Route? newRoute, Route? oldRoute)? onReplace;

  TestNavigatorObserver({this.onPush, this.onPop, this.onReplace});

  @override
  void didPush(Route route, Route? previousRoute) {
    onPush?.call(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    onPop?.call(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    onReplace?.call(newRoute, oldRoute);
  }
}
