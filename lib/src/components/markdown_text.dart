import 'package:markdown/markdown.dart' as md;
import 'package:nocterm/nocterm.dart';
import 'rich_text.dart';

/// A widget that displays markdown-formatted text.
///
/// This widget parses markdown text and displays it with appropriate styling
/// for terminal output. It supports basic markdown features like bold, italic,
/// headers, lists, code blocks, and links.
///
/// Features supported:
/// - **Bold text** using ** or __
/// - *Italic text* using * or _
/// - ~~Strikethrough~~ using ~~
/// - Headers (# H1, ## H2, etc.)
/// - Unordered lists (-, *, +)
/// - Ordered lists (1., 2., etc.)
/// - `Inline code` using backticks
/// - Code blocks using triple backticks
/// - Links [text](url) - displayed as "text [url]"
/// - Blockquotes using >
/// - Horizontal rules using ---, ***, or ___
///
/// Terminal limitations:
/// - Images are shown as [Image: alt text]
/// - Tables are rendered with basic ASCII formatting
/// - No font size changes (headers use bold/colors instead)
class MarkdownText extends StatefulComponent {
  /// Creates a markdown text widget.
  ///
  /// The [data] parameter must not be null.
  const MarkdownText(
    this.data, {
    super.key,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.styleSheet,
  });

  /// The markdown string to display.
  final String data;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// Whether the text should break at soft line breaks.
  final bool softWrap;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// An optional maximum number of lines for the text to span.
  final int? maxLines;

  /// Optional custom style sheet for markdown elements.
  final MarkdownStyleSheet? styleSheet;

  @override
  State<MarkdownText> createState() => _MarkdownTextState();
}

class _MarkdownTextState extends State<MarkdownText> {
  late List<InlineSpan> _spans;

  @override
  void initState() {
    super.initState();
    _parseMarkdown();
  }

  @override
  void didUpdateComponent(MarkdownText oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.data != component.data ||
        oldComponent.styleSheet != component.styleSheet) {
      _parseMarkdown();
    }
  }

  void _parseMarkdown() {
    final effectiveStyleSheet =
        component.styleSheet ?? MarkdownStyleSheet.terminal();
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    );
    final nodes = document.parse(component.data);

    final visitor = _MarkdownVisitor(effectiveStyleSheet);
    _spans = visitor.visitNodes(nodes);
  }

  @override
  Component build(BuildContext context) {
    return RichText(
      text: TextSpan(children: _spans),
      textAlign: component.textAlign,
      softWrap: component.softWrap,
      overflow: component.overflow,
      maxLines: component.maxLines,
    );
  }
}

/// Style sheet for markdown elements.
class MarkdownStyleSheet {
  const MarkdownStyleSheet({
    this.h1Style,
    this.h2Style,
    this.h3Style,
    this.h4Style,
    this.h5Style,
    this.h6Style,
    this.paragraphStyle,
    this.boldStyle,
    this.italicStyle,
    this.strikethroughStyle,
    this.codeStyle,
    this.codeBlockStyle,
    this.blockquoteStyle,
    this.linkStyle,
    this.listBullet = '• ',
    this.horizontalRule = '─',
  });

  /// Creates a default style sheet for terminal display.
  factory MarkdownStyleSheet.terminal() {
    return MarkdownStyleSheet(
      h1Style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
      h2Style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      h3Style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
      h4Style: const TextStyle(fontWeight: FontWeight.bold),
      h5Style: const TextStyle(fontWeight: FontWeight.bold),
      h6Style: const TextStyle(fontWeight: FontWeight.bold),
      boldStyle: const TextStyle(fontWeight: FontWeight.bold),
      italicStyle: const TextStyle(fontStyle: FontStyle.italic),
      strikethroughStyle: const TextStyle(
        decoration: TextDecoration.lineThrough,
      ),
      codeStyle: const TextStyle(
        color: Colors.yellow,
        backgroundColor: Colors.black,
      ),
      codeBlockStyle: const TextStyle(
        color: Colors.green,
        backgroundColor: Colors.black,
      ),
      blockquoteStyle: const TextStyle(
        color: Colors.grey,
        fontStyle: FontStyle.italic,
      ),
      linkStyle: const TextStyle(
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
    );
  }

  final TextStyle? h1Style;
  final TextStyle? h2Style;
  final TextStyle? h3Style;
  final TextStyle? h4Style;
  final TextStyle? h5Style;
  final TextStyle? h6Style;
  final TextStyle? paragraphStyle;
  final TextStyle? boldStyle;
  final TextStyle? italicStyle;
  final TextStyle? strikethroughStyle;
  final TextStyle? codeStyle;
  final TextStyle? codeBlockStyle;
  final TextStyle? blockquoteStyle;
  final TextStyle? linkStyle;
  final String listBullet;
  final String horizontalRule;
}

/// Visitor that converts markdown AST nodes to TextSpan trees.
class _MarkdownVisitor {
  _MarkdownVisitor(this.styleSheet);

  final MarkdownStyleSheet styleSheet;
  int _listDepth = 0;

  List<InlineSpan> visitNodes(List<md.Node> nodes) {
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      final span = visitNode(node);
      if (span != null) {
        spans.add(span);
      }
    }
    return spans;
  }

  InlineSpan? visitNode(md.Node node) {
    if (node is md.Element) {
      return visitElement(node);
    } else if (node is md.Text) {
      return TextSpan(text: node.text);
    }
    return null;
  }

  InlineSpan? visitElement(md.Element element) {
    switch (element.tag) {
      case 'h1':
        return TextSpan(
          children: [
            TextSpan(text: '# ', style: styleSheet.h1Style),
            ...visitChildren(element),
            const TextSpan(text: '\n\n'),
          ],
          style: styleSheet.h1Style,
        );
      case 'h2':
        return TextSpan(
          children: [
            TextSpan(text: '## ', style: styleSheet.h2Style),
            ...visitChildren(element),
            const TextSpan(text: '\n\n'),
          ],
          style: styleSheet.h2Style,
        );
      case 'h3':
        return TextSpan(
          children: [
            TextSpan(text: '### ', style: styleSheet.h3Style),
            ...visitChildren(element),
            const TextSpan(text: '\n\n'),
          ],
          style: styleSheet.h3Style,
        );
      case 'h4':
      case 'h5':
      case 'h6':
        final style = element.tag == 'h4'
            ? styleSheet.h4Style
            : element.tag == 'h5'
            ? styleSheet.h5Style
            : styleSheet.h6Style;
        return TextSpan(
          children: [
            ...visitChildren(element),
            const TextSpan(text: '\n\n'),
          ],
          style: style,
        );
      case 'p':
        return TextSpan(
          children: [
            ...visitChildren(element),
            const TextSpan(text: '\n\n'),
          ],
          style: styleSheet.paragraphStyle,
        );
      case 'strong':
      case 'b':
        return TextSpan(
          children: visitChildren(element),
          style: styleSheet.boldStyle,
        );
      case 'em':
      case 'i':
        return TextSpan(
          children: visitChildren(element),
          style: styleSheet.italicStyle,
        );
      case 'del':
      case 's':
        return TextSpan(
          children: visitChildren(element),
          style: styleSheet.strikethroughStyle,
        );
      case 'code':
        return TextSpan(text: element.textContent, style: styleSheet.codeStyle);
      case 'pre':
        // Code block
        final codeElement =
            element.children != null && element.children!.isNotEmpty
            ? element.children!.first
            : null;
        final code = codeElement?.textContent ?? element.textContent;
        return TextSpan(
          children: [
            TextSpan(text: code, style: styleSheet.codeBlockStyle),
            const TextSpan(text: '\n\n'),
          ],
        );
      case 'blockquote':
        final children = visitChildren(element);
        return TextSpan(
          children: [
            TextSpan(text: '│ ', style: styleSheet.blockquoteStyle),
            ...children,
            const TextSpan(text: '\n'),
          ],
          style: styleSheet.blockquoteStyle,
        );
      case 'a':
        final href = element.attributes['href'] ?? '';
        final text = element.textContent;
        return TextSpan(
          children: [
            TextSpan(text: text, style: styleSheet.linkStyle),
            TextSpan(
              text: ' [$href]',
              style: styleSheet.linkStyle?.copyWith(
                fontWeight: FontWeight.normal,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        );
      case 'img':
        final alt = element.attributes['alt'] ?? 'image';
        return TextSpan(
          text: '[Image: $alt]',
          style: const TextStyle(fontStyle: FontStyle.italic),
        );
      case 'ul':
      case 'ol':
        _listDepth++;
        // Note: Ordered list numbering is not yet implemented
        final children = visitChildren(element);
        _listDepth--;
        return TextSpan(
          children: [
            ...children,
            if (_listDepth == 0) const TextSpan(text: '\n'),
          ],
        );
      case 'li':
        final indent = '  ' * _listDepth;
        // Using unordered list bullet style for now
        final bullet = styleSheet.listBullet;
        final children = <InlineSpan>[TextSpan(text: indent + bullet)];

        if (element.children != null) {
          for (final child in element.children!) {
            // Insert line break before nested lists
            if (child is md.Element &&
                (child.tag == 'ul' || child.tag == 'ol')) {
              // Only add newline if there's content before the nested list
              if (children.length > 1) {
                children.add(const TextSpan(text: '\n'));
              }
            }

            final span = visitNode(child);
            if (span != null) {
              children.add(span);
            }
          }
        }

        children.add(const TextSpan(text: '\n'));
        return TextSpan(children: children);
      case 'hr':
        final width = 40; // Default width for horizontal rule
        return TextSpan(
          text: styleSheet.horizontalRule * width + '\n\n',
          style: const TextStyle(color: Colors.grey),
        );
      case 'br':
        return const TextSpan(text: '\n');
      case 'table':
        // Basic table rendering - this is simplified
        return _renderTable(element);
      default:
        // For unknown elements, just visit children
        return TextSpan(children: visitChildren(element));
    }
  }

  List<InlineSpan> visitChildren(md.Element element) {
    final spans = <InlineSpan>[];
    if (element.children != null) {
      for (final child in element.children!) {
        final span = visitNode(child);
        if (span != null) {
          spans.add(span);
        }
      }
    }
    return spans;
  }

  InlineSpan _renderTable(md.Element table) {
    final rows = <List<String>>[];
    final columnWidths = <int>[];

    // Extract table data
    if (table.children != null) {
      for (final child in table.children!) {
        if (child is md.Element) {
          if (child.tag == 'thead' || child.tag == 'tbody') {
            if (child.children != null) {
              for (final row in child.children!) {
                if (row is md.Element && row.tag == 'tr') {
                  final cells = <String>[];
                  if (row.children != null) {
                    for (final cell in row.children!) {
                      if (cell is md.Element &&
                          (cell.tag == 'th' || cell.tag == 'td')) {
                        cells.add(cell.textContent);
                      }
                    }
                  }
                  rows.add(cells);

                  // Update column widths
                  for (int i = 0; i < cells.length; i++) {
                    if (i >= columnWidths.length) {
                      columnWidths.add(0);
                    }
                    columnWidths[i] = columnWidths[i] > cells[i].length
                        ? columnWidths[i]
                        : cells[i].length;
                  }
                }
              }
            }
          }
        }
      }
    }

    // Render table as ASCII
    final buffer = StringBuffer();
    if (rows.isNotEmpty) {
      // Top border
      buffer.write('┌');
      for (int i = 0; i < columnWidths.length; i++) {
        buffer.write('─' * (columnWidths[i] + 2));
        if (i < columnWidths.length - 1) {
          buffer.write('┬');
        }
      }
      buffer.write('┐\n');

      // Rows
      for (int r = 0; r < rows.length; r++) {
        buffer.write('│');
        for (int c = 0; c < rows[r].length; c++) {
          buffer.write(' ');
          buffer.write(rows[r][c].padRight(columnWidths[c]));
          buffer.write(' │');
        }
        buffer.write('\n');

        // Separator after header
        if (r == 0 && rows.length > 1) {
          buffer.write('├');
          for (int i = 0; i < columnWidths.length; i++) {
            buffer.write('─' * (columnWidths[i] + 2));
            if (i < columnWidths.length - 1) {
              buffer.write('┼');
            }
          }
          buffer.write('┤\n');
        }
      }

      // Bottom border
      buffer.write('└');
      for (int i = 0; i < columnWidths.length; i++) {
        buffer.write('─' * (columnWidths[i] + 2));
        if (i < columnWidths.length - 1) {
          buffer.write('┴');
        }
      }
      buffer.write('┘\n');
    }

    return TextSpan(text: buffer.toString());
  }
}
