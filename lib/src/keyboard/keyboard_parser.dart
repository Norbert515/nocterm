import 'dart:convert';
import 'logical_key.dart';
import 'keyboard_event.dart';

/// Parses raw terminal input bytes into keyboard events.
class KeyboardParser {
  final List<int> _buffer = [];

  /// Parse incoming bytes and return keyboard events.
  /// Returns null if more bytes are needed to complete a sequence.
  KeyboardEvent? parseBytes(List<int> bytes) {
    _buffer.addAll(bytes);

    if (_buffer.isEmpty) return null;

    // Try to parse the current buffer
    final event = _parseBuffer();

    // If we successfully parsed an event, clear the buffer
    if (event != null) {
      _buffer.clear();
    }

    return event;
  }

  KeyboardEvent? _parseBuffer() {
    if (_buffer.isEmpty) return null;

    final first = _buffer[0];

    // ESC sequences
    if (first == 0x1B) {
      return _parseEscapeSequence();
    }

    // Tab
    if (first == 0x09) {
      return KeyboardEvent(
        logicalKey: LogicalKey.tab,
        character: '\t',
        modifiers: const ModifierKeys(),
      );
    }

    // Enter/Return - 0x0D (CR) and 0x0A (LF).
    // In raw mode most terminals send 0x0D for Enter, but some (e.g. Warp)
    // may send 0x0A. We treat both as Enter for compatibility.
    // When kitty keyboard protocol is active, Ctrl+J arrives as a kitty
    // CSI sequence (\x1b[106;5u), not as raw 0x0A, so this doesn't
    // interfere with Ctrl+J newline detection in kitty-capable terminals.
    if (first == 0x0D || first == 0x0A) {
      return KeyboardEvent(
        logicalKey: LogicalKey.enter,
        character: '\n',
        modifiers: const ModifierKeys(),
      );
    }

    // Backspace - check before control characters since 0x08 (Ctrl+H) and 0x7F are backspace
    if (first == 0x7F || first == 0x08) {
      return KeyboardEvent(
        logicalKey: LogicalKey.backspace,
        modifiers: const ModifierKeys(),
      );
    }

    // Control characters (Ctrl+A through Ctrl+Z)
    // Note: 0x08 (Ctrl+H), 0x09 (Ctrl+I/Tab), 0x0A (Ctrl+J), 0x0D (Ctrl+M/Enter) are handled above
    if (first >= 0x01 && first <= 0x1A) {
      return _parseControlChar(first);
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
      // Remove consumed bytes from buffer
      _buffer.removeRange(
          0, bytesConsumed - 1); // Keep one byte for the main parser to clear

      // Regular character
      final key = LogicalKey.fromCharacter(decodedChar);
      // Check if it's uppercase to infer shift was pressed
      final code = decodedChar.codeUnitAt(0);
      final isUpperCase = (code >= 0x41 && code <= 0x5A) || // A-Z
          (decodedChar != decodedChar.toLowerCase()); // Other uppercase chars
      return KeyboardEvent(
        logicalKey: key ?? LogicalKey(code, 'unknown'),
        character: decodedChar,
        modifiers: ModifierKeys(shift: isUpperCase),
      );
    }

    // Unknown character - create a generic key
    return KeyboardEvent(
      logicalKey: LogicalKey(first, 'unknown'),
      modifiers: const ModifierKeys(),
    );
  }

  KeyboardEvent? _parseEscapeSequence() {
    if (_buffer.length == 1) {
      // Just ESC key pressed
      return KeyboardEvent(
        logicalKey: LogicalKey.escape,
        modifiers: const ModifierKeys(),
      );
    }

    // Check for Alt+key combinations (ESC followed by character)
    if (_buffer.length == 2) {
      final second = _buffer[1];

      // Alt+letter (lowercase)
      if (second >= 0x61 && second <= 0x7A) {
        // Return the base key with Alt modifier
        final char = String.fromCharCode(second);
        final baseKey =
            LogicalKey.fromCharacter(char) ?? LogicalKey(second, 'unknown');
        return KeyboardEvent(
          logicalKey: baseKey,
          character: char,
          modifiers: const ModifierKeys(alt: true),
        );
      }

      // If it's not a complete Alt sequence, might be start of longer sequence
      if (second != 0x5B && second != 0x4F) {
        // Not a CSI or SS3 sequence, treat as ESC + char
        return KeyboardEvent(
          logicalKey: LogicalKey.escape,
          modifiers: const ModifierKeys(),
        );
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

  KeyboardEvent? _parseCSISequence() {
    // Try kitty keyboard protocol: CSI codepoint ; modifier u
    {
      final result = _parseKittySequence();
      if (result != null) return result;
    }

    // Try xterm modifyOtherKeys: CSI 27 ; modifier ; charcode ~
    {
      final result = _parseModifyOtherKeysSequence();
      if (result != null) return result;
    }

    // Arrow keys: ESC [ A/B/C/D
    if (_buffer.length == 3) {
      switch (_buffer[2]) {
        case 0x41:
          return KeyboardEvent(
            logicalKey: LogicalKey.arrowUp,
            modifiers: const ModifierKeys(),
          );
        case 0x42:
          return KeyboardEvent(
            logicalKey: LogicalKey.arrowDown,
            modifiers: const ModifierKeys(),
          );
        case 0x43:
          return KeyboardEvent(
            logicalKey: LogicalKey.arrowRight,
            modifiers: const ModifierKeys(),
          );
        case 0x44:
          return KeyboardEvent(
            logicalKey: LogicalKey.arrowLeft,
            modifiers: const ModifierKeys(),
          );
        case 0x48:
          return KeyboardEvent(
            logicalKey: LogicalKey.home,
            modifiers: const ModifierKeys(),
          );
        case 0x46:
          return KeyboardEvent(
            logicalKey: LogicalKey.end,
            modifiers: const ModifierKeys(),
          );
        case 0x5A:
          return KeyboardEvent(
            logicalKey: LogicalKey.tab,
            modifiers: const ModifierKeys(shift: true),
          ); // ESC [ Z is Shift+Tab
      }
    }

    // Modified arrow keys and other sequences
    if (_buffer.length >= 6) {
      final sequence = String.fromCharCodes(_buffer);

      // Modified arrow/home/end keys: ESC [ 1 ; {modifier} A/B/C/D/H/F
      // Modifier is 1 + bitmask (shift=1, alt=2, ctrl=4, meta=8).
      // Handles all combinations: Shift(2), Alt(3), Alt+Shift(4), Ctrl(5),
      // Ctrl+Shift(6), Ctrl+Alt(7), Ctrl+Alt+Shift(8), etc.
      if (sequence.startsWith('\x1B[1;') && _buffer.length == 6) {
        final modValue = int.tryParse(String.fromCharCode(_buffer[4]));
        if (modValue != null) {
          final modifiers = _decodeModifiers(modValue);
          final LogicalKey? key;
          switch (_buffer[5]) {
            case 0x41: key = LogicalKey.arrowUp;
            case 0x42: key = LogicalKey.arrowDown;
            case 0x43: key = LogicalKey.arrowRight;
            case 0x44: key = LogicalKey.arrowLeft;
            case 0x48: key = LogicalKey.home;
            case 0x46: key = LogicalKey.end;
            default: key = null;
          }
          if (key != null) {
            return KeyboardEvent(logicalKey: key, modifiers: modifiers);
          }
        }
      }
    }

    // Function keys and special keys with ~ terminator
    if (_buffer.contains(0x7E)) {
      final sequence = String.fromCharCodes(_buffer);

      // Parse sequences like ESC [ 2 ~ (Insert), ESC [ 3 ~ (Delete), etc.
      if (sequence == '\x1B[2~') {
        return KeyboardEvent(
          logicalKey: LogicalKey.insert,
          modifiers: const ModifierKeys(),
        );
      }
      if (sequence == '\x1B[3~') {
        return KeyboardEvent(
          logicalKey: LogicalKey.delete,
          modifiers: const ModifierKeys(),
        );
      }
      if (sequence == '\x1B[5~') {
        return KeyboardEvent(
          logicalKey: LogicalKey.pageUp,
          modifiers: const ModifierKeys(),
        );
      }
      if (sequence == '\x1B[6~') {
        return KeyboardEvent(
          logicalKey: LogicalKey.pageDown,
          modifiers: const ModifierKeys(),
        );
      }

      // F5-F12
      if (sequence == '\x1B[15~') {
        return KeyboardEvent(
          logicalKey: LogicalKey.f5,
          modifiers: const ModifierKeys(),
        );
      }
      if (sequence == '\x1B[17~') {
        return KeyboardEvent(
          logicalKey: LogicalKey.f6,
          modifiers: const ModifierKeys(),
        );
      }
      if (sequence == '\x1B[18~') {
        return KeyboardEvent(
          logicalKey: LogicalKey.f7,
          modifiers: const ModifierKeys(),
        );
      }
      if (sequence == '\x1B[19~') {
        return KeyboardEvent(
          logicalKey: LogicalKey.f8,
          modifiers: const ModifierKeys(),
        );
      }
      if (sequence == '\x1B[20~') {
        return KeyboardEvent(
          logicalKey: LogicalKey.f9,
          modifiers: const ModifierKeys(),
        );
      }
      if (sequence == '\x1B[21~') {
        return KeyboardEvent(
          logicalKey: LogicalKey.f10,
          modifiers: const ModifierKeys(),
        );
      }
      if (sequence == '\x1B[23~') {
        return KeyboardEvent(
          logicalKey: LogicalKey.f11,
          modifiers: const ModifierKeys(),
        );
      }
      if (sequence == '\x1B[24~') {
        return KeyboardEvent(
          logicalKey: LogicalKey.f12,
          modifiers: const ModifierKeys(),
        );
      }

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

  KeyboardEvent? _parseSS3Sequence() {
    if (_buffer.length != 3) return null;

    // F1-F4 use SS3 sequences
    switch (_buffer[2]) {
      case 0x50:
        return KeyboardEvent(
          logicalKey: LogicalKey.f1,
          modifiers: const ModifierKeys(),
        );
      case 0x51:
        return KeyboardEvent(
          logicalKey: LogicalKey.f2,
          modifiers: const ModifierKeys(),
        );
      case 0x52:
        return KeyboardEvent(
          logicalKey: LogicalKey.f3,
          modifiers: const ModifierKeys(),
        );
      case 0x53:
        return KeyboardEvent(
          logicalKey: LogicalKey.f4,
          modifiers: const ModifierKeys(),
        );
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
      final baseKey = LogicalKey.fromCharacter(letter) ??
          LogicalKey(letterCode, 'ctrl+$letter');

      return KeyboardEvent(
        logicalKey: baseKey,
        modifiers: const ModifierKeys(ctrl: true),
      );
    }

    return null;
  }

  /// Parse kitty keyboard protocol sequence: CSI codepoint ; modifier u
  /// Supports `:` sub-parameters per the kitty spec (e.g. \x1b[13:10;2u).
  KeyboardEvent? _parseKittySequence() {
    // Find 'u' terminator (0x75)
    // Valid parameter bytes: digits (0x30-0x39), ';' (0x3B), ':' (0x3A)
    int uIndex = -1;
    for (int i = 2; i < _buffer.length; i++) {
      if (_buffer[i] == 0x75) {
        uIndex = i;
        break;
      }
      if (_buffer[i] != 0x3B && // ';'
          _buffer[i] != 0x3A && // ':' (sub-parameter separator)
          !(_buffer[i] >= 0x30 && _buffer[i] <= 0x39)) {
        return null;
      }
    }

    if (uIndex == -1) return null;

    final paramStr = String.fromCharCodes(_buffer.sublist(2, uIndex));
    final parts = paramStr.split(';');

    if (parts.isEmpty || parts.length > 3) return null;

    // The codepoint field may contain `:` sub-parameters (e.g. "13:10").
    // Per the kitty spec, the first value is the Unicode codepoint.
    final codepointStr = parts[0].split(':').first;
    final codepoint = int.tryParse(codepointStr);
    if (codepoint == null) return null;

    // The modifier field may also contain `:` sub-parameters (e.g. "2:1").
    // The first value is the modifier bitmask.
    final modifierStr = parts.length >= 2 ? parts[1].split(':').first : null;
    final modifierValue =
        modifierStr != null ? int.tryParse(modifierStr) : null;
    final modifiers = modifierValue != null
        ? _decodeModifiers(modifierValue)
        : const ModifierKeys();

    return _codepointToKeyEvent(codepoint, modifiers);
  }

  /// Parse xterm modifyOtherKeys sequence: CSI 27 ; modifier ; charcode ~
  KeyboardEvent? _parseModifyOtherKeysSequence() {
    if (_buffer.length < 3 || _buffer[2] != 0x32) return null;

    // Find '~' terminator
    int tildeIndex = -1;
    for (int i = 2; i < _buffer.length; i++) {
      if (_buffer[i] == 0x7E) {
        tildeIndex = i;
        break;
      }
    }

    if (tildeIndex == -1) return null;

    final paramStr = String.fromCharCodes(_buffer.sublist(2, tildeIndex));
    final parts = paramStr.split(';');

    if (parts.length != 3) return null;

    final marker = int.tryParse(parts[0]);
    if (marker != 27) return null;

    final modifierValue = int.tryParse(parts[1]);
    final charCode = int.tryParse(parts[2]);
    if (modifierValue == null || charCode == null) return null;

    final modifiers = _decodeModifiers(modifierValue);
    return _codepointToKeyEvent(charCode, modifiers);
  }

  /// Decode modifier bitmask. Value is 1 + bitmask.
  /// Bit 0 = shift, Bit 1 = alt, Bit 2 = ctrl, Bit 3 = super/meta
  ModifierKeys _decodeModifiers(int value) {
    final bitmask = value - 1;
    return ModifierKeys(
      shift: (bitmask & 1) != 0,
      alt: (bitmask & 2) != 0,
      ctrl: (bitmask & 4) != 0,
      meta: (bitmask & 8) != 0,
    );
  }

  /// Convert a Unicode codepoint to a KeyboardEvent.
  KeyboardEvent _codepointToKeyEvent(int codepoint, ModifierKeys modifiers) {
    switch (codepoint) {
      case 13:
        return KeyboardEvent(
          logicalKey: LogicalKey.enter,
          character: '\n',
          modifiers: modifiers,
        );
      case 9:
        return KeyboardEvent(
          logicalKey: LogicalKey.tab,
          character: '\t',
          modifiers: modifiers,
        );
      case 27:
        return KeyboardEvent(
          logicalKey: LogicalKey.escape,
          modifiers: modifiers,
        );
      case 127:
        return KeyboardEvent(
          logicalKey: LogicalKey.backspace,
          modifiers: modifiers,
        );
      default:
        final char = String.fromCharCode(codepoint);
        final key = LogicalKey.fromCharacter(char) ??
            LogicalKey(codepoint, 'codepoint($codepoint)');
        return KeyboardEvent(
          logicalKey: key,
          character: char,
          modifiers: modifiers,
        );
    }
  }

  /// Clear any buffered input
  void clear() {
    _buffer.clear();
  }
}
