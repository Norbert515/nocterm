import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  test('Column properly removes old children from render tree', () async {
    await testNocterm('render tree update', (tester) async {
      // Start with a column containing one Text widget
      await tester.pumpComponent(Column(children: [Text('First')]));

      expect(tester.terminalState, containsText('First'));

      // Replace with a different Text widget
      await tester.pumpComponent(Column(children: [Text('Second')]));

      // Should only show Second
      expect(tester.terminalState, containsText('Second'));
      expect(tester.terminalState, isNot(containsText('First')));

      // Try with multiple children
      await tester.pumpComponent(
        Column(children: [Text('A'), Text('B'), Text('C')]),
      );

      expect(tester.terminalState, containsText('A'));
      expect(tester.terminalState, containsText('B'));
      expect(tester.terminalState, containsText('C'));
      expect(tester.terminalState, isNot(containsText('Second')));

      // Replace with fewer children
      await tester.pumpComponent(Column(children: [Text('X')]));

      expect(tester.terminalState, containsText('X'));
      expect(tester.terminalState, isNot(containsText('A')));
      expect(tester.terminalState, isNot(containsText('B')));
      expect(tester.terminalState, isNot(containsText('C')));
    });
  });
}
