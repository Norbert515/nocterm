import 'dart:async';
import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:nocterm/nocterm.dart' hide TextAlign;
import 'package:nocterm/src/framework/terminal_canvas.dart';
import '../text/text_layout_engine.dart';
import '../utils/unicode_width.dart';
import 'text_field/cursor_movement.dart';

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
    this.cursorBlinkRate,
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

  // Reference to the render object for cursor movement
  RenderTextField? _renderTextField;

  void _handleSelectionChangeFromRenderObject(TextSelection newSelection) {
    setState(() {
      _controller.selection = newSelection;
    });
  }

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
    if (component.focused != oldComponent.focused || component.cursorBlinkRate != oldComponent.cursorBlinkRate) {
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
      final text = _controller.text;
      final cursorPos = _controller.selection.extentOffset;

      // Account for borders and padding to get actual content width
      final decoration = component.decoration ?? const InputDecoration();
      final padding = decoration.contentPadding ?? const EdgeInsets.symmetric(horizontal: 1);
      final horizontalPadding = padding.left + padding.right;
      final borderWidth = decoration.border != null ? 2.0 : 0.0; // 1 on each side
      // Reserve 1 column for cursor display
      final maxVisibleWidth = (component.width! - borderWidth - horizontalPadding - 1).toInt();

      if (maxVisibleWidth <= 0) return; // No space to display text

      // Calculate visual column position of cursor (accounting for wide characters)
      final textBeforeCursor = text.substring(0, math.min(cursorPos, text.length));
      final cursorVisualColumn = UnicodeWidth.stringWidth(textBeforeCursor);

      // Calculate visual width of currently visible text
      int viewOffsetVisualColumn = 0;
      if (_viewOffset > 0 && _viewOffset <= text.length) {
        viewOffsetVisualColumn = UnicodeWidth.stringWidth(text.substring(0, _viewOffset));
      }

      // Adjust view offset to keep cursor visible
      if (cursorVisualColumn < viewOffsetVisualColumn) {
        // Cursor moved before visible area - scroll left
        // Find the character offset that corresponds to the cursor's visual position
        _viewOffset = cursorPos;
      } else if (cursorVisualColumn >= viewOffsetVisualColumn + maxVisibleWidth) {
        // Cursor moved after visible area - scroll right
        // We need to find a view offset such that the cursor is visible
        int newOffset = 0;
        int visualWidth = 0;

        // Find the rightmost offset that still shows the cursor
        final graphemes = text.characters.toList();
        for (int i = 0; i <= math.min(cursorPos, graphemes.length); i++) {
          if (i < graphemes.length) {
            final graphemeWidth = UnicodeWidth.graphemeWidth(graphemes[i]);
            if (cursorVisualColumn - visualWidth <= maxVisibleWidth - 1) {
              newOffset = i;
            }
            visualWidth += graphemeWidth;
          }
        }
        _viewOffset = newOffset;
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
    // Note: Shift+Enter detection doesn't work in most terminals due to input limitations
    // Most terminals send the same code for Enter and Shift+Enter
    if (key == LogicalKey.enter && event.isShiftPressed) {
      // This branch rarely works in real terminals but is kept for compatibility
      // with test environments and potential future terminal improvements
      if (component.maxLines != 1) {
        _insertText('\n');
      }
      return true;
    } else if (key == LogicalKey.enter && !event.isShiftPressed) {
      // Enter submits in all fields (both single-line and multi-line)
      component.onEditingComplete?.call();
      component.onSubmitted?.call(_controller.text);
      return true;
    } else if (key == LogicalKey.backspace) {
      _handleBackspace();
      return true;
    } else if (key == LogicalKey.delete) {
      _handleDelete();
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
    } else if (key == LogicalKey.arrowUp && event.isShiftPressed && component.maxLines != 1) {
      _moveCursorVertically(-1, true);
      return true;
    } else if (key == LogicalKey.arrowDown && event.isShiftPressed && component.maxLines != 1) {
      _moveCursorVertically(1, true);
      return true;
    } else if (key == LogicalKey.arrowLeft) {
      _moveCursor(-1, false);
      return true;
    } else if (key == LogicalKey.arrowRight) {
      _moveCursor(1, false);
      return true;
    } else if (key == LogicalKey.arrowUp && component.maxLines != 1) {
      _moveCursorVertically(-1, false);
      return true;
    } else if (key == LogicalKey.arrowDown && component.maxLines != 1) {
      _moveCursorVertically(1, false);
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
    } else if (key == LogicalKey.backspace && event.isControlPressed) {
      _deleteWordBackward();
      return true;
    } else if (key == LogicalKey.delete && event.isControlPressed) {
      _deleteWordForward();
      return true;
    } else if (event.matches(LogicalKey.keyT, ctrl: true)) {
      _transposeCharacters();
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
    final text = _controller.text;
    final selection = _controller.selection;

    // Check if we're at max length
    if (component.maxLength != null) {
      final currentLength = text.characters.length;
      final insertLength = char.characters.length;
      final deleteLength = selection.isCollapsed ? 0 : (selection.end - selection.start);

      if (currentLength - deleteLength + insertLength > component.maxLength!) {
        return;
      }
    }

    // Check max lines for multi-line fields
    if (component.maxLines != null && component.maxLines! > 1 && char.contains('\n')) {
      final currentLines = text.split('\n').length;
      final newLines = char.split('\n').length - 1;

      if (currentLines + newLines > component.maxLines!) {
        return;
      }
    }

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

    // Reset target column after text modification
    _renderTextField?.resetTargetColumn();
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
    _renderTextField?.moveCursorHorizontally(delta, extendSelection);
  }

  void _moveCursorByWord(int direction, bool extendSelection) {
    _renderTextField?.moveCursorByWord(direction, extendSelection);
  }

  bool _isSpace(String char) {
    return char == ' ' || char == '\t' || char == '\n' || char == '\r';
  }

  void _deleteWordBackward() {
    final text = _controller.text;
    final selection = _controller.selection;

    if (!selection.isCollapsed) {
      // Delete selected text
      _controller.text = text.substring(0, selection.start) + text.substring(selection.end);
      _controller.selection = TextSelection.collapsed(offset: selection.start);
      return;
    }

    if (selection.extentOffset == 0) return;

    int start = selection.extentOffset;

    // Skip spaces backward
    while (start > 0 && _isSpace(text[start - 1])) {
      start--;
    }

    // Skip word characters backward
    while (start > 0 && !_isSpace(text[start - 1])) {
      start--;
    }

    _controller.text = text.substring(0, start) + text.substring(selection.extentOffset);
    _controller.selection = TextSelection.collapsed(offset: start);
  }

  void _deleteWordForward() {
    final text = _controller.text;
    final selection = _controller.selection;

    if (!selection.isCollapsed) {
      // Delete selected text
      _controller.text = text.substring(0, selection.start) + text.substring(selection.end);
      _controller.selection = TextSelection.collapsed(offset: selection.start);
      return;
    }

    if (selection.extentOffset >= text.length) return;

    int end = selection.extentOffset;

    // Skip current word forward
    while (end < text.length && !_isSpace(text[end])) {
      end++;
    }

    // Skip spaces forward
    while (end < text.length && _isSpace(text[end])) {
      end++;
    }

    _controller.text = text.substring(0, selection.extentOffset) + text.substring(end);
    // Cursor position stays the same
  }

  void _transposeCharacters() {
    final text = _controller.text;
    final selection = _controller.selection;

    if (selection.extentOffset == 0 || text.length < 2) return;

    final chars = text.characters.toList();
    int pos = selection.extentOffset;

    // Find character positions
    int charCount = 0;
    int charIndex = 0;
    for (int i = 0; i < chars.length; i++) {
      if (charCount >= pos) {
        charIndex = i;
        break;
      }
      charCount += chars[i].length;
    }

    if (charIndex >= chars.length) {
      charIndex = chars.length - 1;
    }

    // Transpose characters
    if (charIndex > 0) {
      final temp = chars[charIndex - 1];
      chars[charIndex - 1] = chars[charIndex == chars.length ? charIndex - 1 : charIndex];
      chars[charIndex == chars.length ? charIndex - 1 : charIndex] = temp;

      _controller.text = chars.join();

      // Move cursor forward if not at end
      if (pos < text.length) {
        _moveCursor(1, false);
      }
    }
  }

  void _moveCursorVertically(int direction, bool extendSelection) {
    _renderTextField?.moveCursorVertically(direction, extendSelection);
  }

  void _moveCursorToStart() {
    _controller.selection = const TextSelection.collapsed(offset: 0);
    _renderTextField?.resetTargetColumn();
  }

  void _moveCursorToEnd() {
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    _renderTextField?.resetTargetColumn();
  }

  void _selectAll() {
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _copy() {
    // Copy selected text to clipboard using OSC 52
    if (!_controller.selection.isCollapsed) {
      final text = _controller.text;
      final selection = _controller.selection;
      final selectedText = text.substring(selection.start, selection.end);
      ClipboardManager.copy(selectedText);
    }
  }

  void _cut() {
    // Copy selected text to clipboard and then delete it
    if (!_controller.selection.isCollapsed) {
      final text = _controller.text;
      final selection = _controller.selection;
      final selectedText = text.substring(selection.start, selection.end);

      // Copy to clipboard using OSC 52
      ClipboardManager.copy(selectedText);

      // Delete the selected text
      _controller.text = text.substring(0, selection.start) + text.substring(selection.end);
      _controller.selection = TextSelection.collapsed(offset: selection.start);
    }
  }

  void _paste() {
    // Paste text from clipboard
    final clipboardText = ClipboardManager.paste();
    if (clipboardText != null && clipboardText.isNotEmpty) {
      _insertText(clipboardText);
    }
  }

  @override
  Component build(BuildContext context) {
    final decoration = component.decoration ?? const InputDecoration();
    final isFocused = component.focused;

    // Prepare display text (for obscuring only)
    final actualText = _controller.text;
    String displayText = actualText;
    if (component.obscureText) {
      displayText = component.obscuringCharacter * displayText.length;
    }

    // Handle view offset for single-line fields
    if (component.maxLines == 1 && component.width != null) {
      final padding = decoration.contentPadding ?? const EdgeInsets.symmetric(horizontal: 1);
      final horizontalPadding = padding.left + padding.right;
      final borderWidth = decoration.border != null ? 2.0 : 0.0;
      // Reserve 1 column for cursor display
      final maxVisibleWidth = (component.width! - borderWidth - horizontalPadding - 1).toInt();

      if (maxVisibleWidth > 0 && _viewOffset < displayText.length) {
        // Extract the visible portion based on visual width, not character count
        // We need to iterate through grapheme clusters, not individual chars
        final graphemes = displayText.characters.toList();

        if (_viewOffset < graphemes.length) {
          int startIdx = _viewOffset;
          int endIdx = _viewOffset;
          int visualWidth = 0;

          // Find how many graphemes fit in the visible width
          while (endIdx < graphemes.length && visualWidth < maxVisibleWidth) {
            final graphemeWidth = UnicodeWidth.graphemeWidth(graphemes[endIdx]);
            if (visualWidth + graphemeWidth <= maxVisibleWidth) {
              visualWidth += graphemeWidth;
              endIdx++;
            } else {
              break;
            }
          }

          // Reconstruct the visible text from graphemes
          displayText = graphemes.sublist(startIdx, endIdx).join();
        } else {
          displayText = '';
        }
      }
    }

    // Build the text field content
    Component content = _TextFieldContent(
      text: actualText,
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
      obscureText: component.obscureText,
      obscuringCharacter: component.obscuringCharacter,
      onSelectionChange: _handleSelectionChangeFromRenderObject,
      onRenderObjectCreate: (renderObject) {
        _renderTextField = renderObject;
      },
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
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.onSelectionChange,
    this.onRenderObjectCreate,
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
  final bool obscureText;
  final String obscuringCharacter;
  final void Function(TextSelection)? onSelectionChange;
  final void Function(RenderTextField)? onRenderObjectCreate;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final renderObject = RenderTextField(
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
      obscureText: obscureText,
      obscuringCharacter: obscuringCharacter,
      onSelectionChange: onSelectionChange,
    );
    onRenderObjectCreate?.call(renderObject);
    return renderObject;
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
      ..isFocused = isFocused
      ..obscureText = obscureText
      ..obscuringCharacter = obscuringCharacter;
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
    bool obscureText = false,
    String obscuringCharacter = '•',
    this.onSelectionChange,
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
        _isFocused = isFocused,
        _obscureText = obscureText,
        _obscuringCharacter = obscuringCharacter;

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
  bool _obscureText;
  String _obscuringCharacter;

  // Callback for selection changes
  final void Function(TextSelection)? onSelectionChange;

  // Store the layout result for proper Unicode rendering
  TextLayoutResult? _layoutResult;

  // Track target visual column for vertical movement
  int? _targetVisualColumn;

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

  set obscureText(bool value) {
    if (_obscureText != value) {
      _obscureText = value;
      markNeedsLayout();
    }
  }

  set obscuringCharacter(String value) {
    if (_obscuringCharacter != value) {
      _obscuringCharacter = value;
      if (_obscureText) {
        markNeedsLayout();
      }
    }
  }

  /// Move cursor horizontally
  void moveCursorHorizontally(int direction, bool extendSelection) {
    if (_layoutResult == null) return;

    final newOffset = CursorMovement.moveCursorHorizontally(
      text: _text,
      currentOffset: _selection.extentOffset,
      direction: direction,
    );

    final newSelection =
        extendSelection ? _selection.copyWith(extentOffset: newOffset) : TextSelection.collapsed(offset: newOffset);

    if (newSelection != _selection) {
      _selection = newSelection;
      _targetVisualColumn = null; // Reset target column
      onSelectionChange?.call(newSelection);
      markNeedsPaint();
    }
  }

  /// Move cursor vertically
  void moveCursorVertically(int direction, bool extendSelection) {
    if (_layoutResult == null) return;

    // Get current position if we don't have a target column
    if (_targetVisualColumn == null) {
      final currentPos = CursorMovement.getCursorPosition(
        layoutResult: _layoutResult!,
        text: _text,
        cursorOffset: _selection.extentOffset,
      );
      _targetVisualColumn = currentPos.visualColumn;
    }

    final newOffset = CursorMovement.moveCursorVertically(
      layoutResult: _layoutResult!,
      text: _text,
      currentOffset: _selection.extentOffset,
      direction: direction,
      targetVisualColumn: _targetVisualColumn!,
    );

    final newSelection =
        extendSelection ? _selection.copyWith(extentOffset: newOffset) : TextSelection.collapsed(offset: newOffset);

    if (newSelection != _selection) {
      _selection = newSelection;
      onSelectionChange?.call(newSelection);
      markNeedsPaint();
    }
  }

  /// Move cursor by word
  void moveCursorByWord(int direction, bool extendSelection) {
    final newOffset = CursorMovement.moveCursorByWord(
      text: _text,
      currentOffset: _selection.extentOffset,
      direction: direction,
    );

    final newSelection =
        extendSelection ? _selection.copyWith(extentOffset: newOffset) : TextSelection.collapsed(offset: newOffset);

    if (newSelection != _selection) {
      _selection = newSelection;
      _targetVisualColumn = null; // Reset target column
      onSelectionChange?.call(newSelection);
      markNeedsPaint();
    }
  }

  /// Move cursor to start of current line
  void moveCursorToLineStart(bool extendSelection) {
    if (_layoutResult == null) return;

    final newOffset = CursorMovement.moveCursorToLineStart(
      layoutResult: _layoutResult!,
      text: _text,
      currentOffset: _selection.extentOffset,
    );

    final newSelection =
        extendSelection ? _selection.copyWith(extentOffset: newOffset) : TextSelection.collapsed(offset: newOffset);

    if (newSelection != _selection) {
      _selection = newSelection;
      _targetVisualColumn = null; // Reset target column
      onSelectionChange?.call(newSelection);
      markNeedsPaint();
    }
  }

  /// Move cursor to end of current line
  void moveCursorToLineEnd(bool extendSelection) {
    if (_layoutResult == null) return;

    final newOffset = CursorMovement.moveCursorToLineEnd(
      layoutResult: _layoutResult!,
      text: _text,
      currentOffset: _selection.extentOffset,
    );

    final newSelection =
        extendSelection ? _selection.copyWith(extentOffset: newOffset) : TextSelection.collapsed(offset: newOffset);

    if (newSelection != _selection) {
      _selection = newSelection;
      _targetVisualColumn = null; // Reset target column
      onSelectionChange?.call(newSelection);
      markNeedsPaint();
    }
  }

  /// Reset target visual column (used when text changes)
  void resetTargetColumn() {
    _targetVisualColumn = null;
  }

  @override
  void performLayout() {
    // Use TextLayoutEngine for proper Unicode text wrapping
    String textToLayout = _text.isEmpty && _placeholder != null ? _placeholder! : _text;

    // Apply text obscuring if needed
    if (_obscureText && !_text.isEmpty) {
      textToLayout = _obscuringCharacter * _text.length;
    }

    // Reserve 1 column for the cursor block to be displayed within bounds
    // This ensures the cursor doesn't appear to go "into the wall" at line ends
    final availableWidth = constraints.maxWidth.isFinite ? constraints.maxWidth.toInt() : 80;
    final maxWidth = (availableWidth - 1).clamp(1, double.infinity).toInt(); // Reserve space for cursor

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
      final xOffset = offset.dx +
          TextLayoutEngine.calculateAlignmentOffset(
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
        // Only add 1 for actual newline characters in the text, not wrapped lines
        if (i < _layoutResult!.lines.length - 1) {
          final textUpToLine = _text.substring(0, math.min(lineStartOffset, _text.length));
          if (textUpToLine.endsWith('\n')) {
            lineStartOffset++;
          }
        }
      }
    }

    final lineEndOffset = lineStartOffset + line.length;

    // Check if selection intersects with this line
    if (!_selection.isCollapsed) {
      final selStart = _selection.start;
      final selEnd = _selection.end;
      final selectionColor = _selectionColor ?? Colors.blue;

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
          final selectionStyle = style.copyWith(backgroundColor: selectionColor);
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
      // Only add 1 for actual newline characters, not wrapped lines
      // Check if the accumulated text so far ends with a newline
      if (i < lines.length - 1) {
        final textSoFar = _text.substring(0, math.min(charCount, _text.length));
        if (textSoFar.endsWith('\n')) {
          charCount++; // Account for the newline character
        }
      }
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
