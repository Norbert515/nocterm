import 'package:nocterm/nocterm.dart';

void main() {
  runApp(const StackDemo());
}

class StackDemo extends StatelessComponent {
  const StackDemo({super.key});

  @override
  Component build(BuildContext context) {
    return Container(
      child: Stack(
        children: [
          // Background container
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: BoxBorder.all(style: BoxBorderStyle.double),
              ),
              child: const Center(child: Text('Background Layer')),
            ),
          ),

          // Positioned at top-left
          Positioned(
            left: 2,
            top: 1,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: BoxBorder.all(),
                color: const Color.fromRGB(100, 100, 200),
              ),
              child: const Text('Top Left'),
            ),
          ),

          // Positioned at bottom-right
          Positioned(
            right: 2,
            bottom: 1,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: BoxBorder.all(style: BoxBorderStyle.rounded),
                color: const Color.fromRGB(200, 100, 100),
              ),
              child: const Text('Bottom Right'),
            ),
          ),

          // Centered with explicit size
          Positioned(
            left: 20,
            top: 8,
            width: 20,
            height: 5,
            child: Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(style: BoxBorderStyle.double),
              ),
              child: const Center(child: Text('Centered')),
            ),
          ),
        ],
      ),
    );
  }
}
