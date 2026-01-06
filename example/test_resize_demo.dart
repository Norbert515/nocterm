/// Terminal Resize Event Demo
///
/// This demonstrates that terminal resize events are properly handled in the TUI framework.
/// The framework listens for SIGWINCH signals on Unix systems (macOS/Linux) and also
/// polls for size changes as a fallback mechanism.
library;

import 'dart:io';
import 'package:nocterm/nocterm.dart';

void main() async {
  print('Starting Terminal Resize Demo...');
  print(
    'The TUI will automatically detect and respond to terminal resize events.',
  );
  print('Press any key to start...');
  stdin.readLineSync();

  await runApp(TerminalResizeDemo());
}

class TerminalResizeDemo extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    // The framework automatically handles resize events
    // This component will be rebuilt when the terminal is resized

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.toInt();
        final height = constraints.maxHeight.toInt();

        // Create a border that adapts to the terminal size
        final horizontalLine = '═' * (width - 2);
        final verticalPadding = height - 10;

        return Column(
          children: [
            Text('╔$horizontalLine╗', style: TextStyle(color: Colors.cyan)),
            Text(
              '║${_centerText("Terminal Resize Demo", width - 2)}║',
              style: TextStyle(color: Colors.cyan),
            ),
            Text('╠$horizontalLine╣', style: TextStyle(color: Colors.cyan)),
            Text(
              '║${_centerText("Current Size: ${width}x$height", width - 2)}║',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '║${_centerText("", width - 2)}║',
              style: TextStyle(color: Colors.cyan),
            ),
            Text(
              '║${_centerText("Resize your terminal to see the UI adapt!", width - 2)}║',
              style: TextStyle(color: Colors.yellow),
            ),
            Text(
              '║${_centerText("SIGWINCH signal handling is active", width - 2)}║',
              style: TextStyle(color: Colors.magenta),
            ),
            ...List.generate(
              verticalPadding > 0 ? verticalPadding : 0,
              (i) => Text(
                '║${" " * (width - 2)}║',
                style: TextStyle(color: Colors.cyan),
              ),
            ),
            Text('╚$horizontalLine╝', style: TextStyle(color: Colors.cyan)),
          ],
        );
      },
    );
  }

  String _centerText(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    final padding = (width - text.length) ~/ 2;
    final rightPadding = width - text.length - padding;
    return ' ' * padding + text + ' ' * rightPadding;
  }
}
