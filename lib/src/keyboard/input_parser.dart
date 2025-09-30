import 'dart:convert';
import 'logical_key.dart';
import 'keyboard_event.dart';
import 'mouse_parser.dart';
import 'input_event.dart';

/// Parses raw terminal input bytes into input events (keyboard and mouse).
class InputParser {
  final List<int> _buffer = [];

  /// Add bytes to the buffer for parsing
  void addBytes(List<int> bytes) {
    _buffer.addAll(bytes);
  }

  /// Parse the next event from the buffer
  /// Returns null if no complete event is available
  InputEvent? parseNext() {
    if (_buffer.isEmpty) return null;

    // Try to parse the current buffer
    final result = _parseBufferWithLength();

    if (result != null) {
      final (event, bytesConsumed) = result;
      _clearConsumedBytes(event, bytesConsumed);
      return event;
    }

    return null;
  }

  /// Parse incoming bytes and return first event
  InputEvent? parseBytes(List<int> bytes) {
    addBytes(bytes);
    return parseNext();
  }

  void _clearConsumedBytes(InputEvent event, int bytesConsumed) {
    // Remove the consumed bytes from the buffer
    if (bytesConsumed > 0 && bytesConsumed <= _buffer.length) {
      _buffer.removeRange(0, bytesConsumed);
    } else {
      // Fallback: clear everything
      _buffer.clear();
    }
  }

  (InputEvent, int)? _parseBufferWithLength() {
    if (_buffer.isEmpty) return null;

    final first = _buffer[0];

    // Check for mouse sequences first
    if (first == 0x1B && _buffer.length >= 2) {
      // Check for mouse escape sequences
      if (_buffer[1] == 0x5B && _buffer.length >= 3) {
        // SGR mouse mode: ESC [ <
        if (_buffer[2] == 0x3C) {
          // Find the terminator to know how many bytes this event uses
          int terminatorIndex = -1;
          for (int i = 3; i < _buffer.length; i++) {
            if (_buffer[i] == 0x4D || _buffer[i] == 0x6D) {
              terminatorIndex = i;
              break;
            }
          }

          if (terminatorIndex != -1) {
            // Parse only the bytes for this event
            final eventBytes = _buffer.sublist(0, terminatorIndex + 1);
            final mouseEvent = MouseParser.parseSGR(eventBytes);
            if (mouseEvent != null) {
              return (MouseInputEvent(mouseEvent), terminatorIndex + 1);
            } else {
              // Skip this unparseable mouse event - don't convert to keyboard event
              // Just consume the bytes to prevent buffer buildup
              _buffer.removeRange(0, terminatorIndex + 1);
              // Try to parse the next event in the buffer
              return _parseBufferWithLength();
            }
          } else {
            return null; // Need more bytes
          }
        }
        // X10 mouse mode: ESC [ M
        else if (_buffer[2] == 0x4D && _buffer.length >= 6) {
          final eventBytes = _buffer.sublist(0, 6);
          final mouseEvent = MouseParser.parseX10(eventBytes);
          if (mouseEvent != null) {
            return (MouseInputEvent(mouseEvent), 6);
          }
        }
      }
    }

    // Try to parse as keyboard event
    final result = _parseKeyboardEvent();
    if (result != null) {
      final (keyEvent, bytesConsumed) = result;
      return (KeyboardInputEvent(keyEvent), bytesConsumed);
    }

    return null;
  }

  (KeyboardEvent, int)? _parseKeyboardEvent() {
    if (_buffer.isEmpty) return null;

    final first = _buffer[0];

    // ESC sequences
    if (first == 0x1B) {
      final result = _parseEscapeSequence();
      if (result != null) {
        return result; // Returns (KeyboardEvent, bytesConsumed)
      }
      return null;
    }

    // Tab
    if (first == 0x09) {
      return (KeyboardEvent(
        logicalKey: LogicalKey.tab,
        character: '\t',
        modifiers: const ModifierKeys(),
      ), 1);
    }

    // Enter/Return - check before control characters since 0x0A and 0x0D are in control range
    if (first == 0x0D || first == 0x0A) {
      return (KeyboardEvent(
        logicalKey: LogicalKey.enter,
        character: '\n',
        modifiers: const ModifierKeys(),
      ), 1);
    }

    // Backspace - check before control characters since 0x08 (Ctrl+H) and 0x7F are backspace
    if (first == 0x7F || first == 0x08) {
      return (KeyboardEvent(
        logicalKey: LogicalKey.backspace,
        modifiers: const ModifierKeys(),
      ), 1);
    }

    // Control characters (Ctrl+A through Ctrl+Z)
    // Note: 0x08 (Ctrl+H), 0x09 (Ctrl+I/Tab), 0x0A (Ctrl+J), 0x0D (Ctrl+M/Enter) are handled above
    if (first >= 0x01 && first <= 0x1A) {
      final event = _parseControlChar(first);
      if (event != null) {
        return (event, 1);
      }
    }

    // Try to decode as UTF-8
    String? decodedChar;
    int bytesConsumed = 0;

    // Determine UTF-8 sequence length
    if (first < 0x80) {
      // Single-byte ASCII
      decodedChar = String.fromCharCode(first);
      bytesConsumed = 1;
    } else if (first >= 0xC0 && first < 0xE0) {
      // Two-byte sequence
      if (_buffer.length >= 2) {
        try {
          decodedChar = utf8.decode(_buffer.sublist(0, 2));
          bytesConsumed = 2;
        } catch (e) {
          // Invalid UTF-8 sequence
        }
      } else {
        // Need more bytes
        return null;
      }
    } else if (first >= 0xE0 && first < 0xF0) {
      // Three-byte sequence
      if (_buffer.length >= 3) {
        try {
          decodedChar = utf8.decode(_buffer.sublist(0, 3));
          bytesConsumed = 3;
        } catch (e) {
          // Invalid UTF-8 sequence
        }
      } else {
        // Need more bytes
        return null;
      }
    } else if (first >= 0xF0) {
      // Four-byte sequence
      if (_buffer.length >= 4) {
        try {
          decodedChar = utf8.decode(_buffer.sublist(0, 4));
          bytesConsumed = 4;
        } catch (e) {
          // Invalid UTF-8 sequence
        }
      } else {
        // Need more bytes
        return null;
      }
    }

    if (decodedChar != null && bytesConsumed > 0) {
      // Regular character
      final key = LogicalKey.fromCharacter(decodedChar);
      // Check if it's uppercase to infer shift was pressed
      final code = decodedChar.codeUnitAt(0);
      final isUpperCase = (code >= 0x41 && code <= 0x5A) || // A-Z
          (decodedChar != decodedChar.toLowerCase()); // Other uppercase chars
      return (KeyboardEvent(
        logicalKey: key ?? LogicalKey(code, 'unknown'),
        character: decodedChar,
        modifiers: ModifierKeys(shift: isUpperCase),
      ), bytesConsumed);
    }

    // Unknown character - create a generic key, consume 1 byte
    return (KeyboardEvent(
      logicalKey: LogicalKey(first, 'unknown'),
      modifiers: const ModifierKeys(),
    ), 1);
  }

  (KeyboardEvent, int)? _parseEscapeSequence() {
    if (_buffer.length == 1) {
      // Just ESC key pressed
      return (KeyboardEvent(
        logicalKey: LogicalKey.escape,
        modifiers: const ModifierKeys(),
      ), 1);
    }

    // Check for Alt+key combinations (ESC followed by character)
    if (_buffer.length == 2) {
      final second = _buffer[1];

      // Alt+letter (lowercase)
      if (second >= 0x61 && second <= 0x7A) {
        // Return the base key with Alt modifier
        final char = String.fromCharCode(second);
        final baseKey = LogicalKey.fromCharacter(char) ?? LogicalKey(second, 'unknown');
        return (KeyboardEvent(
          logicalKey: baseKey,
          character: char,
          modifiers: const ModifierKeys(alt: true),
        ), 2);
      }

      // If it's not a complete Alt sequence, might be start of longer sequence
      if (second != 0x5B && second != 0x4F) {
        // Not a CSI or SS3 sequence, treat as ESC + char
        return (KeyboardEvent(
          logicalKey: LogicalKey.escape,
          modifiers: const ModifierKeys(),
        ), 1);
      }
    }

    // CSI sequences (ESC [ ...)
    if (_buffer.length >= 3 && _buffer[1] == 0x5B) {
      return _parseCSISequence();
    }

    // SS3 sequences (ESC O ...) - used for F1-F4
    if (_buffer.length >= 3 && _buffer[1] == 0x4F) {
      return _parseSS3Sequence();
    }

    // Need more bytes to complete the sequence
    return null;
  }

  (KeyboardEvent, int)? _parseCSISequence() {
    // Skip mouse sequences - they're handled elsewhere
    if (_buffer.length >= 3 && (_buffer[2] == 0x3C || _buffer[2] == 0x4D)) {
      return null;
    }

    // Arrow keys: ESC [ A/B/C/D (3 bytes)
    if (_buffer.length == 3) {
      switch (_buffer[2]) {
        case 0x41:
          return (KeyboardEvent(
            logicalKey: LogicalKey.arrowUp,
            modifiers: const ModifierKeys(),
          ), 3);
        case 0x42:
          return (KeyboardEvent(
            logicalKey: LogicalKey.arrowDown,
            modifiers: const ModifierKeys(),
          ), 3);
        case 0x43:
          return (KeyboardEvent(
            logicalKey: LogicalKey.arrowRight,
            modifiers: const ModifierKeys(),
          ), 3);
        case 0x44:
          return (KeyboardEvent(
            logicalKey: LogicalKey.arrowLeft,
            modifiers: const ModifierKeys(),
          ), 3);
        case 0x48:
          return (KeyboardEvent(
            logicalKey: LogicalKey.home,
            modifiers: const ModifierKeys(),
          ), 3);
        case 0x46:
          return (KeyboardEvent(
            logicalKey: LogicalKey.end,
            modifiers: const ModifierKeys(),
          ), 3);
        case 0x5A:
          return (KeyboardEvent(
            logicalKey: LogicalKey.tab,
            modifiers: const ModifierKeys(shift: true),
          ), 3); // ESC [ Z is Shift+Tab
      }
    }

    // Modified arrow keys and other sequences (6 bytes: ESC [ 1 ; X Y)
    if (_buffer.length >= 6) {
      final sequence = String.fromCharCodes(_buffer);

      // Shift+Arrow: ESC [ 1 ; 2 A/B/C/D
      if (sequence.startsWith('\x1B[1;2')) {
        switch (_buffer[5]) {
          case 0x41:
            return (KeyboardEvent(
              logicalKey: LogicalKey.arrowUp,
              modifiers: const ModifierKeys(shift: true),
            ), 6);
          case 0x42:
            return (KeyboardEvent(
              logicalKey: LogicalKey.arrowDown,
              modifiers: const ModifierKeys(shift: true),
            ), 6);
          case 0x43:
            return (KeyboardEvent(
              logicalKey: LogicalKey.arrowRight,
              modifiers: const ModifierKeys(shift: true),
            ), 6);
          case 0x44:
            return (KeyboardEvent(
              logicalKey: LogicalKey.arrowLeft,
              modifiers: const ModifierKeys(shift: true),
            ), 6);
        }
      }

      // Alt+Arrow: ESC [ 1 ; 3 A/B/C/D
      if (sequence.startsWith('\x1B[1;3')) {
        switch (_buffer[5]) {
          case 0x41:
            return (KeyboardEvent(
              logicalKey: LogicalKey.arrowUp,
              modifiers: const ModifierKeys(alt: true),
            ), 6);
          case 0x42:
            return (KeyboardEvent(
              logicalKey: LogicalKey.arrowDown,
              modifiers: const ModifierKeys(alt: true),
            ), 6);
          case 0x43:
            return (KeyboardEvent(
              logicalKey: LogicalKey.arrowRight,
              modifiers: const ModifierKeys(alt: true),
            ), 6);
          case 0x44:
            return (KeyboardEvent(
              logicalKey: LogicalKey.arrowLeft,
              modifiers: const ModifierKeys(alt: true),
            ), 6);
        }
      }

      // Ctrl+Arrow: ESC [ 1 ; 5 A/B/C/D
      if (sequence.startsWith('\x1B[1;5')) {
        switch (_buffer[5]) {
          case 0x41:
            return (KeyboardEvent(
              logicalKey: LogicalKey.arrowUp,
              modifiers: const ModifierKeys(ctrl: true),
            ), 6);
          case 0x42:
            return (KeyboardEvent(
              logicalKey: LogicalKey.arrowDown,
              modifiers: const ModifierKeys(ctrl: true),
            ), 6);
          case 0x43:
            return (KeyboardEvent(
              logicalKey: LogicalKey.arrowRight,
              modifiers: const ModifierKeys(ctrl: true),
            ), 6);
          case 0x44:
            return (KeyboardEvent(
              logicalKey: LogicalKey.arrowLeft,
              modifiers: const ModifierKeys(ctrl: true),
            ), 6);
        }
      }
    }

    // Function keys and special keys with ~ terminator
    if (_buffer.contains(0x7E)) {
      final sequence = String.fromCharCodes(_buffer);

      // Parse sequences like ESC [ 2 ~ (Insert), ESC [ 3 ~ (Delete), etc.
      // ESC [ X ~ = 4 bytes
      if (sequence == '\x1B[2~')
        return (KeyboardEvent(
          logicalKey: LogicalKey.insert,
          modifiers: const ModifierKeys(),
        ), 4);
      if (sequence == '\x1B[3~')
        return (KeyboardEvent(
          logicalKey: LogicalKey.delete,
          modifiers: const ModifierKeys(),
        ), 4);
      if (sequence == '\x1B[5~')
        return (KeyboardEvent(
          logicalKey: LogicalKey.pageUp,
          modifiers: const ModifierKeys(),
        ), 4);
      if (sequence == '\x1B[6~')
        return (KeyboardEvent(
          logicalKey: LogicalKey.pageDown,
          modifiers: const ModifierKeys(),
        ), 4);

      // F5-F12
      // ESC [ 1 X ~ = 5 bytes
      if (sequence == '\x1B[15~')
        return (KeyboardEvent(
          logicalKey: LogicalKey.f5,
          modifiers: const ModifierKeys(),
        ), 5);
      if (sequence == '\x1B[17~')
        return (KeyboardEvent(
          logicalKey: LogicalKey.f6,
          modifiers: const ModifierKeys(),
        ), 5);
      if (sequence == '\x1B[18~')
        return (KeyboardEvent(
          logicalKey: LogicalKey.f7,
          modifiers: const ModifierKeys(),
        ), 5);
      if (sequence == '\x1B[19~')
        return (KeyboardEvent(
          logicalKey: LogicalKey.f8,
          modifiers: const ModifierKeys(),
        ), 5);
      if (sequence == '\x1B[20~')
        return (KeyboardEvent(
          logicalKey: LogicalKey.f9,
          modifiers: const ModifierKeys(),
        ), 5);
      if (sequence == '\x1B[21~')
        return (KeyboardEvent(
          logicalKey: LogicalKey.f10,
          modifiers: const ModifierKeys(),
        ), 5);
      if (sequence == '\x1B[23~')
        return (KeyboardEvent(
          logicalKey: LogicalKey.f11,
          modifiers: const ModifierKeys(),
        ), 5);
      if (sequence == '\x1B[24~')
        return (KeyboardEvent(
          logicalKey: LogicalKey.f12,
          modifiers: const ModifierKeys(),
        ), 5);

      // Sequence complete but unknown
      return null;
    }

    // Check if we need more bytes (sequence not complete)
    // CSI sequences typically end with a letter or ~
    final lastByte = _buffer.last;
    if ((lastByte >= 0x40 && lastByte <= 0x7E) || lastByte == 0x7E) {
      // Sequence is complete but we don't recognize it
      return null;
    }

    // Need more bytes
    return null;
  }

  (KeyboardEvent, int)? _parseSS3Sequence() {
    if (_buffer.length != 3) return null;

    // F1-F4 use SS3 sequences (all are 3 bytes: ESC O X)
    switch (_buffer[2]) {
      case 0x50:
        return (KeyboardEvent(
          logicalKey: LogicalKey.f1,
          modifiers: const ModifierKeys(),
        ), 3);
      case 0x51:
        return (KeyboardEvent(
          logicalKey: LogicalKey.f2,
          modifiers: const ModifierKeys(),
        ), 3);
      case 0x52:
        return (KeyboardEvent(
          logicalKey: LogicalKey.f3,
          modifiers: const ModifierKeys(),
        ), 3);
      case 0x53:
        return (KeyboardEvent(
          logicalKey: LogicalKey.f4,
          modifiers: const ModifierKeys(),
        ), 3);
    }

    return null;
  }

  KeyboardEvent? _parseControlChar(int code) {
    // Ctrl+A through Ctrl+Z
    // Control characters 0x01-0x1A correspond to Ctrl+A through Ctrl+Z
    if (code >= 0x01 && code <= 0x1A) {
      // Convert to the base letter (A=0x41, B=0x42, etc.)
      final letterCode = code + 0x40; // 0x01 + 0x40 = 0x41 ('A')
      final letter = String.fromCharCode(letterCode).toLowerCase();
      final baseKey = LogicalKey.fromCharacter(letter) ?? LogicalKey(letterCode, 'ctrl+$letter');

      return KeyboardEvent(
        logicalKey: baseKey,
        modifiers: const ModifierKeys(ctrl: true),
      );
    }

    return null;
  }

  /// Clear any buffered input
  void clear() {
    _buffer.clear();
  }
}
