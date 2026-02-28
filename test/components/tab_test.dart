import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

void main() {
  group('TabComponent', () {
    test('visual development - tab bar rendering', () async {
      await testNocterm(
        'see how tab bar looks',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 60,
              height: 5,
              child: TabComponent(
                tabs: ['Tab 1', 'Tab 2', 'Tab 3'],
                selectedIndex: 0,
              ),
            ),
          );
        },
        debugPrintAfterPump: true,
      );
    });

    test('visual development - different selected tab', () async {
      await testNocterm(
        'tab bar with third tab selected',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 60,
              height: 5,
              child: TabComponent(
                tabs: ['Tab 1', 'Tab 2', 'Tab 3'],
                selectedIndex: 2,
              ),
            ),
          );
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders all tab labels', () async {
      await testNocterm(
        'tab labels visible',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 60,
              height: 5,
              child: TabComponent(
                tabs: ['Tab 1', 'Tab 2', 'Tab 3'],
                selectedIndex: 0,
              ),
            ),
          );

          expect(tester.terminalState, containsText('Tab 1'));
          expect(tester.terminalState, containsText('Tab 2'));
          expect(tester.terminalState, containsText('Tab 3'));
        },
      );
    });

    test('renders indicator for selected tab', () async {
      await testNocterm(
        'selected tab has indicator',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 60,
              height: 5,
              child: TabComponent(
                tabs: ['Tab 1', 'Tab 2', 'Tab 3'],
                selectedIndex: 0,
              ),
            ),
          );

          // The selected tab indicator uses '━' characters
          expect(tester.terminalState, containsText('━'));
        },
      );
    });
  });
}
