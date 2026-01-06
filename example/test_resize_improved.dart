import 'dart:async';
import 'dart:io';
import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(ResizeTestApp());
}

class ResizeTestApp extends StatefulComponent {
  @override
  State<ResizeTestApp> createState() => _ResizeTestAppState();
}

class _ResizeTestAppState extends State<ResizeTestApp> {
  Size? _currentSize;
  final List<String> _sizeHistory = [];
  Timer? _sizeCheckTimer;
  int _resizeCount = 0;

  @override
  void initState() {
    super.initState();
    _updateSize();
    // Poll for size changes to verify resize events are working
    _sizeCheckTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
      _updateSize();
    });
  }

  @override
  void dispose() {
    _sizeCheckTimer?.cancel();
    super.dispose();
  }

  void _updateSize() {
    if (stdout.hasTerminal) {
      final newSize = Size(
        stdout.terminalColumns.toDouble(),
        stdout.terminalLines.toDouble(),
      );
      if (_currentSize == null ||
          _currentSize!.width != newSize.width ||
          _currentSize!.height != newSize.height) {
        setState(() {
          _currentSize = newSize;
          _resizeCount++;
          final entry =
              '[${DateTime.now().toString().substring(11, 19)}] ${newSize.width.toInt()}x${newSize.height.toInt()} (Resize #$_resizeCount)';
          _sizeHistory.add(entry);
          if (_sizeHistory.length > 8) {
            _sizeHistory.removeAt(0);
          }
        });
      }
    }
  }

  @override
  Component build(BuildContext context) {
    final size = _currentSize ?? Size(80.0, 24.0);
    final width = size.width.toInt();
    final height = size.height.toInt();

    // Create a visual size indicator
    final horizontalBar = '─' * (width - 2);
    final verticalSpace =
        height - 15 - _sizeHistory.length; // Account for content

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top border showing width
        Text('┌$horizontalBar┐', style: TextStyle(color: Colors.blue)),

        // Title
        Container(
          decoration: BoxDecoration(color: Colors.blue),
          child: Text(
            ' Terminal Resize Monitor ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),

        // Current size display
        Text(''),
        Text(
          'Current Size: ${width}x$height',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        Text('Time: ${DateTime.now().toString().substring(11, 19)}'),
        Text('Resize Count: $_resizeCount'),
        Text(''),

        // Size history
        Text(
          'Resize History:',
          style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
        ),
        ..._sizeHistory.map(
          (h) => Text(h, style: TextStyle(color: Colors.cyan)),
        ),

        // Fill vertical space
        ...List.generate(
          verticalSpace > 0 ? verticalSpace : 0,
          (_) => Text(''),
        ),

        // Instructions at bottom
        Text(''),
        Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('• Resize your terminal window'),
        Text('• Size updates should appear immediately'),
        Text('• Press ESC or Ctrl+C to exit'),

        // Bottom border showing width
        Text('└$horizontalBar┘', style: TextStyle(color: Colors.blue)),
      ],
    );
  }
}
