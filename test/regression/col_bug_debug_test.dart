import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

// Example component for testing
class ColumnBugDemo extends StatefulComponent {
  const ColumnBugDemo();

  @override
  State<ColumnBugDemo> createState() => _ColumnBugDemoState();
}

class _ColumnBugDemoState extends State<ColumnBugDemo> {
  bool first = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        first = false;
      });
    });
  }

  @override
  Component build(BuildContext context) {
    print('Building with first=$first');
    return Column(
      children: [if (first) Text('Widget 1') else Text('Widget 2')],
    );
  }
}

void main() {
  group('Column Bug Debug', () {
    test('debug column replacement', () async {
      await testNocterm('debug output', (tester) async {
        await tester.pumpComponent(const ColumnBugDemo());

        print('Initial render:');
        final output = tester.renderToString(showBorders: false);
        print(output);
        expect(tester.terminalState, containsText('Widget 1'));
        expect(tester.terminalState, isNot(containsText('Widget 2')));

        await Future.delayed(Duration(milliseconds: 2000));
        await tester.pump();

        print('\nAfter state change:');
        final output2 = tester.renderToString(showBorders: false);
        print(output2);

        // We expect only "Widget 2" to be shown
        expect(tester.terminalState, containsText('Widget 2'));
        expect(tester.terminalState, isNot(containsText('Widget 1')));
      });
    });
  });
}
