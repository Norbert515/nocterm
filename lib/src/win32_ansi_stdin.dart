import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:nocterm/nocterm.dart' show TerminalBinding;
import 'package:win32/win32.dart' as win32;
import 'package:ffi/ffi.dart' as ffi;


//~====================================================================================
//^ I have a PR #1009 open on the win32 package to add these missing constants
//~ START OF missing win32 constants that will be included AFTER PR #1009 is merged

// INPUT_RECORD structure `EventType` flags

/// INPUT_RECORD structure `EventType` flag: Event contains key event record.
const KEY_EVENT = 0x0001;

/// INPUT_RECORD structure `EventType` flag: Event contains mouse event record.
const MOUSE_EVENT = 0x0002;

/// INPUT_RECORD structure `EventType` flag: Event contains window change event record.
const WINDOW_BUFFER_SIZE_EVENT = 0x0004;

/// INPUT_RECORD structure `EventType` flag: Event contains menu event record.
const MENU_EVENT = 0x0008;

/// INPUT_RECORD structure `EventType` flag: Event contains focus change.
const FOCUS_EVENT = 0x0010;

// KEY_EVENT_RECORD structure `dwControlKeyState` flags

/// KEY_EVENT_RECORD structure `dwControlKeyState` flag: The right alt key is pressed.
const RIGHT_ALT_PRESSED = 0x0001;

/// KEY_EVENT_RECORD structure `dwControlKeyState` flag: The left alt key is pressed.
const LEFT_ALT_PRESSED = 0x0002;

/// KEY_EVENT_RECORD structure `dwControlKeyState` flag: The right ctrl key is pressed.
const RIGHT_CTRL_PRESSED = 0x0004;

/// KEY_EVENT_RECORD structure `dwControlKeyState` flag: The left ctrl key is pressed.
const LEFT_CTRL_PRESSED = 0x0008;

/// KEY_EVENT_RECORD structure `dwControlKeyState` flag: The shift key is pressed.
const SHIFT_PRESSED = 0x0010;

/// KEY_EVENT_RECORD structure `dwControlKeyState` flag: The numlock light is on.
const NUMLOCK_ON = 0x0020;

/// KEY_EVENT_RECORD structure `dwControlKeyState` flag: The scrolllock light is on.
const SCROLLLOCK_ON = 0x0040;

/// KEY_EVENT_RECORD structure `dwControlKeyState` flag: The capslock light is on.
const CAPSLOCK_ON = 0x0080;

/// KEY_EVENT_RECORD structure `dwControlKeyState` flag: The key is enhanced.
/// Enhanced keys for the IBM® 101- and 102-key keyboards are the INS, DEL, HOME, END,
/// PAGE UP, PAGE DOWN, and direction keys in the clusters to the left of the keypad;
/// and the divide (/) and ENTER keys in the keypad.
const ENHANCED_KEY = 0x0100;

// MOUSE_EVENT_RECORD structure `dwButtonState` flags

/// MOUSE_EVENT_RECORD structure `dwButtonState` flag: First mouse button from left depressed.
const FROM_LEFT_1ST_BUTTON_PRESSED = 0x0001;

/// MOUSE_EVENT_RECORD structure `dwButtonState` flag: Rightmost mouse button depressed.
const RIGHTMOST_BUTTON_PRESSED = 0x0002;

/// MOUSE_EVENT_RECORD structure `dwButtonState` flag: Second mouse button from left depressed.
const FROM_LEFT_2ND_BUTTON_PRESSED = 0x0004;

/// MOUSE_EVENT_RECORD structure `dwButtonState` flag: Third mouse button from left depressed.
const FROM_LEFT_3RD_BUTTON_PRESSED = 0x0008;

/// MOUSE_EVENT_RECORD structure `dwButtonState` flag: Fourth mouse button from left depressed.
const FROM_LEFT_4TH_BUTTON_PRESSED = 0x0010;

/// MOUSE_EVENT_RECORD structure `dwButtonState` flag: Mouse wheel rolled up or tilted right (`dwEventFlags` member will hold `MOUSE_WHEELED` or `MOUSE_HWHEELED` flag)
const MOUSED_WHEELED_UP_OR_RIGHT = 0x00800000;

/// MOUSE_EVENT_RECORD structure `dwButtonState` flag: Mouse wheel rolled down or tilted left (`dwEventFlags` member will hold `MOUSE_WHEELED` or `MOUSE_HWHEELED` flag)
const MOUSE_WHEELED_DOWN_OR_LEFT = 0xff800000;

// MOUSE_EVENT_RECORD structure `dwEventFlags` flags

/// MOUSE_EVENT_RECORD structure `dwEventFlags` flag: Mouse moved.
const MOUSE_MOVED = 0x0001;

/// MOUSE_EVENT_RECORD structure `dwEventFlags` flag: Double click.
const DOUBLE_CLICK = 0x0002;

/// MOUSE_EVENT_RECORD structure `dwEventFlags` flag: Mouse wheel rolled.
const MOUSE_WHEELED = 0x0004;

/// MOUSE_EVENT_RECORD structure `dwEventFlags` flag: Mouse wheel horizontal tilt.
const MOUSE_HWHEELED = 0x0008;

// CHAR_INFO structure `Attributes` flags

/// CHAR_INFO structure `Attributes` flag: text color contains blue.
const FOREGROUND_BLUE = 0x0001;

/// CHAR_INFO structure `Attributes` flag: text color contains green.
const FOREGROUND_GREEN = 0x0002;

/// CHAR_INFO structure `Attributes` flag: text color contains red.
const FOREGROUND_RED = 0x0004;

/// CHAR_INFO structure `Attributes` flag: text color is intensified.
const FOREGROUND_INTENSITY = 0x0008;

/// CHAR_INFO structure `Attributes` flag: background color contains blue.
const BACKGROUND_BLUE = 0x0010;

/// CHAR_INFO structure `Attributes` flag: background color contains green.
const BACKGROUND_GREEN = 0x0020;

/// CHAR_INFO structure `Attributes` flag: background color contains red.
const BACKGROUND_RED = 0x0040;

/// CHAR_INFO structure `Attributes` flag: background color is intensified.
const BACKGROUND_INTENSITY = 0x0080;

/// CHAR_INFO structure `Attributes` flag: Leading Byte of DBCS (Double Byte Character Set)
const COMMON_LVB_LEADING_BYTE    = 0x0100;

/// CHAR_INFO structure `Attributes` flag: Trailing Byte of DBCS (Double Byte Character Set)
const COMMON_LVB_TRAILING_BYTE   = 0x0200;

/// CHAR_INFO structure `Attributes` flag: DBCS (Double Byte Character Set): Grid attribute: top horizontal.
const COMMON_LVB_GRID_HORIZONTAL = 0x0400;

/// CHAR_INFO structure `Attributes` flag: DBCS (Double Byte Character Set): Grid attribute: left vertical.
const COMMON_LVB_GRID_LVERTICAL  = 0x0800;

/// CHAR_INFO structure `Attributes` flag: DBCS (Double Byte Character Set): Grid attribute: right vertical.
const COMMON_LVB_GRID_RVERTICAL  = 0x1000;

/// CHAR_INFO structure `Attributes` flag: DBCS (Double Byte Character Set): Reverse fore/back ground attribute.
const COMMON_LVB_REVERSE_VIDEO   = 0x4000;

/// CHAR_INFO structure `Attributes` flag: DBCS (Double Byte Character Set): Underscore.
const COMMON_LVB_UNDERSCORE      = 0x8000;

/// CHAR_INFO structure `Attributes` flag: SBCS (Single Byte Character Set) or DBCS (Double Byte Character Set) flag.
const COMMON_LVB_SBCSDBCS = 0x0300;

// CONSOLE_SELECTION_INFO structure `dwFlags` flags

/// CONSOLE_SELECTION_INFO structure `dwFlags` flag: No selection.
const CONSOLE_NO_SELECTION          = 0x0000;

/// CONSOLE_SELECTION_INFO structure `dwFlags` flag: Selection has begun.
const CONSOLE_SELECTION_IN_PROGRESS = 0x0001;

/// CONSOLE_SELECTION_INFO structure `dwFlags` flag: Non-null select rectangle.
const CONSOLE_SELECTION_NOT_EMPTY   = 0x0002;

/// CONSOLE_SELECTION_INFO structure `dwFlags` flag: Selecting with mouse.
const CONSOLE_MOUSE_SELECTION       = 0x0004;

/// CONSOLE_SELECTION_INFO structure `dwFlags` flag: Mouse is down.
const CONSOLE_MOUSE_DOWN            = 0x0008;

// PHANDLER_ROUTINE callback function `dwCtrlType` parameter flags

/// PHANDLER_ROUTINE callback function `dwCtrlType` parameter flag: A CTRL+C signal was received,
/// either from keyboard input or from a signal generated by the `GenerateConsoleCtrlEvent` function.
const CTRL_C_EVENT = 0;

/// PHANDLER_ROUTINE callback function `dwCtrlType` parameter flag: A CTRL+BREAK signal was received,
/// either from keyboard input or from a signal generated by `GenerateConsoleCtrlEvent`.
const CTRL_BREAK_EVENT = 1;

/// PHANDLER_ROUTINE callback function `dwCtrlType` parameter flag: A signal that the system sends
/// to all processes attached to a console when the user closes the console (either by clicking Close
/// on the console window's window menu, or by clicking the End Task button command from Task Manager).
const CTRL_CLOSE_EVENT = 2;

/// PHANDLER_ROUTINE callback function `dwCtrlType` parameter flag: A signal that the system sends
/// to all console processes when a user is logging off. This signal does not indicate which user
/// is logging off, so no assumptions can be made.
/// 
/// Note that this signal is received only by services. Interactive applications are terminated at logoff,
/// so they are not present when the system sends this signal.
const CTRL_LOGOFF_EVENT = 5;

/// PHANDLER_ROUTINE callback function `dwCtrlType` parameter flag: A signal that the system sends
/// when the system is shutting down. Interactive applications are not present by the time the system
/// sends this signal, therefore it can be received only be services in this situation. Services also have
/// their own notification mechanism for shutdown events. For more information, see `LphandlerFunction` handler.
const CTRL_SHUTDOWN_EVENT = 6;


//~ END OF missing win32 constants that will be included AFTER PR #1009 is merged
//~====================================================================================




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

    TerminalBinding.instance.logSink?.writeln('_translateAndFire() event.EventType=${event.EventType}');

    if (event.EventType == MOUSE_EVENT) {
      _translateMouseEvent(event.Event.MouseEvent);
    } else if (event.EventType == KEY_EVENT) {
      _translateKeyEvent(event.Event.KeyEvent);
    } else if (event.EventType == WINDOW_BUFFER_SIZE_EVENT) {
      // Handle window resize if needed
      final windowBufferSizeRecord = event.Event.WindowBufferSizeEvent;
      TerminalBinding.instance.logSink?.writeln('UNHANDLED event.EventType == WINDOW_BUFFER_SIZE_EVENT  windowBufferSizeRecord.dwSize=${windowBufferSizeRecord.dwSize}');
    } else if (event.EventType == MENU_EVENT) {
      // Handle menu event if needed
      final menuEventRecord = event.Event.MenuEvent;
      TerminalBinding.instance.logSink?.writeln('UNHANDLED event.EventType == MENU_EVENT  menuEventRecord.dwCommandId=${menuEventRecord.dwCommandId}');
    } else if (event.EventType == FOCUS_EVENT) {
      // Handle focus event if needed
      final focusEventRecord = event.Event.FocusEvent;
      TerminalBinding.instance.logSink?.writeln('UNHANDLED event.EventType == FOCUS_EVENT  focusEventRecord.bSetFocus=${focusEventRecord.bSetFocus}');
    }
  }

  /*
 =================================================================================
 | ASCII Table
 | =================================================================================
 | Represents the 7-bit ASCII (American Standard Code for Information Interchange).
 | It includes control characters (0-31), printable characters (32-126), and DEL (127).
 |
 | Char | Dec | Hex   ||  Char | Dec | Hex
 | -----|-----|------ || -----|-----|------
 | NUL  |   0 | 0x00  ||  @    |  64 | 0x40
 | SOH  |   1 | 0x01  ||  A    |  65 | 0x41
 | STX  |   2 | 0x02  ||  B    |  66 | 0x42
 | ETX  |   3 | 0x03  ||  C    |  67 | 0x43
 | EOT  |   4 | 0x04  ||  D    |  68 | 0x44
 | ENQ  |   5 | 0x05  ||  E    |  69 | 0x45
 | ACK  |   6 | 0x06  ||  F    |  70 | 0x46
 | BEL  |   7 | 0x07  ||  G    |  71 | 0x47
 | BS   |   8 | 0x08  ||  H    |  72 | 0x48
 | HT   |   9 | 0x09  ||  I    |  73 | 0x49
 | LF   |  10 | 0x0A  ||  J    |  74 | 0x4A
 | VT   |  11 | 0x0B  ||  K    |  75 | 0x4B
 | FF   |  12 | 0x0C  ||  L    |  76 | 0x4C
 | CR   |  13 | 0x0D  ||  M    |  77 | 0x4D
 | SO   |  14 | 0x0E  ||  N    |  78 | 0x4E
 | SI   |  15 | 0x0F  ||  O    |  79 | 0x4F
 | DLE  |  16 | 0x10  ||  P    |  80 | 0x50
 | DC1  |  17 | 0x11  ||  Q    |  81 | 0x51
 | DC2  |  18 | 0x12  ||  R    |  82 | 0x52
 | DC3  |  19 | 0x13  ||  S    |  83 | 0x53
 | DC4  |  20 | 0x14  ||  T    |  84 | 0x54
 | NAK  |  21 | 0x15  ||  U    |  85 | 0x55
 | SYN  |  22 | 0x16  ||  V    |  86 | 0x56
 | ETB  |  23 | 0x17  ||  W    |  87 | 0x57
 | CAN  |  24 | 0x18  ||  X    |  88 | 0x58
 | EM   |  25 | 0x19  ||  Y    |  89 | 0x59
 | SUB  |  26 | 0x1A  ||  Z    |  90 | 0x5A
 | ESC  |  27 | 0x1B  ||  [    |  91 | 0x5B
 | FS   |  28 | 0x1C  ||  \    |  92 | 0x5C
 | GS   |  29 | 0x1D  ||  ]    |  93 | 0x5D
 | RS   |  30 | 0x1E  ||  ^    |  94 | 0x5E
 | US   |  31 | 0x1F  ||  _    |  95 | 0x5F
 | SP   |  32 | 0x20  ||  `    |  96 | 0x60
 | !    |  33 | 0x21  ||  a    |  97 | 0x61
 | "    |  34 | 0x22  ||  b    |  98 | 0x62
 | #    |  35 | 0x23  ||  c    |  99 | 0x63
 | $    |  36 | 0x24  ||  d    | 100 | 0x64
 | %    |  37 | 0x25  ||  e    | 101 | 0x65
 | &    |  38 | 0x26  ||  f    | 102 | 0x66
 | '    |  39 | 0x27  ||  g    | 103 | 0x67
 | (    |  40 | 0x28  ||  h    | 104 | 0x68
 | )    |  41 | 0x29  ||  i    | 105 | 0x69
 | *    |  42 | 0x2A  ||  j    | 106 | 0x6A
 | +    |  43 | 0x2B  ||  k    | 107 | 0x6B
 | ,    |  44 | 0x2C  ||  l    | 108 | 0x6C
 | -    |  45 | 0x2D  ||  m    | 109 | 0x6D
 | .    |  46 | 0x2E  ||  n    | 110 | 0x6E
 | /    |  47 | 0x2F  ||  o    | 111 | 0x6F
 | 0    |  48 | 0x30  ||  p    | 112 | 0x70
 | 1    |  49 | 0x31  ||  q    | 113 | 0x71
 | 2    |  50 | 0x32  ||  r    | 114 | 0x72
 | 3    |  51 | 0x33  ||  s    | 115 | 0x73
 | 4    |  52 | 0x34  ||  t    | 116 | 0x74
 | 5    |  53 | 0x35  ||  u    | 117 | 0x75
 | 6    |  54 | 0x36  ||  v    | 118 | 0x76
 | 7    |  55 | 0x37  ||  w    | 119 | 0x77
 | 8    |  56 | 0x38  ||  x    | 120 | 0x78
 | 9    |  57 | 0x39  ||  y    | 121 | 0x79
 | :    |  58 | 0x3A  ||  z    | 122 | 0x7A
 | ;    |  59 | 0x3B  ||  {    | 123 | 0x7B
 | <    |  60 | 0x3C  ||  |    | 124 | 0x7C
 | =    |  61 | 0x3D  ||  }    | 125 | 0x7D
 | >    |  62 | 0x3E  ||  ~    | 126 | 0x7E
 | ?    |  63 | 0x3F  ||  DEL  | 127 | 0x7F
 |===========================================
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
    
    TerminalBinding.instance.logSink?.writeln('_translateKeyEvent()  KeyEvent: vKey=$virtualKeyCode char=${keyEvent.uChar.UnicodeChar} ctrl=$controlKeyState (isCtrl=$isCtrl isAlt=$isAlt)');

    if (isCtrl && !isAlt && virtualKeyCode >= 'A'.codeUnitAt(0) && virtualKeyCode <= 'Z'.codeUnitAt(0)) {
      final charCode = virtualKeyCode - 'A'.codeUnitAt(0) + 1;

      TerminalBinding.instance.logSink?.writeln(' isCtrl && !isAlt virtualKeyCode>=A <=Z: RETURNING charCode=$charCode');

      _addAnsiSequence(String.fromCharCode(charCode));
      return;
    }

    final modifier = _getAnsiModifier(controlKeyState);

    TerminalBinding.instance.logSink?.writeln('_getAnsiModifier(controlKeyState) returned modifier = $modifier');

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

      TerminalBinding.instance.logSink?.writeln('keyMap has virtualKeyCode MAPPED code=$code   modifier=$modifier');

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

      TerminalBinding.instance.logSink?.writeln('letterSuffixMap has virtualKeyCode MAPPED char=$char   modifier=$modifier');

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
    final eventFlags = mouseEvent.dwEventFlags;
    final buttonState = mouseEvent.dwButtonState;

    final col = pos.X + 1;
    final row = pos.Y + 1;

    TerminalBinding.instance.logSink?.writeln('_translateMouseEvent()  MouseEvent: pos=($col,$row) flags=$eventFlags buttonState=${buttonState.toHexString(32)} lastButtonState=${_lastButtonState.toHexString(32)}');

    if ((eventFlags & MOUSE_WHEELED) != 0) { // mouse wheel event roll up/down event
      // buttons 4 and 5, changed to 0 and 1, then add 64 for wheel up/down
      // Wheel mice may return buttons 4 and 5. Those buttons are represented by the same event codes as buttons 1 and 2
      // respectively, except that 64 is added to the event code. Release events for the wheel buttons are not reported.
      // By default, the wheel mouse events (buttons 4 and 5) are translated to scroll−back and scroll−forw actions, respectively. 
      final isDown = (buttonState & MOUSE_WHEELED_DOWN_OR_LEFT) == MOUSE_WHEELED_DOWN_OR_LEFT;
      final button = isDown ? 65 : 64;

      TerminalBinding.instance.logSink?.writeln('VERTICAL wheel event detected: isDown=$isDown button=$button');

      _addAnsiSequence('\x1b[<${button};${col};${row}M');
      return;
    } else if ((eventFlags & MOUSE_HWHEELED) != 0) { // horizontal mouse wheel tilt left/right
      final isLeft = (buttonState & MOUSE_WHEELED_DOWN_OR_LEFT) == MOUSE_WHEELED_DOWN_OR_LEFT;
      // Xterm says horizontal mouse wheel - button 7 (left) and button 6 (right)
      // and then changed to 2 and 3, then add 64 for wheel right/left
      // (https://stackoverflow.com/questions/46627983/what-is-the-correct-xterm-ansi-sequence-for-mouse-wheel-and-or-scroll-prefera )
      final button = isLeft ? 67 : 66;

      TerminalBinding.instance.logSink?.writeln('HORIZONTAL wheel event detected: isLeft=$isLeft button=$button');

      _addAnsiSequence('\x1b[<${button};${col};${row}M');
      return;
    }

    if (eventFlags & MOUSE_MOVED != 0) {
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
