import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart' hide isEmpty;

void main() {
  test('debug output with complex layout - investigating', () async {
    await testNocterm(
      'complex layout visualization',
      (tester) async {
        print('\n📺 Visualizing a complex layout:\n');

        await tester.pumpComponent(
          Container(
            padding: const EdgeInsets.all(1),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(1),
                      child: Text('╔═══╗\n║ A ║\n╚═══╝'),
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
                  child: Text('── Center Line ──', style: TextStyle(fontWeight: FontWeight.dim)),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Expanded(
                      child: Text('Left aligned', style: TextStyle(color: Colors.red)),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('Centered', style: TextStyle(color: Colors.green)),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('Right aligned', style: TextStyle(color: Colors.blue)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        print('Terminal content:');
        print(tester.terminalState.getText());
        
        // Check what's actually rendered
        expect(tester.terminalState, containsText('Left aligned'));
        
        // Try to find A or B
        final content = tester.terminalState.getText();
        print('\nSearching for "A": ${content.contains('A')}');
        print('Searching for "B": ${content.contains('B')}');
        print('Searching for "Center Line": ${content.contains('Center Line')}');
      },
      debugPrintAfterPump: true,
      size: const Size(60, 30), // Larger size to avoid overflow
    );
  });
}