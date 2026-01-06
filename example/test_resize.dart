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

  @override
  void initState() {
    super.initState();
    _updateSize();
    // Poll for size changes
    _sizeCheckTimer = Timer.periodic(Duration(seconds: 1), (_) {
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
          _sizeHistory.add(
            '[${DateTime.now().toString().substring(11, 19)}] ${newSize.width}x${newSize.height}',
          );
          if (_sizeHistory.length > 10) {
            _sizeHistory.removeAt(0);
          }
        });
      }
    }
  }

  @override
  Component build(BuildContext context) {
    final size = _currentSize ?? Size(80.0, 24.0);

    return Container(
      decoration: BoxDecoration(border: BoxBorder.all(color: Colors.blue)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              ' Terminal Resize Test ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 1),
          Text('Current terminal size: ${size.width}x${size.height}'),
          Text('Time: ${DateTime.now().toString().substring(11, 19)}'),
          SizedBox(height: 1),
          Text('Size history:', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._sizeHistory.map((h) => Text(h)),
          SizedBox(height: 1),
          Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('1. Resize your terminal window'),
          Text('2. Size should update automatically'),
          Text('3. Press ESC or Ctrl+C to exit'),
        ],
      ),
    );
  }
}
