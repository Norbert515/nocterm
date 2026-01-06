import 'package:nocterm/nocterm.dart';

void main() {
  // Super performant
  // runApp(const NoNavigation());
  // return;

  // Super slow
  runApp(const Navigator(home: MyAppWithNavigation(depth: 0)));
}

class NoNavigation extends StatefulComponent {
  const NoNavigation({super.key});
  @override
  State<NoNavigation> createState() => _NoNavigationState();
}

class _NoNavigationState extends State<NoNavigation> {
  final controller = TextEditingController();
  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.tab) {
          return true;
        }
        return false;
      },
      child: TextField(controller: controller, focused: true),
    );
  }
}

class MyAppWithNavigation extends StatefulComponent {
  const MyAppWithNavigation({super.key, this.depth = 0});
  final int depth;
  @override
  State<MyAppWithNavigation> createState() => _MyAppWithNavigationState();
}

class _MyAppWithNavigationState extends State<MyAppWithNavigation> {
  final controller = TextEditingController();
  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.tab) {
          Navigator.of(context).push(
            PageRoute(
              builder: (context) =>
                  MyAppWithNavigation(depth: component.depth + 1),
              settings: RouteSettings(name: 'depth_${component.depth}'),
            ),
          );
          return true;
        }
        return false;
      },
      child: component.depth == 5 || component.depth == 0
          ? Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.gray),
              ),
              width: 100,
              height: 100,
              child: TextField(controller: controller, focused: true),
            )
          : Text('Depth: ${component.depth}'),
    );
  }
}
