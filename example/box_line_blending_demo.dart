import 'package:nocterm/nocterm.dart';

/// Demonstrates box-line blending: dividers and overlaid borders merge with
/// the box-drawing characters underneath them, forming junctions
/// (`├ ┤ ┬ ┴ ┼`) instead of leaving gaps.
///
/// Dividers join a surrounding border by reaching into it with negative
/// indents. The left column keeps dividers inside their own bounds
/// (`indent: 0`, lines stop short of the border), the right column reaches
/// into the border rows and columns (`indent: -1`, junctions form) - same
/// layout otherwise.
class BoxLineBlendingDemo extends StatelessComponent {
  const BoxLineBlendingDemo({super.key});

  @override
  Component build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Box-Line Blending Demo',
            style: TextStyle(
                color: Colors.cyan, decoration: TextDecoration.underline),
          ),
          SizedBox(height: 1),
          Text(
            'Left: indent: 0 (dividers stop short of the border) · '
            'Right: indent: -1 (junctions)',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _DemoPane(reachIntoBorders: false)),
                SizedBox(width: 2),
                Expanded(child: _DemoPane(reachIntoBorders: true)),
              ],
            ),
          ),
          SizedBox(height: 1),
          Text(
            'Press Ctrl+C to exit',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// One column of divider scenarios, with or without negative indents.
class _DemoPane extends StatelessComponent {
  const _DemoPane({required this.reachIntoBorders});

  final bool reachIntoBorders;

  @override
  Component build(BuildContext context) {
    final indent = reachIntoBorders ? -1.0 : 0.0;
    final label = reachIntoBorders ? 'indent: -1' : 'indent: 0';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: reachIntoBorders ? Colors.green : Colors.red,
          ),
        ),
        SizedBox(height: 1),
        // Scenario 1: split panes - a vertical divider and a horizontal
        // header rule inside one bordered box, in two different styles.
        //
        // The dashed rule tees into the light border as a solid `├`: dashed
        // and dotted variants carry the same arms as their solid
        // counterparts, so a junction never comes out dashed. Where it runs
        // into the double divider it forms `╢`, and the double divider tees
        // into the light border above and below as `╥` and `╨`.
        //
        // The divider is a layer of its own, painted before the content, so
        // that the horizontal rule has something to join when it arrives.
        // Blending only sees what is already in the buffer: a junction
        // needs the surface drawn first, exactly as the box's own border is
        // drawn before the dividers that tee into it. As Row siblings the
        // vertical divider would paint second and the rule would simply
        // stop against it.
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.rounded),
              title: BorderTitle(text: 'Split panes'),
            ),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: SizedBox.shrink()),
                    VerticalDivider(
                      indent: indent,
                      endIndent: indent,
                      style: DividerStyle.double,
                    ),
                    Expanded(child: SizedBox.shrink()),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Center(child: Text('Server')),
                          Divider(
                            indent: indent,
                            endIndent: indent,
                            style: DividerStyle.dashed,
                          ),
                          Expanded(child: Center(child: Text('logs'))),
                        ],
                      ),
                    ),
                    // Where the divider already is.
                    SizedBox(width: 1),
                    Expanded(child: Center(child: Text('Apps'))),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 1),
        // Scenario 2: crossing dividers meeting in a cross junction, plus
        // a heavy divider showing mixed-weight tees.
        //
        // The border is heavy here, so the light dividers reaching into it
        // tee as `┠`/`┨` and `┰`/`┸` - the wall stays heavy and the arm
        // stays light rather than either weight winning. The heavy divider
        // meets it as `┣`/`┫`, all of one weight.
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.bold),
              title: BorderTitle(text: 'Crossing + heavy'),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    children: [
                      Expanded(child: SizedBox.shrink()),
                      Divider(indent: indent, endIndent: indent),
                      Expanded(child: SizedBox.shrink()),
                      Divider(
                        indent: indent,
                        endIndent: indent,
                        style: DividerStyle.bold,
                      ),
                      Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(child: SizedBox.shrink()),
                      VerticalDivider(indent: indent, endIndent: indent),
                      Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 1),
        // Scenario 3: a floating panel overlaid on the box.
        //
        // The panel carries a background, so it hides the text running
        // underneath it - but its corners still tee into the border rather
        // than staying `╭`/`╰`. Occlusion and blending are decided
        // separately: the background fill stops short of the border ring so
        // it cannot erase a border it is meant to merge with, and that ring
        // is exactly where the corners fuse. Neither depends on the indent,
        // so both columns render alike.
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(style: BoxBorderStyle.rounded),
                    title: BorderTitle(text: 'Overlaid panel'),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1),
                    child: Text(
                      'This text sits behind the floating panel. Where the '
                      'panel covers it, it simply disappears.',
                      // Capped so a narrow terminal clips it rather than
                      // letting it spill over the box's own bottom border.
                      maxLines: 3,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  width: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: BoxBorder.all(style: BoxBorderStyle.rounded),
                    ),
                    child: Center(child: Text('Apps')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void main() {
  runApp(const BoxLineBlendingDemo());
}
