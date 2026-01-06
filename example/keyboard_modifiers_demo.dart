import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const KeyboardModifiersDemo());
}

/// Demo application showing the new keyboard modifier handling
class KeyboardModifiersDemo extends StatefulComponent {
  const KeyboardModifiersDemo({super.key});

  @override
  State<KeyboardModifiersDemo> createState() => _KeyboardModifiersDemoState();
}

class _KeyboardModifiersDemoState extends State<KeyboardModifiersDemo> {
  String _lastKey = 'None';
  String _modifiers = 'None';
  String _character = 'None';
  final List<String> _history = [];

  void _handleKeyEvent(KeyboardEvent event) {
    setState(() {
      _lastKey = event.logicalKey.debugName;
      _modifiers = event.modifiers.toString();
      _character = event.character ?? 'None';

      final entry =
          '${event.modifiers.hasAnyModifier ? '${event.modifiers}+' : ''}${event.logicalKey.debugName}';
      _history.insert(0, entry);
      if (_history.length > 10) {
        _history.removeLast();
      }
    });
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        _handleKeyEvent(event);

        // Exit on Escape or Ctrl+C using the new modifier system
        if (event.logicalKey == LogicalKey.escape ||
            event.matches(LogicalKey.keyC, ctrl: true)) {
          // Signal to close the app
          return false; // Let the binding handle the exit
        }

        return true; // Handle all other keys
      },
      child: Center(
        child: Container(
          width: 60,
          height: 25,
          decoration: BoxDecoration(border: BoxBorder.all(color: Colors.cyan)),
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keyboard Modifiers Demo',
                style: TextStyle(
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Last Key: $_lastKey',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                'Modifiers: $_modifiers',
                style: TextStyle(color: Colors.yellow),
              ),
              Text(
                'Character: $_character',
                style: TextStyle(color: Colors.green),
              ),
              const SizedBox(height: 1),
              const Text('History:', style: TextStyle(color: Colors.gray)),
              ..._history
                  .take(8)
                  .map(
                    (entry) => Text(
                      '  $entry',
                      style: TextStyle(
                        color: Colors.gray,
                        fontWeight: FontWeight.dim,
                      ),
                    ),
                  ),
              const Spacer(),
              const Text(
                'Try: Ctrl+A, Shift+Tab, Alt+X, Arrows',
                style: TextStyle(
                  color: Colors.gray,
                  fontWeight: FontWeight.dim,
                ),
              ),
              const Text(
                'Press Escape or Ctrl+C to exit',
                style: TextStyle(
                  color: Colors.gray,
                  fontWeight: FontWeight.dim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
