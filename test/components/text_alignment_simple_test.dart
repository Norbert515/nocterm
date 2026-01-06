import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart' hide TextAlign;
import 'package:nocterm/src/components/basic.dart' show TextAlign;

void main() {
  group('Simple Text Alignment Test', () {
    test('text alignment in SizedBox', () async {
      await testNocterm('simple alignment', (tester) async {
        await tester.pumpComponent(
          Column(
            children: const [
              SizedBox(
                width: 20,
                child: Text('Left', textAlign: TextAlign.left),
              ),
              SizedBox(
                width: 20,
                child: Text('Center', textAlign: TextAlign.center),
              ),
              SizedBox(
                width: 20,
                child: Text('Right', textAlign: TextAlign.right),
              ),
            ],
          ),
        );

        final output = tester.terminalState.getText();
        print('Simple alignment output:');
        print(output);

        final lines = output.split('\n');

        // The SizedBox is centered in the 80-column terminal at position 30
        final boxOffset = 30;

        // Check left alignment (should be at box start)
        expect(lines[0].indexOf('Left'), equals(boxOffset + 0));

        // Check center alignment (centered in 20 width box)
        // "Center" is 6 chars, so offset should be (20-6)/2 = 7
        final centerPos = lines[1].indexOf('Center');
        print('Center position: $centerPos, expected ${boxOffset + 7}');
        expect(centerPos, equals(boxOffset + 7));

        // Check right alignment (right-aligned in 20 width box)
        // "Right" is 5 chars, so offset should be 20-5 = 15
        final rightPos = lines[2].indexOf('Right');
        print('Right position: $rightPos, expected ${boxOffset + 15}');
        expect(rightPos, equals(boxOffset + 15));
      }, debugPrintAfterPump: false);
    });
  });
}
