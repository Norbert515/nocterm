import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart' hide isEmpty;

void main() {
  test('multiline text rendering', () async {
    await testNocterm(
      'multiline text test',
      (tester) async {
        // Test 1: Simple multiline text
        await tester.pumpComponent(
          Container(
            padding: const EdgeInsets.all(1),
            child: Text('Line 1\nLine 2\nLine 3'),
          ),
        );
        
        print('Test 1 - Simple multiline:');
        print(tester.terminalState.getText());
        print('---');
        
        // Test 2: Box drawing
        await tester.pumpComponent(
          Container(
            padding: const EdgeInsets.all(1),
            child: Text('╔═══╗\n║ A ║\n╚═══╝'),
          ),
        );
        
        print('\nTest 2 - Box with A:');
        print(tester.terminalState.getText());
        print('Contains A: ${tester.terminalState.getText().contains('A')}');
        print('---');
        
        // Test 3: Just the problematic row
        await tester.pumpComponent(
          Container(
            padding: const EdgeInsets.all(1),
            child: Row(
              children: [
                Text('╔═══╗\n║ A ║\n╚═══╝'),
                const Spacer(),
                Text('╔═══╗\n║ B ║\n╚═══╝'),
              ],
            ),
          ),
        );
        
        print('\nTest 3 - Row with boxes:');
        print(tester.terminalState.getText());
        print('Contains A: ${tester.terminalState.getText().contains('A')}');
        print('Contains B: ${tester.terminalState.getText().contains('B')}');
      },
      debugPrintAfterPump: false,
      size: const Size(40, 10),
    );
  });
}