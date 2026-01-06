import 'package:nocterm/nocterm.dart';

void main() {
  runApp(SimpleMarkdownExample());
}

class SimpleMarkdownExample extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simple Markdown Example',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
            const SizedBox(height: 2),
            const MarkdownText('''# Hello Markdown!

This is a simple example showing **bold text**, *italic text*, and `inline code`.

## Features

- Bullet point 1
- Bullet point 2
- Bullet point 3

### Code Example

```dart
void main() {
  print('Hello from Nocterm!');
}
```

> This is a blockquote with some important information.

Check out the [documentation](https://nocterm.dev) for more!'''),
          ],
        ),
      ),
    );
  }
}
