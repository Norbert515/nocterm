import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:win32/win32.dart' as win32;
import 'package:ffi/ffi.dart' as ffi;


// I have a PR #1009 open on the win32 package to add these missing constants

// Manually define the missing Windows event type constants.
const int KEY_EVENT = 0x0001;
const int MOUSE_EVENT = 0x0002;

// For the dwControlKeyState member of the KEY_EVENT_RECORD struct
const int RIGHT_ALT_PRESSED = 0x0001;
const int LEFT_ALT_PRESSED = 0x0002;
const int RIGHT_CTRL_PRESSED = 0x0004;
const int LEFT_CTRL_PRESSED = 0x0008;
const int SHIFT_PRESSED = 0x0010;

const int  FROM_LEFT_1ST_BUTTON_PRESSED = 0x0001;
const int  RIGHTMOST_BUTTON_PRESSED     = 0x0002;
const int  FROM_LEFT_2ND_BUTTON_PRESSED = 0x0004;
const int  FROM_LEFT_3RD_BUTTON_PRESSED = 0x0008;
const int  FROM_LEFT_4TH_BUTTON_PRESSED = 0x0010;

/// A class that emulates a Unix-style Stdin by extending StreamView to behave
/// like a Stream and implementing the Stdin interface - but specifically sending
/// the appropriate ANSI escape sequences for mouse and keyboard events on Windows.
/// As if it were a Unix terminal for which the ANSI commands:
///    ESC [ ? 1000 h - Send Mouse X & Y on button press and release
///    ESC [ ? 1002 h - Use Cell Motion Mouse Tracking
///    ESC [ ? 1003 h - Enable all motion mouse tracking
///    ESC [ ? 1006 h - Enable SGR mouse mode
/// had been send to the terminal stdout.
/// This class is asynchronous and does not support synchronous read methods.
class Win32AnsiStdin extends StreamView<List<int>> implements Stdin {
  final StreamController<List<int>> _controller;
  final _inputHandle = win32.GetStdHandle(win32.STD_INPUT_HANDLE);

  late final int _originalConsoleMode;
  int _lastButtonState = 0;
  bool _isListening = false;
  
  // Backing fields for required Stdin properties
  bool _lineMode = false;
  bool _echoMode = false;
  bool _echoNewlineMode = false;

  // Factory constructor for proper initialization
  factory Win32AnsiStdin() {
    final controller = StreamController<List<int>>();
    return Win32AnsiStdin._(controller);
  }

  // Private constructor
  Win32AnsiStdin._(this._controller) : super(_controller.stream) {
    final pMode = ffi.calloc<Uint32>();
    try {
      win32.GetConsoleMode(_inputHandle, pMode);
      _originalConsoleMode = pMode.value;
    } finally {
      win32.free(pMode);
    }
    _startEventLoopIfNeeded();
  }

  void _startEventLoopIfNeeded() {
    if (_isListening) return;
    _isListening = true;
    
    final newMode = win32.ENABLE_EXTENDED_FLAGS |
        (_originalConsoleMode & ~win32.ENABLE_QUICK_EDIT_MODE) |
        win32.ENABLE_MOUSE_INPUT;
    win32.SetConsoleMode(_inputHandle, newMode);

    Future(_eventLoop);
  }

  void close() {
    if (!_isListening) return;
    _isListening = false;
    win32.SetConsoleMode(_inputHandle, _originalConsoleMode);
    _controller.close();
    print('\nConsole mode restored.');
  }

  // --- Overriding the Stdin interface properties ---
  @override
  bool get hasTerminal => true;

  @override
  bool get lineMode => _lineMode;

  @override
  set lineMode(bool mode) => _lineMode = mode;

  @override
  bool get echoMode => _echoMode;

  @override
  set echoMode(bool mode) => _echoMode = mode;

  @override
  bool get echoNewlineMode => _echoNewlineMode;

  @override
  set echoNewlineMode(bool mode) => _echoNewlineMode = mode;

  @override
  bool get supportsAnsiEscapes => true;

  @override
  int readByteSync() {
    throw UnsupportedError(
        'Win32Stdin is asynchronous and does not support readByteSync.');
  }

  @override
  String? readLineSync(
      {Encoding encoding = systemEncoding, bool retainNewlines = false}) {
    throw UnsupportedError(
        'Win32Stdin is asynchronous and does not support readLineSync.');
  }

  // --- Event Loop and Translation Logic ---

  Future<void> _eventLoop() async {
    final pInputRecord = ffi.calloc<win32.INPUT_RECORD>();
    final pEventsRead = ffi.calloc<Uint32>();

    try {
      while (_isListening) {
        if (win32.ReadConsoleInput(_inputHandle, pInputRecord, 1, pEventsRead) != 0) {
          if (pEventsRead.value > 0) {
            _translateAndFire(pInputRecord.ref);
          }
        }
        await Future.delayed(Duration.zero);
      }
    } finally {
      win32.free(pInputRecord);
      win32.free(pEventsRead);
    }
  }

  void _addAnsiSequence(String seq) {
    _controller.add(utf8.encode(seq));
  }

  void _translateAndFire(win32.INPUT_RECORD event) {
    if (event.EventType == MOUSE_EVENT) {
      _translateMouseEvent(event.Event.MouseEvent);
    } else if (event.EventType == KEY_EVENT) {
      _translateKeyEvent(event.Event.KeyEvent);
    }
  }

  /*
    ANSI CSI (Control Sequence Introducer) for extended keys with modifiers
    ┌─────────────────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
    │ Key                     │ Code        │ SHIFT+code  │ CTRL+code   │ ALT+code    │
    ├─────────────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
    │ F1                      │ 0;59        │ 0;84        │ 0;94        │ 0;104       │
    │ F2                      │ 0;60        │ 0;85        │ 0;95        │ 0;105       │
    │ F3                      │ 0;61        │ 0;86        │ 0;96        │ 0;106       │
    │ F4                      │ 0;62        │ 0;87        │ 0;97        │ 0;107       │
    │ F5                      │ 0;63        │ 0;88        │ 0;98        │ 0;108       │
    │ F6                      │ 0;64        │ 0;89        │ 0;99        │ 0;109       │
    │ F7                      │ 0;65        │ 0;90        │ 0;100       │ 0;110       │
    │ F8                      │ 0;66        │ 0;91        │ 0;101       │ 0;111       │
    │ F9                      │ 0;67        │ 0;92        │ 0;102       │ 0;112       │
    │ F10                     │ 0;68        │ 0;93        │ 0;103       │ 0;113       │
    │ F11                     │ 0;133       │ 0;135       │ 0;137       │ 0;139       │
    │ F12                     │ 0;134       │ 0;136       │ 0;138       │ 0;140       │
    ├─────────────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
    │ HOME (num keypad)       │ 0;71        │ 55          │ 0;119       │ --          │
    │ UP ARROW (num keypad)   │ 0;72        │ 56          │ (0;141)     │ --          │
    │ PAGE UP (num keypad)    │ 0;73        │ 57          │ 0;132       │ --          │
    │ LEFT ARROW (num keypad) │ 0;75        │ 52          │ 0;115       │ --          │
    │ RIGHT ARROW (num keypad)│ 0;77        │ 54          │ 0;116       │ --          │
    │ END (num keypad)        │ 0;79        │ 49          │ 0;117       │ --          │
    │ DOWN ARROW (num keypad) │ 0;80        │ 50          │ (0;145)     │ --          │
    │ PAGE DOWN (num keypad)  │ 0;81        │ 51          │ 0;118       │ --          │
    │ INSERT (num keypad)     │ 0;82        │ 48          │ (0;146)     │ --          │
    │ DELETE (num keypad)     │ 0;83        │ 46          │ (0;147)     │ --          │
    ├─────────────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
    │ HOME                    │ (224;71)    │ (224;71)    │ (224;119)   │ (224;151)   │
    │ UP ARROW                │ (224;72)    │ (224;72)    │ (224;141)   │ (224;152)   │
    │ PAGE UP                 │ (224;73)    │ (224;73)    │ (224;132)   │ (224;153)   │
    │ LEFT ARROW              │ (224;75)    │ (224;75)    │ (224;115)   │ (224;155)   │
    │ RIGHT ARROW             │ (224;77)    │ (224;77)    │ (224;116)   │ (224;157)   │
    │ END                     │ (224;79)    │ (224;79)    │ (224;117)   │ (224;159)   │
    │ DOWN ARROW              │ (224;80)    │ (224;80)    │ (224;145)   │ (224;154)   │
    │ PAGE DOWN               │ (224;81)    │ (224;81)    │ (224;118)   │ (224;161)   │
    │ INSERT                  │ (224;82)    │ (224;82)    │ (224;146)   │ (224;162)   │
    │ DELETE                  │ (224;83)    │ (224;83)    │ (224;147)   │ (224;163)   │
    ├─────────────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
    │ PRINT SCREEN            │ --          │ --          │ 0;114       │ --          │
    │ PAUSE/BREAK             │ --          │ --          │ 0;0         │ --          │
    │ BACKSPACE               │ 8           │ 8           │ 127         │ (0)         │
    │ ENTER                   │ 13          │ --          │ 10          │ (0)         │
    │ TAB                     │ 9           │ 0;15        │ (0;148)     │ (0;165)     │
    │ NULL                    │ 0;3         │ --          │ --          │ --          │
    ├─────────────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
    │ A                       │ 97          │ 65          │ 1           │ 0;30        │
    │ B                       │ 98          │ 66          │ 2           │ 0;48        │
    │ C                       │ 99          │ 67          │ 3           │ 0;46        │
    │ D                       │ 100         │ 68          │ 4           │ 0;32        │
    │ E                       │ 101         │ 69          │ 5           │ 0;18        │
    │ F                       │ 102         │ 70          │ 6           │ 0;33        │
    │ G                       │ 103         │ 71          │ 7           │ 0;34        │
    │ H                       │ 104         │ 72          │ 8           │ 0;35        │
    │ I                       │ 105         │ 73          │ 9           │ 0;23        │
    │ J                       │ 106         │ 74          │ 10          │ 0;36        │
    │ K                       │ 107         │ 75          │ 11          │ 0;37        │
    │ L                       │ 108         │ 76          │ 12          │ 0;38        │
    │ M                       │ 109         │ 77          │ 13          │ 0;50        │
    │ N                       │ 110         │ 78          │ 14          │ 0;49        │
    │ O                       │ 111         │ 79          │ 15          │ 0;24        │
    │ P                       │ 112         │ 80          │ 16          │ 0;25        │
    │ Q                       │ 113         │ 81          │ 17          │ 0;16        │
    │ R                       │ 114         │ 82          │ 18          │ 0;19        │
    │ S                       │ 115         │ 83          │ 19          │ 0;31        │
    │ T                       │ 116         │ 84          │ 20          │ 0;20        │
    │ U                       │ 117         │ 85          │ 21          │ 0;22        │
    │ V                       │ 118         │ 86          │ 22          │ 0;47        │
    │ W                       │ 119         │ 87          │ 23          │ 0;17        │
    │ X                       │ 120         │ 88          │ 24          │ 0;45        │
    │ Y                       │ 121         │ 89          │ 25          │ 0;21        │
    │ Z                       │ 122         │ 90          │ 26          │ 0;44        │
    ├─────────────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
    │ 1                       │ 49          │ 33          │ --          │ 0;120       │
    │ 2                       │ 50          │ 64          │ 0           │ 0;121       │
    │ 3                       │ 51          │ 35          │ --          │ 0;122       │
    │ 4                       │ 52          │ 36          │ --          │ 0;123       │
    │ 5                       │ 53          │ 37          │ --          │ 0;124       │
    │ 6                       │ 54          │ 94          │ 30          │ 0;125       │
    │ 7                       │ 55          │ 38          │ --          │ 0;126       │
    │ 8                       │ 56          │ 42          │ --          │ 0;127       │
    │ 9                       │ 57          │ 40          │ --          │ 0;128       │
    │ 0                       │ 48          │ 41          │ --          │ 0;129       │
    │ -                       │ 45          │ 95          │ 31          │ 0;130       │
    │ =                       │ 61          │ 43          │ --          │ 0;131       │
    │ [                       │ 91          │ 123         │ 27          │ 0;26        │
    │ ]                       │ 93          │ 125         │ 29          │ 0;27        │
    │ \                       │ 92          │ 124         │ 28          │ 0;43        │
    │ ;                       │ 59          │ 58          │ --          │ 0;39        │
    │ '                       │ 39          │ 34          │ --          │ 0;40        │
    │ ,                       │ 44          │ 60          │ --          │ 0;51        │
    │ .                       │ 46          │ 62          │ --          │ 0;52        │
    │ /                       │ 47          │ 63          │ --          │ 0;53        │
    │ `                       │ 96          │ 126         │ --          │ (0;41)      │
    ├─────────────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
    │ ENTER (keypad)          │ 13          │ --          │ 10          │ (0;166)     │
    │ / (keypad)              │ 47          │ 47          │ (0;142)     │ (0;74)      │
    │ * (keypad)              │ 42          │ (0;144)     │ (0;78)      │ --          │
    │ - (keypad)              │ 45          │ 45          │ (0;149)     │ (0;164)     │
    │ + (keypad)              │ 43          │ 43          │ (0;150)     │ (0;55)      │
    │ 5 (keypad)              │ (0;76)      │ 53          │ (0;143)     │ --          │
    └─────────────────────────┴─────────────┴─────────────┴─────────────┴─────────────┘
    */

  /// Calculates the ANSI modifier value based on the key state.
  /// ANSI modifiers are 1-based: 1=None, 2=Shift, 3=Alt, 5=Ctrl, etc.
  int _getAnsiModifier(int controlKeyState) {
    int modifier = 1; // Base value for no modifier
    if ((controlKeyState & SHIFT_PRESSED) != 0) {
      modifier += 1;
    }
    if ((controlKeyState & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED)) != 0) {
      modifier += 2;
    }
    if ((controlKeyState & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED)) != 0) {
      modifier += 4;
    }
    return modifier;
  }
  
  void _translateKeyEvent(win32.KEY_EVENT_RECORD keyEvent) {
    if (keyEvent.bKeyDown == 0) return;

    final controlKeyState = keyEvent.dwControlKeyState;
    final virtualKeyCode = keyEvent.wVirtualKeyCode;
    
    // Handle standard Ctrl+[A-Z] combinations which map to ASCII 1-26
    final isCtrl = (controlKeyState & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED)) != 0;
    final isAlt = (controlKeyState & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED)) != 0;
    
    if (isCtrl && !isAlt && virtualKeyCode >= 'A'.codeUnitAt(0) && virtualKeyCode <= 'Z'.codeUnitAt(0)) {
      final charCode = virtualKeyCode - 'A'.codeUnitAt(0) + 1;
      _addAnsiSequence(String.fromCharCode(charCode));
      return;
    }

    final modifier = _getAnsiModifier(controlKeyState);

    // Map of Virtual Key Codes to their ANSI escape character codes.
    // This handles keys that use the '~' suffix format.
    const keyMap = {
      win32.VK_INSERT: 2, win32.VK_DELETE: 3,
      win32.VK_HOME: 1,   win32.VK_END: 4,
      win32.VK_PRIOR: 5,  win32.VK_NEXT: 6, // Page Up, Page Down
      win32.VK_F1: 11,    win32.VK_F2: 12,
      win32.VK_F3: 13,    win32.VK_F4: 14,
      win32.VK_F5: 15,    win32.VK_F6: 17,
      win32.VK_F7: 18,    win32.VK_F8: 19,
      win32.VK_F9: 20,    win32.VK_F10: 21,
      win32.VK_F11: 23,   win32.VK_F12: 24,
    };

    if (keyMap.containsKey(virtualKeyCode)) {
      final code = keyMap[virtualKeyCode]!;
      // Modified keys use the format: ESC [ <keycode> ; <modifier> ~
      if (modifier > 1) {
        _addAnsiSequence('\x1b[${code};${modifier}~');
      } else {
        _addAnsiSequence('\x1b[${code}~');
      }
      return;
    }
    
    // Handles keys that use a letter suffix (e.g., arrows)
    const letterSuffixMap = {
      win32.VK_UP: 'A', win32.VK_DOWN: 'B',
      win32.VK_RIGHT: 'C', win32.VK_LEFT: 'D',
    };

    if (letterSuffixMap.containsKey(virtualKeyCode)) {
      final char = letterSuffixMap[virtualKeyCode]!;
      // Modified arrows use the format: ESC [ 1 ; <modifier> <char>
      if (modifier > 1) {
        _addAnsiSequence('\x1b[1;${modifier}$char');
      } else {
        _addAnsiSequence('\x1b[$char');
      }
      return;
    }

    // Fallback for printable characters and other simple keys
    final charCode = keyEvent.uChar.UnicodeChar;
    if (charCode != 0 && !isCtrl && !isAlt) {
       _addAnsiSequence(String.fromCharCode(charCode));
       return;
    }
    
    // Handle special cases that don't produce a printable character
    switch (virtualKeyCode) {
        case win32.VK_RETURN: _addAnsiSequence('\r'); break;
        case win32.VK_ESCAPE: _addAnsiSequence('\x1b'); break;
        case win32.VK_BACK: _addAnsiSequence('\x7f'); break; // Backspace
        case win32.VK_TAB: _addAnsiSequence('\t'); break;
    }
  }


  void _translateMouseEvent(win32.MOUSE_EVENT_RECORD mouseEvent) {
    final pos = mouseEvent.dwMousePosition;
    final flags = mouseEvent.dwEventFlags;
    final buttonState = mouseEvent.dwButtonState;

    final col = pos.X + 1;
    final row = pos.Y + 1;

    if (flags & win32.MOUSEEVENTF_WHEEL != 0) {
      final isUp = (buttonState >> 16) > 0;
      final button = isUp ? 64 : 65;
      _addAnsiSequence('\x1b[<${button};${col};${row}M');
      return;
    }

    if (flags & win32.MOUSEEVENTF_MOVE != 0) {
      if (buttonState != 0) {
        final button = 32 + _getButtonCode(buttonState);
        _addAnsiSequence('\x1b[<${button};${col};${row}M');
      } else {
        _addAnsiSequence('\x1b[<35;${col};${row}m');
      }
    } else {
      final releasedButton = _lastButtonState & ~buttonState;
      if (releasedButton != 0) {
        final button = _getButtonCode(releasedButton);
        _addAnsiSequence('\x1b[<${button};${col};${row}m');
      }

      final pressedButton = buttonState & ~_lastButtonState;
      if (pressedButton != 0) {
        final button = _getButtonCode(pressedButton);
        _addAnsiSequence('\x1b[<${button};${col};${row}M');
      }
    }

    _lastButtonState = buttonState;
  }
  
  int _getButtonCode(int buttonState) {
    if ((buttonState & FROM_LEFT_1ST_BUTTON_PRESSED) != 0) return 0;
    if ((buttonState & RIGHTMOST_BUTTON_PRESSED) != 0) return 2;
    if ((buttonState & FROM_LEFT_2ND_BUTTON_PRESSED) != 0) return 1;
    return 0;
  }
}
