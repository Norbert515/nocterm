import 'dart:io';

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/process/pty_controller.dart';

/// Example demonstrating the PTY controller/component pattern.
///
/// This example shows how to use PtyController with TerminalXterm,
/// following the same pattern as Flutter's TextEditingController.
void main() {
  runApp(const PtyControllerDemo());
}

class PtyControllerDemo extends StatefulComponent {
  const PtyControllerDemo({super.key});

  @override
  State<PtyControllerDemo> createState() => _PtyControllerDemoState();
}

class _PtyControllerDemoState extends State<PtyControllerDemo> {
  late final PtyController _controller;
  bool _showStatus = true;

  @override
  void initState() {
    super.initState();

    // Create a PTY controller
    _controller = PtyController(
      command: '/bin/bash',
      onOutput: (data) {
        // You can handle output here if needed
        print('Terminal output: ${data.length} chars');
      },
      onExit: (code) {
        print('Process exited with code: $code');
      },
      onError: (error) {
        print('Error: $error');
      },
    );

    // Listen to controller changes
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    // React to controller state changes
    print('Controller status: ${_controller.status}');
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyboardEvent event) {
    // Handle global shortcuts
    if (event.modifiers.ctrl) {
      switch (event.logicalKey) {
        case LogicalKey.keyC:
          // Ctrl+C: Send interrupt signal
          _controller.kill(ProcessSignal.sigint);
          return true;
        case LogicalKey.keyR:
          // Ctrl+R: Restart terminal
          _controller.restart();
          return true;
        case LogicalKey.keyS:
          // Ctrl+S: Toggle status display
          setState(() {
            _showStatus = !_showStatus;
          });
          return true;
        case LogicalKey.keyQ:
          // Ctrl+Q: Quit application
          shutdownApp();
      }
    }
    return true;
  }

  @override
  Component build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          color: Colors.blue,
          child: Row(
            children: [
              Text(
                'PTY Controller Demo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                'Ctrl+R: Restart | Ctrl+S: Toggle Status | Ctrl+Q: Quit',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),

        // Status bar (optional)
        if (_showStatus) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            color: Colors.black,
            child: Row(
              children: [
                _buildStatusIndicator(),
                SizedBox(width: 2),
                Text(
                  'PID: ${_controller.pid ?? "N/A"}',
                  style: TextStyle(color: Colors.gray),
                ),
                SizedBox(width: 2),
                Text(
                  'Size: ${_controller.columns}×${_controller.rows}',
                  style: TextStyle(color: Colors.gray),
                ),
                if (_controller.exitCode != null) ...[
                  SizedBox(width: 2),
                  Text(
                    'Exit: ${_controller.exitCode}',
                    style: TextStyle(color: Colors.yellow),
                  ),
                ],
              ],
            ),
          ),
        ],

        // Terminal
        Expanded(
          child: Focusable(
            focused: true,
            onKeyEvent: _handleKeyEvent,
            child: TerminalXterm(
              controller: _controller,
              focused: true,
              autoStart: true,
            ),
          ),
        ),

        // Footer
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          color: Colors.grey,
          child: Text(
            'Using PtyController with TerminalXterm - Similar to Flutter\'s TextEditingController pattern',
            style: TextStyle(color: Colors.gray),
          ),
        ),
      ],
    );
  }

  Component _buildStatusIndicator() {
    Color color;
    String text;

    switch (_controller.status) {
      case PtyStatus.notStarted:
        color = Colors.gray;
        text = '○ Not Started';
        break;
      case PtyStatus.starting:
        color = Colors.yellow;
        text = '◐ Starting';
        break;
      case PtyStatus.running:
        color = Colors.green;
        text = '● Running';
        break;
      case PtyStatus.exited:
        color = Colors.red;
        text = '○ Exited';
        break;
      case PtyStatus.error:
        color = Colors.red;
        text = '✗ Error';
        break;
      case PtyStatus.disposed:
        color = Colors.gray;
        text = '○ Disposed';
        break;
    }

    return Text(text, style: TextStyle(color: color));
  }
}
