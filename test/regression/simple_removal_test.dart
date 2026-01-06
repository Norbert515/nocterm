import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

class FirstWidget extends StatelessComponent {
  const FirstWidget();

  @override
  Component build(BuildContext context) {
    return Text('FIRST');
  }
}

class SecondWidget extends StatelessComponent {
  const SecondWidget();

  @override
  Component build(BuildContext context) {
    return Text('SECOND');
  }
}

void main() {
  test('Direct widget replacement in Column', () async {
    await testNocterm('direct replacement', (tester) async {
      // Create a Column with FirstWidget
      await tester.pumpComponent(Column(children: [FirstWidget()]));

      print('Initial state:');
      print(tester.renderToString(showBorders: false));
      expect(tester.terminalState, containsText('FIRST'));
      expect(tester.terminalState, isNot(containsText('SECOND')));

      // Replace with SecondWidget
      await tester.pumpComponent(Column(children: [SecondWidget()]));

      print('\nAfter replacement:');
      print(tester.renderToString(showBorders: false));

      // Should only show SECOND
      expect(tester.terminalState, containsText('SECOND'));
      expect(tester.terminalState, isNot(containsText('FIRST')));
    });
  });

  test('Widget replacement via setState', () async {
    await testNocterm('stateful replacement', (tester) async {
      bool showFirst = true;

      // Helper to build the column
      Component buildColumn() {
        return Column(children: [showFirst ? FirstWidget() : SecondWidget()]);
      }

      // Initial state
      await tester.pumpComponent(buildColumn());

      print('Initial state (showFirst=true):');
      print(tester.renderToString(showBorders: false));
      expect(tester.terminalState, containsText('FIRST'));
      expect(tester.terminalState, isNot(containsText('SECOND')));

      // Change state
      showFirst = false;
      await tester.pumpComponent(buildColumn());

      print('\nAfter state change (showFirst=false):');
      print(tester.renderToString(showBorders: false));

      // Should only show SECOND
      expect(tester.terminalState, containsText('SECOND'));
      expect(tester.terminalState, isNot(containsText('FIRST')));
    });
  });
}
