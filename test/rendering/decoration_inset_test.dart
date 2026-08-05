import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

/// The background fill is inset by one cell on every non-none border side
/// so it cannot erase a border it should be merging with. Every cell of the
/// box still has to be painted by one pass or the other.
void main() {
  test(
      'Given a box with vertical borders but no top or bottom '
      'when rendered then the whole column keeps the background', () {
    // _paintBorder paints a vertical side only for rows strictly between
    // top and bottom, so with top/bottom none the first and last cells of
    // the left and right columns are covered by neither pass.
    return testNocterm(
      'vertical-only border background',
      (tester) async {
        await tester.pumpComponent(
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              border: const BoxBorder(
                left: BorderSide(),
                right: BorderSide(),
                top: BorderSide(),
              ),
            ),
            child: const SizedBox.shrink(),
          ),
        );

        final state = tester.terminalState;
        // The box fills the 12x5 terminal. Row 4 is its last row, and with
        // no bottom border the vertical sides stop short of it, so its two
        // end cells are covered by neither the fill nor the border pass.
        expect(state.getCellAt(6, 4)?.style.backgroundColor, Colors.blue);
        expect(state.getCellAt(0, 4)?.style.backgroundColor, Colors.blue);
        expect(state.getCellAt(11, 4)?.style.backgroundColor, Colors.blue);
      },
      size: const Size(12, 5),
    );
  });

  test(
      'Given an opaque box with only a left border '
      'when drawn over content then nothing shows through', () {
    return testNocterm(
      'left-only border is opaque',
      (tester) async {
        await tester.pumpComponent(
          Stack(
            children: [
              const Text('XXXXXXXXXXXX\nXXXXXXXXXXXX\nXXXXXXXXXXXX'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  border: const BoxBorder(left: BorderSide()),
                ),
                child: const SizedBox(width: 6, height: 3),
              ),
            ],
          ),
        );

        final state = tester.terminalState;
        // Top and bottom cells of the left border column.
        expect(state.getCellAt(0, 0)?.style.backgroundColor, Colors.blue);
        expect(state.getCellAt(0, 2)?.style.backgroundColor, Colors.blue);
      },
      size: const Size(12, 5),
    );
  });
}
