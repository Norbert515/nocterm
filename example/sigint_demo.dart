import 'dart:async';
import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const SigintDemo());
}

/// Demo application showing custom Ctrl+C handling with "press twice to quit" pattern.
///
/// This example demonstrates:
/// - Intercepting Ctrl+C (SIGINT) before default exit
/// - Implementing a confirmation pattern (press twice to quit)
/// - Visual feedback showing current state
/// - Auto-reset timer that clears warning after inactivity
/// - Using shutdownApp() API for safe exit
class SigintDemo extends StatefulComponent {
  const SigintDemo({super.key});

  @override
  State<SigintDemo> createState() => _SigintDemoState();
}

class _SigintDemoState extends State<SigintDemo> {
  int _ctrlCCount = 0;
  String _status = 'Ready';
  String _lastKey = 'None';
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  bool _handleKeyEvent(KeyboardEvent event) {
    // Cancel any existing reset timer on any key press
    _resetTimer?.cancel();

    if (event.matches(LogicalKey.keyC, ctrl: true)) {
      setState(() {
        _ctrlCCount++;
        _lastKey = 'Ctrl+C';

        if (_ctrlCCount == 1) {
          _status = 'Warning';
          // Auto-reset after 3 seconds
          _resetTimer = Timer(const Duration(seconds: 3), () {
            setState(() {
              _ctrlCCount = 0;
              _status = 'Ready';
              _lastKey = '(timer reset)';
            });
          });
        } else if (_ctrlCCount >= 2) {
          _status = 'Exiting';
          // Use shutdownApp for safe exit with cleanup
          shutdownApp();
        }
      });
      return true; // Handled - prevent default behavior
    } else if (event.logicalKey == LogicalKey.keyQ) {
      // Direct quit with 'q' - bypass confirmation
      shutdownApp();
      return true;
    } else {
      // Reset counter on any other key
      setState(() {
        _ctrlCCount = 0;
        _status = 'Ready';
        _lastKey = event.character ?? event.logicalKey.debugName;
      });
      return false;
    }
  }

  Color _getStatusColor() {
    switch (_status) {
      case 'Warning':
        return Colors.yellow;
      case 'Exiting':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String _getStatusIcon() {
    switch (_status) {
      case 'Warning':
        return '⚠';
      case 'Exiting':
        return '✕';
      default:
        return '✓';
    }
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        return _handleKeyEvent(event);
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
              // Title
              Text(
                'Custom Ctrl+C Handler Demo',
                style: TextStyle(
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),

              // Description
              const Text(
                'This demo shows how to intercept Ctrl+C',
                style: TextStyle(color: Colors.gray),
              ),
              const Text(
                'before it exits the application.',
                style: TextStyle(color: Colors.gray),
              ),
              const SizedBox(height: 1),

              // Status display
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1F2937),
                  border: BoxBorder.all(color: Color(0xFF374151)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                child: Row(
                  children: [
                    Text('Status: ', style: TextStyle(color: Colors.white)),
                    Text(
                      _getStatusIcon(),
                      style: TextStyle(color: _getStatusColor()),
                    ),
                    const SizedBox(width: 1),
                    Text(
                      _status,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 1),

              // Instructions
              Text(
                'Instructions:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '  • Press Ctrl+C once to see warning',
                style: TextStyle(color: Colors.gray),
              ),
              Text(
                '  • Press Ctrl+C twice to quit',
                style: TextStyle(color: Colors.gray),
              ),
              Text(
                '  • Press q to quit immediately',
                style: TextStyle(color: Colors.gray),
              ),
              Text(
                '  • Warning auto-resets after 3 seconds',
                style: TextStyle(color: Colors.gray),
              ),
              const SizedBox(height: 1),

              // Counter and last key
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Ctrl+C Count: ',
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        _ctrlCCount.toString(),
                        style: TextStyle(
                          color: _ctrlCCount > 0 ? Colors.yellow : Colors.gray,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Last Key: ', style: TextStyle(color: Colors.white)),
                      Text(_lastKey, style: TextStyle(color: Colors.cyan)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
