import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const CursorStylesDemo());
}

class CursorStylesDemo extends StatefulComponent {
  const CursorStylesDemo({super.key});

  @override
  State<CursorStylesDemo> createState() => _CursorStylesDemoState();
}

class _CursorStylesDemoState extends State<CursorStylesDemo> {
  final _textController = TextEditingController();
  CursorStyle _currentStyle = CursorStyle.block;
  Color _cursorColor = Colors.white;
  Duration? _cursorBlinkRate = const Duration(milliseconds: 800);
  int _focusedFieldIndex = 0;
  static const int _totalFields = 4; // 3 demo fields + 1 interactive field

  final Map<CursorStyle, String> _styleDescriptions = {
    CursorStyle.block: 'Filled block cursor (traditional terminal style)',
    CursorStyle.underline: 'Underline cursor (shows text with underline)',
    CursorStyle.blockOutline: 'Outlined block cursor (inverted colors)',
  };

  final List<Color> _availableColors = [
    Colors.white,
    Colors.cyan,
    Colors.green,
    Colors.yellow,
    Colors.magenta,
    Colors.red,
    Colors.blue,
  ];

  @override
  void initState() {
    super.initState();
    _textController.text = 'Type here to test cursor';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _cycleCursorStyle() {
    setState(() {
      final styles = CursorStyle.values;
      final currentIndex = styles.indexOf(_currentStyle);
      _currentStyle = styles[(currentIndex + 1) % styles.length];
    });
  }

  void _cycleCursorColor() {
    setState(() {
      final currentIndex = _availableColors.indexOf(_cursorColor);
      _cursorColor =
          _availableColors[(currentIndex + 1) % _availableColors.length];
    });
  }

  void _toggleBlinking() {
    setState(() {
      if (_cursorBlinkRate == null) {
        _cursorBlinkRate = const Duration(milliseconds: 800);
      } else {
        _cursorBlinkRate = null;
      }
    });
  }

  void _handleTabNavigation({bool reverse = false}) {
    setState(() {
      if (reverse) {
        _focusedFieldIndex =
            (_focusedFieldIndex - 1 + _totalFields) % _totalFields;
      } else {
        _focusedFieldIndex = (_focusedFieldIndex + 1) % _totalFields;
      }
    });
  }

  bool _handleGlobalKey(KeyboardEvent event) {
    final key = event.logicalKey;

    if (key == LogicalKey.tab && !event.isShiftPressed) {
      _handleTabNavigation(reverse: false);
      return true;
    } else if (key == LogicalKey.tab && event.isShiftPressed) {
      _handleTabNavigation(reverse: true);
      return true;
    } else if (event.matches(LogicalKey.keyS, ctrl: true)) {
      _cycleCursorStyle();
      return true;
    } else if (event.matches(LogicalKey.keyC, ctrl: true)) {
      _cycleCursorColor();
      return true;
    } else if (event.matches(LogicalKey.keyB, ctrl: true)) {
      _toggleBlinking();
      return true;
    }
    return false;
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: _handleGlobalKey,
      child: Container(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'TextField Cursor Styles Demo',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
            const SizedBox(height: 1),

            // Instructions
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.gray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Controls:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                    ),
                  ),
                  Text('• Tab/Shift+Tab: Navigate fields'),
                  Text('• Ctrl+S: Change cursor style'),
                  Text('• Ctrl+C: Change cursor color'),
                  Text('• Ctrl+B: Toggle blinking on/off'),
                  Text('• Type to test cursor behavior'),
                ],
              ),
            ),
            const SizedBox(height: 2),

            // Current settings display
            Text(
              'Current Style: ${_currentStyle.name}',
              style: TextStyle(color: Colors.green),
            ),
            Text(
              _styleDescriptions[_currentStyle]!,
              style: TextStyle(color: Colors.gray),
            ),
            Text(
              'Current Color: ${_getColorName(_cursorColor)}',
              style: TextStyle(color: _cursorColor),
            ),
            Text(
              'Blinking: ${_cursorBlinkRate == null ? "OFF (static)" : "ON (${_cursorBlinkRate!.inMilliseconds}ms)"}',
              style: TextStyle(color: Colors.cyan),
            ),
            const SizedBox(height: 2),

            // Interactive test field
            Text(
              'Interactive Field (focused: ${_focusedFieldIndex == 0}):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _textController,
              focused: _focusedFieldIndex == 0,
              cursorStyle: _currentStyle,
              cursorColor: _cursorColor,
              cursorBlinkRate: _cursorBlinkRate,
              width: 40,
              placeholder: 'Type to test cursor...',
              decoration: InputDecoration(
                border: BoxBorder.all(color: Colors.gray),
                focusedBorder: BoxBorder.all(color: Colors.green),
                contentPadding: const EdgeInsets.symmetric(horizontal: 1),
              ),
            ),
            const SizedBox(height: 2),

            // Demo fields showing all styles
            Text(
              'All Cursor Styles:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(height: 1),

            // Block cursor
            Row(
              children: [
                SizedBox(
                  width: 15,
                  child: Text('Block:', style: TextStyle(color: Colors.gray)),
                ),
                TextField(
                  controller: TextEditingController(text: 'Block cursor'),
                  focused: _focusedFieldIndex == 1,
                  cursorStyle: CursorStyle.block,
                  cursorColor: Colors.white,
                  width: 25,
                  cursorBlinkRate: _cursorBlinkRate,
                  decoration: InputDecoration(
                    border: BoxBorder.all(color: Colors.gray),
                    focusedBorder: BoxBorder.all(color: Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),

            // Underline cursor
            Row(
              children: [
                SizedBox(
                  width: 15,
                  child: Text(
                    'Underline:',
                    style: TextStyle(color: Colors.gray),
                  ),
                ),
                TextField(
                  controller: TextEditingController(text: 'Underline cursor'),
                  focused: _focusedFieldIndex == 2,
                  cursorStyle: CursorStyle.underline,
                  cursorColor: Colors.cyan,
                  width: 25,
                  cursorBlinkRate: _cursorBlinkRate,
                  decoration: InputDecoration(
                    border: BoxBorder.all(color: Colors.gray),
                    focusedBorder: BoxBorder.all(color: Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),

            // Block outline cursor
            Row(
              children: [
                SizedBox(
                  width: 15,
                  child: Text('Outline:', style: TextStyle(color: Colors.gray)),
                ),
                TextField(
                  controller: TextEditingController(text: 'Outline cursor'),
                  focused: _focusedFieldIndex == 3,
                  cursorStyle: CursorStyle.blockOutline,
                  cursorColor: Colors.red,
                  width: 25,
                  cursorBlinkRate: _cursorBlinkRate,
                  decoration: InputDecoration(
                    border: BoxBorder.all(color: Colors.gray),
                    focusedBorder: BoxBorder.all(color: Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text('Press Escape to exit', style: TextStyle(color: Colors.gray)),
          ],
        ),
      ),
    );
  }

  String _getColorName(Color color) {
    if (color == Colors.white) return 'White';
    if (color == Colors.cyan) return 'Cyan';
    if (color == Colors.green) return 'Green';
    if (color == Colors.yellow) return 'Yellow';
    if (color == Colors.magenta) return 'Magenta';
    if (color == Colors.red) return 'Red';
    if (color == Colors.blue) return 'Blue';
    return 'Custom';
  }
}
