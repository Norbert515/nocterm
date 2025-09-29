import 'dart:async';
import 'dart:io';
import 'package:nocterm/nocterm.dart';

void main() {
  runApp(const TextFieldDemo());
}

class TextFieldDemo extends StatefulComponent {
  const TextFieldDemo({super.key});

  @override
  State<TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<TextFieldDemo> {
  final _singleLineController = TextEditingController();
  final _multiLineController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emojiController = TextEditingController();
  final _chineseController = TextEditingController();
  final _maxLengthController = TextEditingController();

  int _focusedField = 0;
  String _submittedText = '';

  @override
  void dispose() {
    _singleLineController.dispose();
    _multiLineController.dispose();
    _passwordController.dispose();
    _emojiController.dispose();
    _chineseController.dispose();
    _maxLengthController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyboardEvent event) {
    if (event.logicalKey == LogicalKey.tab && !event.isShiftPressed) {
      setState(() {
        _focusedField = (_focusedField + 1) % 6;
      });
    } else if (event.logicalKey == LogicalKey.tab && event.isShiftPressed) {
      setState(() {
        _focusedField = (_focusedField - 1 + 6) % 6;
      });
    } else if (event.logicalKey == LogicalKey.escape) {
      // Exit the app
      exit(0);
    }
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        _handleKeyEvent(event);
        return false; // Let the event propagate to focused field
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        child: ListView(
          children: [
            Text(
              'TextField Demo',
              style: TextStyle(
                color: Colors.cyan,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 1),
            const Text('Use Tab/Shift+Tab to navigate, Esc to exit'),
            const SizedBox(height: 2),

            // Single line field
            const Text('Single Line (Basic):'),
            Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(
                  color: _focusedField == 0 ? Colors.cyan : Colors.gray,
                ),
              ),
              child: TextField(
                controller: _singleLineController,
                focused: _focusedField == 0,
                width: 50,
                height: 1,
                placeholder: 'Enter text...',
                onSubmitted: (text) {
                  setState(() {
                    _submittedText = 'Submitted: $text';
                  });
                },
              ),
            ),
            const SizedBox(height: 1),

            // Multi-line field
            const Text('Multi-line (Enter to submit):'),
            Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(
                  color: _focusedField == 1 ? Colors.cyan : Colors.gray,
                ),
              ),
              child: TextField(
                controller: _multiLineController,
                focused: _focusedField == 1,
                width: 50,
                height: 4,
                maxLines: 4,
                placeholder: 'Enter multiple lines...\nNote: Enter submits the text',
              ),
            ),
            const SizedBox(height: 1),

            // Password field
            const Text('Password Field:'),
            Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(
                  color: _focusedField == 2 ? Colors.cyan : Colors.gray,
                ),
              ),
              child: TextField(
                controller: _passwordController,
                focused: _focusedField == 2,
                width: 30,
                height: 1,
                obscureText: true,
                placeholder: 'Enter password...',
              ),
            ),
            const SizedBox(height: 1),

            // Emoji support
            const Text('Emoji Support:'),
            Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(
                  color: _focusedField == 3 ? Colors.cyan : Colors.gray,
                ),
              ),
              child: TextField(
                controller: _emojiController,
                focused: _focusedField == 3,
                width: 40,
                height: 1,
                placeholder: 'Try emojis: 🦄 🌈 💖',
              ),
            ),
            const SizedBox(height: 1),

            // Chinese characters
            const Text('Unicode Support (Chinese):'),
            Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(
                  color: _focusedField == 4 ? Colors.cyan : Colors.gray,
                ),
              ),
              child: TextField(
                controller: _chineseController,
                focused: _focusedField == 4,
                width: 40,
                height: 1,
                placeholder: '输入中文文字...',
              ),
            ),
            const SizedBox(height: 1),

            // Max length field
            const Text('Max Length (10 chars):'),
            Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(
                  color: _focusedField == 5 ? Colors.cyan : Colors.gray,
                ),
              ),
              child: TextField(
                controller: _maxLengthController,
                focused: _focusedField == 5,
                width: 30,
                height: 1,
                maxLength: 10,
                placeholder: 'Max 10 chars',
              ),
            ),
            const SizedBox(height: 2),

            // Display submitted text
            if (_submittedText.isNotEmpty) ...[
              Text(
                _submittedText,
                style: const TextStyle(color: Colors.green),
              ),
              const SizedBox(height: 1),
            ],

            // Instructions
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.gray),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Keyboard Shortcuts:', style: TextStyle(color: Colors.yellow)),
                  Text('• Ctrl+A: Select all'),
                  Text('• Ctrl+C/X/V: Copy/Cut/Paste (clipboard integration pending)'),
                  Text('• Ctrl+←/→: Move by word'),
                  Text('• Ctrl+Backspace: Delete word'),
                  Text('• Ctrl+T: Transpose characters'),
                  Text('• Home/End: Move to start/end'),
                  Text('• Tab/Shift+Tab: Navigate fields'),
                  Text('• Esc: Exit'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
