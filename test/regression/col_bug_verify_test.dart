import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  test('Column should properly replace children', () async {
    await testNocterm('column child replacement', (tester) async {
      // Create a simple stateful widget that changes content
      await tester.pumpComponent(Column(children: [Text('First')]));

      // Verify initial state
      expect(tester.terminalState, containsText('First'));
      expect(tester.terminalState, isNot(containsText('Second')));

      // Update to different child
      await tester.pumpComponent(Column(children: [Text('Second')]));

      // Should only show Second, not both
      expect(tester.terminalState, isNot(containsText('First')));
      expect(tester.terminalState, containsText('Second'));
    });
  });
}
