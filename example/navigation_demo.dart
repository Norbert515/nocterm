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
        '/settings': (context) => const SettingsPage(),
        '/settings/profile': (context) => const ProfilePage(),
        '/settings/appearance': (context) => const AppearancePage(),
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
          Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.double),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: const Text(
              'Navigation Demo - Home',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          const Text('Welcome to the Navigation Demo!'),
          const SizedBox(height: 1),
          const Text('Use arrow keys to navigate, Enter to select'),
          const Text('Press ESC or Q to go back'),
          const SizedBox(height: 2),
          MenuList(
            items: const [
              MenuItem('Settings', '/settings'),
              MenuItem('About', '/about'),
              MenuItem('Show Dialog', 'dialog'),
              MenuItem('Input Demo', 'input'),
            ],
            onSelect: (value) async {
              if (value == 'dialog') {
                final result = await Navigator.of(context).showDialog<bool>(
                  builder: (context) =>
                      const ConfirmDialog(message: 'This is a modal dialog!'),
                  width: 50,
                  height: 12,
                );
                print('Dialog result: $result');
              } else if (value == 'input') {
                final result = await Navigator.of(
                  context,
                ).pushComponent<String>(const InputPage());
                print('Input result: $result');
              } else {
                Navigator.of(context).pushNamed(value);
              }
            },
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessComponent {
  const SettingsPage({super.key});

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.double),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          MenuList(
            items: const [
              MenuItem('Profile', '/settings/profile'),
              MenuItem('Appearance', '/settings/appearance'),
              MenuItem('Back', 'back'),
            ],
            onSelect: (value) {
              if (value == 'back') {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushNamed(value);
              }
            },
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessComponent {
  const ProfilePage({super.key});

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.rounded),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: const Text(
              'Profile Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          const Text('Username: user123'),
          const Text('Email: user@example.com'),
          const Text('Member since: 2024'),
          const SizedBox(height: 2),
          const Text('Press ESC or Q to go back'),
        ],
      ),
    );
  }
}

class AppearancePage extends StatelessComponent {
  const AppearancePage({super.key});

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.rounded),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: const Text(
              'Appearance Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          const Text('Theme: Dark'),
          const Text('Font Size: Medium'),
          const Text('Color Scheme: Default'),
          const SizedBox(height: 2),
          const Text('Press ESC or Q to go back'),
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
        ],
      ),
    );
  }
}

// Input page that returns a value
class InputPage extends StatefulComponent {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  String _input = '';

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          const Text('Enter some text:'),
          const SizedBox(height: 1),
          TextField(
            onChanged: (value) => setState(() => _input = value),
            onSubmitted: (value) {
              Navigator.of(context).pop(value);
            },
          ),
          const SizedBox(height: 2),
          Text('Current input: $_input'),
          const SizedBox(height: 1),
          const Text('Press Enter to submit, ESC to cancel'),
        ],
      ),
    );
  }
}

// Confirm dialog component
class ConfirmDialog extends StatelessComponent {
  final String message;

  const ConfirmDialog({super.key, required this.message});

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 2),
          MenuList(
            items: const [MenuItem('Yes', true), MenuItem('No', false)],
            onSelect: (value) {
              Navigator.of(context).pop(value);
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
