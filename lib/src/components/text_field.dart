import 'dart:async';
import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:nocterm/nocterm.dart' hide TextAlign;
import 'package:nocterm/src/framework/terminal_canvas.dart';
import '../text/text_layout_engine.dart';
import '../utils/unicode_width.dart';

/// Controls the text being edited.
class TextEditingController {
  TextEditingController({String? text})
      : _text = text ?? '',
        _selection = TextSelection.collapsed(offset: text?.length ?? 0);

  String _text;
  TextSelection _selection;
  final _listeners = <VoidCallback>[];

  /// The current text being edited.
  String get text => _text;
  set text(String newText) {
    if (_text != newText) {
      _text = newText;
      _selection = TextSelection.collapsed(offset: newText.length);
      notifyListeners();
    }
  }

  /// The current selection.
  TextSelection get selection => _selection;
  set selection(TextSelection newSelection) {
    if (_selection != newSelection) {
      _selection = newSelection;
      notifyListeners();
    }
  }

  /// Clear the text.
  void clear() {
    text = '';
  }

  /// Add a listener.
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove a listener.
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners.
  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Dispose of the controller.
  void dispose() {
    _listeners.clear();
  }
}

/// Text selection representation.
class TextSelection {
  const TextSelection({
    required this.baseOffset,
    required this.extentOffset,
  });

  const TextSelection.collapsed({required int offset})
      : baseOffset = offset,
        extentOffset = offset;

  final int baseOffset;
  final int extentOffset;

  bool get isCollapsed => baseOffset == extentOffset;
  int get start => math.min(baseOffset, extentOffset);
  int get end => math.max(baseOffset, extentOffset);

  TextSelection copyWith({int? baseOffset, int? extentOffset}) {
    return TextSelection(
      baseOffset: baseOffset ?? this.baseOffset,
      extentOffset: extentOffset ?? this.extentOffset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextSelection && other.baseOffset == baseOffset && other.extentOffset == extentOffset;
  }

  @override
  int get hashCode => Object.hash(baseOffset, extentOffset);
}

/// A Material Design text field for terminal UI.
class TextField extends StatefulComponent {
  const TextField({
    super.key,
    this.controller,
    this.focused = false,
    this.onFocusChange,
    this.decoration,
    this.style,
    this.placeholder,
    this.placeholderStyle,
    this.textAlign = TextAlign.left,
    this.readOnly = false,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.enabled = true,
    this.cursorColor,
    this.cursorStyle = CursorStyle.block,
    this.cursorBlinkRate = const Duration(milliseconds: 800),
    this.selectionColor,
    this.showCursor = true,
    this.width,
    this.height,
  })  : assert(maxLines == null || maxLines > 0),
        assert(minLines == null || minLines > 0),
        assert(
          (maxLines == null) || (minLines == null) || (maxLines >= minLines),
          "minLines can't be greater than maxLines",
        ),
        assert(!obscureText || maxLines == 1, 'Obscured fields cannot be multiline.'),
        assert(maxLength == null || maxLength > 0);

  final TextEditingController? controller;
  final bool focused;
  final ValueChanged<bool>? onFocusChange;
  final InputDecoration? decoration;
  final TextStyle? style;
  final String? placeholder;
  final TextStyle? placeholderStyle;
  final TextAlign textAlign;
  final bool readOnly;
  final bool obscureText;
  final String obscuringCharacter;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final Color? cursorColor;
  final CursorStyle cursorStyle;
  final Duration? cursorBlinkRate;
  final Color? selectionColor;
  final bool showCursor;
  final double? width;
  final double? height;

  @override
  State<TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<TextField> {
  late TextEditingController _controller;
  bool _controllerIsInternal = false;
  Timer? _cursorTimer;
  bool _cursorVisible = true;
  int _viewOffset = 0; // For horizontal scrolling

  @override
  void initState() {
    super.initState();

    if (component.controller == null) {
      _controller = TextEditingController();
      _controllerIsInternal = true;
    } else {
      _controller = component.controller!;
    }

    _controller.addListener(_handleControllerChanged);

    if (component.focused && component.showCursor) {
      _startCursorBlink();
    }
  }

  @override
  void dispose() {
    _stopCursorBlink();
    _controller.removeListener(_handleControllerChanged);

    if (_controllerIsInternal) {
      _controller.dispose();
    }

    super.dispose();
  }

  void _handleControllerChanged() {
    component.onChanged?.call(_controller.text);
    setState(() {
      // Update view offset for horizontal scrolling
      _updateViewOffset();
    });
  }

  @override
  void didUpdateComponent(TextField oldComponent) {
    super.didUpdateComponent(oldComponent);

    // Handle focus changes or blink rate changes
    if (component.focused != oldComponent.focused ||
        component.cursorBlinkRate != oldComponent.cursorBlinkRate) {
      if (component.focused && component.showCursor) {
        _startCursorBlink();
      } else {
        _stopCursorBlink();
      }
    }
  }

  void _startCursorBlink() {
    _cursorVisible = true;
    _cursorTimer?.cancel();

    // Check if blinking is disabled (null blink rate means static cursor)
    if (component.cursorBlinkRate == null) {
      // Non-blinking cursor - always visible
      _cursorVisible = true;
      return;
    }

    // Start blinking with specified rate
    _cursorTimer = Timer.periodic(component.cursorBlinkRate!, (timer) {
      setState(() {
        _cursorVisible = !_cursorVisible;
      });
    });
  }

  void _stopCursorBlink() {
    _cursorTimer?.cancel();
    _cursorTimer = null;
    _cursorVisible = false;
  }

  void _updateViewOffset() {
    // Simple horizontal scrolling for single-line fields
    if (component.maxLines == 1 && component.width != null) {
      final cursorPos = _controller.selection.extentOffset;
      final maxVisible = component.width!.toInt() - 2; // Account for borders

      if (cursorPos < _viewOffset) {
        _viewOffset = cursorPos;
      } else if (cursorPos >= _viewOffset + maxVisible) {
        _viewOffset = (cursorPos - maxVisible + 1).toInt();
      }
    }
  }

  bool _handleKeyEvent(KeyboardEvent event) {
    if (component.readOnly || !component.enabled) {
      return false;
    }

    final key = event.logicalKey;

    // Handle Tab/Shift+Tab for focus navigation
    if (key == LogicalKey.tab) {
      // Don't consume tab keys - let them bubble up for focus navigation
      return false;
    }

    // Handle special keys
    if (key == LogicalKey.enter && event.isShiftPressed) {
      // Shift+Enter always inserts a newline in multi-line fields
      if (component.maxLines != 1) {
        _insertText('\n');
      }
      return true;
    } else if (key == LogicalKey.enter && !event.isShiftPressed) {
      // Enter always submits (for both single-line and multi-line fields)
      component.onEditingComplete?.call();
      component.onSubmitted?.call(_controller.text);
      return true;
    } else if (key == LogicalKey.backspace) {
      _handleBackspace();
      return true;
    } else if (key == LogicalKey.delete) {
      _handleDelete();
      return true;
    } else if (key == LogicalKey.arrowLeft) {
      _moveCursor(-1, false);
      return true;
    } else if (key == LogicalKey.arrowRight) {
      _moveCursor(1, false);
      return true;
    } else if (key == LogicalKey.arrowUp && component.maxLines != 1) {
      _moveCursorVertically(-1);
      return true;
    } else if (key == LogicalKey.arrowDown && component.maxLines != 1) {
      _moveCursorVertically(1);
      return true;
    } else if (key == LogicalKey.home) {
      _moveCursorToStart();
      return true;
    } else if (key == LogicalKey.end) {
      _moveCursorToEnd();
      return true;
    } else if (event.matches(LogicalKey.keyA, ctrl: true)) {
      _selectAll();
      return true;
    } else if (event.matches(LogicalKey.keyC, ctrl: true)) {
      _copy();
      return true;
    } else if (event.matches(LogicalKey.keyX, ctrl: true)) {
      _cut();
      return true;
    } else if (event.matches(LogicalKey.keyV, ctrl: true)) {
      _paste();
      return true;
    } else if (key == LogicalKey.arrowLeft && event.isShiftPressed) {
      _moveCursor(-1, true);
      return true;
    } else if (key == LogicalKey.arrowRight && event.isShiftPressed) {
      _moveCursor(1, true);
      return true;
    } else if (key == LogicalKey.arrowLeft && event.isControlPressed) {
      _moveCursorByWord(-1, false);
      return true;
    } else if (key == LogicalKey.arrowRight && event.isControlPressed) {
      _moveCursorByWord(1, false);
      return true;
    } else {
      // Use the character from the event if available (supports UTF-8 and composed characters)
      if (event.character != null) {
        _insertText(event.character!);
        return true;
      }

      // Fallback to getting character from key
      final char = _getCharacterFromKey(key);
      if (char != null) {
        _insertText(char);
        return true;
      }
    }

    return false;
  }

  String? _getCharacterFromKey(LogicalKey key) {
    // Map common printable keys to characters
    if (key == LogicalKey.space) return ' ';
    if (key == LogicalKey.exclamation) return '!';
    if (key == LogicalKey.quoteDbl) return '"';
    if (key == LogicalKey.numberSign) return '#';
    if (key == LogicalKey.dollar) return '\$';
    if (key == LogicalKey.percent) return '%';
    if (key == LogicalKey.ampersand) return '&';
    if (key == LogicalKey.quoteSingle) return '\'';
    if (key == LogicalKey.parenthesisLeft) return '(';
    if (key == LogicalKey.parenthesisRight) return ')';
    if (key == LogicalKey.asterisk) return '*';
    if (key == LogicalKey.add) return '+';
    if (key == LogicalKey.comma) return ',';
    if (key == LogicalKey.minus) return '-';
    if (key == LogicalKey.period) return '.';
    if (key == LogicalKey.slash) return '/';
    if (key == LogicalKey.colon) return ':';
    if (key == LogicalKey.semicolon) return ';';
    if (key == LogicalKey.less) return '<';
    if (key == LogicalKey.equal) return '=';
    if (key == LogicalKey.greater) return '>';
    if (key == LogicalKey.question) return '?';
    if (key == LogicalKey.at) return '@';
    if (key == LogicalKey.bracketLeft) return '[';
    if (key == LogicalKey.backslash) return '\\';
    if (key == LogicalKey.bracketRight) return ']';
    if (key == LogicalKey.caret) return '^';
    if (key == LogicalKey.underscore) return '_';
    if (key == LogicalKey.backquote) return '`';
    if (key == LogicalKey.braceLeft) return '{';
    if (key == LogicalKey.bar) return '|';
    if (key == LogicalKey.braceRight) return '}';
    if (key == LogicalKey.tilde) return '~';

    // Digits
    if (key == LogicalKey.digit0) return '0';
    if (key == LogicalKey.digit1) return '1';
    if (key == LogicalKey.digit2) return '2';
    if (key == LogicalKey.digit3) return '3';
    if (key == LogicalKey.digit4) return '4';
    if (key == LogicalKey.digit5) return '5';
    if (key == LogicalKey.digit6) return '6';
    if (key == LogicalKey.digit7) return '7';
    if (key == LogicalKey.digit8) return '8';
    if (key == LogicalKey.digit9) return '9';

    // Letters - character is already provided in the event, this is just fallback
    // Note: This method is rarely used now since event.character is preferred

    return null;
  }

  void _insertText(String char) {
    if (component.maxLength != null && _controller.text.length >= component.maxLength!) {
      return;
    }

    final text = _controller.text;
    final selection = _controller.selection;

    String newText;
    int newOffset;

    if (!selection.isCollapsed) {
      // Replace selected text
      newText = text.substring(0, selection.start) + char + text.substring(selection.end);
      newOffset = selection.start + char.length;
    } else {
      // Insert at cursor position
      newText = text.substring(0, selection.extentOffset) + char + text.substring(selection.extentOffset);
      newOffset = selection.extentOffset + char.length;
    }

    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: newOffset);
  }

  void _handleBackspace() {
    final text = _controller.text;
    final selection = _controller.selection;

    if (!selection.isCollapsed) {
      // Delete selected text
      _controller.text = text.substring(0, selection.start) + text.substring(selection.end);
      _controller.selection = TextSelection.collapsed(offset: selection.start);
    } else if (selection.extentOffset > 0) {
      // Delete the grapheme cluster before cursor
      final textBefore = text.substring(0, selection.extentOffset);
      final textAfter = text.substring(selection.extentOffset);

      // Use grapheme clusters to delete the entire cluster
      final graphemes = textBefore.characters;
      if (graphemes.isNotEmpty) {
        final newTextBefore = graphemes.skipLast(1).toString();
        _controller.text = newTextBefore + textAfter;
        _controller.selection = TextSelection.collapsed(offset: newTextBefore.length);
      }
    }
  }

  void _handleDelete() {
    final text = _controller.text;
    final selection = _controller.selection;

    if (!selection.isCollapsed) {
      // Delete selected text
      _controller.text = text.substring(0, selection.start) + text.substring(selection.end);
      _controller.selection = TextSelection.collapsed(offset: selection.start);
    } else if (selection.extentOffset < text.length) {
      // Delete the grapheme cluster after cursor
      final textBefore = text.substring(0, selection.extentOffset);
      final textAfter = text.substring(selection.extentOffset);

      // Use grapheme clusters to delete the entire cluster
      final graphemesAfter = textAfter.characters;
      if (graphemesAfter.isNotEmpty) {
        final newTextAfter = graphemesAfter.skip(1).toString();
        _controller.text = textBefore + newTextAfter;
        // Cursor position stays the same
      }
    }
  }

  void _moveCursor(int delta, bool extendSelection) {
    final selection = _controller.selection;
    final text = _controller.text;

    // Use grapheme clusters for proper cursor movement
    final graphemes = text.characters.toList();

    // Find current position in grapheme clusters
    int currentGraphemeIndex = 0;
    int charCount = 0;
    for (int i = 0; i < graphemes.length; i++) {
      if (charCount >= selection.extentOffset) {
        currentGraphemeIndex = i;
        break;
      }
      charCount += graphemes[i].length;
    }

    // Move by grapheme clusters
    final newGraphemeIndex = (currentGraphemeIndex + delta).clamp(0, graphemes.length);

    // Calculate new character offset
    int newOffset = 0;
    for (int i = 0; i < newGraphemeIndex; i++) {
      newOffset += graphemes[i].length;
    }

    if (extendSelection) {
      _controller.selection = selection.copyWith(extentOffset: newOffset);
    } else {
      _controller.selection = TextSelection.collapsed(offset: newOffset);
    }
  }

  void _moveCursorByWord(int direction, bool extendSelection) {
    final text = _controller.text;
    final selection = _controller.selection;
    int offset = selection.extentOffset;

    if (direction < 0) {
      // Move left by word
      while (offset > 0 && text[offset - 1] == ' ') offset--;
      while (offset > 0 && text[offset - 1] != ' ') offset--;
    } else {
      // Move right by word
      while (offset < text.length && text[offset] != ' ') offset++;
      while (offset < text.length && text[offset] == ' ') offset++;
    }

    if (extendSelection) {
      _controller.selection = selection.copyWith(extentOffset: offset);
    } else {
      _controller.selection = TextSelection.collapsed(offset: offset);
    }
  }

  void _moveCursorVertically(int direction) {
    final text = _controller.text;
    final selection = _controller.selection;
    final currentOffset = selection.extentOffset;

    // For multi-line text, calculate layout using TextLayoutEngine
    final maxWidth = component.width?.toInt() ?? 80;

    final config = TextLayoutConfig(
      maxWidth: maxWidth,
      maxLines: component.maxLines,
      textAlign: component.textAlign,
      overflow: TextOverflow.visible,
      softWrap: component.maxLines != 1,
    );

    final layoutResult = TextLayoutEngine.layout(text, config);
    final layoutLines = layoutResult.lines;

    if (layoutLines.isEmpty) return;

    // Build line offset mapping
    final List<int> lineStartOffsets = [];
    final List<int> lineEndOffsets = [];
    int textPosition = 0;

    for (final line in layoutLines) {
      lineStartOffsets.add(textPosition);
      // Find the actual text that corresponds to this line
      // Account for the fact that lines might be wrapped
      int lineLength = line.characters.length;
      lineEndOffsets.add(textPosition + lineLength);
      textPosition += lineLength;

      // Check if there's a newline after this line in the original text
      if (textPosition < text.length && text[textPosition] == '\n') {
        textPosition++; // Skip the newline
      }
    }

    // Find current line and column position
    int currentLineIndex = 0;
    int currentVisualColumn = 0;

    for (int i = 0; i < layoutLines.length; i++) {
      if (currentOffset >= lineStartOffsets[i] &&
          (i == layoutLines.length - 1 || currentOffset < lineStartOffsets[i + 1])) {
        currentLineIndex = i;
        // Calculate visual column from start of this line
        final lineStart = lineStartOffsets[i];
        if (currentOffset > lineStart) {
          final textBeforeCursor = text.substring(lineStart, currentOffset);
          currentVisualColumn = UnicodeWidth.stringWidth(textBeforeCursor);
        }
        break;
      }
    }

    // Move to new line
    final newLineIndex = (currentLineIndex + direction).clamp(0, layoutLines.length - 1);
    if (newLineIndex == currentLineIndex) return;

    // Find the position in the new line that matches the visual column
    final newLineStart = lineStartOffsets[newLineIndex];
    final newLineEnd = lineEndOffsets[newLineIndex];
    final newLineText = text.substring(newLineStart, math.min(newLineEnd, text.length));

    int targetOffset = newLineStart;
    int visualPosition = 0;

    for (final char in newLineText.characters) {
      final charWidth = UnicodeWidth.stringWidth(char);
      if (visualPosition + charWidth > currentVisualColumn) {
        // If we'd overshoot, decide whether to place before or after this character
        if (visualPosition + charWidth / 2 <= currentVisualColumn) {
          targetOffset += char.length;
        }
        break;
      }
      visualPosition += charWidth;
      targetOffset += char.length;
    }

    _controller.selection = TextSelection.collapsed(offset: targetOffset);
  }

  void _moveCursorToStart() {
    _controller.selection = const TextSelection.collapsed(offset: 0);
  }

  void _moveCursorToEnd() {
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  void _selectAll() {
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _copy() {
    // TODO: Implement clipboard integration
    // For now, just a placeholder
  }

  void _cut() {
    // TODO: Implement clipboard integration
    // For now, just delete selected text
    if (!_controller.selection.isCollapsed) {
      final text = _controller.text;
      final selection = _controller.selection;
      _controller.text = text.substring(0, selection.start) + text.substring(selection.end);
      _controller.selection = TextSelection.collapsed(offset: selection.start);
    }
  }

  void _paste() {
    // TODO: Implement clipboard integration
    // For now, just a placeholder
  }

  @override
  Component build(BuildContext context) {
    final decoration = component.decoration ?? const InputDecoration();
    final isFocused = component.focused;

    // Prepare display text
    String displayText = _controller.text;
    if (component.obscureText) {
      displayText = component.obscuringCharacter * displayText.length;
    }

    // Handle view offset for single-line fields
    if (component.maxLines == 1 && component.width != null) {
      final maxVisible = component.width!.toInt() - 2;
      if (displayText.length > maxVisible) {
        displayText = displayText.substring(_viewOffset, math.min(_viewOffset + maxVisible, displayText.length));
      }
    }

    // Build the text field content
    Component content = _TextFieldContent(
      text: displayText,
      placeholder: component.placeholder,
      style: component.style,
      placeholderStyle: component.placeholderStyle,
      selection: _controller.selection,
      viewOffset: _viewOffset,
      cursorVisible: _cursorVisible && isFocused && component.showCursor,
      cursorColor: component.cursorColor,
      cursorStyle: component.cursorStyle,
      selectionColor: component.selectionColor,
      textAlign: component.textAlign,
      maxLines: component.maxLines,
      isFocused: isFocused, // Pass focus state to render object
    );

    // Apply decoration
    if (decoration.border != null || decoration.fillColor != null) {
      content = Container(
        width: component.width,
        height: component.height ?? (component.maxLines ?? 1).toDouble() + 2,
        padding: decoration.contentPadding ?? const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          border: isFocused ? decoration.focusedBorder ?? decoration.border : decoration.border,
          color: decoration.fillColor,
        ),
        child: content,
      );
    }

    // Wrap with Focusable for keyboard input
    return Focusable(
      focused: isFocused,
      onKeyEvent: _handleKeyEvent,
      child: content,
    );
  }
}

/// Internal component for rendering text field content
class _TextFieldContent extends SingleChildRenderObjectComponent {
  const _TextFieldContent({
    required this.text,
    this.placeholder,
    this.style,
    this.placeholderStyle,
    required this.selection,
    required this.viewOffset,
    required this.cursorVisible,
    this.cursorColor,
    this.cursorStyle = CursorStyle.block,
    this.selectionColor,
    required this.textAlign,
    this.maxLines,
    required this.isFocused,
  });

  final String text;
  final String? placeholder;
  final TextStyle? style;
  final TextStyle? placeholderStyle;
  final TextSelection selection;
  final int viewOffset;
  final bool cursorVisible;
  final Color? cursorColor;
  final CursorStyle cursorStyle;
  final Color? selectionColor;
  final TextAlign textAlign;
  final int? maxLines;
  final bool isFocused;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTextField(
      text: text,
      placeholder: placeholder,
      style: style,
      placeholderStyle: placeholderStyle,
      selection: selection,
      viewOffset: viewOffset,
      cursorVisible: cursorVisible,
      cursorColor: cursorColor,
      cursorStyle: cursorStyle,
      selectionColor: selectionColor,
      textAlign: textAlign,
      maxLines: maxLines,
      isFocused: isFocused,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderTextField renderObject) {
    renderObject
      ..text = text
      ..placeholder = placeholder
      ..style = style
      ..placeholderStyle = placeholderStyle
      ..selection = selection
      ..viewOffset = viewOffset
      ..cursorVisible = cursorVisible
      ..cursorColor = cursorColor
      ..cursorStyle = cursorStyle
      ..selectionColor = selectionColor
      ..textAlign = textAlign
      ..maxLines = maxLines
      ..isFocused = isFocused;
  }
}

/// Render object for text field
class RenderTextField extends RenderObject {
  RenderTextField({
    required String text,
    String? placeholder,
    TextStyle? style,
    TextStyle? placeholderStyle,
    required TextSelection selection,
    required int viewOffset,
    required bool cursorVisible,
    Color? cursorColor,
    CursorStyle cursorStyle = CursorStyle.block,
    Color? selectionColor,
    required TextAlign textAlign,
    int? maxLines,
    required bool isFocused,
  })  : _text = text,
        _placeholder = placeholder,
        _style = style,
        _placeholderStyle = placeholderStyle,
        _selection = selection,
        _viewOffset = viewOffset,
        _cursorVisible = cursorVisible,
        _cursorColor = cursorColor,
        _cursorStyle = cursorStyle,
        _selectionColor = selectionColor,
        _textAlign = textAlign,
        _maxLines = maxLines,
        _isFocused = isFocused;

  String _text;
  String? _placeholder;
  TextStyle? _style;
  TextStyle? _placeholderStyle;
  TextSelection _selection;
  int _viewOffset;
  bool _cursorVisible;
  Color? _cursorColor;
  CursorStyle _cursorStyle;
  Color? _selectionColor;
  TextAlign _textAlign;
  int? _maxLines;
  bool _isFocused;

  // Store the layout result for proper Unicode rendering
  TextLayoutResult? _layoutResult;

  set text(String value) {
    if (_text != value) {
      _text = value;
      markNeedsLayout();
    }
  }

  set placeholder(String? value) {
    if (_placeholder != value) {
      _placeholder = value;
      markNeedsPaint();
    }
  }

  set style(TextStyle? value) {
    if (_style != value) {
      _style = value;
      markNeedsPaint();
    }
  }

  set placeholderStyle(TextStyle? value) {
    if (_placeholderStyle != value) {
      _placeholderStyle = value;
      markNeedsPaint();
    }
  }

  set selection(TextSelection value) {
    if (_selection != value) {
      _selection = value;
      markNeedsPaint();
    }
  }

  set viewOffset(int value) {
    if (_viewOffset != value) {
      _viewOffset = value;
      markNeedsPaint();
    }
  }

  set cursorVisible(bool value) {
    if (_cursorVisible != value) {
      _cursorVisible = value;
      markNeedsPaint();
    }
  }

  set cursorColor(Color? value) {
    if (_cursorColor != value) {
      _cursorColor = value;
      markNeedsPaint();
    }
  }

  set cursorStyle(CursorStyle value) {
    if (_cursorStyle != value) {
      _cursorStyle = value;
      markNeedsPaint();
    }
  }

  set selectionColor(Color? value) {
    if (_selectionColor != value) {
      _selectionColor = value;
      markNeedsPaint();
    }
  }

  set textAlign(TextAlign value) {
    if (_textAlign != value) {
      _textAlign = value;
      markNeedsPaint();
    }
  }

  set maxLines(int? value) {
    if (_maxLines != value) {
      _maxLines = value;
      markNeedsLayout();
    }
  }

  set isFocused(bool value) {
    if (_isFocused != value) {
      _isFocused = value;
      markNeedsPaint();
    }
  }

  @override
  void performLayout() {
    // Use TextLayoutEngine for proper Unicode text wrapping
    final textToLayout = _text.isEmpty && _placeholder != null ? _placeholder! : _text;

    final maxWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth.toInt()
        : 80; // Default width for infinite constraints

    final config = TextLayoutConfig(
      softWrap: _maxLines != 1, // Enable wrapping for multi-line fields
      overflow: TextOverflow.clip,
      textAlign: _textAlign,
      maxLines: _maxLines,
      maxWidth: maxWidth,
    );

    _layoutResult = TextLayoutEngine.layout(textToLayout, config);

    // Size based on actual layout result
    final actualHeight = _layoutResult!.actualHeight.toDouble();
    size = constraints.constrain(Size(
      constraints.maxWidth,
      actualHeight,
    ));
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);

    if (_layoutResult == null) return;

    final textStyle = _text.isEmpty && _placeholder != null
        ? (_placeholderStyle ?? TextStyle(color: Colors.gray))
        : (_style ?? const TextStyle());

    final lines = _layoutResult!.lines;
    final alignmentWidth = size.width.toInt();

    // Paint each line from the layout result
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Calculate horizontal offset based on text alignment
      final xOffset = offset.dx + TextLayoutEngine.calculateAlignmentOffset(
        line,
        alignmentWidth,
        _textAlign,
      );

      // Apply justification if needed
      String displayLine = line;
      if (_textAlign == TextAlign.justify && i < lines.length - 1) {
        displayLine = TextLayoutEngine.justifyLine(line, alignmentWidth, isLastLine: false);
      }

      _paintLineWithSelection(canvas, Offset(xOffset, offset.dy + i), displayLine, textStyle, i);
    }

    // Paint cursor only for the focused field
    if (_cursorVisible && _isFocused) {
      _paintCursor(canvas, offset);
    }
  }

  void _paintLineWithSelection(TerminalCanvas canvas, Offset offset, String line, TextStyle style, int lineIndex) {
    // Calculate the character range for this line
    int lineStartOffset = 0;
    if (_layoutResult != null && lineIndex > 0) {
      // Sum up the character count of all previous lines
      for (int i = 0; i < lineIndex && i < _layoutResult!.lines.length; i++) {
        lineStartOffset += _layoutResult!.lines[i].length;
        // Add 1 for the newline character if not a wrapped line
        if (i < _layoutResult!.lines.length - 1 && _text.contains('\n')) {
          // Check if this is a natural line break or wrapped
          final textUpToLine = _text.substring(0, math.min(lineStartOffset, _text.length));
          if (textUpToLine.endsWith('\n')) {
            lineStartOffset++;
          }
        }
      }
    }

    final lineEndOffset = lineStartOffset + line.length;

    // Check if selection intersects with this line
    if (!_selection.isCollapsed && _selectionColor != null) {
      final selStart = _selection.start;
      final selEnd = _selection.end;

      // Check if selection overlaps with this line
      if (selEnd > lineStartOffset && selStart < lineEndOffset) {
        // Calculate selection within this line
        final localSelStart = math.max(0, selStart - lineStartOffset);
        final localSelEnd = math.min(line.length, selEnd - lineStartOffset);

        if (localSelStart < localSelEnd) {
          // Paint non-selected text before selection
          if (localSelStart > 0) {
            final beforeText = line.substring(0, localSelStart);
            canvas.drawText(offset, beforeText, style: style);
          }

          // Paint selected text with selection background
          final selectedText = line.substring(localSelStart, localSelEnd);
          final beforeWidth = localSelStart > 0 ? UnicodeWidth.stringWidth(line.substring(0, localSelStart)) : 0;
          final selectionStyle = style.copyWith(backgroundColor: _selectionColor);
          canvas.drawText(offset + Offset(beforeWidth.toDouble(), 0), selectedText, style: selectionStyle);

          // Paint non-selected text after selection
          if (localSelEnd < line.length) {
            final afterText = line.substring(localSelEnd);
            final beforeSelectedWidth = UnicodeWidth.stringWidth(line.substring(0, localSelEnd));
            canvas.drawText(offset + Offset(beforeSelectedWidth.toDouble(), 0), afterText, style: style);
          }

          return;
        }
      }
    }

    // No selection on this line, paint normally
    canvas.drawText(offset, line, style: style);
  }

  void _paintCursor(TerminalCanvas canvas, Offset offset) {
    if (_layoutResult == null) return;

    final cursorColor = _cursorColor ?? Colors.white;
    final lines = _layoutResult!.lines;

    if (_text.isEmpty && _placeholder == null) {
      // Empty field - show cursor at beginning
      _drawCursorAtPosition(canvas, offset, ' ', 0, cursorColor);
      return;
    }

    // Find which line the cursor is on
    int charCount = 0;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineLength = line.length;

      // Check if cursor is on this line
      if (charCount + lineLength >= _selection.extentOffset || i == lines.length - 1) {
        final positionInLine = (_selection.extentOffset - charCount).clamp(0, lineLength);

        // Calculate visual position using Unicode width
        final textBeforeCursor = line.substring(0, positionInLine);
        final visualColumn = UnicodeWidth.stringWidth(textBeforeCursor);

        final cursorOffset = offset + Offset(visualColumn.toDouble(), i.toDouble());

        // Get the character at cursor position (or space if at end)
        final charAtCursor = positionInLine < line.length ? line[positionInLine] : ' ';

        _drawCursorAtPosition(canvas, cursorOffset, charAtCursor, positionInLine, cursorColor);
        break;
      }

      charCount += lineLength;
      // Add 1 for the newline if not the last line
      if (i < lines.length - 1) charCount++;
    }
  }

  void _drawCursorAtPosition(
    TerminalCanvas canvas,
    Offset position,
    String charUnderCursor,
    int cursorPos,
    Color cursorColor,
  ) {
    switch (_cursorStyle) {
      case CursorStyle.block:
        // Filled block - traditional terminal cursor
        final blockStyle = TextStyle(
          color: Colors.black,
          backgroundColor: cursorColor,
        );
        canvas.drawText(position, charUnderCursor, style: blockStyle);
        break;

      case CursorStyle.underline:
        // Draw the character with underline decoration
        final underlineStyle = TextStyle(
          color: _style?.color ?? Colors.white,
          backgroundColor: _style?.backgroundColor,
          decoration: TextDecoration.underline,
        );
        canvas.drawText(position, charUnderCursor, style: underlineStyle);
        break;

      case CursorStyle.blockOutline:
        // Draw block outline - invert the colors
        final outlineStyle = TextStyle(
          color: Colors.black,
          backgroundColor: cursorColor,
        );
        canvas.drawText(position, charUnderCursor, style: outlineStyle);
        break;
    }
  }
}

/// Input decoration for text fields
class InputDecoration {
  const InputDecoration({
    this.hintText,
    this.labelText,
    this.helperText,
    this.errorText,
    this.prefixText,
    this.suffixText,
    this.counter,
    this.filled,
    this.fillColor,
    this.border,
    this.focusedBorder,
    this.errorBorder,
    this.contentPadding,
  });

  final String? hintText;
  final String? labelText;
  final String? helperText;
  final String? errorText;
  final String? prefixText;
  final String? suffixText;
  final Component? counter;
  final bool? filled;
  final Color? fillColor;
  final BoxBorder? border;
  final BoxBorder? focusedBorder;
  final BoxBorder? errorBorder;
  final EdgeInsets? contentPadding;
}

// TextAlign is now imported from text_layout_engine.dart

/// Cursor style options for the text field
enum CursorStyle {
  /// A filled block cursor (default terminal style)
  block,

  /// An underline cursor
  underline,

  /// An outlined block cursor
  blockOutline,
}

/// Type definitions
typedef ValueChanged<T> = void Function(T value);
