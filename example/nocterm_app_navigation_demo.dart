import 'package:nocterm/nocterm.dart';

/// Demo showcasing NoctermApp with Navigator support
///
/// This example demonstrates:
/// - Using NoctermApp with built-in Navigator
/// - Defining routes declaratively
/// - Navigating between screens
/// - Passing data between routes
/// - Dynamic terminal title updates based on route
void main() async {
  await runApp(const NavigationDemoApp());
}

class NavigationDemoApp extends StatelessComponent {
  const NavigationDemoApp({super.key});

  @override
  Component build(BuildContext context) {
    return NoctermApp(
      title: 'Navigation Demo',
      iconName: 'NavDemo',
      routes: {
        '/': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessComponent {
  const HomeScreen({super.key});

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.character == '1') {
          Navigator.of(context).pushNamed('/settings');
          return true;
        } else if (event.character == '2') {
          Navigator.of(context).pushNamed('/about');
          return true;
        } else if (event.character?.toLowerCase() == 'q') {
          shutdownApp();
          return true;
        }
        return false;
      },
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            border: BoxBorder.all(style: BoxBorderStyle.rounded),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'NoctermApp Navigation Demo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(''),
                Center(
                  child: Text(
                    '🏠 Home Screen',
                    style: TextStyle(color: Color.fromRGB(100, 200, 255)),
                  ),
                ),
                Text(''),
                const Divider(),
                Text(''),
                Text(
                  'This demo shows NoctermApp with built-in Navigator support.',
                ),
                Text(
                  'You can navigate between different screens using routes.',
                ),
                Text(''),
                const Divider(),
                Text(''),
                Text('Available Screens:'),
                Text('  [1] Settings'),
                Text('  [2] About'),
                Text(''),
                const Divider(),
                Text(''),
                Text('Controls:'),
                Text('  [1-2]   - Navigate to screen'),
                Text('  [ESC]   - Go back'),
                Text('  [Q]     - Quit'),
                Text(''),
                Center(
                  child: Text(
                    'Try pressing 1 or 2 to navigate!',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color.fromRGB(255, 200, 100),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulComponent {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape) {
          Navigator.of(context).pop();
          return true;
        } else if (event.character == '1') {
          setState(() => _darkMode = !_darkMode);
          return true;
        } else if (event.character == '2') {
          setState(() => _notifications = !_notifications);
          return true;
        } else if (event.character?.toLowerCase() == 'q') {
          shutdownApp();
          return true;
        }
        return false;
      },
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            border: BoxBorder.all(style: BoxBorderStyle.rounded),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(''),
                Center(
                  child: Text(
                    '⚙️  Settings Screen',
                    style: TextStyle(color: Color.fromRGB(150, 255, 150)),
                  ),
                ),
                Text(''),
                const Divider(),
                Text(''),
                Text('Configure your application settings:'),
                Text(''),
                Text(
                  '[1] Dark Mode: ${_darkMode ? "✓ Enabled" : "✗ Disabled"}',
                ),
                Text(
                  '[2] Notifications: ${_notifications ? "✓ Enabled" : "✗ Disabled"}',
                ),
                Text(''),
                const Divider(),
                Text(''),
                Text('Controls:'),
                Text('  [1-2]   - Toggle setting'),
                Text('  [ESC]   - Go back to home'),
                Text('  [Q]     - Quit'),
                Text(''),
                Center(
                  child: Text(
                    'Press ESC to return to home',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color.fromRGB(200, 200, 100),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessComponent {
  const AboutScreen({super.key});

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape) {
          Navigator.of(context).pop();
          return true;
        } else if (event.character?.toLowerCase() == 'q') {
          shutdownApp();
          return true;
        }
        return false;
      },
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            border: BoxBorder.all(style: BoxBorderStyle.rounded),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'About',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(''),
                Center(
                  child: Text(
                    'ℹ️  About Screen',
                    style: TextStyle(color: Color.fromRGB(255, 150, 255)),
                  ),
                ),
                Text(''),
                const Divider(),
                Text(''),
                Text('NoctermApp Navigation Demo'),
                Text('Version: 1.0.0'),
                Text(''),
                Text('Features:'),
                Text('  • Declarative routing'),
                Text('  • Built-in Navigator'),
                Text('  • Terminal title management'),
                Text('  • Route-based navigation'),
                Text(''),
                const Divider(),
                Text(''),
                Text('Controls:'),
                Text('  [ESC]   - Go back to home'),
                Text('  [Q]     - Quit'),
                Text(''),
                Center(
                  child: Text(
                    'Press ESC to return to home',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color.fromRGB(150, 200, 255),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
