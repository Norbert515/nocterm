import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const TextFieldDemo());
}

class TextFieldDemo extends StatefulComponent {
  const TextFieldDemo({super.key});

  @override
  State<TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<TextFieldDemo> {
  final TextEditingController controller = TextEditingController();
  bool _focused = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill with some text for testing wrapping
    controller.text =
        'This is some initial text that should wrap nicely. Try typing more text including emojis like 😀 👍 🎉 and see how it wraps. You can also test with very long words like supercalifragilisticexpialidocious or URLs like https://www.example.com/very/long/path/to/some/resource. The text should wrap at word boundaries when possible.';
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TextField Wrapping Demo',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
          ),
          Text(
            'Type text to test wrapping. Use arrows to navigate.',
            style: TextStyle(color: Colors.gray),
          ),
          const SizedBox(height: 1),
          Container(
            height: 10,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: _focused ? Colors.green : Colors.gray),
            ),
            child: TextField(
              controller: controller,
              focused: _focused,
              onFocusChange: (focused) {
                setState(() => _focused = focused);
              },
              placeholder: 'Type here...',
              maxLines: null, // Allow multiple lines
              style: TextStyle(color: Colors.white),
              cursorStyle: CursorStyle.block,
              cursorBlinkRate: const Duration(milliseconds: 100000000000),
              cursorColor: Colors.yellow,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(1),
              ),
              onSubmitted: (value) {
                // Add a marker to show submission
                controller.text = '${controller.text}\n[Submitted at ${DateTime.now().toString().split('.')[0]}]';
              },
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'Text length: ${controller.text.length} characters',
            style: TextStyle(color: Colors.yellow),
          ),
          Text(
            'Press Escape to exit',
            style: TextStyle(color: Colors.gray),
          ),
        ],
      ),
    );
  }
}
