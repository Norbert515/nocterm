import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

class WidgetA extends StatelessComponent {
  const WidgetA();

  @override
  Component build(BuildContext context) {
    return Text('A');
  }
}

class WidgetB extends StatelessComponent {
  const WidgetB();

  @override
  Component build(BuildContext context) {
    return Text('B');
  }
}

void main() {
  test('Column properly replaces StatelessComponent children', () async {
    await testNocterm('stateless replacement', (tester) async {
      // Start with WidgetA
      await tester.pumpComponent(Column(children: [WidgetA()]));

      expect(tester.terminalState, containsText('A'));
      expect(tester.terminalState, isNot(containsText('B')));

      // Replace with WidgetB
      await tester.pumpComponent(Column(children: [WidgetB()]));

      // Should only show B, not A
      expect(tester.terminalState, containsText('B'));
      expect(tester.terminalState, isNot(containsText('A')));
    });
  });
}
