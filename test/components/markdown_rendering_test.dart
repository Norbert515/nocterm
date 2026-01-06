import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('MarkdownText Line Breaks', () {
    test('renders paragraphs with proper spacing', () async {
      await testNocterm('paragraph spacing', (tester) async {
        await tester.pumpComponent(
          const MarkdownText('''First paragraph.

Second paragraph.

Third paragraph.'''),
        );

        print('=== Paragraph Test Output ===');
        final lines = tester.terminalState.toString().split('\n');
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].trim().isNotEmpty) {
            print('Line $i: "${lines[i].trim()}"');
          }
        }

        expect(tester.terminalState, containsText('First paragraph.'));
        expect(tester.terminalState, containsText('Second paragraph.'));
        expect(tester.terminalState, containsText('Third paragraph.'));
      }, debugPrintAfterPump: true);
    });

    test('renders headers with proper line breaks', () async {
      await testNocterm('header line breaks', (tester) async {
        await tester.pumpComponent(
          const MarkdownText('''# Header 1
Some text after header.

## Header 2
More text here.'''),
        );

        print('=== Header Test Output ===');
        final lines = tester.terminalState.toString().split('\n');
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].trim().isNotEmpty) {
            print('Line $i: "${lines[i].trim()}"');
          }
        }

        expect(tester.terminalState, containsText('# Header 1'));
        expect(tester.terminalState, containsText('Some text after header.'));
        expect(tester.terminalState, containsText('## Header 2'));
        expect(tester.terminalState, containsText('More text here.'));
      }, debugPrintAfterPump: true);
    });

    test('renders lists with proper formatting', () async {
      await testNocterm('list formatting', (tester) async {
        await tester.pumpComponent(
          const MarkdownText('''Some text before list.

- Item 1
- Item 2
- Item 3

Text after list.'''),
        );

        print('=== List Test Output ===');
        final lines = tester.terminalState.toString().split('\n');
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isNotEmpty) {
            print('Line $i: "$line"');
          }
        }

        expect(tester.terminalState, containsText('Some text before list.'));
        expect(tester.terminalState, containsText('• Item 1'));
        expect(tester.terminalState, containsText('• Item 2'));
        expect(tester.terminalState, containsText('• Item 3'));
        expect(tester.terminalState, containsText('Text after list.'));
      }, debugPrintAfterPump: true);
    });

    test('renders code blocks with proper spacing', () async {
      await testNocterm('code block spacing', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 50,
            child: const MarkdownText('''Text before code.

```dart
void main() {
  print('Hello');
}
```

Text after code.'''),
          ),
        );

        print('=== Code Block Test Output ===');
        final lines = tester.terminalState.toString().split('\n');
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trim().isNotEmpty) {
            print(
              'Line $i: "${line.substring(0, line.length > 50 ? 50 : line.length).trim()}"',
            );
          }
        }

        expect(tester.terminalState, containsText('Text before code.'));
        expect(tester.terminalState, containsText('void main()'));
        expect(tester.terminalState, containsText("print('Hello')"));
        expect(tester.terminalState, containsText('Text after code.'));
      }, debugPrintAfterPump: true);
    });

    test('handles mixed content correctly', () async {
      await testNocterm('mixed content', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 60,
            child: const MarkdownText('''# Title

This is a paragraph with **bold** and *italic* text.

## Features

- First feature
- Second feature

```
code example
```

> Quote text

Final paragraph.'''),
          ),
        );

        print('=== Mixed Content Test Output ===');
        final lines = tester.terminalState.toString().split('\n');
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trim().isNotEmpty) {
            print(
              'Line $i: "${line.substring(0, line.length > 60 ? 60 : line.length).trim()}"',
            );
          }
        }

        expect(tester.terminalState, containsText('# Title'));
        expect(
          tester.terminalState,
          containsText('This is a paragraph with bold and italic text.'),
        );
        expect(tester.terminalState, containsText('## Features'));
        expect(tester.terminalState, containsText('• First feature'));
        expect(tester.terminalState, containsText('• Second feature'));
        expect(tester.terminalState, containsText('code example'));
        expect(tester.terminalState, containsText('│ Quote text'));
        expect(tester.terminalState, containsText('Final paragraph.'));
      }, debugPrintAfterPump: true);
    });

    test('check exact line structure', () async {
      await testNocterm('exact line structure', (tester) async {
        await tester.pumpComponent(
          Container(
            padding: const EdgeInsets.all(1),
            child: const MarkdownText('''# Header
Paragraph text.

- List item 1
- List item 2'''),
          ),
        );

        print('=== Exact Line Structure ===');

        // Check that all the expected content is there
        expect(tester.terminalState, containsText('# Header'));
        expect(tester.terminalState, containsText('Paragraph text.'));
        expect(tester.terminalState, containsText('• List item 1'));
        expect(tester.terminalState, containsText('• List item 2'));
      }, debugPrintAfterPump: true);
    });
  });
}
