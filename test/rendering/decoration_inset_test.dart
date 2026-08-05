import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

/// The background fill is inset by one cell on every non-none border side
/// so it cannot erase a border it should be merging with. Every cell of the
/// box still has to be painted by one pass or the other.
void main() {
  /// Where the decoration painted a background: `#` filled, `·` bare.
  ///
  /// Snapshots carry characters only, so an unpainted cell is invisible in
  /// one - it holds a space either way. This draws the coverage itself, so
  /// a hole in the fill shows up as a hole in the picture.
  List<String> backgroundMap(TerminalState state, int width, int height) {
    return [
      for (var y = 0; y < height; y++)
        [
          for (var x = 0; x < width; x++)
            state.getCellAt(x, y)?.style.backgroundColor == null ? '·' : '#',
        ].join(),
    ];
  }

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
      'Given a box with vertical borders but no top or bottom '
      'when rendered then its background covers every cell', () {
    return testNocterm(
      'vertical-only border background picture',
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

        expect(backgroundMap(tester.terminalState, 12, 5), [
          '############',
          '############',
          '############',
          '############',
          '############',
        ]);
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

  test(
      'Given an opaque box with only a left border '
      'when drawn over content then its background covers every cell', () {
    return testNocterm(
      'left-only border background picture',
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

        // The box is 8 wide; the four columns beyond it stay bare.
        expect(backgroundMap(tester.terminalState, 12, 5), [
          '########····',
          '########····',
          '########····',
          '########····',
          '########····',
        ]);
      },
      size: const Size(12, 5),
    );
  });

  test(
      'Given a titled bordered box with a background '
      'when the title has its own style then it keeps the background', () {
    // The title paints on the border row, which the inset fill does not
    // cover, so a title style with no backgroundColor of its own takes
    // whatever is underneath the panel.
    return testNocterm(
      'title keeps panel background',
      (tester) async {
        await tester.pumpComponent(
          Stack(
            children: [
              Container(
                decoration: const BoxDecoration(color: Colors.red),
                child: const SizedBox(width: 12, height: 5),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  border: BoxBorder.all(),
                  title: const BorderTitle(
                    text: 'Hi',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                child: const SizedBox(width: 10, height: 3),
              ),
            ],
          ),
        );

        final state = tester.terminalState;
        final titleX = state.getText().split('\n').first.indexOf('H');
        expect(titleX, greaterThan(0), reason: 'title should be rendered');
        expect(state.getCellAt(titleX, 0)?.style.backgroundColor, Colors.blue);
      },
      size: const Size(12, 5),
    );
  });

  test(
      'Given a dotted border with a light divider '
      'when they meet then the junction matches the border weight', () {
    // A dotted border's edges and corners carry the same weight, so a light
    // divider meets them at that weight rather than a heavier one.
    return testNocterm(
      'dotted border junction weight',
      (tester) async {
        await tester.pumpComponent(
          Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.dotted),
            ),
            child: Column(
              children: [
                const SizedBox(height: 1),
                const Divider(indent: -1, endIndent: -1),
                Expanded(child: const SizedBox.shrink()),
              ],
            ),
          ),
        );

        final state = tester.terminalState;
        expect(state.getTextAt(0, 2, length: 1), '├');
        expect(state.getTextAt(11, 2, length: 1), '┤');
      },
      size: const Size(12, 5),
    );
  });
}
