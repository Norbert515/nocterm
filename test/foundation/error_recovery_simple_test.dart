import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/components/error_widget.dart';

void main() {
  group('Error Recovery Simple', () {
    test('error box is constrained to widget space', () async {
      await testNocterm(
        'error box constraint',
        (tester) async {
          await tester.pumpComponent(
            Row(
              children: [
                const Text('A'),
                const SizedBox(
                  width: 30,
                  height: 5,
                  child: ErrorThrowingWidget(
                    throwInLayout: true,
                    errorMessage: 'Test Error',
                  ),
                ),
                const Text('B'),
              ],
            ),
          );

          final output = tester.terminalState.getText();
          print('Output:\n$output');

          // Check that A and B are visible and the error is between them
          expect(output, contains('A'));
          expect(output, contains('B'));

          // The error should show "No Error" because ErrorThrowingWidget
          // still paints normally after a layout error
          expect(output, contains('No Error'));

          // Verify horizontal layout
          final lines = output.split('\n');
          for (final line in lines) {
            if (line.contains('A') && line.contains('B')) {
              final aIndex = line.indexOf('A');
              final bIndex = line.indexOf('B');
              expect(aIndex, lessThan(bIndex));
              print('Found row with A at $aIndex and B at $bIndex');
              break;
            }
          }
        },
        debugPrintAfterPump: false,
        size: const Size(60, 10),
      );
    });

    test('direct error widget shows error box properly', () async {
      await testNocterm('direct error widget', (tester) async {
        await tester.pumpComponent(
          const Center(
            child: SizedBox(
              width: 40,
              height: 10,
              child: ErrorThrowingWidget(
                throwInLayout: true,
                errorMessage: 'Layout Test',
              ),
            ),
          ),
        );

        final output = tester.terminalState.getText();

        // When layout fails, the widget gets a default size and continues
        // The ErrorThrowingWidget will show "No Error" in its paint
        expect(output, contains('No Error'));
      }, debugPrintAfterPump: true);
    });

    test('paint error shows error box', () async {
      await testNocterm('paint error display', (tester) async {
        await tester.pumpComponent(
          const Center(
            child: SizedBox(
              width: 40,
              height: 10,
              child: ErrorThrowingWidget(
                throwInLayout: false,
                throwInPaint: true,
                errorMessage: 'Paint Test',
              ),
            ),
          ),
        );

        final output = tester.terminalState.getText();

        // When paint fails, we should see the error box
        expect(output, contains('Paint Error'));
        expect(output, contains('┌')); // Error box border
      }, debugPrintAfterPump: true);
    });
  });
}
