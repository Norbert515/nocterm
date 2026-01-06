import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  test('Parent bug', () async {
    await testNocterm(
      'Parent bug',
      (tester) async {
        await tester.pumpComponent(Navigator(home: _Pusher()));

        // Push page
        await tester.sendKey(LogicalKey.enter);
        await tester.pump();

        // Pop page
        await tester.sendKey(LogicalKey.escape);
        await tester.pump();
      },
      debugPrintAfterPump: false,
      size: Size(30, 10),
    );
  });
}

class _Pusher extends StatefulComponent {
  const _Pusher();

  @override
  State<_Pusher> createState() => _PusherState();
}

class _PusherState extends State<_Pusher> {
  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (key) {
        print('Before push:');
        print('  context: $context');
        print('  context.parent: ${context.parent}');
        print('  context.parent?.parent: ${context.parent?.parent}');
        print('  mounted: $mounted');

        Navigator.of(context)
            .push(
              PageRoute(
                builder: (context) => _SecondPage(),
                settings: RouteSettings(name: 'second'),
              ),
            )
            .then((it) {
              print('After pop:');
              print('  context: $context');
              print('  context.parent: ${context.parent}');
              print('  context.parent?.parent: ${context.parent?.parent}');
              print('  mounted: $mounted');
              expect(context.parent?.parent, isNotNull);
            });
        return true;
      },
      child: Container(),
    );
  }
}

class _SecondPage extends StatelessComponent {
  const _SecondPage();

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (key) {
        Navigator.of(context).pop();
        return true;
      },
      child: Container(),
    );
  }
}
