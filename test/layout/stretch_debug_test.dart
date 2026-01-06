import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart' hide TextAlign;
import 'package:nocterm/src/components/basic.dart' show TextAlign;

void main() {
  group('Stretch Debug Test', () {
    test('container constrains column correctly', () async {
      await testNocterm('container column constraints', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 30,
            height: 10,
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.solid),
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [Text('Test')],
            ),
          ),
        );

        print('Container with Column:');
        print(tester.terminalState.getText());
      }, debugPrintAfterPump: false);
    });

    test('container constrains text directly', () async {
      await testNocterm('container text constraints', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 30,
            height: 5,
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.solid),
              color: Colors.green,
            ),
            child: const Text('Test', textAlign: TextAlign.center),
          ),
        );

        print('Container with Text directly:');
        print(tester.terminalState.getText());
      }, debugPrintAfterPump: false);
    });
  });
}
