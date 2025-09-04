import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart' hide isEmpty;

void main() {
  test('check heights needed', () async {
    await testNocterm(
      'height calculation',
      (tester) async {
        // Count the actual lines needed
        final boxText = '╔═══╗\n║ A ║\n╚═══╝';
        print('Box text lines: ${boxText.split('\n').length}'); // Should be 3
        
        // Test with Container padding
        final containerPadding = 1;
        print('Container padding top/bottom: $containerPadding each');
        
        // First row with boxes
        print('\nFirst Row needs:');
        print('- Container padding top: 1');
        print('- Box height: 3 lines');  
        print('- Container padding bottom: 1');
        print('Total: 5 lines');
        
        // SizedBox
        print('\nSizedBox: 1 line');
        
        // Center line
        print('\nCenter line: 1 line');
        
        // Another SizedBox
        print('\nSizedBox: 1 line');
        
        // Bottom row
        print('\nBottom Row: 1 line');
        
        // Outer container padding
        print('\nOuter container padding: 2 lines (1 top + 1 bottom)');
        
        print('\n=== TOTAL NEEDED ===');
        print('5 (first row) + 1 (space) + 1 (center) + 1 (space) + 1 (bottom row) + 2 (padding) = 11 lines');
        
        // Now test the actual component with sufficient height
        await tester.pumpComponent(
          Container(
            padding: const EdgeInsets.all(1),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(1),
                      child: Text(boxText),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(1),
                      child: Text('╔═══╗\n║ B ║\n╚═══╝'),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Center(
                  child: Text('── Center Line ──'),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Expanded(child: Text('Left')),
                    Expanded(child: Center(child: Text('Center'))),
                    Expanded(child: Align(alignment: Alignment.centerRight, child: Text('Right'))),
                  ],
                ),
              ],
            ),
          ),
        );
        
        print('\nActual render:');
        print(tester.terminalState.getText());
        
        // Check if everything is visible
        expect(tester.terminalState.getText(), contains('A'));
        expect(tester.terminalState.getText(), contains('B'));
        expect(tester.terminalState.getText(), contains('Center Line'));
        expect(tester.terminalState.getText(), contains('Left'));
      },
      debugPrintAfterPump: true,
      size: const Size(60, 15), // Should be enough for 11 lines + borders
    );
  });
}