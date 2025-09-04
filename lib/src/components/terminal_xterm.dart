import 'dart:io';
import 'dart:math' as math;

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/third_party/xterm_pure.dart/xterm.dart' as xterm;
import '../process/pty_controller.dart' as pty;

/// A terminal component using the xterm.dart library for proper terminal emulation.
///
/// This component requires a [PtyController] following the same pattern as Flutter's
/// TextField with TextEditingController.
class TerminalXterm extends StatefulComponent {
  /// The controller that manages the PTY process.
  final pty.PtyController controller;

  /// Whether the terminal is focused.
  final bool focused;

  /// Custom key event handler.
  /// Return true to consume the event and prevent default handling.
  final bool Function(KeyboardEvent)? onKeyEvent;

  /// Maximum number of lines in the terminal buffer.
  final int maxLines;

  /// Whether to auto-start the terminal if not already running.
  final bool autoStart;

  const TerminalXterm({
    super.key,
    required this.controller,
    this.focused = false,
    this.onKeyEvent,
    this.maxLines = 10000,
    this.autoStart = true,
  });

  @override
  State<TerminalXterm> createState() => _TerminalXtermState();
}

class _TerminalXtermState extends State<TerminalXterm> {
  late final xterm.Terminal _terminal;
  VoidCallback? _controllerListener;

  // Terminal dimensions
  int _rows = 24;
  int _cols = 80;

  // Scrolling support
  int _scrollOffset = 0;

  @override
  void initState() {
    super.initState();

    // Create the xterm terminal
    _terminal = xterm.Terminal(
      maxLines: component.maxLines,
      platform: _getPlatform(),
    );

    // Initialize terminal size
    _terminal.resize(_cols, _rows);

    // Set up terminal callbacks
    _terminal.onOutput = (data) {
      if (component.controller.isRunning) {
        component.controller.write(data);
      }
    };

    _terminal.onResize = (width, height, _, __) {
      if (component.controller.isRunning) {
        component.controller.resize(width, height);
      }
    };

    _terminal.onTitleChange = (title) {
      // Could update the window title if needed
    };

    _terminal.onBell = () {
      // Terminal bell - could play a sound or flash
    };

    // Set up controller output handler
    _setupControllerHandler();

    // Listen to controller changes
    _controllerListener = _onControllerChanged;
    component.controller.addListener(_controllerListener!);

    // Auto-start if requested
    if (component.autoStart && !component.controller.isRunning) {
      _startTerminal();
    }
  }

  void _setupControllerHandler() {
    // Set up output handler
    component.controller.addOutputCallback((data) {
      _terminal.write(data);
      setState(() {
        // Trigger rebuild when terminal updates
      });
    });
  }

  void _onControllerChanged() {
    // Handle controller state changes
    setState(() {});
  }

  xterm.TerminalTargetPlatform _getPlatform() {
    if (Platform.isMacOS) return xterm.TerminalTargetPlatform.macos;
    if (Platform.isLinux) return xterm.TerminalTargetPlatform.linux;
    if (Platform.isWindows) return xterm.TerminalTargetPlatform.windows;
    return xterm.TerminalTargetPlatform.unknown;
  }

  void _startTerminal() async {
    try {
      await component.controller.start(columns: _cols, rows: _rows);
    } catch (e) {
      // Handle error
      _terminal.write('\r\nError starting terminal: $e\r\n');
    }
  }

  void _handleKeyEvent(KeyboardEvent event) {
    if (!component.controller.isRunning) return;

    // Call parent's key handler first, if provided
    if (component.onKeyEvent != null) {
      final handled = component.onKeyEvent!(event);
      if (handled) return; // Parent consumed the event
    }

    // Handle special keys using xterm's key input
    if (event.logicalKey == LogicalKey.enter) {
      _terminal.keyInput(xterm.TerminalKey.enter);
    } else if (event.logicalKey == LogicalKey.backspace) {
      _terminal.keyInput(xterm.TerminalKey.backspace);
    } else if (event.logicalKey == LogicalKey.tab) {
      _terminal.keyInput(xterm.TerminalKey.tab);
    } else if (event.logicalKey == LogicalKey.escape) {
      _terminal.keyInput(xterm.TerminalKey.escape);
    } else if (event.logicalKey == LogicalKey.arrowUp) {
      _terminal.keyInput(xterm.TerminalKey.arrowUp);
    } else if (event.logicalKey == LogicalKey.arrowDown) {
      _terminal.keyInput(xterm.TerminalKey.arrowDown);
    } else if (event.logicalKey == LogicalKey.arrowRight) {
      _terminal.keyInput(xterm.TerminalKey.arrowRight);
    } else if (event.logicalKey == LogicalKey.arrowLeft) {
      _terminal.keyInput(xterm.TerminalKey.arrowLeft);
    } else if (event.logicalKey == LogicalKey.home) {
      _terminal.keyInput(xterm.TerminalKey.home);
    } else if (event.logicalKey == LogicalKey.end) {
      _terminal.keyInput(xterm.TerminalKey.end);
    } else if (event.logicalKey == LogicalKey.pageUp) {
      _scrollUp(5);
    } else if (event.logicalKey == LogicalKey.pageDown) {
      _scrollDown(5);
    } else if (event.logicalKey == LogicalKey.delete) {
      _terminal.keyInput(xterm.TerminalKey.delete);
    } else if (event.logicalKey == LogicalKey.insert) {
      _terminal.keyInput(xterm.TerminalKey.insert);
    } else if (event.character != null && event.character!.isNotEmpty) {
      // Handle control characters
      final charCode = event.character!.codeUnitAt(0);
      if (charCode >= 1 && charCode <= 26) {
        // Control character (Ctrl+A through Ctrl+Z)
        _terminal.charInput(charCode);
      } else {
        // Regular text input
        _terminal.textInput(event.character!);
      }
    }
  }

  void _scrollUp(int lines) {
    final maxScroll = _terminal.buffer.lines.length - _terminal.viewHeight;
    setState(() {
      _scrollOffset = (_scrollOffset - lines).clamp(-maxScroll, 0);
    });
  }

  void _scrollDown(int lines) {
    final maxScroll = _terminal.buffer.lines.length - _terminal.viewHeight;
    setState(() {
      _scrollOffset = (_scrollOffset + lines).clamp(-maxScroll, 0);
    });
  }

  void _updateSize(int cols, int rows) {
    if (cols != _cols || rows != _rows) {
      _cols = cols;
      _rows = rows;
      _terminal.resize(cols, rows);
      component.controller.resize(cols, rows);
    }
  }

  @override
  void dispose() {
    if (_controllerListener != null) {
      component.controller.removeListener(_controllerListener!);
    }
    super.dispose();
  }

  @override
  void didUpdateComponent(TerminalXterm oldComponent) {
    super.didUpdateComponent(oldComponent);

    // Handle controller change
    if (oldComponent.controller != component.controller) {
      if (_controllerListener != null) {
        oldComponent.controller.removeListener(_controllerListener!);
      }
      _controllerListener = _onControllerChanged;
      component.controller.addListener(_controllerListener!);
      _setupControllerHandler();
    }
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: component.focused,
      onKeyEvent: (event) {
        _handleKeyEvent(event);
        return true; // Consume all key events
      },
      child: _TerminalRenderer(
        terminal: _terminal,
        scrollOffset: _scrollOffset,
        onSizeChange: _updateSize,
      ),
    );
  }
}

/// Terminal renderer that converts xterm buffer to TUI components
class _TerminalRenderer extends StatelessComponent {
  final xterm.Terminal terminal;
  final int scrollOffset;
  final void Function(int cols, int rows)? onSizeChange;

  const _TerminalRenderer({
    required this.terminal,
    required this.scrollOffset,
    this.onSizeChange,
  });

  @override
  Component build(BuildContext context) {
    // For now, we'll render with a fixed size
    // In a real implementation, we'd get size from constraints
    const cols = 80;
    const rows = 24;

    // Notify size change
    onSizeChange?.call(cols, rows);

    final lines = <Component>[];

    // Calculate visible range considering scrollback
    final buffer = terminal.buffer;
    final totalLines = buffer.lines.length;
    final viewHeight = rows;

    // Determine which lines to display
    final startLine = math.max(0, totalLines - viewHeight + scrollOffset);

    // Render terminal buffer lines
    for (int y = 0; y < viewHeight; y++) {
      final lineIndex = startLine + y;

      if (lineIndex >= 0 && lineIndex < totalLines) {
        final line = buffer.lines[lineIndex];
        final hasCursor = lineIndex == buffer.cursorY && scrollOffset == 0;
        lines.add(_renderLine(line, hasCursor, buffer.cursorX));
      } else {
        // Empty line
        lines.add(Text(' ' * cols));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }

  Component _renderLine(xterm.BufferLine line, bool hasCursor, int cursorX) {
    final spans = <_StyledSpan>[];
    final lineLength = line.length;
    final cellData = xterm.CellData.empty();

    for (int x = 0; x < 80; x++) {
      if (x < lineLength) {
        line.getCellData(x, cellData);
        final codePoint = cellData.content & xterm.CellContent.codepointMask;
        if (codePoint != 0) {
          final char = String.fromCharCode(codePoint);
          final style = _convertCellStyle(cellData, hasCursor && x == cursorX);

          // Merge consecutive spans with same style
          if (spans.isNotEmpty && spans.last.style == style) {
            spans.last.text += char;
          } else {
            spans.add(_StyledSpan(char, style));
          }
        } else {
          // Empty cell
          if (spans.isNotEmpty && spans.last.style == const TextStyle()) {
            spans.last.text += ' ';
          } else {
            spans.add(_StyledSpan(' ', const TextStyle()));
          }
        }
      } else {
        // Padding
        if (spans.isNotEmpty && spans.last.style == const TextStyle()) {
          spans.last.text += ' ';
        } else {
          spans.add(_StyledSpan(' ', const TextStyle()));
        }
      }
    }

    // Combine all spans into a single text
    if (spans.isEmpty) {
      return Text(' ' * 80);
    } else if (spans.length == 1) {
      return Text(spans[0].text, style: spans[0].style);
    } else {
      // For multiple styles, we need to combine them
      // For now, just use the first style for the whole line
      final buffer = StringBuffer();
      TextStyle? primaryStyle;

      for (final span in spans) {
        buffer.write(span.text);
        primaryStyle ??= span.style;
      }

      return Text(buffer.toString(), style: primaryStyle ?? const TextStyle());
    }
  }

  TextStyle _convertCellStyle(xterm.CellData cell, bool isCursor) {
    Color? fg;
    Color? bg;
    bool bold = false;
    bool dim = false;
    bool italic = false;
    bool underline = false;
    bool reverse = false;

    // Extract attributes from flags
    final flags = cell.flags;
    if (flags & xterm.CellAttr.bold != 0) bold = true;
    if (flags & xterm.CellAttr.faint != 0) dim = true;
    if (flags & xterm.CellAttr.italic != 0) italic = true;
    if (flags & xterm.CellAttr.underline != 0) underline = true;
    if (flags & xterm.CellAttr.inverse != 0) reverse = true;

    // Convert colors
    fg = _convertColor(cell.foreground);
    bg = _convertColor(cell.background);

    // Apply cursor
    if (isCursor) {
      reverse = !reverse;
    }

    return TextStyle(
      color: fg,
      backgroundColor: bg,
      fontWeight: bold ? FontWeight.bold : (dim ? FontWeight.dim : null),
      fontStyle: italic ? FontStyle.italic : null,
      decoration: underline ? TextDecoration.underline : null,
      // Note: reverse is not supported in TextStyle
    );
  }

  Color? _convertColor(int color) {
    if (color == 0) return null;

    final colorType = color & xterm.CellColor.typeMask;
    final colorValue = color & xterm.CellColor.valueMask;

    if (colorType == xterm.CellColor.rgb) {
      // RGB color
      final r = (colorValue >> 16) & 0xFF;
      final g = (colorValue >> 8) & 0xFF;
      final b = colorValue & 0xFF;
      return Color.fromRGB(r, g, b);
    } else if (colorType == xterm.CellColor.palette || colorType == xterm.CellColor.named) {
      // Palette color (0-255)
      return _getPaletteColor(colorValue);
    }

    return null;
  }

  Color _getPaletteColor(int index) {
    // ANSI 16 colors
    switch (index) {
      case 0:
        return Colors.black;
      case 1:
        return Colors.red;
      case 2:
        return Colors.green;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.blue;
      case 5:
        return Colors.magenta;
      case 6:
        return Colors.cyan;
      case 7:
        return Colors.white;
      case 8:
        return Colors.brightBlack;
      case 9:
        return Colors.brightRed;
      case 10:
        return Colors.brightGreen;
      case 11:
        return Colors.brightYellow;
      case 12:
        return Colors.brightBlue;
      case 13:
        return Colors.brightMagenta;
      case 14:
        return Colors.brightCyan;
      case 15:
        return Colors.brightWhite;
      default:
        // 256 color palette
        if (index < 232) {
          // 216 color cube
          final i = index - 16;
          final r = (i ~/ 36) * 51;
          final g = ((i ~/ 6) % 6) * 51;
          final b = (i % 6) * 51;
          return Color.fromRGB(r, g, b);
        } else {
          // Grayscale
          final gray = 8 + (index - 232) * 10;
          return Color.fromRGB(gray, gray, gray);
        }
    }
  }
}

/// Helper class for styled text spans
class _StyledSpan {
  String text;
  final TextStyle style;

  _StyledSpan(this.text, this.style);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _StyledSpan && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
