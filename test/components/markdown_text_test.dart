import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('MarkdownText', () {
    test('renders plain text', () async {
      await testNocterm(
        'plain text',
        (tester) async {
          await tester.pumpComponent(
            const MarkdownText('This is plain text'),
          );

          expect(tester.terminalState, containsText('This is plain text'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders bold text', () async {
      await testNocterm(
        'bold text',
        (tester) async {
          await tester.pumpComponent(
            const MarkdownText('This is **bold** text'),
          );

          expect(tester.terminalState, containsText('This is bold text'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders italic text', () async {
      await testNocterm(
        'italic text',
        (tester) async {
          await tester.pumpComponent(
            const MarkdownText('This is *italic* text'),
          );

          expect(tester.terminalState, containsText('This is italic text'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders headers', () async {
      await testNocterm(
        'headers',
        (tester) async {
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
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders code blocks', () async {
      await testNocterm(
        'code blocks',
        (tester) async {
          await tester.pumpComponent(
            const MarkdownText('''Some text with `inline code` and:

```
code block
with multiple lines
```

More text'''),
          );

          expect(
              tester.terminalState, containsText('Some text with inline code'));
          expect(tester.terminalState, containsText('code block'));
          expect(tester.terminalState, containsText('with multiple lines'));
          expect(tester.terminalState, containsText('More text'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders lists', () async {
      await testNocterm(
        'lists',
        (tester) async {
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
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders task lists', () async {
      await testNocterm(
        'task lists',
        (tester) async {
          await tester.pumpComponent(
            const MarkdownText('''- [ ] Task 1
- [x] Task 2
  - [ ] Nested task
- Plain item'''),
          );

          expect(tester.terminalState, containsText('□ Task 1'));
          expect(tester.terminalState, containsText('✓ Task 2'));
          expect(tester.terminalState, containsText('  □ Nested task'));
          expect(tester.terminalState, containsText('• Plain item'));
          expect(tester.terminalState, isNot(containsText('• □')));
          expect(tester.terminalState, isNot(containsText('[ ]')));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders task lists with custom markers', () async {
      await testNocterm(
        'task lists custom markers',
        (tester) async {
          await tester.pumpComponent(
            const MarkdownText(
              '''- [ ] Todo
- [x] Done''',
              styleSheet: MarkdownStyleSheet(
                taskListUnchecked: '◎ ',
                taskListChecked: '◉ ',
              ),
            ),
          );

          expect(tester.terminalState, containsText('◎ Todo'));
          expect(tester.terminalState, containsText('◉ Done'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders links', () async {
      await testNocterm(
        'links',
        (tester) async {
          await tester.pumpComponent(
            const MarkdownText('Check out [Flutter](https://flutter.dev)!'),
          );

          expect(tester.terminalState, containsText('Flutter'));
          expect(tester.terminalState, containsText('[https://flutter.dev]'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders blockquotes', () async {
      await testNocterm(
        'blockquotes',
        (tester) async {
          await tester.pumpComponent(
            const MarkdownText('''Normal text

> This is a blockquote
> with multiple lines

More normal text'''),
          );

          expect(tester.terminalState, containsText('Normal text'));
          expect(tester.terminalState, containsText('│ This is a blockquote'));
          expect(tester.terminalState, containsText('More normal text'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders horizontal rules', () async {
      await testNocterm(
        'horizontal rules',
        (tester) async {
          await tester.pumpComponent(
            const MarkdownText('''Above the line

---

Below the line'''),
          );

          expect(tester.terminalState, containsText('Above the line'));
          expect(tester.terminalState, containsText('────')); // Horizontal rule
          expect(tester.terminalState, containsText('Below the line'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders complex markdown',
        skip: 'Known issue: Complex markdown rendering', () async {
      await testNocterm(
        'complex markdown',
        (tester) async {
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
        },
        debugPrintAfterPump: true,
      );
    });

    test('handles images', () async {
      await testNocterm(
        'images',
        (tester) async {
          await tester.pumpComponent(
            const MarkdownText('Here is an image: ![Alt text](image.png)'),
          );

          expect(tester.terminalState, containsText('[Image: Alt text]'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders simple table', () async {
      await testNocterm(
        'simple table',
        (tester) async {
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
        },
        debugPrintAfterPump: true,
      );
    });

    test('table wraps cell content in narrow terminal', () async {
      await testNocterm(
        'table smart wrap',
        (tester) async {
          // This table naturally needs ~60 cols but we give it 40
          await tester.pumpComponent(
            const MarkdownText('''| Service | Description |
|---------|-------------|
| auth | Authentication and authorization service |
| api | Public REST API endpoint |'''),
          );

          // All content should still be visible (wrapped within cells)
          // "Service" may be split across lines in the narrow column
          expect(tester.terminalState, containsText('Serv'));
          expect(tester.terminalState, containsText('Description'));
          expect(tester.terminalState, containsText('auth'));
          expect(tester.terminalState, containsText('api'));
          // The long description should be wrapped, so check parts
          expect(tester.terminalState, containsText('Authentication'));
          expect(tester.terminalState, containsText('authorization'));
          // Table borders should be intact (not broken by wrapping)
          expect(tester.terminalState, containsText('┌'));
          expect(tester.terminalState, containsText('┘'));
          expect(tester.terminalState, containsText('├'));
          expect(tester.terminalState, containsText('┤'));
        },
        size: const Size(40, 24),
        debugPrintAfterPump: true,
      );
    });

    test('table preserves structure when it fits', () async {
      await testNocterm(
        'table fits',
        (tester) async {
          await tester.pumpComponent(
            const MarkdownText('''| A | B |
|---|---|
| 1 | 2 |'''),
          );

          // Small table should fit perfectly with borders
          expect(tester.terminalState, containsText('│ A │ B │'));
          expect(tester.terminalState, containsText('│ 1 │ 2 │'));
          expect(tester.terminalState, containsText('┌'));
          expect(tester.terminalState, containsText('┐'));
          expect(tester.terminalState, containsText('└'));
          expect(tester.terminalState, containsText('┘'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('table with multi-line cells pads shorter cells', () async {
      await testNocterm(
        'table multi-line cell padding',
        (tester) async {
          // In a 30-wide terminal, the long cell should wrap while short stays on one line
          await tester.pumpComponent(
            const MarkdownText('''| Key | Value |
|-----|-------|
| id | A very long value that must wrap |
| ok | Short |'''),
          );

          // Both cells should be visible
          expect(tester.terminalState, containsText('Key'));
          expect(tester.terminalState, containsText('Value'));
          expect(tester.terminalState, containsText('id'));
          expect(tester.terminalState, containsText('ok'));
          expect(tester.terminalState, containsText('Short'));
          // The long value should be wrapped but still fully present
          expect(tester.terminalState, containsText('very'));
          expect(tester.terminalState, containsText('long'));
          expect(tester.terminalState, containsText('wrap'));
        },
        size: const Size(30, 24),
        debugPrintAfterPump: true,
      );
    });
  });
}
