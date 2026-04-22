// Regression test for the ListView child-constraints caching mishap.
//
// Symptom observed in serverpod_cli's start-command log viewer: after the
// ListView cached its childConstraints across frames, the first few columns
// of Row-based list items (type label, timestamp) would drop out, leaving
// only the Expanded(Divider)/Expanded(Text) filling the row. The cached
// constraints object made RenderObject.layout's `identical(constraints,
// _constraints)` short-circuit trigger on the row, so RenderFlex.performLayout
// never re-ran and the row's children kept whatever offsets and sizes they
// had from a transient earlier frame.
//
// The pattern mirrors serverpod's LogMessageWidget / CompletedOperationWidget:
// a Row with a few fixed-width Text/SizedBox leaders followed by an
// Expanded child. If the Row's own layout is skipped, all the fixed-width
// leaders collapse to the default parent-data offset (0, 0) and the
// Expanded gets the whole row - exactly the visual breakage observed.

import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  test(
    'ListView Row items keep their leading columns across rebuilds',
    () async {
      await testNocterm('row leaders preserved across rebuild', (tester) async {
        await tester.pumpComponent(_LogViewer());

        final stateFinder = tester.findState<_LogViewerState>();
        expect(
          tester.terminalState.containsText('info'),
          isTrue,
          reason: 'initial frame must show the level label column',
        );
        expect(
          tester.terminalState.containsText('boot'),
          isTrue,
          reason: 'initial frame must show the message column',
        );

        // Append more entries. This is exactly the serverpod scenario: the
        // ListView's parent rebuilds with a larger itemCount, and existing
        // items get re-reconciled while new ones are built fresh.
        stateFinder.appendEntry('info', 'one');
        await tester.pump();
        stateFinder.appendEntry('warn', 'two');
        await tester.pump();
        stateFinder.appendEntry('error', 'three');
        await tester.pump();

        // Every message column must still be visible. If the row's layout was
        // short-circuited, the Expanded(Text(message)) slid to column 0 and
        // painted over the label, so the label text would disappear even
        // though the underlying entry still exists.
        for (final level in const ['info', 'warn', 'error']) {
          expect(
            tester.terminalState.containsText(level),
            isTrue,
            reason: 'level column "$level" disappeared after rebuild',
          );
        }
        for (final msg in const ['boot', 'one', 'two', 'three']) {
          expect(
            tester.terminalState.containsText(msg),
            isTrue,
            reason: 'message "$msg" missing after rebuild',
          );
        }
      });
    },
  );
}

class _LogViewer extends StatefulComponent {
  @override
  State<_LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<_LogViewer> {
  final List<_Entry> _entries = [const _Entry('info', 'boot')];

  void appendEntry(String level, String message) {
    setState(() {
      _entries.add(_Entry(level, message));
    });
  }

  @override
  Component build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 10,
      child: ListView.builder(
        itemCount: _entries.length,
        itemExtent: 1,
        itemBuilder: (context, index) => _LogRow(entry: _entries[index]),
      ),
    );
  }
}

class _Entry {
  const _Entry(this.level, this.message);
  final String level;
  final String message;
}

class _LogRow extends StatelessComponent {
  const _LogRow({required this.entry});
  final _Entry entry;

  @override
  Component build(BuildContext context) {
    return Row(
      children: [
        Text(entry.level),
        const SizedBox(width: 1),
        Expanded(child: Text(entry.message)),
      ],
    );
  }
}
