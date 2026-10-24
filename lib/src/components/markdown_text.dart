import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/utils/unicode_width.dart';

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
/// - Task lists (- [ ] and - [x]) - displayed as "□ " and "✓ "
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
  List<InlineSpan> _spans = const [];
  int? _lastMaxWidth;
  String? _lastData;
  MarkdownStyleSheet? _lastStyleSheet;

  List<InlineSpan> _parseMarkdown({int? maxWidth}) {
    final effectiveStyleSheet =
        component.styleSheet ?? MarkdownStyleSheet.terminal();
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    );
    final nodes = document.parse(component.data);

    final visitor = _MarkdownVisitor(effectiveStyleSheet, maxWidth: maxWidth);
    return visitor.visitNodes(nodes);
  }

  @override
  Component build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth.toInt() : null;

        if (component.data != _lastData ||
            component.styleSheet != _lastStyleSheet ||
            maxWidth != _lastMaxWidth) {
          _lastData = component.data;
          _lastStyleSheet = component.styleSheet;
          _lastMaxWidth = maxWidth;
          _spans = _parseMarkdown(maxWidth: maxWidth);
        }

        return RichText(
          text: TextSpan(children: _spans),
          textAlign: component.textAlign,
          softWrap: component.softWrap,
          overflow: component.overflow,
          maxLines: component.maxLines,
        );
      },
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
    this.taskListUnchecked = '□ ',
    this.taskListChecked = '✓ ',
    this.horizontalRule = '─',
  });

  /// Creates a default style sheet for terminal display.
  factory MarkdownStyleSheet.terminal() {
    return MarkdownStyleSheet(
      h1Style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.cyan,
      ),
      h2Style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
      h3Style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
      h4Style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
      h5Style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
      h6Style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
      boldStyle: const TextStyle(fontWeight: FontWeight.bold),
      italicStyle: const TextStyle(fontStyle: FontStyle.italic),
      strikethroughStyle:
          const TextStyle(decoration: TextDecoration.lineThrough),
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

  /// Marker shown in place of [listBullet] for an unchecked task list item
  /// (`- [ ] task`).
  final String taskListUnchecked;

  /// Marker shown in place of [listBullet] for a checked task list item
  /// (`- [x] task`).
  final String taskListChecked;

  final String horizontalRule;
}

/// Visitor that converts markdown AST nodes to TextSpan trees.
class _MarkdownVisitor {
  _MarkdownVisitor(this.styleSheet, {this.maxWidth});

  final MarkdownStyleSheet styleSheet;
  final int? maxWidth;
  int _listDepth = 0;

  List<InlineSpan> visitNodes(List<md.Node> nodes) {
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      final span = visitNode(node);
      if (span != null) {
        spans.add(span);
      }
    }
    // Trim trailing newlines from the last span so the final block element
    // doesn't produce extra blank lines at the bottom.
    if (spans.isNotEmpty) {
      spans[spans.length - 1] = _trimTrailingNewlines(spans.last);
    }
    return spans;
  }

  /// Recursively removes trailing newline-only children from a span tree.
  static InlineSpan _trimTrailingNewlines(InlineSpan span) {
    if (span is! TextSpan) return span;

    final children = span.children;
    if (children != null && children.isNotEmpty) {
      final last = children.last;
      if (last is TextSpan &&
          last.text != null &&
          RegExp(r'^\n+$').hasMatch(last.text!)) {
        // Last child is a pure-newline span — drop it.
        final trimmed = children.sublist(0, children.length - 1);
        return TextSpan(children: trimmed, style: span.style);
      }
      // Otherwise recurse into the last child.
      final trimmedLast = _trimTrailingNewlines(last);
      if (trimmedLast != last) {
        final updated = [...children];
        updated[updated.length - 1] = trimmedLast;
        return TextSpan(children: updated, style: span.style);
      }
    } else if (span.text != null && span.text!.endsWith('\n')) {
      return TextSpan(text: span.text!.trimRight(), style: span.style);
    }

    return span;
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
        return TextSpan(
          text: element.textContent,
          style: styleSheet.codeStyle,
        );
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
                )),
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
        return TextSpan(children: [
          ...children,
          if (_listDepth == 0) const TextSpan(text: '\n'),
        ]);
      case 'li':
        final indent = '  ' * _listDepth;
        // Task list items render their checkbox in place of the bullet.
        final firstChild = element.children?.firstOrNull;
        final isTaskListItem =
            firstChild is md.Element && _isCheckbox(firstChild);
        // Using unordered list bullet style for now
        final bullet = isTaskListItem ? '' : styleSheet.listBullet;
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
        final width = maxWidth ?? 40;
        return TextSpan(
          text: styleSheet.horizontalRule * width + '\n\n',
          style: const TextStyle(color: Colors.grey),
        );
      case 'br':
        return const TextSpan(text: '\n');
      case 'input':
        if (!_isCheckbox(element)) return null;
        return TextSpan(
          text: element.attributes.containsKey('checked')
              ? styleSheet.taskListChecked
              : styleSheet.taskListUnchecked,
        );
      case 'table':
        // Basic table rendering - this is simplified
        return _renderTable(element);
      default:
        // For unknown elements, just visit children
        return TextSpan(children: visitChildren(element));
    }
  }

  static bool _isCheckbox(md.Element element) =>
      element.tag == 'input' && element.attributes['type'] == 'checkbox';

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
    final naturalWidths = <int>[];

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

                  // Update column widths (using display width, not string length)
                  for (int i = 0; i < cells.length; i++) {
                    if (i >= naturalWidths.length) {
                      naturalWidths.add(0);
                    }
                    final cellWidth = UnicodeWidth.stringWidth(cells[i]);
                    naturalWidths[i] = naturalWidths[i] > cellWidth
                        ? naturalWidths[i]
                        : cellWidth;
                  }
                }
              }
            }
          }
        }
      }
    }

    if (rows.isEmpty || naturalWidths.isEmpty) {
      return const TextSpan(text: '');
    }

    // Shrink columns to fit available width if needed
    final columnWidths = _distributeColumnWidths(naturalWidths);

    // Word-wrap all cell content to fit column widths
    final wrappedRows = <List<List<String>>>[];
    for (final row in rows) {
      final wrappedCells = <List<String>>[];
      for (int c = 0; c < naturalWidths.length; c++) {
        final content = c < row.length ? row[c] : '';
        wrappedCells.add(_wrapCell(content, columnWidths[c]));
      }
      wrappedRows.add(wrappedCells);
    }

    // Render table
    final buffer = StringBuffer();

    // Top border
    _writeHorizontalBorder(buffer, columnWidths, '┌', '─', '┬', '┐');

    for (int r = 0; r < wrappedRows.length; r++) {
      final rowCells = wrappedRows[r];
      final rowHeight =
          rowCells.fold(1, (max, cell) => math.max(max, cell.length));

      // Render each line of this row
      for (int l = 0; l < rowHeight; l++) {
        buffer.write('│');
        for (int c = 0; c < columnWidths.length; c++) {
          final lines = c < rowCells.length ? rowCells[c] : const [''];
          final line = l < lines.length ? lines[l] : '';
          final displayWidth = UnicodeWidth.stringWidth(line);
          final paddingNeeded = columnWidths[c] - displayWidth;
          buffer.write(' ');
          buffer.write(line);
          if (paddingNeeded > 0) {
            buffer.write(' ' * paddingNeeded);
          }
          buffer.write(' │');
        }
        buffer.write('\n');
      }

      // Separator after header row
      if (r == 0 && wrappedRows.length > 1) {
        _writeHorizontalBorder(buffer, columnWidths, '├', '─', '┼', '┤');
      }
    }

    // Bottom border
    _writeHorizontalBorder(buffer, columnWidths, '└', '─', '┴', '┘');

    return TextSpan(text: buffer.toString());
  }

  /// Distributes column widths to fit within [maxWidth].
  /// If the table fits naturally, returns the natural widths unchanged.
  List<int> _distributeColumnWidths(List<int> naturalWidths) {
    final numCols = naturalWidths.length;
    // Each column uses: 1 border + 1 space + content + 1 space = 3 + content
    // Plus the final border: +1
    // Total overhead = 3 * numCols + 1
    final overhead = 3 * numCols + 1;
    final naturalTotal = naturalWidths.fold(0, (sum, w) => sum + w) + overhead;

    if (maxWidth == null || naturalTotal <= maxWidth!) {
      return List.of(naturalWidths);
    }

    const minColWidth = 3;
    final available = maxWidth! - overhead;

    // If even minimum widths don't fit, use minimums and accept overflow
    if (available < numCols * minColWidth) {
      return List.filled(numCols, minColWidth);
    }

    // Proportional reduction
    final result = List<int>.filled(numCols, 0);
    final totalNatural = naturalWidths.fold(0, (sum, w) => sum + w);

    // First pass: proportional allocation
    int allocated = 0;
    for (int i = 0; i < numCols; i++) {
      result[i] = math.max(
        minColWidth,
        (naturalWidths[i] * available / totalNatural).floor(),
      );
      allocated += result[i];
    }

    // Second pass: distribute remaining space to columns that need it most
    var remaining = available - allocated;
    while (remaining > 0) {
      // Find the column with the biggest deficit (natural - assigned)
      int bestIdx = 0;
      int bestDeficit = 0;
      for (int i = 0; i < numCols; i++) {
        final deficit = naturalWidths[i] - result[i];
        if (deficit > bestDeficit) {
          bestDeficit = deficit;
          bestIdx = i;
        }
      }
      if (bestDeficit == 0) break;
      result[bestIdx]++;
      remaining--;
    }

    // Third pass: reclaim excess if we overallocated
    while (remaining < 0) {
      // Find the column with the most excess over minColWidth
      int bestIdx = 0;
      int bestExcess = 0;
      for (int i = 0; i < numCols; i++) {
        final excess = result[i] - minColWidth;
        if (excess > bestExcess) {
          bestExcess = excess;
          bestIdx = i;
        }
      }
      if (bestExcess == 0) break;
      result[bestIdx]--;
      remaining++;
    }

    return result;
  }

  /// Word-wraps cell content to fit within [cellWidth].
  static List<String> _wrapCell(String content, int cellWidth) {
    if (cellWidth <= 0) return [''];
    if (UnicodeWidth.stringWidth(content) <= cellWidth) return [content];

    final lines = <String>[];
    final words = content.split(' ');
    var currentLine = '';
    var currentWidth = 0;

    for (final word in words) {
      final wordWidth = UnicodeWidth.stringWidth(word);

      if (currentWidth == 0) {
        // First word on line - may need to break if too long
        if (wordWidth > cellWidth) {
          lines.addAll(_breakLongWord(word, cellWidth));
          final lastLine = lines.removeLast();
          currentLine = lastLine;
          currentWidth = UnicodeWidth.stringWidth(lastLine);
        } else {
          currentLine = word;
          currentWidth = wordWidth;
        }
      } else if (currentWidth + 1 + wordWidth <= cellWidth) {
        // Word fits with space
        currentLine += ' $word';
        currentWidth += 1 + wordWidth;
      } else {
        // Word doesn't fit - start new line
        lines.add(currentLine);
        if (wordWidth > cellWidth) {
          lines.addAll(_breakLongWord(word, cellWidth));
          final lastLine = lines.removeLast();
          currentLine = lastLine;
          currentWidth = UnicodeWidth.stringWidth(lastLine);
        } else {
          currentLine = word;
          currentWidth = wordWidth;
        }
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines.isEmpty ? [''] : lines;
  }

  /// Breaks a single word that exceeds [maxWidth] into multiple lines.
  static List<String> _breakLongWord(String word, int maxWidth) {
    final parts = <String>[];
    var current = '';
    var currentWidth = 0;

    for (final grapheme in word.characters) {
      final w = UnicodeWidth.graphemeWidth(grapheme);
      if (currentWidth + w > maxWidth && current.isNotEmpty) {
        parts.add(current);
        current = grapheme;
        currentWidth = w;
      } else {
        current += grapheme;
        currentWidth += w;
      }
    }
    if (current.isNotEmpty) parts.add(current);
    return parts.isEmpty ? [''] : parts;
  }

  /// Writes a horizontal border line like ┌──┬──┐ or ├──┼──┤.
  static void _writeHorizontalBorder(
    StringBuffer buffer,
    List<int> columnWidths,
    String left,
    String fill,
    String middle,
    String right,
  ) {
    buffer.write(left);
    for (int i = 0; i < columnWidths.length; i++) {
      buffer.write(fill * (columnWidths[i] + 2));
      if (i < columnWidths.length - 1) {
        buffer.write(middle);
      }
    }
    buffer.write(right);
    buffer.write('\n');
  }
}
