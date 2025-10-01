import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const ClipboardDemoApp());
}

class ClipboardDemoApp extends StatefulComponent {
  const ClipboardDemoApp({super.key});

  @override
  State<ClipboardDemoApp> createState() => _ClipboardDemoAppState();
}

class _ClipboardDemoAppState extends State<ClipboardDemoApp> {
  final _controller1 = TextEditingController(text: 'Hello, World!');
  final _controller2 = TextEditingController(text: '');
  int _focusedField = 0;

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        // Handle Tab to switch between fields
        if (event.logicalKey == LogicalKey.tab && !event.isShiftPressed) {
          setState(() {
            _focusedField = (_focusedField + 1) % 2;
          });
          return true;
        }
        // Handle Shift+Tab to go backwards
        if (event.logicalKey == LogicalKey.tab && event.isShiftPressed) {
          setState(() {
            _focusedField = (_focusedField - 1) % 2;
            if (_focusedField < 0) _focusedField = 1;
          });
          return true;
        }
        // Handle Escape to exit
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
            // Title
            const Text(
              '📋 Clipboard Demo',
              style: TextStyle(
                color: Color.fromRGB(100, 200, 255),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),

            // Instructions
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Ctrl+A: Select all text'),
            const Text('• Ctrl+C: Copy selected text'),
            const Text('• Ctrl+X: Cut selected text'),
            const Text('• Ctrl+V: Paste from clipboard'),
            const Text('• Tab: Switch between fields'),
            const Text('• Esc: Exit'),
            const SizedBox(height: 1),

            // Divider
            const Divider(),
            const SizedBox(height: 1),

            // Field 1
            Text(
              'Field 1: ${_focusedField == 0 ? '← FOCUSED' : ''}',
              style: TextStyle(
                color: _focusedField == 0 ? const Color.fromRGB(100, 255, 100) : const Color.fromRGB(150, 150, 150),
                fontWeight: _focusedField == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 0.5),
            TextField(
              controller: _controller1,
              focused: _focusedField == 0,
              decoration: InputDecoration(
                border: BoxBorder.all(
                  color: _focusedField == 0 ? const Color.fromRGB(100, 255, 100) : const Color.fromRGB(100, 100, 100),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 1),
              ),
            ),
            const SizedBox(height: 1),

            // Field 2
            Text(
              'Field 2: ${_focusedField == 1 ? '← FOCUSED' : ''}',
              style: TextStyle(
                color: _focusedField == 1 ? const Color.fromRGB(100, 255, 100) : const Color.fromRGB(150, 150, 150),
                fontWeight: _focusedField == 1 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 0.5),
            TextField(
              controller: _controller2,
              focused: _focusedField == 1,
              decoration: InputDecoration(
                border: BoxBorder.all(
                  color: _focusedField == 1 ? const Color.fromRGB(100, 255, 100) : const Color.fromRGB(100, 100, 100),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 1),
              ),
            ),
            const SizedBox(height: 1),

            // Divider
            const Divider(),
            const SizedBox(height: 1),

            // Clipboard info
            const Text(
              'Clipboard Status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              ClipboardManager.hasContent() ? '✓ Has content: "${ClipboardManager.paste()}"' : '✗ Empty',
              style: TextStyle(
                color: ClipboardManager.hasContent()
                    ? const Color.fromRGB(100, 255, 100)
                    : const Color.fromRGB(255, 100, 100),
              ),
            ),
            const SizedBox(height: 1),

            // Terminal info
            Text(
              'OSC 52 Support: ${Clipboard.isSupported() ? '✓ Likely supported' : '✗ Not detected'}',
              style: TextStyle(
                color:
                    Clipboard.isSupported() ? const Color.fromRGB(100, 255, 100) : const Color.fromRGB(255, 200, 100),
              ),
            ),

            const Spacer(),

            // Footer
            const Text(
              'Try: Select text in Field 1, copy it (Ctrl+C), switch to Field 2 (Tab), and paste (Ctrl+V)',
              style: TextStyle(
                color: Color.fromRGB(150, 150, 150),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
