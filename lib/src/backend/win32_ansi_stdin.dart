import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Windows Console API wrapper that translates Windows console input events
/// to ANSI escape sequences, enabling Unix-like terminal behavior on Windows.
///
/// This is necessary because Windows doesn't send arrow keys and other special
/// keys through stdin - they require the Windows Console API (ReadConsoleInput).
class Win32AnsiStdin extends Stream<List<int>> implements Stdin {
  static Win32AnsiStdin? _instance;

  final int _inputHandle;
  final int _originalConsoleMode;
  final StreamController<List<int>> _controller =
      StreamController<List<int>>.broadcast();
  bool _running = false;
  int _lastButtonState = 0;

  /// Factory constructor - returns singleton instance
  factory Win32AnsiStdin() {
    return _instance ??= Win32AnsiStdin._create();
  }

  Win32AnsiStdin._create()
      : _inputHandle = _getStdHandle(_STD_INPUT_HANDLE),
        _originalConsoleMode = _getConsoleMode() {
    _configureConsoleMode();
  }

  static int _getConsoleMode() {
    final handle = _getStdHandle(_STD_INPUT_HANDLE);
    final modePtr = calloc<Uint32>();
    try {
      _GetConsoleMode(handle, modePtr);
      return modePtr.value;
    } finally {
      calloc.free(modePtr);
    }
  }

  void _configureConsoleMode() {
    // Enable mouse input, extended flags, and disable quick edit mode
    final newMode = _ENABLE_EXTENDED_FLAGS |
        (_originalConsoleMode & ~_ENABLE_QUICK_EDIT_MODE) |
        _ENABLE_MOUSE_INPUT;
    _SetConsoleMode(_inputHandle, newMode);
  }

  /// Start the input event loop
  void startEventLoop() {
    if (_running) return;
    _running = true;
    _eventLoop();
  }

  Future<void> _eventLoop() async {
    final pInputRecord = calloc<_INPUT_RECORD>();
    final pEventsRead = calloc<Uint32>();

    try {
      while (_running) {
        // Yield to Dart event loop
        await Future.delayed(Duration.zero);

        if (!_running) break;

        // Read one input event
        final result =
            _ReadConsoleInputW(_inputHandle, pInputRecord, 1, pEventsRead);
        if (result != 0 && pEventsRead.value > 0) {
          _translateAndFire(pInputRecord.ref);
        }
      }
    } finally {
      calloc.free(pInputRecord);
      calloc.free(pEventsRead);
    }
  }

  void _translateAndFire(_INPUT_RECORD event) {
    final eventType = event.EventType;

    if (eventType == _KEY_EVENT) {
      final keyEvent = event.Event.KeyEvent;
      if (keyEvent.bKeyDown != 0) {
        // Only process key down events
        final bytes = _translateKeyEvent(keyEvent);
        if (bytes.isNotEmpty) {
          _controller.add(bytes);
        }
      }
    } else if (eventType == _MOUSE_EVENT) {
      final mouseEvent = event.Event.MouseEvent;
      final bytes = _translateMouseEvent(mouseEvent);
      if (bytes.isNotEmpty) {
        _controller.add(bytes);
      }
    }
  }

  List<int> _translateKeyEvent(_KEY_EVENT_RECORD keyEvent) {
    final virtualKeyCode = keyEvent.wVirtualKeyCode;
    final char = keyEvent.uChar;
    final controlKeyState = keyEvent.dwControlKeyState;

    final ctrlPressed = (controlKeyState & _LEFT_CTRL_PRESSED) != 0 ||
        (controlKeyState & _RIGHT_CTRL_PRESSED) != 0;
    final altPressed = (controlKeyState & _LEFT_ALT_PRESSED) != 0 ||
        (controlKeyState & _RIGHT_ALT_PRESSED) != 0;
    final shiftPressed = (controlKeyState & _SHIFT_PRESSED) != 0;

    // Calculate modifier code for ANSI sequences
    // Format: 1 + shift(1) + alt(2) + ctrl(4)
    int modifierCode = 1;
    if (shiftPressed) modifierCode += 1;
    if (altPressed) modifierCode += 2;
    if (ctrlPressed) modifierCode += 4;

    // Ctrl+A-Z → ASCII 1-26
    if (ctrlPressed &&
        !altPressed &&
        virtualKeyCode >= 0x41 &&
        virtualKeyCode <= 0x5A) {
      return [virtualKeyCode - 0x40];
    }

    // Special keys - translate to ANSI escape sequences
    switch (virtualKeyCode) {
      // Arrow keys
      case _VK_UP:
        return modifierCode > 1
            ? [
                0x1b,
                0x5b,
                0x31,
                0x3b,
                ...modifierCode.toString().codeUnits,
                0x41
              ]
            : [0x1b, 0x5b, 0x41]; // ESC [ A
      case _VK_DOWN:
        return modifierCode > 1
            ? [
                0x1b,
                0x5b,
                0x31,
                0x3b,
                ...modifierCode.toString().codeUnits,
                0x42
              ]
            : [0x1b, 0x5b, 0x42]; // ESC [ B
      case _VK_RIGHT:
        return modifierCode > 1
            ? [
                0x1b,
                0x5b,
                0x31,
                0x3b,
                ...modifierCode.toString().codeUnits,
                0x43
              ]
            : [0x1b, 0x5b, 0x43]; // ESC [ C
      case _VK_LEFT:
        return modifierCode > 1
            ? [
                0x1b,
                0x5b,
                0x31,
                0x3b,
                ...modifierCode.toString().codeUnits,
                0x44
              ]
            : [0x1b, 0x5b, 0x44]; // ESC [ D

      // Navigation keys
      case _VK_HOME:
        return modifierCode > 1
            ? [
                0x1b,
                0x5b,
                0x31,
                0x3b,
                ...modifierCode.toString().codeUnits,
                0x48
              ]
            : [0x1b, 0x5b, 0x48]; // ESC [ H
      case _VK_END:
        return modifierCode > 1
            ? [
                0x1b,
                0x5b,
                0x31,
                0x3b,
                ...modifierCode.toString().codeUnits,
                0x46
              ]
            : [0x1b, 0x5b, 0x46]; // ESC [ F
      case _VK_INSERT:
        return [0x1b, 0x5b, 0x32, 0x7e]; // ESC [ 2 ~
      case _VK_DELETE:
        return [0x1b, 0x5b, 0x33, 0x7e]; // ESC [ 3 ~
      case _VK_PRIOR: // Page Up
        return [0x1b, 0x5b, 0x35, 0x7e]; // ESC [ 5 ~
      case _VK_NEXT: // Page Down
        return [0x1b, 0x5b, 0x36, 0x7e]; // ESC [ 6 ~

      // Function keys F1-F12
      case _VK_F1:
        return [0x1b, 0x4f, 0x50]; // ESC O P
      case _VK_F2:
        return [0x1b, 0x4f, 0x51]; // ESC O Q
      case _VK_F3:
        return [0x1b, 0x4f, 0x52]; // ESC O R
      case _VK_F4:
        return [0x1b, 0x4f, 0x53]; // ESC O S
      case _VK_F5:
        return [0x1b, 0x5b, 0x31, 0x35, 0x7e]; // ESC [ 15 ~
      case _VK_F6:
        return [0x1b, 0x5b, 0x31, 0x37, 0x7e]; // ESC [ 17 ~
      case _VK_F7:
        return [0x1b, 0x5b, 0x31, 0x38, 0x7e]; // ESC [ 18 ~
      case _VK_F8:
        return [0x1b, 0x5b, 0x31, 0x39, 0x7e]; // ESC [ 19 ~
      case _VK_F9:
        return [0x1b, 0x5b, 0x32, 0x30, 0x7e]; // ESC [ 20 ~
      case _VK_F10:
        return [0x1b, 0x5b, 0x32, 0x31, 0x7e]; // ESC [ 21 ~
      case _VK_F11:
        return [0x1b, 0x5b, 0x32, 0x33, 0x7e]; // ESC [ 23 ~
      case _VK_F12:
        return [0x1b, 0x5b, 0x32, 0x34, 0x7e]; // ESC [ 24 ~

      // Control characters
      case _VK_RETURN:
        return [0x0d]; // CR
      case _VK_ESCAPE:
        return [0x1b]; // ESC
      case _VK_BACK:
        return [0x7f]; // DEL (Unix backspace)
      case _VK_TAB:
        return shiftPressed ? [0x1b, 0x5b, 0x5a] : [0x09]; // Shift+Tab or Tab
    }

    // Printable characters
    if (char >= 32 && char < 127) {
      return [char];
    }
    // Extended characters (UTF-16)
    if (char > 127) {
      return String.fromCharCode(char).codeUnits;
    }

    return [];
  }

  List<int> _translateMouseEvent(_MOUSE_EVENT_RECORD mouseEvent) {
    final buttonState = mouseEvent.dwButtonState;
    final eventFlags = mouseEvent.dwEventFlags;
    final x = mouseEvent.dwMousePosition_X + 1; // 1-indexed
    final y = mouseEvent.dwMousePosition_Y + 1;

    int button;
    String suffix;

    if (eventFlags & _MOUSE_WHEELED != 0) {
      // Wheel event - check high word of buttonState for direction
      final wheelDelta = (buttonState >> 16) & 0xFFFF;
      button = wheelDelta > 32767 ? 65 : 64; // Down or Up
      suffix = 'M';
    } else if (eventFlags & _MOUSE_HWHEELED != 0) {
      // Horizontal wheel
      final wheelDelta = (buttonState >> 16) & 0xFFFF;
      button = wheelDelta > 32767 ? 67 : 66;
      suffix = 'M';
    } else if (eventFlags & _MOUSE_MOVED != 0) {
      // Motion event
      if (buttonState != 0) {
        // Motion with button down
        button = 32;
        if (buttonState & _FROM_LEFT_1ST_BUTTON_PRESSED != 0) button += 0;
        if (buttonState & _RIGHTMOST_BUTTON_PRESSED != 0) button += 2;
        if (buttonState & _FROM_LEFT_2ND_BUTTON_PRESSED != 0) button += 1;
        suffix = 'M';
      } else {
        // Motion without button - don't report
        return [];
      }
    } else {
      // Button event
      if (buttonState & _FROM_LEFT_1ST_BUTTON_PRESSED != 0 &&
          _lastButtonState & _FROM_LEFT_1ST_BUTTON_PRESSED == 0) {
        button = 0;
        suffix = 'M';
      } else if (buttonState & _RIGHTMOST_BUTTON_PRESSED != 0 &&
          _lastButtonState & _RIGHTMOST_BUTTON_PRESSED == 0) {
        button = 2;
        suffix = 'M';
      } else if (buttonState & _FROM_LEFT_2ND_BUTTON_PRESSED != 0 &&
          _lastButtonState & _FROM_LEFT_2ND_BUTTON_PRESSED == 0) {
        button = 1;
        suffix = 'M';
      } else if (_lastButtonState != 0 && buttonState == 0) {
        // Button release
        button = 0;
        suffix = 'm';
      } else {
        _lastButtonState = buttonState;
        return [];
      }
    }

    _lastButtonState = buttonState;

    // SGR mouse format: ESC [ < button ; x ; y M/m
    final seq = '\x1b[<$button;$x;$y$suffix';
    return seq.codeUnits;
  }

  /// Stop the event loop and restore console mode
  void close() {
    _running = false;
    _SetConsoleMode(_inputHandle, _originalConsoleMode);
    _controller.close();
    _instance = null;
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    startEventLoop();
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  // Stdin interface implementation
  @override
  bool get echoMode => stdin.echoMode;
  @override
  set echoMode(bool value) => stdin.echoMode = value;

  @override
  bool get lineMode => stdin.lineMode;
  @override
  set lineMode(bool value) => stdin.lineMode = value;

  @override
  bool get hasTerminal => stdin.hasTerminal;

  @override
  bool get supportsAnsiEscapes => stdin.supportsAnsiEscapes;

  @override
  int readByteSync() => stdin.readByteSync();

  @override
  String? readLineSync(
          {Encoding encoding = systemEncoding, bool retainNewlines = false}) =>
      stdin.readLineSync(encoding: encoding, retainNewlines: retainNewlines);

  @override
  bool get echoNewlineMode => stdin.echoNewlineMode;
  @override
  set echoNewlineMode(bool value) => stdin.echoNewlineMode = value;
}

// Windows API Constants
const int _STD_INPUT_HANDLE = -10;
const int _ENABLE_MOUSE_INPUT = 0x0010;
const int _ENABLE_EXTENDED_FLAGS = 0x0080;
const int _ENABLE_QUICK_EDIT_MODE = 0x0040;

// Event types
const int _KEY_EVENT = 0x0001;
const int _MOUSE_EVENT = 0x0002;

// Control key states
const int _SHIFT_PRESSED = 0x0010;
const int _LEFT_CTRL_PRESSED = 0x0008;
const int _RIGHT_CTRL_PRESSED = 0x0004;
const int _LEFT_ALT_PRESSED = 0x0002;
const int _RIGHT_ALT_PRESSED = 0x0001;

// Mouse event flags
const int _MOUSE_MOVED = 0x0001;
const int _MOUSE_WHEELED = 0x0004;
const int _MOUSE_HWHEELED = 0x0008;

// Mouse button states
const int _FROM_LEFT_1ST_BUTTON_PRESSED = 0x0001;
const int _RIGHTMOST_BUTTON_PRESSED = 0x0002;
const int _FROM_LEFT_2ND_BUTTON_PRESSED = 0x0004;

// Virtual key codes
const int _VK_BACK = 0x08;
const int _VK_TAB = 0x09;
const int _VK_RETURN = 0x0D;
const int _VK_ESCAPE = 0x1B;
const int _VK_PRIOR = 0x21;
const int _VK_NEXT = 0x22;
const int _VK_END = 0x23;
const int _VK_HOME = 0x24;
const int _VK_LEFT = 0x25;
const int _VK_UP = 0x26;
const int _VK_RIGHT = 0x27;
const int _VK_DOWN = 0x28;
const int _VK_INSERT = 0x2D;
const int _VK_DELETE = 0x2E;
const int _VK_F1 = 0x70;
const int _VK_F2 = 0x71;
const int _VK_F3 = 0x72;
const int _VK_F4 = 0x73;
const int _VK_F5 = 0x74;
const int _VK_F6 = 0x75;
const int _VK_F7 = 0x76;
const int _VK_F8 = 0x77;
const int _VK_F9 = 0x78;
const int _VK_F10 = 0x79;
const int _VK_F11 = 0x7A;
const int _VK_F12 = 0x7B;

// FFI Structs
final class _COORD extends Struct {
  @Int16()
  external int X;
  @Int16()
  external int Y;
}

final class _KEY_EVENT_RECORD extends Struct {
  @Int32()
  external int bKeyDown;
  @Uint16()
  external int wRepeatCount;
  @Uint16()
  external int wVirtualKeyCode;
  @Uint16()
  external int wVirtualScanCode;
  @Uint16()
  external int uChar;
  @Uint32()
  external int dwControlKeyState;
}

final class _MOUSE_EVENT_RECORD extends Struct {
  @Int16()
  external int dwMousePosition_X;
  @Int16()
  external int dwMousePosition_Y;
  @Uint32()
  external int dwButtonState;
  @Uint32()
  external int dwControlKeyState;
  @Uint32()
  external int dwEventFlags;
}

final class _EVENT_UNION extends Union {
  external _KEY_EVENT_RECORD KeyEvent;
  external _MOUSE_EVENT_RECORD MouseEvent;
}

final class _INPUT_RECORD extends Struct {
  @Uint16()
  external int EventType;
  external _EVENT_UNION Event;
}

// FFI Function bindings
typedef _GetStdHandleNative = IntPtr Function(Uint32 nStdHandle);
typedef _GetStdHandleDart = int Function(int nStdHandle);

typedef _GetConsoleModeNative = Int32 Function(
    IntPtr hConsoleHandle, Pointer<Uint32> lpMode);
typedef _GetConsoleModeDart = int Function(
    int hConsoleHandle, Pointer<Uint32> lpMode);

typedef _SetConsoleModeNative = Int32 Function(
    IntPtr hConsoleHandle, Uint32 dwMode);
typedef _SetConsoleModeDart = int Function(int hConsoleHandle, int dwMode);

typedef _ReadConsoleInputNative = Int32 Function(
    IntPtr hConsoleInput,
    Pointer<_INPUT_RECORD> lpBuffer,
    Uint32 nLength,
    Pointer<Uint32> lpNumberOfEventsRead);
typedef _ReadConsoleInputDart = int Function(
    int hConsoleInput,
    Pointer<_INPUT_RECORD> lpBuffer,
    int nLength,
    Pointer<Uint32> lpNumberOfEventsRead);

final _kernel32 = DynamicLibrary.open('kernel32.dll');

final _getStdHandle = _kernel32
    .lookupFunction<_GetStdHandleNative, _GetStdHandleDart>('GetStdHandle');

final _GetConsoleMode =
    _kernel32.lookupFunction<_GetConsoleModeNative, _GetConsoleModeDart>(
        'GetConsoleMode');

final _SetConsoleMode =
    _kernel32.lookupFunction<_SetConsoleModeNative, _SetConsoleModeDart>(
        'SetConsoleMode');

final _ReadConsoleInputW =
    _kernel32.lookupFunction<_ReadConsoleInputNative, _ReadConsoleInputDart>(
        'ReadConsoleInputW');
