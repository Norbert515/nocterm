import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('ProgressBar', () {
    test('visual development - basic progress bar', () async {
      await testNocterm('basic progress bar at different values', (
        tester,
      ) async {
        print('Progress at 0%:');
        await tester.pumpComponent(
          SizedBox(
            width: 30,
            height: 1,
            child: ProgressBar(
              value: 0.0,
              valueColor: Colors.green,
              backgroundColor: Colors.grey,
            ),
          ),
        );

        print('\nProgress at 25%:');
        await tester.pumpComponent(
          SizedBox(
            width: 30,
            height: 1,
            child: ProgressBar(
              value: 0.25,
              valueColor: Colors.green,
              backgroundColor: Colors.grey,
            ),
          ),
        );

        print('\nProgress at 50%:');
        await tester.pumpComponent(
          SizedBox(
            width: 30,
            height: 1,
            child: ProgressBar(
              value: 0.5,
              valueColor: Colors.blue,
              backgroundColor: Colors.grey,
            ),
          ),
        );

        print('\nProgress at 75%:');
        await tester.pumpComponent(
          SizedBox(
            width: 30,
            height: 1,
            child: ProgressBar(
              value: 0.75,
              valueColor: Colors.yellow,
              backgroundColor: Colors.grey,
            ),
          ),
        );

        print('\nProgress at 100%:');
        await tester.pumpComponent(
          SizedBox(
            width: 30,
            height: 1,
            child: ProgressBar(
              value: 1.0,
              valueColor: Colors.green,
              backgroundColor: Colors.grey,
            ),
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test('visual development - progress bar with borders', () async {
      await testNocterm('progress bars with different border styles', (
        tester,
      ) async {
        print('Single border:');
        await tester.pumpComponent(
          SizedBox(
            width: 30,
            height: 3,
            child: ProgressBar(
              value: 0.6,
              borderStyle: ProgressBarBorderStyle.single,
              valueColor: Colors.cyan,
              backgroundColor: Colors.grey,
            ),
          ),
        );

        print('\nDouble border:');
        await tester.pumpComponent(
          SizedBox(
            width: 30,
            height: 3,
            child: ProgressBar(
              value: 0.6,
              borderStyle: ProgressBarBorderStyle.double,
              valueColor: Colors.magenta,
              backgroundColor: Colors.grey,
            ),
          ),
        );

        print('\nRounded border:');
        await tester.pumpComponent(
          SizedBox(
            width: 30,
            height: 3,
            child: ProgressBar(
              value: 0.6,
              borderStyle: ProgressBarBorderStyle.rounded,
              valueColor: Colors.green,
              backgroundColor: Colors.grey,
            ),
          ),
        );

        print('\nBold border:');
        await tester.pumpComponent(
          SizedBox(
            width: 30,
            height: 3,
            child: ProgressBar(
              value: 0.6,
              borderStyle: ProgressBarBorderStyle.bold,
              valueColor: Colors.red,
              backgroundColor: Colors.grey,
            ),
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test('visual development - progress bar with percentage', () async {
      await testNocterm('progress bar showing percentage', (tester) async {
        print('Progress bar with percentage display:');
        await tester.pumpComponent(
          Column(
            children: [
              SizedBox(
                width: 40,
                height: 3,
                child: ProgressBar(
                  value: 0.33,
                  showPercentage: true,
                  borderStyle: ProgressBarBorderStyle.single,
                  valueColor: Colors.green,
                  backgroundColor: Colors.grey,
                ),
              ),
              SizedBox(height: 1),
              SizedBox(
                width: 40,
                height: 3,
                child: ProgressBar(
                  value: 0.67,
                  showPercentage: true,
                  borderStyle: ProgressBarBorderStyle.rounded,
                  valueColor: Colors.blue,
                  backgroundColor: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test('visual development - custom characters', () async {
      await testNocterm('progress bar with custom fill characters', (
        tester,
      ) async {
        print('Custom characters:');
        await tester.pumpComponent(
          Column(
            children: [
              Text('Using = and -'),
              SizedBox(
                width: 30,
                height: 1,
                child: ProgressBar(
                  value: 0.7,
                  fillCharacter: '=',
                  emptyCharacter: '-',
                  valueColor: Colors.cyan,
                  backgroundColor: Colors.grey,
                ),
              ),
              SizedBox(height: 1),
              Text('Using # and .'),
              SizedBox(
                width: 30,
                height: 1,
                child: ProgressBar(
                  value: 0.4,
                  fillCharacter: '#',
                  emptyCharacter: '.',
                  valueColor: Colors.yellow,
                  backgroundColor: Colors.grey,
                ),
              ),
              SizedBox(height: 1),
              Text('Using ▓ and ░'),
              SizedBox(
                width: 30,
                height: 1,
                child: ProgressBar(
                  value: 0.85,
                  fillCharacter: '▓',
                  emptyCharacter: '░',
                  valueColor: Colors.magenta,
                  backgroundColor: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test('visual development - progress bar with labels', () async {
      await testNocterm('progress bar with custom labels', (tester) async {
        print('Progress bars with labels:');
        await tester.pumpComponent(
          Column(
            children: [
              SizedBox(
                width: 40,
                height: 3,
                child: ProgressBar(
                  value: 0.45,
                  label: 'Loading...',
                  borderStyle: ProgressBarBorderStyle.single,
                  valueColor: Colors.green,
                  backgroundColor: Colors.grey,
                ),
              ),
              SizedBox(height: 1),
              SizedBox(
                width: 40,
                height: 3,
                child: ProgressBar(
                  value: 0.75,
                  label: 'Processing',
                  borderStyle: ProgressBarBorderStyle.double,
                  valueColor: Colors.blue,
                  backgroundColor: Colors.grey,
                ),
              ),
              SizedBox(height: 1),
              SizedBox(
                width: 40,
                height: 1,
                child: ProgressBar(
                  value: 0.9,
                  label: 'Done!',
                  valueColor: Colors.green,
                  backgroundColor: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test(
      'visual development - indeterminate progress',
      skip: 'Known issue: Indeterminate progress animation timing',
      () async {
        await testNocterm('indeterminate progress animation', (tester) async {
          print('Indeterminate progress (animated):');
          await tester.pumpComponent(
            Column(
              children: [
                Text('Indeterminate progress bar:'),
                SizedBox(
                  width: 40,
                  height: 1,
                  child: ProgressBar(
                    indeterminate: true,
                    valueColor: Colors.cyan,
                    backgroundColor: Colors.grey,
                  ),
                ),
                SizedBox(height: 1),
                SizedBox(
                  width: 40,
                  height: 3,
                  child: ProgressBar(
                    indeterminate: true,
                    borderStyle: ProgressBarBorderStyle.rounded,
                    valueColor: Colors.magenta,
                    backgroundColor: Colors.grey,
                  ),
                ),
              ],
            ),
          );

          // Show a few animation frames
          for (int i = 0; i < 5; i++) {
            await Future.delayed(Duration(milliseconds: 100));
            print('\nAnimation frame ${i + 1}:');
            await tester.pump();
          }
        }, debugPrintAfterPump: true);
      },
    );

    test('renders correctly', () async {
      await testNocterm('correct rendering', (tester) async {
        await tester.pumpComponent(
          SizedBox(width: 20, height: 1, child: ProgressBar(value: 0.5)),
        );

        // Check that the progress bar contains filled and unfilled parts
        final terminalContent = tester.terminalState.getText();
        expect(terminalContent, contains('█'));
        expect(terminalContent, contains('░'));
      });
    });

    test('handles different sizes', () async {
      await testNocterm('different sizes', (tester) async {
        // Small progress bar
        await tester.pumpComponent(
          SizedBox(width: 10, height: 1, child: ProgressBar(value: 0.5)),
        );

        expect(tester.terminalState.getText().length, greaterThan(0));

        // Large progress bar
        await tester.pumpComponent(
          SizedBox(
            width: 50,
            height: 5,
            child: ProgressBar(
              value: 0.5,
              borderStyle: ProgressBarBorderStyle.single,
            ),
          ),
        );

        final content = tester.terminalState.getText();
        expect(content, contains('─'));
        expect(content, contains('│'));
      });
    });
  });
}
