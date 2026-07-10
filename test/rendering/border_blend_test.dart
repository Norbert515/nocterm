import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

/// A border's corner cells merge with box-drawing characters painted
/// underneath them, so a panel overlaid on another box tees into its border.
void main() {
  test(
      'Given a bordered panel overlaid on a bordered box '
      'when rendered then the panel corners tee into the border underneath',
      () {
    return testNocterm(
      'overlay tees into outer border',
      (tester) async {
        await tester.pumpComponent(
          Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(style: BoxBorderStyle.rounded),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  width: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(style: BoxBorderStyle.rounded),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        final state = tester.terminalState;
        // The panel spans cols 12-19 over the full height; its left edge
        // lands on the outer box's top and bottom borders.
        expect(state.getTextAt(12, 0, length: 1), '┬');
        expect(state.getTextAt(12, 6, length: 1), '┴');
        // Coincident corners keep their rounded shape.
        expect(state.getTextAt(19, 0, length: 1), '╮');
        expect(state.getTextAt(19, 6, length: 1), '╯');
        expect(state.getTextAt(0, 0, length: 1), '╭');
        // The panel's own left edge stays a plain line.
        expect(state.getTextAt(12, 3, length: 1), '│');
      },
      size: const Size(20, 7),
    );
  });

  test(
      'Given an overlaid bordered panel with a background color '
      'when rendered then the background does not erase the border underneath',
      () {
    return testNocterm(
      'background keeps outer border',
      (tester) async {
        await tester.pumpComponent(
          Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(style: BoxBorderStyle.rounded),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  width: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      border: BoxBorder.all(style: BoxBorderStyle.rounded),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        final state = tester.terminalState;
        // The background fill stops at the panel's interior, so the border
        // ring still merges with the outer box underneath.
        expect(state.getTextAt(12, 0, length: 1), '┬');
        expect(state.getTextAt(12, 6, length: 1), '┴');
        expect(state.getTextAt(19, 0, length: 1), '╮');
        // The interior is filled with the background.
        expect(
          state.getCellAt(15, 3)?.style.backgroundColor,
          Colors.blue,
        );
      },
      size: const Size(20, 7),
    );
  });
}
