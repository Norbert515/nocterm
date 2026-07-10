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
          // The overlaid-panel case needs no indents at all: the panel's
          // border corners always merge with the border they land on.
          SizedBox(
            height: 7,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(style: BoxBorderStyle.rounded),
                      title: BorderTitle(
                        text: 'Overlaid panel - corners tee into the border',
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        border: BoxBorder.all(style: BoxBorderStyle.rounded),
                      ),
                      child: Center(child: Text('Apps')),
                    ),
                  ),
                ),
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
        // header rule inside one bordered box.
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.rounded),
              title: BorderTitle(text: 'Split panes'),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Center(child: Text('Server')),
                      Divider(indent: indent, endIndent: indent),
                      Expanded(child: Center(child: Text('logs'))),
                    ],
                  ),
                ),
                VerticalDivider(indent: indent, endIndent: indent),
                Expanded(child: Center(child: Text('Apps'))),
              ],
            ),
          ),
        ),
        SizedBox(height: 1),
        // Scenario 2: crossing dividers meeting in a cross junction, plus
        // a heavy divider showing mixed-weight tees.
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.rounded),
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
      ],
    );
  }
}

void main() {
  runApp(const BoxLineBlendingDemo());
}
