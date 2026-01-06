import 'package:nocterm/nocterm.dart';

/// Demo showcasing the NoctermApp widget and its ability to set terminal window titles
///
/// This example demonstrates:
/// - Setting a window title declaratively using NoctermApp
/// - Setting both window title and icon name separately
/// - Dynamically updating the title based on user interaction
///
/// The window title will appear in your terminal emulator's title bar
void main() async {
  await runApp(const NoctermAppDemoApp());
}

class NoctermAppDemoApp extends StatefulComponent {
  const NoctermAppDemoApp({super.key});

  @override
  State<NoctermAppDemoApp> createState() => _NoctermAppDemoAppState();
}

class _NoctermAppDemoAppState extends State<NoctermAppDemoApp> {
  int _counter = 0;
  String _currentTitle = 'NoctermApp Demo';

  @override
  Component build(BuildContext context) {
    return NoctermApp(
      // The title parameter sets the terminal window title
      // This appears in your terminal emulator's title bar
      title: _currentTitle,

      // The iconName parameter sets the icon name (primarily used in X11)
      iconName: 'NoctermDemo',

      child: Focusable(
        focused: true,
        onKeyEvent: (event) {
          if (event.character == ' ') {
            setState(() {
              _counter++;
              _currentTitle = 'NoctermApp Demo - Count: $_counter';
            });
            return true;
          } else if (event.character?.toLowerCase() == 'r') {
            setState(() {
              _counter = 0;
              _currentTitle = 'NoctermApp Demo';
            });
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
                      'NoctermApp Demo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(''),
                  Text(
                    'This demo showcases the NoctermApp widget, which provides',
                  ),
                  Text('a declarative way to set terminal window titles.'),
                  Text(''),
                  const Divider(),
                  Text(''),
                  Text('Current window title: "$_currentTitle"'),
                  Text('Icon name: "NoctermDemo"'),
                  Text(''),
                  const Divider(),
                  Text(''),
                  Center(
                    child: Text(
                      'Counter: $_counter',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(''),
                  const Divider(),
                  Text(''),
                  Text('Controls:'),
                  Text('  [Space] - Increment counter (updates window title)'),
                  Text('  [R]     - Reset counter'),
                  Text('  [Q]     - Quit'),
                  Text(''),
                  Center(
                    child: Text(
                      'Look at your terminal window title bar!',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Color.fromRGB(100, 200, 255),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
