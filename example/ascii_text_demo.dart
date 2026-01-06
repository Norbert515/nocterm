import 'package:nocterm/nocterm.dart';

/// Demo showcasing the AsciiText component with various fonts and styles.
class AsciiTextDemo extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'ASCII Text Demo - Big Text Rendering',
            style: TextStyle(
              color: Colors.cyan,
              decoration: TextDecoration.underline,
            ),
          ),
          SizedBox(height: 1),

          // Standard font (default)
          Text('Standard Font:', style: TextStyle(color: Colors.yellow)),
          AsciiText('HELLO', style: TextStyle(color: Colors.green)),
          SizedBox(height: 1),

          // Banner font
          Text('Banner Font:', style: TextStyle(color: Colors.yellow)),
          AsciiText(
            'WORLD',
            font: AsciiFont.banner,
            style: TextStyle(color: Colors.magenta),
          ),
          SizedBox(height: 1),

          // Block font
          Text('Block Font:', style: TextStyle(color: Colors.yellow)),
          AsciiText(
            'BOLD',
            font: AsciiFont.block,
            style: TextStyle(color: Colors.red),
          ),
          SizedBox(height: 1),

          // Slim font
          Text('Slim Font:', style: TextStyle(color: Colors.yellow)),
          AsciiText(
            'THIN',
            font: AsciiFont.slim,
            style: TextStyle(color: Colors.blue),
          ),
          SizedBox(height: 1),

          // Numbers
          Text('Numbers:', style: TextStyle(color: Colors.yellow)),
          AsciiText(
            '12345',
            font: AsciiFont.standard,
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 1),

          // Special characters
          Text('Punctuation:', style: TextStyle(color: Colors.yellow)),
          AsciiText(
            'HI!',
            font: AsciiFont.block,
            style: TextStyle(color: Colors.brightYellow),
          ),
          SizedBox(height: 2),

          Text('Press Ctrl+C to exit', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

void main() {
  runApp(AsciiTextDemo());
}
