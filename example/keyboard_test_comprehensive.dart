import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const KeyboardTestApp());
}

/// Comprehensive keyboard test application
class KeyboardTestApp extends StatefulComponent {
  const KeyboardTestApp({super.key});

  @override
  State<KeyboardTestApp> createState() => _KeyboardTestAppState();
}

class _KeyboardTestAppState extends State<KeyboardTestApp> {
  // Event log
  final List<String> _eventLog = [];

  // Test results
  bool _ctrlAPressed = false;
  bool _ctrlCPressed = false;
  bool _shiftTabPressed = false;
  bool _altXPressed = false;
  bool _shiftArrowPressed = false;
  bool _ctrlArrowPressed = false;
  bool _altArrowPressed = false;

  // Current key info
  String _lastKey = 'None';
  String _lastCharacter = 'None';
  bool _ctrlState = false;
  bool _shiftState = false;
  bool _altState = false;
  bool _metaState = false;

  // Text field for testing
  final _textController = TextEditingController(text: 'Test text field');
  bool _textFieldFocused = false;

  void _handleKeyEvent(KeyboardEvent event) {
    setState(() {
      // Update current key info
      _lastKey = event.logicalKey.debugName;
      _lastCharacter = event.character ?? 'None';
      _ctrlState = event.isControlPressed;
      _shiftState = event.isShiftPressed;
      _altState = event.isAltPressed;
      _metaState = event.isMetaPressed;

      // Build event description
      final modifiers = <String>[];
      if (event.isControlPressed) modifiers.add('Ctrl');
      if (event.isShiftPressed) modifiers.add('Shift');
      if (event.isAltPressed) modifiers.add('Alt');
      if (event.isMetaPressed) modifiers.add('Meta');

      final modifierStr = modifiers.isEmpty ? '' : '${modifiers.join('+')}+';
      final eventStr = '$modifierStr${event.logicalKey.debugName}';

      // Add to log
      _eventLog.insert(0, eventStr);
      if (_eventLog.length > 15) {
        _eventLog.removeLast();
      }

      // Test specific combinations
      if (event.matches(LogicalKey.keyA, ctrl: true)) {
        _ctrlAPressed = true;
      }
      if (event.matches(LogicalKey.keyC, ctrl: true)) {
        _ctrlCPressed = true;
      }
      if (event.matches(LogicalKey.tab, shift: true)) {
        _shiftTabPressed = true;
      }
      if (event.matches(LogicalKey.keyX, alt: true)) {
        _altXPressed = true;
      }

      // Test arrow key combinations
      if (event.logicalKey == LogicalKey.arrowUp ||
          event.logicalKey == LogicalKey.arrowDown ||
          event.logicalKey == LogicalKey.arrowLeft ||
          event.logicalKey == LogicalKey.arrowRight) {
        if (event.isShiftPressed) _shiftArrowPressed = true;
        if (event.isControlPressed) _ctrlArrowPressed = true;
        if (event.isAltPressed) _altArrowPressed = true;
      }
    });
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: !_textFieldFocused,
      onKeyEvent: (event) {
        _handleKeyEvent(event);

        // Exit on Escape or Ctrl+Q
        if (event.logicalKey == LogicalKey.escape ||
            event.matches(LogicalKey.keyQ, ctrl: true)) {
          return false; // Let binding handle exit
        }

        // Switch focus with Tab
        if (event.logicalKey == LogicalKey.tab && !event.isShiftPressed) {
          setState(() {
            _textFieldFocused = !_textFieldFocused;
          });
          return true;
        }

        return true;
      },
      child: Container(
        padding: const EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main content in two columns
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column - Current state and tests
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.gray),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Key State',
                            style: TextStyle(
                              color: Colors.yellow,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text('Last Key: $_lastKey'),
                          Text('Character: $_lastCharacter'),
                          const SizedBox(height: 1),
                          Text(
                            'Modifiers:',
                            style: TextStyle(color: Colors.cyan),
                          ),
                          Text(
                            '  Ctrl:  ${_ctrlState ? "✓" : "✗"}',
                            style: TextStyle(
                              color: _ctrlState ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            '  Shift: ${_shiftState ? "✓" : "✗"}',
                            style: TextStyle(
                              color: _shiftState ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            '  Alt:   ${_altState ? "✓" : "✗"}',
                            style: TextStyle(
                              color: _altState ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            '  Meta:  ${_metaState ? "✓" : "✗"}',
                            style: TextStyle(
                              color: _metaState ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Test Results:',
                            style: TextStyle(
                              color: Colors.yellow,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ctrl+A:      ${_ctrlAPressed ? "✓ PASS" : "⋯ waiting"}',
                            style: TextStyle(
                              color: _ctrlAPressed ? Colors.green : Colors.gray,
                            ),
                          ),
                          Text(
                            'Ctrl+C:      ${_ctrlCPressed ? "✓ PASS" : "⋯ waiting"}',
                            style: TextStyle(
                              color: _ctrlCPressed ? Colors.green : Colors.gray,
                            ),
                          ),
                          Text(
                            'Shift+Tab:   ${_shiftTabPressed ? "✓ PASS" : "⋯ waiting"}',
                            style: TextStyle(
                              color: _shiftTabPressed
                                  ? Colors.green
                                  : Colors.gray,
                            ),
                          ),
                          Text(
                            'Alt+X:       ${_altXPressed ? "✓ PASS" : "⋯ waiting"}',
                            style: TextStyle(
                              color: _altXPressed ? Colors.green : Colors.gray,
                            ),
                          ),
                          Text(
                            'Shift+Arrow: ${_shiftArrowPressed ? "✓ PASS" : "⋯ waiting"}',
                            style: TextStyle(
                              color: _shiftArrowPressed
                                  ? Colors.green
                                  : Colors.gray,
                            ),
                          ),
                          Text(
                            'Ctrl+Arrow:  ${_ctrlArrowPressed ? "✓ PASS" : "⋯ waiting"}',
                            style: TextStyle(
                              color: _ctrlArrowPressed
                                  ? Colors.green
                                  : Colors.gray,
                            ),
                          ),
                          Text(
                            'Alt+Arrow:   ${_altArrowPressed ? "✓ PASS" : "⋯ waiting"}',
                            style: TextStyle(
                              color: _altArrowPressed
                                  ? Colors.green
                                  : Colors.gray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 2),

                  // Right column - Event log and text field
                  Expanded(
                    child: Column(
                      children: [
                        // Event log
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              border: BoxBorder.all(color: Colors.gray),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Event Log:',
                                  style: TextStyle(
                                    color: Colors.yellow,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (final event in _eventLog)
                                        Text(
                                          event,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.dim,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 1),

                        // Text field test
                        Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.gray),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TextField Test:',
                                style: TextStyle(
                                  color: Colors.yellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '(Tab to focus, test Ctrl+A/C/X/V)',
                                style: TextStyle(
                                  color: Colors.gray,
                                  fontWeight: FontWeight.dim,
                                ),
                              ),
                              const SizedBox(height: 1),
                              TextField(
                                controller: _textController,
                                focused: _textFieldFocused,
                                onFocusChange: (focused) {
                                  setState(() {
                                    _textFieldFocused = focused;
                                  });
                                },
                                decoration: InputDecoration(
                                  border: BoxBorder.all(
                                    color: _textFieldFocused
                                        ? Colors.cyan
                                        : Colors.gray,
                                  ),
                                ),
                                width: 30,
                                placeholder: 'Type here...',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
