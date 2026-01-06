import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart' hide TextAlign;
import 'package:nocterm/src/components/basic.dart' show TextAlign;

void main() {
  group('Text Alignment Fix', () {
    test('text alignment with proper constraints', () async {
      await testNocterm('proper alignment', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 30,
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.solid),
            ),
            child: Column(
              // This is the key - stretch the children to fill the width
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Text('Left', textAlign: TextAlign.left),
                Text('Center', textAlign: TextAlign.center),
                Text('Right', textAlign: TextAlign.right),
                SizedBox(height: 1),
                Text(
                  'This is longer text that should wrap and align',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

        print('With CrossAxisAlignment.stretch:');
        final output = tester.terminalState.getText();
        print(output);

        // Verify alignment - with CrossAxisAlignment.stretch, text alignment works
        final lines = output.split('\n');

        // Left aligned text should start near the left (after border and padding)
        // The line contains the border character and padding, then "Left"
        expect(lines[2], contains('Left'));
        // Verify Left is closer to the start than Center
        final leftPos = lines[2].indexOf('Left');
        expect(leftPos, greaterThan(0)); // Has border/padding before

        // Center aligned text should be roughly centered
        expect(lines[3], contains('Center'));
        final centerPos = lines[3].indexOf('Center');
        expect(
          centerPos,
          greaterThan(leftPos),
        ); // Center is more to the right than Left

        // Right aligned text should be at the right
        expect(lines[4], contains('Right'));
        final rightPos = lines[4].indexOf('Right');
        expect(rightPos, greaterThan(centerPos)); // Right is furthest right
      }, debugPrintAfterPump: true);
    });

    test('text alignment with SizedBox wrapper', () async {
      await testNocterm('sized box alignment', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 30,
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.solid),
            ),
            child: Column(
              children: const [
                // Wrap each Text in a SizedBox to give it width constraint
                SizedBox(
                  width: 28, // Container width minus padding
                  child: Text('Left', textAlign: TextAlign.left),
                ),
                SizedBox(
                  width: 28,
                  child: Text('Center', textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 28,
                  child: Text('Right', textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
        );

        print('With SizedBox wrappers:');
        print(tester.terminalState.getText());
      }, debugPrintAfterPump: true);
    });

    test('text alignment with Expanded', () async {
      await testNocterm('expanded alignment', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 30,
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.solid),
            ),
            child: Column(
              children: [
                Expanded(child: Text('Left', textAlign: TextAlign.left)),
                Expanded(child: Text('Center', textAlign: TextAlign.center)),
                Expanded(child: Text('Right', textAlign: TextAlign.right)),
              ],
            ),
          ),
        );

        print('With Expanded wrappers:');
        print(tester.terminalState.getText());
      }, debugPrintAfterPump: true);
    });
  });
}
