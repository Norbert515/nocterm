import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('FittedBox', () {
    test('FittedBox with BoxFit.contain', () async {
      await testNocterm(
        'fitted_box_contain',
        (tester) async {
          await tester.pumpComponent(Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(
                color: Colors.blue,
                width: 2,
              ),
            ),
            height: 40,
            width: 40,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text('A'),
            ),
          ));

          expect(
            tester.terminalState.containsText('A'),
            isTrue,
          );

          expect(tester.terminalState.size.width, equals(80));
        },
        size: Size(80, 24),
        debugPrintAfterPump: true,
      );
    });

    test('FittedBox with BoxFit.cover', () async {
      await testNocterm(
        'fitted_box_cover',
        (tester) async {
          await tester.pumpComponent(SizedBox(
            width: 20,
            height: 10,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 10,
                height: 5,
                child: Text('B'),
              ),
            ),
          ));

          final output = tester.terminalState.getText();
          expect(output, contains('B'));
          expect(tester.terminalState.size, equals(Size(80, 24)));
        },
        size: Size(80, 24),
        debugPrintAfterPump: true,
      );
    });

    test('FittedBox with BoxFit.fill', () async {
      await testNocterm(
        'fitted_box_fill',
        (tester) async {
          await tester.pumpComponent(
            SizedBox(
              width: 20,
              height: 10,
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: 5,
                  height: 2,
                  child: Text('C'),
                ),
              ),
            ),
          );

          // The child ("C") should be scaled to exactly fill 20x10, potentially distorting the aspect ratio
          final output = tester.terminalState.getText();
          expect(output, contains('C'));
          expect(tester.terminalState.size, equals(Size(80, 24)));
        },
        size: Size(80, 24),
      );
    });

    // Add more test cases for other BoxFit options as needed,
    // such as BoxFit.fitWidth, BoxFit.fitHeight, BoxFit.none, BoxFit.scaleDown

    //Test FittedBox with Alignment options

    //Test FittedBox with different constraints from parent

    //Test FittedBox with overflow and how it handles it
  });
}
