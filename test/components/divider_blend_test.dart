import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

/// Dividers reaching into a surrounding border with negative indents must
/// form tee junctions instead of leaving gaps or overwriting the border.
void main() {
  test(
      'Given a bordered box with a horizontal divider reaching into the '
      'borders when rendered then it tees into both border columns', () {
    return testNocterm(
      'horizontal divider tees',
      (tester) async {
        await tester.pumpComponent(
          Container(
            decoration: BoxDecoration(border: BoxBorder.all()),
            child: Column(
              children: [
                const SizedBox(height: 2),
                const Divider(indent: -1, endIndent: -1),
                Expanded(child: const SizedBox.shrink()),
              ],
            ),
          ),
        );

        final state = tester.terminalState;
        // Border cols are 0 and 11; content starts at row 1, so the
        // divider sits on row 3.
        expect(state.getTextAt(0, 3, length: 1), '├');
        expect(state.getTextAt(11, 3, length: 1), '┤');
        expect(state.getTextAt(5, 3, length: 1), '─');
        // The border away from the junction is untouched.
        expect(state.getTextAt(0, 2, length: 1), '│');
      },
      size: const Size(12, 7),
    );
  });

  test(
      'Given a bordered box with a vertical divider reaching into the '
      'borders when rendered then it tees into both border rows', () {
    return testNocterm(
      'vertical divider tees',
      (tester) async {
        await tester.pumpComponent(
          Container(
            decoration: BoxDecoration(border: BoxBorder.all()),
            child: Row(
              children: [
                const SizedBox(width: 3),
                const VerticalDivider(indent: -1, endIndent: -1),
                Expanded(child: const SizedBox.shrink()),
              ],
            ),
          ),
        );

        final state = tester.terminalState;
        // Border rows are 0 and 4; content starts at col 1, so the
        // divider sits on col 4.
        expect(state.getTextAt(4, 0, length: 1), '┬');
        expect(state.getTextAt(4, 4, length: 1), '┴');
        expect(state.getTextAt(4, 2, length: 1), '│');
        expect(state.getTextAt(3, 0, length: 1), '─');
      },
      size: const Size(12, 5),
    );
  });

  test(
      'Given a bordered box with crossing dividers '
      'when rendered then a cross junction is formed where they intersect', () {
    return testNocterm(
      'crossing dividers',
      (tester) async {
        await tester.pumpComponent(
          Container(
            decoration: BoxDecoration(border: BoxBorder.all()),
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 2),
                    const Divider(indent: -1, endIndent: -1),
                    Expanded(child: const SizedBox.shrink()),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 3),
                    const VerticalDivider(indent: -1, endIndent: -1),
                    Expanded(child: const SizedBox.shrink()),
                  ],
                ),
              ],
            ),
          ),
        );

        final state = tester.terminalState;
        expect(state.getTextAt(4, 3, length: 1), '┼');
        expect(state.getTextAt(4, 0, length: 1), '┬');
        expect(state.getTextAt(0, 3, length: 1), '├');
      },
      size: const Size(12, 7),
    );
  });

  test(
      'Given a rounded bordered box with a divider reaching into the '
      'borders '
      'when rendered then the corners stay rounded', () {
    return testNocterm(
      'rounded corners survive',
      (tester) async {
        await tester.pumpComponent(
          Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.rounded),
            ),
            child: Column(
              children: [
                const SizedBox(height: 2),
                const Divider(indent: -1, endIndent: -1),
                Expanded(child: const SizedBox.shrink()),
              ],
            ),
          ),
        );

        final state = tester.terminalState;
        expect(state.getTextAt(0, 3, length: 1), '├');
        expect(state.getTextAt(0, 0, length: 1), '╭');
        expect(state.getTextAt(11, 6, length: 1), '╯');
      },
      size: const Size(12, 7),
    );
  });

  test(
      'Given a bordered box with a divider that stays within its bounds '
      'when rendered then the border is untouched', () {
    return testNocterm(
      'divider within bounds',
      (tester) async {
        await tester.pumpComponent(
          Container(
            decoration: BoxDecoration(border: BoxBorder.all()),
            child: Column(
              children: [
                const SizedBox(height: 2),
                const Divider(),
                Expanded(child: const SizedBox.shrink()),
              ],
            ),
          ),
        );

        final state = tester.terminalState;
        // No caps, no junctions: the border column keeps its vertical
        // line.
        expect(state.getTextAt(0, 3, length: 1), '│');
        expect(state.getTextAt(1, 3, length: 1), '─');
        expect(state.getTextAt(10, 3, length: 1), '─');
      },
      size: const Size(12, 7),
    );
  });
}
