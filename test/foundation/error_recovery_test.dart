import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/components/error_widget.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import 'package:test/test.dart';

void main() {
  group('Error Recovery', () {
    test(
      'error box takes only the space of failed widget',
      skip: 'Error recovery system needs refactoring',
      () async {
        await testNocterm(
          'error box size constraint',
          (tester) async {
            await tester.pumpComponent(
              Row(
                children: [
                  const SizedBox(width: 10, height: 5, child: Text('Left')),
                  const SizedBox(
                    width: 20,
                    height: 5,
                    child: ErrorThrowingWidget(
                      throwInLayout: true,
                      errorMessage: 'Error in middle',
                    ),
                  ),
                  const SizedBox(width: 10, height: 5, child: Text('Right')),
                ],
              ),
            );

            final output = tester.terminalState.getText();
            print('Full output:');
            print(output);

            // All widgets should be visible in a row
            final lines = output.split('\n');

            // The error box should be constrained to its allocated space
            // and not overflow to other widgets
            expect(output, contains('Left'));
            expect(output, contains('Right'));

            // Check that the error box appears between Left and Right
            // and doesn't take the full width
            for (final line in lines) {
              if (line.contains('Left') && line.contains('Layout Error')) {
                // Check positioning - Left should come before the error
                final leftIndex = line.indexOf('Left');
                final errorIndex = line.indexOf('Layout Error');
                if (errorIndex != -1) {
                  expect(leftIndex, lessThan(errorIndex));
                }
              }
            }
          },
          debugPrintAfterPump: true,
          size: const Size(80, 10),
        );
      },
    );

    test(
      'errors clear when performLayout succeeds on retry',
      skip: 'Error recovery system needs refactoring',
      () async {
        await testNocterm('error recovery on successful layout', (
          tester,
        ) async {
          // Create a widget that fails initially but succeeds on rebuild
          final widget = _TestRecoverableWidget();

          await tester.pumpComponent(
            Column(
              children: [const Text('Before'), widget, const Text('After')],
            ),
          );

          // First pump - should show error
          var output = tester.terminalState.getText();
          expect(output, contains('Before'));
          expect(output, contains('After'));
          // Should show error box
          expect(output, contains('Layout Error'));

          // Change state to stop throwing
          widget.stopThrowing();

          // Force a rebuild by pumping again
          await tester.pump();

          output = tester.terminalState.getText();
          expect(output, contains('Before'));
          expect(output, contains('After'));
          expect(output, contains('Recovered'));
          // Error should be gone
          expect(output, isNot(contains('Layout Error')));
        }, debugPrintAfterPump: true);
      },
    );

    test(
      'paint errors clear on successful repaint',
      skip: 'Error recovery system needs refactoring',
      () async {
        await testNocterm('paint error recovery', (tester) async {
          final widget = _TestRecoverableWidget(throwInPaint: true);

          await tester.pumpComponent(widget);

          // First pump - should show paint error
          var output = tester.terminalState.getText();
          expect(output, contains('Paint Error'));

          // Stop throwing
          widget.stopThrowing();
          await tester.pump();

          output = tester.terminalState.getText();
          expect(output, contains('Recovered'));
          expect(output, isNot(contains('Paint Error')));
        }, debugPrintAfterPump: true);
      },
    );
  });
}

/// A test widget that can recover from errors
// ignore: must_be_immutable
class _TestRecoverableWidget extends SingleChildRenderObjectComponent {
  _TestRecoverableWidget({this.throwInPaint = false});

  final bool throwInPaint;
  bool _shouldThrow = true;

  void stopThrowing() {
    _shouldThrow = false;
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderRecoverable(
      shouldThrow: _shouldThrow,
      throwInPaint: throwInPaint,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderRecoverable renderObject,
  ) {
    renderObject.shouldThrow = _shouldThrow;
  }
}

class _RenderRecoverable extends RenderObject {
  _RenderRecoverable({required bool shouldThrow, required this.throwInPaint})
    : _shouldThrow = shouldThrow;

  bool _shouldThrow;
  final bool throwInPaint;

  set shouldThrow(bool value) {
    if (_shouldThrow != value) {
      _shouldThrow = value;
      markNeedsLayout();
      markNeedsPaint();
    }
  }

  @override
  void performLayout() {
    if (!throwInPaint && _shouldThrow) {
      throw Exception('Recoverable layout error');
    }
    size = constraints.constrain(const Size(20, 3));
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);

    if (throwInPaint && _shouldThrow) {
      throw Exception('Recoverable paint error');
    }

    canvas.drawText(offset, 'Recovered');
  }
}
