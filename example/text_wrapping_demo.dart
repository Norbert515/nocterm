import 'package:nocterm/nocterm.dart' hide TextAlign;
import 'package:nocterm/src/components/basic.dart' show TextAlign, TextOverflow;

void main() {
  runApp(TextWrapDemo());
}

class TextWrapDemo extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    const longText =
        'This is a very long piece of text that will demonstrate '
        'how text wrapping works in our TUI framework. It should automatically '
        'wrap at word boundaries when it exceeds the available width.';

    const veryLongWord = 'Supercalifragilisticexpialidocious';

    return Container(
      padding: const EdgeInsets.all(2),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text Wrapping Demo',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromRGB(0, 255, 0),
              ),
            ),
            const SizedBox(height: 1),

            // Normal wrapping
            Container(
              width: 40,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: BoxBorder.all(style: BoxBorderStyle.solid),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Normal wrap (40 width):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(longText),
                ],
              ),
            ),

            const SizedBox(height: 1),

            // No wrapping
            Container(
              width: 40,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: BoxBorder.all(style: BoxBorderStyle.solid),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No wrap (overflow visible):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    longText,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 1),

            // With ellipsis
            Container(
              width: 40,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: BoxBorder.all(style: BoxBorderStyle.solid),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Max 2 lines with ellipsis:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    longText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 1),

            // Text alignment - needs crossAxisAlignment.stretch to work
            Container(
              width: 40,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: BoxBorder.all(style: BoxBorderStyle.solid),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .stretch, // This is crucial for alignment!
                children: [
                  const Text(
                    'Text Alignment:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 1),
                  const Text('Left aligned text', textAlign: TextAlign.left),
                  const Container(
                    color: Colors.red,
                    child: Text('Center aligned', textAlign: TextAlign.center),
                  ),
                  const Text('Right aligned', textAlign: TextAlign.right),
                  const SizedBox(height: 1),
                  const Text(
                    'This text is justified to fill the entire width of the container.',
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 1),

            // Long word breaking
            Container(
              width: 20,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: BoxBorder.all(style: BoxBorderStyle.solid),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Long word break:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Word: $veryLongWord breaks automatically'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
