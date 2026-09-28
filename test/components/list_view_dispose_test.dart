import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

/// The rows whose [_Probe] is initialized and not yet disposed, by index.
final _live = <int>[];

/// Stands in for a shared animation tick that states below the rows follow.
final _tick = _Notifier();

class _Notifier extends ChangeNotifier {
  void fire() => notifyListeners();
}

class _Probe extends StatefulComponent {
  const _Probe(this.index);

  final int index;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  late final int _index = component.index;

  @override
  void initState() {
    super.initState();
    _live.add(_index);
    _tick.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tick.removeListener(_onTick);
    _live.remove(_index);
    super.dispose();
  }

  @override
  Component build(BuildContext context) => Text('Row $_index');
}

/// A lazy list of [itemCount] rows, each with a [_Probe] below its root the
/// way a real row nests. The row's key includes [generation], so bumping it
/// replaces every row instead of updating it.
class _List extends StatefulComponent {
  const _List({required this.changes, this.controller});

  final _Notifier changes;
  final ScrollController? controller;

  @override
  State<_List> createState() => _ListState();
}

class _ListState extends State<_List> {
  int itemCount = 5;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    component.changes.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    component.changes.removeListener(_changed);
    super.dispose();
  }

  @override
  Component build(BuildContext context) => SizedBox(
        width: 30,
        height: 10,
        child: ListView.builder(
          lazy: true,
          itemExtent: 1,
          controller: component.controller,
          itemCount: itemCount,
          itemBuilder: (context, index) => Padding(
            key: ValueKey((index, generation)),
            padding: EdgeInsets.zero,
            child: _Probe(index),
          ),
        ),
      );
}

void main() {
  setUp(_live.clear);

  test(
    'a row replaced by one that cannot update it disposes its subtree',
    () async {
      await testNocterm('replaced rows', (tester) async {
        final changes = _Notifier();
        await tester.pumpComponent(_List(changes: changes));
        expect(_live, hasLength(5));

        tester.findState<_ListState>().generation++;
        changes.fire();
        await tester.pump();
        _tick.fire();
        await tester.pump();

        expect(
          _live,
          hasLength(5),
          reason: 'the replaced rows must dispose the states below them',
        );
      }, size: Size(35, 15));
    },
  );

  test('a row scrolled out of the cache extent disposes its subtree', () async {
    await testNocterm('scrolled rows', (tester) async {
      final changes = _Notifier();
      final controller = ScrollController();
      await tester.pumpComponent(
        _List(changes: changes, controller: controller),
      );
      tester.findState<_ListState>().itemCount = 100;
      changes.fire();
      await tester.pump();
      expect(_live, contains(0));

      controller.jumpTo(80);
      await tester.pump();
      await tester.pump();

      expect(_live, isNot(contains(0)));
      expect(
        _live.every((index) => index >= 60),
        isTrue,
        reason: 'only rows near the viewport may stay alive, got $_live',
      );
    }, size: Size(35, 15));
  });

  test('rows past a smaller itemCount dispose their subtrees', () async {
    await testNocterm('shrunk list', (tester) async {
      final changes = _Notifier();
      await tester.pumpComponent(_List(changes: changes));
      expect(_live, hasLength(5));

      tester.findState<_ListState>().itemCount = 2;
      changes.fire();
      await tester.pump();
      await tester.pump();

      expect(_live..sort(), [0, 1]);
    }, size: Size(35, 15));
  });
}
