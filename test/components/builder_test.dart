import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

void main() {
  group('Builder', () {
    test('builds component from builder callback', () async {
      await testNocterm(
        'basic builder',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: Builder(
                builder: (context) => Text('Built by Builder'),
              ),
            ),
          );

          expect(tester.terminalState, containsText('Built by Builder'));
        },
      );
    });

    test('provides BuildContext to builder callback', () async {
      await testNocterm(
        'builder context',
        (tester) async {
          BuildContext? capturedContext;

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: Builder(
                builder: (context) {
                  capturedContext = context;
                  return Text('Has context');
                },
              ),
            ),
          );

          expect(capturedContext, isNotNull);
          expect(tester.terminalState, containsText('Has context'));
        },
      );
    });

    test('can access inherited widgets through context', () async {
      await testNocterm(
        'builder inherited access',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 40,
              height: 5,
              child: TuiTheme(
                data: TuiThemeData.catppuccinMocha,
                child: Builder(
                  builder: (context) {
                    final theme = TuiTheme.of(context);
                    return Text(
                      'Themed text',
                      style: TextStyle(color: theme.primary),
                    );
                  },
                ),
              ),
            ),
          );

          expect(tester.terminalState, containsText('Themed text'));
        },
      );
    });

    test('rebuilds when parent rebuilds', () async {
      await testNocterm(
        'builder rebuilds',
        (tester) async {
          var buildCount = 0;

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: Builder(
                builder: (context) {
                  buildCount++;
                  return Text('Build count: $buildCount');
                },
              ),
            ),
          );

          expect(buildCount, equals(1));
          expect(tester.terminalState, containsText('Build count: 1'));
        },
      );
    });

    test('works nested inside other components', () async {
      await testNocterm(
        'nested builder',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 40,
              height: 10,
              child: Column(
                children: [
                  Text('Header'),
                  Builder(
                    builder: (context) => Text('Built content'),
                  ),
                  Text('Footer'),
                ],
              ),
            ),
          );

          expect(tester.terminalState, containsText('Header'));
          expect(tester.terminalState, containsText('Built content'));
          expect(tester.terminalState, containsText('Footer'));
        },
      );
    });

    test('can return complex component trees', () async {
      await testNocterm(
        'complex builder output',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 40,
              height: 10,
              child: Builder(
                builder: (context) => Column(
                  children: [
                    Text('Line 1'),
                    Text('Line 2'),
                    Text('Line 3'),
                  ],
                ),
              ),
            ),
          );

          expect(tester.terminalState, containsText('Line 1'));
          expect(tester.terminalState, containsText('Line 2'));
          expect(tester.terminalState, containsText('Line 3'));
        },
      );
    });

    test('visual development - builder in layout', () async {
      await testNocterm(
        'visual builder demo',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 50,
              height: 10,
              child: Column(
                children: [
                  Text('Using Builder:'),
                  Divider(),
                  Builder(
                    builder: (context) => Padding(
                      padding: EdgeInsets.all(1),
                      child: Text('Content from builder'),
                    ),
                  ),
                  Divider(),
                  Text('End'),
                ],
              ),
            ),
          );
        },
        debugPrintAfterPump: true,
      );
    });
  });
}
