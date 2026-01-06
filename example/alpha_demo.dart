import 'package:nocterm/nocterm.dart';

/// Demonstrates alpha/transparency support in nocterm.
///
/// This example shows:
/// - Creating colors with alpha using Color.fromARGB()
/// - Using withOpacity() to create semi-transparent colors
/// - How colors blend with backgrounds
/// - Layering semi-transparent elements
void main() {
  runApp(
    Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alpha/Transparency Demo',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),

          // Opacity gradient
          Container(
            color: Colors.blue,
            padding: const EdgeInsets.all(1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Opacity Gradient (white on blue):'),
                Text(
                  '100%',
                  style: TextStyle(color: Colors.white.withOpacity(1.0)),
                ),
                Text(
                  ' 80%',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
                Text(
                  ' 60%',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
                Text(
                  ' 40%',
                  style: TextStyle(color: Colors.white.withOpacity(0.4)),
                ),
                Text(
                  ' 20%',
                  style: TextStyle(color: Colors.white.withOpacity(0.2)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 1),

          // Semi-transparent overlay
          SizedBox(
            height: 5,
            child: Stack(
              children: [
                Container(
                  color: Colors.green,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Base Layer Content'),
                      Text('More text here...'),
                      Text('Even more text...'),
                    ],
                  ),
                ),
                Positioned(
                  left: 5,
                  top: 1,
                  child: Container(
                    width: 30,
                    height: 2,
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: Text(
                        'Semi-transparent overlay',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 1),

          // Different alpha values side by side
          Row(
            children: [
              Container(
                width: 15,
                color: Colors.red.withOpacity(1.0),
                child: const Text('100% Red'),
              ),
              Container(
                width: 15,
                color: Colors.red.withOpacity(0.5),
                child: const Text(' 50% Red'),
              ),
            ],
          ),
          const SizedBox(height: 1),

          // Using Color.fromARGB directly
          Container(
            color: const Color.fromARGB(128, 255, 255, 0), // 50% yellow
            child: const Text('Color.fromARGB(128, 255, 255, 0)'),
          ),
          const SizedBox(height: 1),

          // Text with transparent foreground
          Container(
            color: Colors.magenta,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Text transparency on colored background:'),
                Text(
                  'Fully visible',
                  style: TextStyle(color: Colors.white.withOpacity(1.0)),
                ),
                Text(
                  'Faded',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
                Text(
                  'Very faded',
                  style: TextStyle(color: Colors.white.withOpacity(0.2)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
