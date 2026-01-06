import 'package:nocterm/nocterm.dart';

void main() {
  runApp(MarkdownDemo());
}

class MarkdownDemo extends StatefulComponent {
  @override
  State<MarkdownDemo> createState() => _MarkdownDemoState();
}

class _MarkdownDemoState extends State<MarkdownDemo> {
  int _selectedTab = 0;

  final List<String> _tabs = [
    'Overview',
    'Formatting',
    'Lists & Code',
    'Advanced',
  ];

  final List<String> _markdownContent = [
    // Overview tab
    '''# Welcome to Markdown in Terminal UI

This is a **demonstration** of the MarkdownText widget that renders 
*markdown* content in your terminal with proper styling.

## Why Markdown in TUI?

Markdown provides a simple way to format text that is:
- Easy to write and read
- Portable across platforms
- Perfect for documentation

> "Simplicity is the ultimate sophistication."
> - Leonardo da Vinci

---

Try navigating through the tabs to see more examples!''',

    // Formatting tab
    '''# Text Formatting

## Basic Styles

You can use **bold text** for emphasis, *italic text* for subtle emphasis,
and ~~strikethrough~~ for deleted content.

You can also combine them: ***bold and italic*** text!

## Inline Code

Use backticks for `inline code` snippets within your text.

## Links

Visit [Nocterm Documentation](https://nocterm.dev) for more information.
Links are displayed as: text [url]

## Images

Images are shown as placeholders:
![Terminal UI Logo](logo.png)

Since terminals can't display images, we show: [Image: alt text]''',

    // Lists & Code tab
    '''# Lists and Code Blocks

## Unordered Lists

- First item
- Second item
  - Nested item 1
  - Nested item 2
- Third item

## Ordered Lists

1. Step one
2. Step two
3. Step three

## Code Blocks

Here's a Dart example:

```dart
void main() {
  print('Hello from Nocterm!');
  
  final widget = MarkdownText(
    'Your **markdown** content here',
  );
}
```

And some Python:

```python
def greet(name):
    return f"Hello, {name}!"
    
print(greet("Terminal"))
```''',

    // Advanced tab
    '''# Advanced Features

## Tables

| Feature | Status | Notes |
|---------|--------|-------|
| Bold | ✅ | Works great |
| Italic | ✅ | Fully supported |
| Tables | ✅ | ASCII rendering |
| Links | ✅ | Show URL in brackets |

## Blockquotes

> Blockquotes are great for highlighting important information.
> They can span multiple lines and maintain formatting.
>
> > They can even be nested!

## Horizontal Rules

Use three or more hyphens, asterisks, or underscores:

---

***

___

## Mixed Content

You can combine all these features to create rich documentation:

1. **Important:** Remember to use `markdown` effectively
2. Visit [our site](https://example.com) for more
3. Try the following code:

```
echo "Hello, Terminal!"
```

> Pro tip: Markdown in terminals brings documentation to life!''',
  ];

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.tab) {
          setState(() {
            _selectedTab = (_selectedTab + 1) % _tabs.length;
          });
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
              'Markdown Text Demo',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
            const SizedBox(height: 1),

            // Tab bar
            Row(
              children: [
                for (int i = 0; i < _tabs.length; i++) ...[
                  if (i > 0) const Text(' | '),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: _selectedTab == i
                        ? BoxDecoration(color: Colors.blue)
                        : null,
                    child: Text(
                      _tabs[i],
                      style: TextStyle(
                        fontWeight: _selectedTab == i
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedTab == i ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 1),

            // Content area with border
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  border: BoxBorder.all(style: BoxBorderStyle.solid),
                ),
                child: SingleChildScrollView(
                  child: MarkdownText(_markdownContent[_selectedTab]),
                ),
              ),
            ),

            const SizedBox(height: 1),
            Text(
              'Use Tab or click to switch between examples',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
