import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const PasteTestApp());
}

class PasteTestApp extends StatefulComponent {
  const PasteTestApp({super.key});

  @override
  State<PasteTestApp> createState() => _PasteTestAppState();
}

class _PasteTestAppState extends State<PasteTestApp> {
  final _controller = TextEditingController(text: '');
  final _events = <String>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _logEvent(String event) {
    setState(() {
      _events.add(event);
      if (_events.length > 10) {
        _events.removeAt(0);
      }
    });
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        // Log every key event
        _logEvent('Key: ${event.logicalKey}, Char: ${event.character}');

        if (event.logicalKey == LogicalKey.escape) {
          TerminalBinding.instance.shutdown();
          return true;
        }
        return false;
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🔍 Paste Debug Tool',
              style: TextStyle(
                color: Color.fromRGB(100, 200, 255),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            const Text('Paste text here and observe what happens:'),
            const Text('• Ctrl+V: Uses internal clipboard (ClipboardManager)'),
            const Text('• Cmd+V: Terminal paste (system clipboard)'),
            const Text('• Esc: Exit'),
            const SizedBox(height: 1),
            const Divider(),
            const SizedBox(height: 1),

            TextField(
              controller: _controller,
              focused: true,
              decoration: InputDecoration(
                border: BoxBorder.all(
                  color: const Color.fromRGB(100, 255, 100),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 1),
              ),
              onChanged: (text) {
                _logEvent('Text changed: length=${text.length}');
              },
            ),

            const SizedBox(height: 1),
            Text(
              'Current text: "${_controller.text}"',
              style: const TextStyle(color: Color.fromRGB(200, 200, 200)),
            ),
            Text(
              'Length: ${_controller.text.length} characters',
              style: const TextStyle(color: Color.fromRGB(200, 200, 200)),
            ),

            const SizedBox(height: 1),
            const Divider(),
            const SizedBox(height: 1),
            const Text('Recent events:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._events.map((e) => Text(
              '  $e',
              style: const TextStyle(color: Color.fromRGB(150, 150, 150)),
            )),
          ],
        ),
      ),
    );
  }
}