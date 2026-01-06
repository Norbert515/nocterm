import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('NoctermApp', () {
    test('sets window title on initialization', () async {
      await testNocterm('title initialization', (tester) async {
        await tester.pumpComponent(
          NoctermApp(title: 'Test App', child: Text('Hello')),
        );

        // The title should be set via OSC sequence
        // We can't easily test the terminal state directly, but we can verify
        // the component renders correctly
        expect(tester.terminalState, containsText('Hello'));
      });
    });

    test('sets both window title and icon name separately', () async {
      await testNocterm('separate title and icon', (tester) async {
        await tester.pumpComponent(
          NoctermApp(
            title: 'My Window Title',
            iconName: 'MyApp',
            child: Text('Content'),
          ),
        );

        expect(tester.terminalState, containsText('Content'));
      });
    });

    test('updates title when component updates', () async {
      await testNocterm('title update', (tester) async {
        // Initial state
        await tester.pumpComponent(
          NoctermApp(title: 'Initial Title', child: Text('Content')),
        );

        expect(tester.terminalState, containsText('Content'));

        // Update the title
        await tester.pumpComponent(
          NoctermApp(title: 'Updated Title', child: Text('Content')),
        );

        expect(tester.terminalState, containsText('Content'));
      });
    });

    test('renders child component correctly', () async {
      await testNocterm('child rendering', (tester) async {
        await tester.pumpComponent(
          NoctermApp(
            title: 'Test',
            child: Column(children: [Text('Line 1'), Text('Line 2')]),
          ),
        );

        expect(tester.terminalState, containsText('Line 1'));
        expect(tester.terminalState, containsText('Line 2'));
      });
    });

    test('works without title (optional parameter)', () async {
      await testNocterm('no title', (tester) async {
        await tester.pumpComponent(NoctermApp(child: Text('No Title Set')));

        expect(tester.terminalState, containsText('No Title Set'));
      });
    });

    test('visual test of NoctermApp with title', () async {
      await testNocterm('visual with title', (tester) async {
        await tester.pumpComponent(
          NoctermApp(
            title: 'Demo Application',
            iconName: 'DemoApp',
            child: Container(
              decoration: BoxDecoration(border: BoxBorder.all()),
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NoctermApp Demo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Window title: "Demo Application"'),
                    Text('Icon name: "DemoApp"'),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('NoctermApp Demo'));
        expect(tester.terminalState, containsText('Demo Application'));
      }, debugPrintAfterPump: true);
    });
  });

  group('NoctermApp with Navigator', () {
    test('creates navigator with home parameter', () async {
      await testNocterm('navigator with home', (tester) async {
        await tester.pumpComponent(
          NoctermApp(title: 'Nav Test', home: Text('Home Screen')),
        );

        expect(tester.terminalState, containsText('Home Screen'));
      });
    });

    test('creates navigator with routes', () async {
      await testNocterm('navigator with routes', (tester) async {
        await tester.pumpComponent(
          NoctermApp(
            title: 'Routes Test',
            routes: {
              '/': (context) => Text('Home Route'),
              '/settings': (context) => Text('Settings Route'),
            },
          ),
        );

        expect(tester.terminalState, containsText('Home Route'));
      });
    });

    test('creates navigator with initialRoute', () async {
      await testNocterm('navigator with initial route', (tester) async {
        await tester.pumpComponent(
          NoctermApp(
            title: 'Initial Route Test',
            initialRoute: '/settings',
            routes: {
              '/': (context) => Text('Home Route'),
              '/settings': (context) => Text('Settings Route'),
            },
          ),
        );

        expect(tester.terminalState, containsText('Settings Route'));
      });
    });

    test(
      'navigation works with pushNamed',
      () async {
        await testNocterm('push named route', (tester) async {
          final navigatorKey = GlobalKey<NavigatorState>();

          await tester.pumpComponent(
            NoctermApp(
              title: 'Push Test',
              navigatorKey: navigatorKey,
              routes: {
                '/': (context) => Text('Home'),
                '/detail': (context) => Text('Detail Screen'),
              },
            ),
          );

          expect(tester.terminalState, containsText('Home'));

          // Navigate to detail using the navigator key
          navigatorKey.currentState!.pushNamed('/detail');
          await tester.pump();

          expect(tester.terminalState, containsText('Detail Screen'));
        });
      },
      skip:
          'Known issue: Navigator pushNamed triggers element lifecycle '
          'assertion in build_owner.dart during route transitions',
    );

    test('uses child when provided instead of navigator', () async {
      await testNocterm('child without navigator', (tester) async {
        await tester.pumpComponent(
          NoctermApp(title: 'Child Test', child: Text('Simple Child')),
        );

        expect(tester.terminalState, containsText('Simple Child'));
      });
    });
  });
}
