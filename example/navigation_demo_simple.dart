import 'package:nocterm/nocterm.dart';

void main() {
  runApp(const NavigationDemo());
}

class NavigationDemo extends StatelessComponent {
  const NavigationDemo({super.key});

  @override
  Component build(BuildContext context) {
    return Navigator(
      home: const HomePage(),
      routes: {
        '/': (context) => const HomePage(),
        '/about': (context) => const AboutPage(),
      },
      popBehavior: const PopBehavior(escapeEnabled: true, customPopKey: 'q'),
      observers: [LoggingNavigatorObserver()],
    );
  }
}

class HomePage extends StatelessComponent {
  const HomePage({super.key});

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MenuList(
            items: const [MenuItem('About', '/about')],
            onSelect: (value) async {
              Navigator.of(context).pushNamed(value);
            },
          ),
        ],
      ),
    );
  }
}

class AboutPage extends StatelessComponent {
  const AboutPage({super.key});

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.double),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: const Text(
              'About',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          const Text('Navigation Demo v1.0'),
          const Text('Built with Nocterm TUI Framework'),
          const SizedBox(height: 2),
          const Text('This demonstrates:'),
          const Text('- Push/Pop navigation'),
          const Text('- Named routes'),
          const Text('- Modal dialogs'),
          const Text('- Deep linking'),
          const Text('- Return values'),
          const SizedBox(height: 2),
          const Text('Press ESC or Q to go back'),
          MenuList(
            items: const [
              MenuItem('Back', '/'),
              MenuItem('Home', '/'),
              MenuItem('About', '/about'),
              MenuItem('Settings', '/settings'),
            ],
            onSelect: (value) {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

// Simple menu list component
class MenuList extends StatefulComponent {
  final List<MenuItem> items;
  final Function(dynamic) onSelect;

  const MenuList({super.key, required this.items, required this.onSelect});

  @override
  State<MenuList> createState() => _MenuListState();
}

class _MenuListState extends State<MenuList> {
  int _selectedIndex = 0;

  bool _handleKey(LogicalKey key) {
    if (key == LogicalKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % component.items.length;
      });
      return true;
    } else if (key == LogicalKey.arrowUp) {
      setState(() {
        _selectedIndex =
            (_selectedIndex - 1 + component.items.length) %
            component.items.length;
      });
      return true;
    } else if (key == LogicalKey.enter) {
      component.onSelect(component.items[_selectedIndex].value);
      return true;
    }
    return false;
  }

  @override
  Component build(BuildContext context) {
    return KeyboardListener(
      onKeyEvent: _handleKey,
      autofocus: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < component.items.length; i++)
            Text(
              '${i == _selectedIndex ? '> ' : '  '}${component.items[i].label}',
              style: i == _selectedIndex
                  ? const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGB(100, 200, 100),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

class MenuItem {
  final String label;
  final dynamic value;

  const MenuItem(this.label, this.value);
}
