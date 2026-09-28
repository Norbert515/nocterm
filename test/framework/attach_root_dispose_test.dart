import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

/// The labels of the [_Probe]s that are initialized and not yet disposed.
final _live = <String>[];

class _Probe extends StatefulComponent {
  const _Probe(this.label);

  final String label;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  late final String _label = component.label;

  @override
  void initState() {
    super.initState();
    _live.add(_label);
  }

  @override
  void dispose() {
    _live.remove(_label);
    super.dispose();
  }

  @override
  Component build(BuildContext context) => Text(_label);
}

void main() {
  setUp(_live.clear);

  test('a new root disposes the states below the old one', () async {
    await testNocterm('replaced root', (tester) async {
      await tester.pumpComponent(
        Column(
          children: [
            const _Probe('first a'),
            Padding(padding: EdgeInsets.zero, child: const _Probe('first b')),
          ],
        ),
      );
      expect(_live, ['first a', 'first b']);

      await tester.pumpComponent(const _Probe('second'));

      expect(_live, ['second']);
    });
  });
}
