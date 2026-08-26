import 'package:nocterm/nocterm.dart' hide TextAlign;

import '../text/text_layout_engine.dart';
import '../text/selection_utils.dart' as selection_utils;

/// Mixin that makes a [RenderObject] participate in text selection.
///
/// Any render object that displays selectable text should mix in this mixin
/// and implement [selectableText] and [selectableLayout].
///
/// A [SelectionArea] ancestor will discover these render objects by walking
/// the render subtree, and call [setSelectionRange] / [clearSelection] to
/// drive highlighting.
mixin Selectable on RenderObject {
  /// The plain-text content that can be selected.
  String get selectableText;

  /// The cached layout result (line-wrapped text).
  TextLayoutResult? get selectableLayout;

  int? _selectionStart;
  int? _selectionEnd;

  /// The color used to highlight selected text.
  Color? selectionColor;

  /// Current selection start (character index), or null if no selection.
  int? get selectionStart => _selectionStart;

  /// Current selection end (character index), or null if no selection.
  int? get selectionEnd => _selectionEnd;

  /// Whether this render object currently has a selection.
  bool get hasSelection =>
      _selectionStart != null &&
      _selectionEnd != null &&
      _selectionStart != _selectionEnd;

  /// Sets the selected character range. Pass null to clear.
  void setSelectionRange(int? start, int? end) {
    if (_selectionStart == start && _selectionEnd == end) return;
    _selectionStart = start;
    _selectionEnd = end;
    markNeedsPaint();
  }

  /// Clears the current selection.
  void clearSelection() {
    setSelectionRange(null, null);
  }

  /// Maps a local position (x, y) to a character index in [selectableText].
  ///
  /// Uses the layout result to determine which line the y coordinate falls on,
  /// then walks grapheme clusters on that line using [UnicodeWidth] to find the
  /// character at the x coordinate.
  int getCharacterIndexAtLocalPosition(Offset localPos) {
    return selection_utils.getCharacterIndexAtLocalPosition(
      localPos: localPos,
      text: selectableText,
      lines: selectableLayout?.lines ?? const [],
    );
  }

  /// Paints a single line of text with optional selection highlighting.
  ///
  /// This is extracted from [RenderTextField]'s `_paintLineWithSelection` so
  /// that any [Selectable] render object can reuse the same painting logic.
  void paintTextWithSelection(
    TerminalCanvas canvas,
    Offset offset,
    String line,
    TextStyle? style,
    int lineIndex,
  ) {
    selection_utils.paintTextWithSelection(
      canvas: canvas,
      offset: offset,
      line: line,
      style: style,
      lineIndex: lineIndex,
      text: selectableText,
      lines: selectableLayout?.lines ?? const [],
      selectionStart: _selectionStart,
      selectionEnd: _selectionEnd,
      selectionColor: selectionColor ?? Colors.blue,
    );
  }

  /// Computes the character offset of the start of each line in [text],
  /// given the layout [lines] (which don't contain `\n` characters).
  ///
  /// The layout engine strips `\n` when splitting into paragraphs, so the
  /// newline character sits at the offset immediately after each line's
  /// content rather than inside it.
  static List<int> lineStartOffsets(String text, List<String> lines) =>
      selection_utils.lineStartOffsets(text, lines);

  /// Computes the global paint offset of this render object by walking
  /// the parent chain and accumulating [BoxParentData] offsets.
  Offset get globalPaintOffset {
    double x = 0;
    double y = 0;
    RenderObject? node = this;
    while (node != null) {
      if (node.parentData is BoxParentData) {
        final pd = node.parentData as BoxParentData;
        x += pd.offset.dx;
        y += pd.offset.dy;
      }
      node = node.parent;
    }
    return Offset(x, y);
  }
}
