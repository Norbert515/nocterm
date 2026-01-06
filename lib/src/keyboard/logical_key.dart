/// Represents a logical keyboard key.
///
/// This includes regular characters, special keys (arrows, function keys),
/// and modifier keys. Modifier combinations are now handled separately
/// through the ModifierKeys class in KeyboardEvent.
class LogicalKey {
  const LogicalKey(this.keyId, this.debugName);

  final int keyId;
  final String debugName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LogicalKey && other.keyId == keyId;

  @override
  int get hashCode => keyId.hashCode;

  @override
  String toString() => 'LogicalKey.$debugName';

  // Character keys
  static const LogicalKey space = LogicalKey(0x20, 'space');
  static const LogicalKey exclamation = LogicalKey(0x21, 'exclamation');
  static const LogicalKey quoteDbl = LogicalKey(0x22, 'quoteDbl');
  static const LogicalKey numberSign = LogicalKey(0x23, 'numberSign');
  static const LogicalKey dollar = LogicalKey(0x24, 'dollar');
  static const LogicalKey percent = LogicalKey(0x25, 'percent');
  static const LogicalKey ampersand = LogicalKey(0x26, 'ampersand');
  static const LogicalKey quoteSingle = LogicalKey(0x27, 'quoteSingle');
  static const LogicalKey parenthesisLeft = LogicalKey(0x28, 'parenthesisLeft');
  static const LogicalKey parenthesisRight = LogicalKey(
    0x29,
    'parenthesisRight',
  );
  static const LogicalKey asterisk = LogicalKey(0x2A, 'asterisk');
  static const LogicalKey add = LogicalKey(0x2B, 'add');
  static const LogicalKey comma = LogicalKey(0x2C, 'comma');
  static const LogicalKey minus = LogicalKey(0x2D, 'minus');
  static const LogicalKey period = LogicalKey(0x2E, 'period');
  static const LogicalKey slash = LogicalKey(0x2F, 'slash');

  // Digit keys
  static const LogicalKey digit0 = LogicalKey(0x30, 'digit0');
  static const LogicalKey digit1 = LogicalKey(0x31, 'digit1');
  static const LogicalKey digit2 = LogicalKey(0x32, 'digit2');
  static const LogicalKey digit3 = LogicalKey(0x33, 'digit3');
  static const LogicalKey digit4 = LogicalKey(0x34, 'digit4');
  static const LogicalKey digit5 = LogicalKey(0x35, 'digit5');
  static const LogicalKey digit6 = LogicalKey(0x36, 'digit6');
  static const LogicalKey digit7 = LogicalKey(0x37, 'digit7');
  static const LogicalKey digit8 = LogicalKey(0x38, 'digit8');
  static const LogicalKey digit9 = LogicalKey(0x39, 'digit9');

  static const LogicalKey colon = LogicalKey(0x3A, 'colon');
  static const LogicalKey semicolon = LogicalKey(0x3B, 'semicolon');
  static const LogicalKey less = LogicalKey(0x3C, 'less');
  static const LogicalKey equal = LogicalKey(0x3D, 'equal');
  static const LogicalKey greater = LogicalKey(0x3E, 'greater');
  static const LogicalKey question = LogicalKey(0x3F, 'question');
  static const LogicalKey at = LogicalKey(0x40, 'at');

  // Letter keys (use shift modifier to determine case)
  static const LogicalKey keyA = LogicalKey(0x61, 'keyA');
  static const LogicalKey keyB = LogicalKey(0x62, 'keyB');
  static const LogicalKey keyC = LogicalKey(0x63, 'keyC');
  static const LogicalKey keyD = LogicalKey(0x64, 'keyD');
  static const LogicalKey keyE = LogicalKey(0x65, 'keyE');
  static const LogicalKey keyF = LogicalKey(0x66, 'keyF');
  static const LogicalKey keyG = LogicalKey(0x67, 'keyG');
  static const LogicalKey keyH = LogicalKey(0x68, 'keyH');
  static const LogicalKey keyI = LogicalKey(0x69, 'keyI');
  static const LogicalKey keyJ = LogicalKey(0x6A, 'keyJ');
  static const LogicalKey keyK = LogicalKey(0x6B, 'keyK');
  static const LogicalKey keyL = LogicalKey(0x6C, 'keyL');
  static const LogicalKey keyM = LogicalKey(0x6D, 'keyM');
  static const LogicalKey keyN = LogicalKey(0x6E, 'keyN');
  static const LogicalKey keyO = LogicalKey(0x6F, 'keyO');
  static const LogicalKey keyP = LogicalKey(0x70, 'keyP');
  static const LogicalKey keyQ = LogicalKey(0x71, 'keyQ');
  static const LogicalKey keyR = LogicalKey(0x72, 'keyR');
  static const LogicalKey keyS = LogicalKey(0x73, 'keyS');
  static const LogicalKey keyT = LogicalKey(0x74, 'keyT');
  static const LogicalKey keyU = LogicalKey(0x75, 'keyU');
  static const LogicalKey keyV = LogicalKey(0x76, 'keyV');
  static const LogicalKey keyW = LogicalKey(0x77, 'keyW');
  static const LogicalKey keyX = LogicalKey(0x78, 'keyX');
  static const LogicalKey keyY = LogicalKey(0x79, 'keyY');
  static const LogicalKey keyZ = LogicalKey(0x7A, 'keyZ');

  static const LogicalKey bracketLeft = LogicalKey(0x5B, 'bracketLeft');
  static const LogicalKey backslash = LogicalKey(0x5C, 'backslash');
  static const LogicalKey bracketRight = LogicalKey(0x5D, 'bracketRight');
  static const LogicalKey caret = LogicalKey(0x5E, 'caret');
  static const LogicalKey underscore = LogicalKey(0x5F, 'underscore');
  static const LogicalKey backquote = LogicalKey(0x60, 'backquote');
  static const LogicalKey braceLeft = LogicalKey(0x7B, 'braceLeft');
  static const LogicalKey bar = LogicalKey(0x7C, 'bar');
  static const LogicalKey braceRight = LogicalKey(0x7D, 'braceRight');
  static const LogicalKey tilde = LogicalKey(0x7E, 'tilde');

  // Control keys
  static const LogicalKey enter = LogicalKey(0x0D, 'enter');
  static const LogicalKey tab = LogicalKey(0x09, 'tab');
  static const LogicalKey backspace = LogicalKey(0x7F, 'backspace');
  static const LogicalKey escape = LogicalKey(0x1B, 'escape');
  static const LogicalKey delete = LogicalKey(0x2E00, 'delete');

  // Modifier keys (for tracking state)
  static const LogicalKey controlLeft = LogicalKey(0x100000100, 'controlLeft');
  static const LogicalKey controlRight = LogicalKey(
    0x100000101,
    'controlRight',
  );
  static const LogicalKey shiftLeft = LogicalKey(0x100000102, 'shiftLeft');
  static const LogicalKey shiftRight = LogicalKey(0x100000103, 'shiftRight');
  static const LogicalKey altLeft = LogicalKey(0x100000104, 'altLeft');
  static const LogicalKey altRight = LogicalKey(0x100000105, 'altRight');
  static const LogicalKey metaLeft = LogicalKey(0x100000106, 'metaLeft');
  static const LogicalKey metaRight = LogicalKey(0x100000107, 'metaRight');

  // Arrow keys
  static const LogicalKey arrowUp = LogicalKey(0x1B5B41, 'arrowUp');
  static const LogicalKey arrowDown = LogicalKey(0x1B5B42, 'arrowDown');
  static const LogicalKey arrowRight = LogicalKey(0x1B5B43, 'arrowRight');
  static const LogicalKey arrowLeft = LogicalKey(0x1B5B44, 'arrowLeft');

  // Navigation keys
  static const LogicalKey home = LogicalKey(0x1B5B48, 'home');
  static const LogicalKey end = LogicalKey(0x1B5B46, 'end');
  static const LogicalKey pageUp = LogicalKey(0x1B5B357E, 'pageUp');
  static const LogicalKey pageDown = LogicalKey(0x1B5B367E, 'pageDown');
  static const LogicalKey insert = LogicalKey(0x1B5B327E, 'insert');

  // Function keys
  static const LogicalKey f1 = LogicalKey(0x1B4F50, 'f1');
  static const LogicalKey f2 = LogicalKey(0x1B4F51, 'f2');
  static const LogicalKey f3 = LogicalKey(0x1B4F52, 'f3');
  static const LogicalKey f4 = LogicalKey(0x1B4F53, 'f4');
  static const LogicalKey f5 = LogicalKey(0x1B5B31357E, 'f5');
  static const LogicalKey f6 = LogicalKey(0x1B5B31377E, 'f6');
  static const LogicalKey f7 = LogicalKey(0x1B5B31387E, 'f7');
  static const LogicalKey f8 = LogicalKey(0x1B5B31397E, 'f8');
  static const LogicalKey f9 = LogicalKey(0x1B5B32307E, 'f9');
  static const LogicalKey f10 = LogicalKey(0x1B5B32317E, 'f10');
  static const LogicalKey f11 = LogicalKey(0x1B5B32337E, 'f11');
  static const LogicalKey f12 = LogicalKey(0x1B5B32347E, 'f12');

  /// Create a LogicalKey from a character
  static LogicalKey? fromCharacter(String char) {
    if (char.isEmpty) return null;
    final code = char.codeUnitAt(0);

    // Map to existing constants
    switch (code) {
      case 0x20:
        return space;
      case 0x21:
        return exclamation;
      case 0x22:
        return quoteDbl;
      case 0x23:
        return numberSign;
      case 0x24:
        return dollar;
      case 0x25:
        return percent;
      case 0x26:
        return ampersand;
      case 0x27:
        return quoteSingle;
      case 0x28:
        return parenthesisLeft;
      case 0x29:
        return parenthesisRight;
      case 0x2A:
        return asterisk;
      case 0x2B:
        return add;
      case 0x2C:
        return comma;
      case 0x2D:
        return minus;
      case 0x2E:
        return period;
      case 0x2F:
        return slash;
      case 0x30:
        return digit0;
      case 0x31:
        return digit1;
      case 0x32:
        return digit2;
      case 0x33:
        return digit3;
      case 0x34:
        return digit4;
      case 0x35:
        return digit5;
      case 0x36:
        return digit6;
      case 0x37:
        return digit7;
      case 0x38:
        return digit8;
      case 0x39:
        return digit9;
      case 0x3A:
        return colon;
      case 0x3B:
        return semicolon;
      case 0x3C:
        return less;
      case 0x3D:
        return equal;
      case 0x3E:
        return greater;
      case 0x3F:
        return question;
      case 0x40:
        return at;
      // Map both uppercase and lowercase to the same key
      case 0x41:
      case 0x61:
        return keyA;
      case 0x42:
      case 0x62:
        return keyB;
      case 0x43:
      case 0x63:
        return keyC;
      case 0x44:
      case 0x64:
        return keyD;
      case 0x45:
      case 0x65:
        return keyE;
      case 0x46:
      case 0x66:
        return keyF;
      case 0x47:
      case 0x67:
        return keyG;
      case 0x48:
      case 0x68:
        return keyH;
      case 0x49:
      case 0x69:
        return keyI;
      case 0x4A:
      case 0x6A:
        return keyJ;
      case 0x4B:
      case 0x6B:
        return keyK;
      case 0x4C:
      case 0x6C:
        return keyL;
      case 0x4D:
      case 0x6D:
        return keyM;
      case 0x4E:
      case 0x6E:
        return keyN;
      case 0x4F:
      case 0x6F:
        return keyO;
      case 0x50:
      case 0x70:
        return keyP;
      case 0x51:
      case 0x71:
        return keyQ;
      case 0x52:
      case 0x72:
        return keyR;
      case 0x53:
      case 0x73:
        return keyS;
      case 0x54:
      case 0x74:
        return keyT;
      case 0x55:
      case 0x75:
        return keyU;
      case 0x56:
      case 0x76:
        return keyV;
      case 0x57:
      case 0x77:
        return keyW;
      case 0x58:
      case 0x78:
        return keyX;
      case 0x59:
      case 0x79:
        return keyY;
      case 0x5A:
      case 0x7A:
        return keyZ;
      case 0x5B:
        return bracketLeft;
      case 0x5C:
        return backslash;
      case 0x5D:
        return bracketRight;
      case 0x5E:
        return caret;
      case 0x5F:
        return underscore;
      case 0x60:
        return backquote;
      case 0x7B:
        return braceLeft;
      case 0x7C:
        return bar;
      case 0x7D:
        return braceRight;
      case 0x7E:
        return tilde;
      case 0x09:
        return tab;
      case 0x0D:
        return enter;
      case 0x1B:
        return escape;
      case 0x7F:
        return backspace;
      default:
        // For any other character, create a dynamic key
        return LogicalKey(code, 'char($char)');
    }
  }
}
