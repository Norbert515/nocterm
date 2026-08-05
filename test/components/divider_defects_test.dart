import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

/// What a divider's blended painting must do at the awkward edges of its
/// own geometry: infinite sizes, no extent at all, fractional indents, and
/// weights with no junction between them.
void main() {
  group('Given a divider under unbounded main-axis constraints', () {
    // performLayout constrains to Size(double.infinity, height), so an
    // unbounded parent leaves the size infinite, and rounding a non-finite
    // value throws. RenderDecoratedBox._paintDecoration and
    // TerminalCanvas.fillRect guard the same way.

    test('when horizontal then painting does not throw', () {
      return testNocterm(
        'horizontal divider unbounded',
        (tester) async {
          await tester.pumpComponent(
            Row(children: [const Text('hi'), const Divider()]),
          );
          // The binding catches a paint exception by discarding the frame,
          // so a sibling surviving is what says painting completed.
          expect(tester.terminalState, containsText('hi'));
        },
        size: const Size(12, 3),
      );
    });

    test('when vertical then painting does not throw', () {
      return testNocterm(
        'vertical divider unbounded',
        (tester) async {
          await tester.pumpComponent(
            Column(children: [const Text('hi'), const VerticalDivider()]),
          );
          expect(tester.terminalState, containsText('hi'));
        },
        size: const Size(12, 3),
      );
    });
  });

  test(
      'Given a divider with no cells of its own '
      'when it reaches into a border then nothing is painted', () {
    // There is no rule for an end to join the border to, so an arm left on
    // the border would promise a line that does not exist.
    return testNocterm(
      'one-cell divider span',
      (tester) async {
        await tester.pumpComponent(
          Container(
            decoration: BoxDecoration(border: BoxBorder.all()),
            child: Column(
              children: [
                const SizedBox(height: 2),
                Row(
                  children: [
                    const SizedBox(width: 0, child: Divider(indent: -1)),
                    Expanded(child: const SizedBox.shrink()),
                  ],
                ),
                Expanded(child: const SizedBox.shrink()),
              ],
            ),
          ),
        );

        final state = tester.terminalState;
        expect(state.getTextAt(0, 3, length: 1), '│');
      },
      size: const Size(12, 7),
    );
  });

  test(
      'Given a divider with a fractional negative indent '
      'when rendered then its own first cell keeps the full line', () {
    // Whether an end reaches outside is decided by the cells it covers,
    // not by the sign of the indent: an indent in (-0.5, 0) rounds back
    // onto the divider's own first cell, which is not a cap.
    return testNocterm(
      'fractional indent',
      (tester) async {
        await tester.pumpComponent(
          Container(
            decoration: BoxDecoration(border: BoxBorder.all()),
            child: Column(
              children: [
                const SizedBox(height: 2),
                const Divider(indent: -0.5),
                Expanded(child: const SizedBox.shrink()),
              ],
            ),
          ),
        );

        final state = tester.terminalState;
        expect(state.getTextAt(1, 3, length: 1), '─');
      },
      size: const Size(12, 7),
    );
  });

  test(
      'Given a heavy divider reaching into a double border '
      'when rendered then the border survives', () {
    // Heavy meeting double has no Unicode junction, so the wall keeps its
    // own character.
    return testNocterm(
      'heavy divider into double border',
      (tester) async {
        await tester.pumpComponent(
          Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.double),
            ),
            child: Column(
              children: [
                const SizedBox(height: 2),
                const Divider(
                  indent: -1,
                  endIndent: -1,
                  style: DividerStyle.bold,
                ),
                Expanded(child: const SizedBox.shrink()),
              ],
            ),
          ),
        );

        final state = tester.terminalState;
        expect(state.getTextAt(0, 3, length: 1), '║');
        expect(state.getTextAt(11, 3, length: 1), '║');
      },
      size: const Size(12, 7),
    );
  });

  test(
      'Given a divider whose cap lands on a cell it does not change '
      'when rendered then that cell keeps its own colour', () {
    // A cell the merge declines to change is not the divider's to restyle
    // either - keeping the glyph means keeping the cell.
    return testNocterm(
      'kept glyph keeps its colour',
      (tester) async {
        await tester.pumpComponent(
          Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.green),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 3),
                    const VerticalDivider(indent: -1, color: Colors.green),
                    Expanded(child: const SizedBox.shrink()),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 3),
                    const VerticalDivider(indent: -1, color: Colors.red),
                    Expanded(child: const SizedBox.shrink()),
                  ],
                ),
              ],
            ),
          ),
        );

        final state = tester.terminalState;
        // The first divider already formed the tee; the second contributes
        // an arm that is already there, so the glyph is kept.
        expect(state.getTextAt(4, 0, length: 1), '┬');
        // Keeping the glyph should mean keeping the cell, colour included.
        expect(state.getCellAt(4, 0)?.style.color, Colors.green);
      },
      size: const Size(12, 5),
    );
  });
}
