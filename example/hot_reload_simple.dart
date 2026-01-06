import 'package:nocterm/nocterm.dart';

void main() async {
  // Run with: dart run --enable-vm-service example/hot_reload_simple.dart
  print('Starting Hot Reload Simple Demo...');
  print(
    'Run with: dart run --enable-vm-service example/hot_reload_simple.dart',
  );
  await runApp(const SimpleHotReloadApp());
}

class SimpleHotReloadApp extends StatefulComponent {
  const SimpleHotReloadApp({super.key});

  @override
  State<SimpleHotReloadApp> createState() => _SimpleHotReloadAppState();
}

class _SimpleHotReloadAppState extends State<SimpleHotReloadApp> {
  int reloadCount = 0;
  DateTime lastReload = DateTime.now();

  @override
  void reassemble() {
    super.reassemble();
    setState(() {
      reloadCount++;
      lastReload = DateTime.now();
    });
    print('[App] Hot reload #$reloadCount at $lastReload');
  }

  @override
  Component build(BuildContext context) {
    // Try changing these values and saving the file!
    final title = 'Hot Reload Demo'; // <- Change me!
    final borderColor = Colors.cyan; // <- Try Color.red, Color.green, etc
    final message = 'Hello, TUI!'; // <- Change this message!

    return Container(
      decoration: BoxDecoration(border: BoxBorder.all(color: borderColor)),
      padding: EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1),
          Text(
            message,
            style: TextStyle(
              color: Colors.yellow, // <- Change this color!
            ),
          ),
          SizedBox(height: 2),
          Text('Hot Reload Count: $reloadCount'),
          Text('Last Reload: ${lastReload.toString().split('.').first}'),
          SizedBox(height: 2),
          Text(
            'Edit this file and save to trigger hot reload!',
            style: TextStyle(color: Colors.gray, fontWeight: FontWeight.dim),
          ),
          Expanded(child: Container()),
          Text(
            'Press Esc to exit',
            style: TextStyle(fontWeight: FontWeight.dim),
          ),
        ],
      ),
    );
  }
}
