class EscapeCodes {
  const EscapeCodes._();

  static const disable = _Disable._();
  static const enable = _Enable._();

  static const hideCursor = '\x1b[?25l';
  static const showCursor = '\x1b[?25h';
  static const clearScreen = '\x1b[2J';
  static const clearLine = '\x1b[2K';
  static const moveCursorHome = '\x1b[H';
  static const alternateBuffer = '\x1b[?1049h';
  static const mainBuffer = '\x1b[?1049l';
}

class _Disable {
  const _Disable._();

  String get motionTracking => '\x1B[?1003l';
  String get sgrMouseMode => '\x1B[?1006l';
  String get buttonEventTracking => '\x1B[?1002l';
  String get basicMouseTracking => '\x1B[?1000l';
  String get bracketedPasteMode => '\x1B[?2004l';

  /// Pop kitty keyboard mode from the stack.
  String get kittyKeyboard => '\x1B[<u';

  /// Reset xterm modifyOtherKeys mode to disabled.
  String get modifyOtherKeys => '\x1B[>4;0m';

  List<String> get values => [
        motionTracking,
        sgrMouseMode,
        buttonEventTracking,
        basicMouseTracking,
        bracketedPasteMode,
        kittyKeyboard,
        modifyOtherKeys,
      ];
}

class _Enable {
  const _Enable._();

  String get motionTracking => '\x1B[?1003h';
  String get sgrMouseMode => '\x1B[?1006h';
  String get buttonEventTracking => '\x1B[?1002h';
  String get basicMouseTracking => '\x1B[?1000h';
  String get bracketedPasteMode => '\x1B[?2004h';

  /// Push kitty keyboard mode. Bit 0 (disambiguate escape codes)
  /// + bit 4 (report associated text, so IME commits on
  /// supporting terminals arrive as 4-part key events instead of
  /// being routed through bracketed paste).
  String get kittyKeyboard => '\x1B[>17u';

  /// Enable xterm modifyOtherKeys mode (level 1).
  String get modifyOtherKeys => '\x1B[>4;1m';

  List<String> get values => [
        motionTracking,
        sgrMouseMode,
        buttonEventTracking,
        basicMouseTracking,
        bracketedPasteMode,
        kittyKeyboard,
        modifyOtherKeys,
      ];
}
