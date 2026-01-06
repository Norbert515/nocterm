import 'package:nocterm/nocterm.dart';

void main() async {
  runApp(const ColorTest());
}

class ColorTest extends StatelessComponent {
  const ColorTest();

  @override
  Component build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        const Text(
          'Testing TUI Colors',
          style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 1),
        const Text('Red text', style: TextStyle(color: Colors.red)),
        const Text('Green text', style: TextStyle(color: Colors.green)),
        const Text('Blue text', style: TextStyle(color: Colors.blue)),
        const Text('Yellow text', style: TextStyle(color: Colors.yellow)),
        const Text('Magenta text', style: TextStyle(color: Colors.magenta)),
        const Text('Cyan text', style: TextStyle(color: Colors.cyan)),
        const SizedBox(height: 1),
        const Text(
          'White on red bg',
          style: TextStyle(color: Colors.white, backgroundColor: Colors.red),
        ),
        const Text(
          'Black on green bg',
          style: TextStyle(color: Colors.black, backgroundColor: Colors.green),
        ),
        const Text(
          'Yellow on blue bg',
          style: TextStyle(color: Colors.yellow, backgroundColor: Colors.blue),
        ),
        const SizedBox(height: 1),
        const Text('Bold text', style: TextStyle(fontWeight: FontWeight.bold)),
        const Text(
          'Italic text',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
        const Text(
          'Underlined text',
          style: TextStyle(decoration: TextDecoration.underline),
        ),
        const Text('Dim text', style: TextStyle(fontWeight: FontWeight.dim)),
        const SizedBox(height: 1),
        Text(
          'RGB Color (255,128,0)',
          style: TextStyle(color: Color.fromRGB(255, 128, 0)),
        ),
        Text(
          'RGB Color (128,0,255)',
          style: TextStyle(color: Color.fromRGB(128, 0, 255)),
        ),
        const Spacer(),
        const Center(
          child: Text(
            'Press Ctrl+C to exit',
            style: TextStyle(color: Colors.gray, fontWeight: FontWeight.dim),
          ),
        ),
      ],
    );
  }
}
