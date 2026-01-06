import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('MarkdownText', () {
    test('renders plain text', () async {
      await testNocterm('plain text', (tester) async {
        await tester.pumpComponent(const MarkdownText('This is plain text'));

        expect(tester.terminalState, containsText('This is plain text'));
      }, debugPrintAfterPump: true);
    });

    test('renders bold text', () async {
      await testNocterm('bold text', (tester) async {
        await tester.pumpComponent(const MarkdownText('This is **bold** text'));

        expect(tester.terminalState, containsText('This is bold text'));
      }, debugPrintAfterPump: true);
    });

    test('renders italic text', () async {
      await testNocterm('italic text', (tester) async {
        await tester.pumpComponent(const MarkdownText('This is *italic* text'));

        expect(tester.terminalState, containsText('This is italic text'));
      }, debugPrintAfterPump: true);
    });

    test('renders headers', () async {
      await testNocterm('headers', (tester) async {
        await tester.pumpComponent(
          const MarkdownText('''# Header 1
## Header 2
### Header 3
Regular text'''),
        );

        expect(tester.terminalState, containsText('# Header 1'));
        expect(tester.terminalState, containsText('## Header 2'));
        expect(tester.terminalState, containsText('### Header 3'));
        expect(tester.terminalState, containsText('Regular text'));
      }, debugPrintAfterPump: true);
    });

    test('renders code blocks', () async {
      await testNocterm('code blocks', (tester) async {
        await tester.pumpComponent(
          const MarkdownText('''Some text with `inline code` and:

```
code block
with multiple lines
```

More text'''),
        );

        expect(
          tester.terminalState,
          containsText('Some text with inline code'),
        );
        expect(tester.terminalState, containsText('code block'));
        expect(tester.terminalState, containsText('with multiple lines'));
        expect(tester.terminalState, containsText('More text'));
      }, debugPrintAfterPump: true);
    });

    test('renders lists', () async {
      await testNocterm('lists', (tester) async {
        await tester.pumpComponent(
          const MarkdownText('''Unordered list:
- Item 1
- Item 2
- Item 3

Ordered list:
1. First
2. Second
3. Third'''),
        );

        expect(tester.terminalState, containsText('• Item 1'));
        expect(tester.terminalState, containsText('• Item 2'));
        expect(tester.terminalState, containsText('• Item 3'));
        // Note: ordered lists default to bullet points in our simple implementation
        expect(tester.terminalState, containsText('First'));
        expect(tester.terminalState, containsText('Second'));
        expect(tester.terminalState, containsText('Third'));
      }, debugPrintAfterPump: true);
    });

    test('renders links', () async {
      await testNocterm('links', (tester) async {
        await tester.pumpComponent(
          const MarkdownText('Check out [Flutter](https://flutter.dev)!'),
        );

        expect(tester.terminalState, containsText('Flutter'));
        expect(tester.terminalState, containsText('[https://flutter.dev]'));
      }, debugPrintAfterPump: true);
    });

    test('renders blockquotes', () async {
      await testNocterm('blockquotes', (tester) async {
        await tester.pumpComponent(
          const MarkdownText('''Normal text

> This is a blockquote
> with multiple lines

More normal text'''),
        );

        expect(tester.terminalState, containsText('Normal text'));
        expect(tester.terminalState, containsText('│ This is a blockquote'));
        expect(tester.terminalState, containsText('More normal text'));
      }, debugPrintAfterPump: true);
    });

    test('renders horizontal rules', () async {
      await testNocterm('horizontal rules', (tester) async {
        await tester.pumpComponent(
          const MarkdownText('''Above the line

---

Below the line'''),
        );

        expect(tester.terminalState, containsText('Above the line'));
        expect(tester.terminalState, containsText('────')); // Horizontal rule
        expect(tester.terminalState, containsText('Below the line'));
      }, debugPrintAfterPump: true);
    });

    test(
      'renders complex markdown',
      skip: 'Known issue: Complex markdown rendering',
      () async {
        await testNocterm('complex markdown', (tester) async {
          await tester.pumpComponent(
            const MarkdownText('''# Welcome to Markdown

This is a **demonstration** of the *markdown* renderer with ~~strikethrough~~.

## Features

- **Bold** text
- *Italic* text
- `Code` snippets
- [Links](https://example.com)

### Code Example

```
void main() {
  print('Hello, World!');
}
```

> "The best way to predict the future is to invent it."
> - Alan Kay

---

That's all folks!'''),
          );

          expect(tester.terminalState, containsText('# Welcome to Markdown'));
          expect(tester.terminalState, containsText('demonstration'));
          expect(tester.terminalState, containsText('## Features'));
          expect(tester.terminalState, containsText('• Bold text'));
          expect(tester.terminalState, containsText('• Italic text'));
          expect(tester.terminalState, containsText('• Code snippets'));
          expect(tester.terminalState, containsText('### Code Example'));
          expect(tester.terminalState, containsText("print('Hello, World!');"));
          expect(tester.terminalState, containsText('│ "The best way'));
          expect(tester.terminalState, containsText("That's all folks!"));
        }, debugPrintAfterPump: true);
      },
    );

    test('handles images', () async {
      await testNocterm('images', (tester) async {
        await tester.pumpComponent(
          const MarkdownText('Here is an image: ![Alt text](image.png)'),
        );

        expect(tester.terminalState, containsText('[Image: Alt text]'));
      }, debugPrintAfterPump: true);
    });

    test('renders simple table', () async {
      await testNocterm('simple table', (tester) async {
        await tester.pumpComponent(
          const MarkdownText('''| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |
| Cell 3   | Cell 4   |'''),
        );

        // Check for table structure
        expect(tester.terminalState, containsText('Header 1'));
        expect(tester.terminalState, containsText('Header 2'));
        expect(tester.terminalState, containsText('Cell 1'));
        expect(tester.terminalState, containsText('Cell 2'));
      }, debugPrintAfterPump: true);
    });
  });
}
