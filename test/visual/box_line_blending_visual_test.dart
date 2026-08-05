import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

/// Box-line blending, shown rather than described.
///
/// Each test states the whole box as it should look. On failure the matcher
/// prints the expected and actual pictures one above the other, so a broken
/// junction is visible at a glance instead of being spelled out one cell at
/// a time. (`·` is an empty cell.)
///
/// The character-level assertions live beside these in
/// test/components/divider_defects_test.dart and
/// test/utils/box_line_merging_test.dart.
void main() {
  /// A bordered box with [child] on its middle row.
  Component boxWith(
    Component child, {
    BoxBorderStyle style = BoxBorderStyle.solid,
  }) {
    return Container(
      decoration: BoxDecoration(border: BoxBorder.all(style: style)),
      child: Column(
        children: [
          const SizedBox(height: 1),
          child,
          Expanded(child: const SizedBox.shrink()),
        ],
      ),
    );
  }

  Matcher looksLike(List<String> picture) =>
      matchesSnapshot(picture.join('\n'));

  Future<void> expectBox(Component component, List<String> picture) {
    return testNocterm(
      'box line blending',
      (tester) async {
        await tester.pumpComponent(component);
        expect(tester.terminalState, looksLike(picture));
      },
      size: const Size(14, 5),
    );
  }

  test('A light divider tees into a light border', () {
    return expectBox(
      boxWith(const Divider(indent: -1, endIndent: -1)),
      [
        '┌────────────┐',
        '│············│',
        '├────────────┤',
        '│············│',
        '└────────────┘',
      ],
    );
  });

  test('A double divider tees into a light border', () {
    return expectBox(
      boxWith(
        const Divider(indent: -1, endIndent: -1, style: DividerStyle.double),
      ),
      [
        '┌────────────┐',
        '│············│',
        '╞════════════╡',
        '│············│',
        '└────────────┘',
      ],
    );
  });

  test('A heavy divider leaves a double border intact', () {
    // Heavy meeting double has no junction glyph, so the end contributes
    // nothing and the wall stays whole rather than gaining two holes.
    return expectBox(
      boxWith(
        const Divider(indent: -1, endIndent: -1, style: DividerStyle.bold),
        style: BoxBorderStyle.double,
      ),
      [
        '╔════════════╗',
        '║············║',
        '║━━━━━━━━━━━━║',
        '║············║',
        '╚════════════╝',
      ],
    );
  });

  test('A light divider tees into a dotted border', () {
    // The dotted style's edges are heavy while its corners are light, so
    // the junctions currently render ┠ ┨ - bolder than the box itself.
    return expectBox(
      boxWith(
        const Divider(indent: -1, endIndent: -1),
        style: BoxBorderStyle.dotted,
      ),
      [
        '┌┅┅┅┅┅┅┅┅┅┅┅┅┐',
        '┇············┇',
        '├────────────┤',
        '┇············┇',
        '└┅┅┅┅┅┅┅┅┅┅┅┅┘',
      ],
    );
  });

  test('A divider with a fractional indent draws an unbroken line', () {
    // Whether an end reaches outside comes from the cells the run covers,
    // not the sign of the indent: -0.5 rounds back onto the divider's own
    // first cell, which is not an end.
    return expectBox(
      boxWith(const Divider(indent: -0.5)),
      [
        '┌────────────┐',
        '│············│',
        '│────────────│',
        '│············│',
        '└────────────┘',
      ],
    );
  });

  test('A divider with no cells of its own leaves the border alone', () {
    // With no rule to join, an arm on the border would promise a line that
    // is not there.
    return expectBox(
      boxWith(
        Row(
          children: [
            const SizedBox(width: 0, child: Divider(indent: -1)),
            Expanded(child: const SizedBox.shrink()),
          ],
        ),
      ),
      [
        '┌────────────┐',
        '│············│',
        '│············│',
        '│············│',
        '└────────────┘',
      ],
    );
  });
}
