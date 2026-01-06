import 'package:nocterm/nocterm.dart';

void main() {
  runApp(const StackInteractiveDemo());
}

class StackInteractiveDemo extends StatefulComponent {
  const StackInteractiveDemo({super.key});

  @override
  State<StackInteractiveDemo> createState() => _StackInteractiveDemoState();
}

class _StackInteractiveDemoState extends State<StackInteractiveDemo> {
  int counter = 0;
  bool showOverlay = false;
  String selectedItem = 'None';
  final List<String> items = ['Apple', 'Banana', 'Cherry', 'Date'];

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.keyO) {
          setState(() {
            showOverlay = !showOverlay;
          });
          return true;
        }
        if (event.logicalKey == LogicalKey.arrowUp) {
          setState(() {
            counter++;
          });
          return true;
        }
        if (event.logicalKey == LogicalKey.arrowDown) {
          setState(() {
            if (counter > 0) counter--;
          });
          return true;
        }
        if (event.logicalKey == LogicalKey.digit1) {
          setState(() {
            selectedItem = items[0];
          });
          return true;
        }
        if (event.logicalKey == LogicalKey.digit2) {
          setState(() {
            selectedItem = items[1];
          });
          return true;
        }
        if (event.logicalKey == LogicalKey.digit3) {
          setState(() {
            selectedItem = items[2];
          });
          return true;
        }
        if (event.logicalKey == LogicalKey.digit4) {
          setState(() {
            selectedItem = items[3];
          });
          return true;
        }
        return false;
      },
      child: Stack(
        children: [
          // Base layer with counter and menu
          Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.double),
            ),
            padding: const EdgeInsets.all(2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interactive Stack Demo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text('Counter: $counter'),
                Text('Selected: $selectedItem'),
                const SizedBox(height: 2),
                Text('Controls:', style: TextStyle(color: Colors.cyan)),
                Text('↑/↓ - Change counter'),
                Text('1-4 - Select item'),
                Text('O   - Toggle overlay'),
                const SizedBox(height: 2),
                Text('Items:', style: TextStyle(color: Colors.yellow)),
                for (int i = 0; i < items.length; i++)
                  Text(
                    '  ${i + 1}. ${items[i]}',
                    style: TextStyle(
                      color: items[i] == selectedItem
                          ? Colors.green
                          : Colors.white,
                      fontWeight: items[i] == selectedItem
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ),

          // Floating counter display
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              decoration: BoxDecoration(
                border: BoxBorder.all(style: BoxBorderStyle.rounded),
                color: Color.fromRGB(50, 50, 150),
              ),
              child: Text(
                'Count: $counter',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Optional overlay that can be toggled
          if (showOverlay)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: BoxBorder.all(
                    style: BoxBorderStyle.double,
                    color: Colors.red,
                  ),
                  color: Color.fromRGB(100, 0, 0),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'OVERLAY ACTIVE',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Press O to close',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Current values:',
                        style: TextStyle(color: Colors.yellow),
                      ),
                      Text('Counter: $counter'),
                      Text('Selected: $selectedItem'),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom status bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(color: Color.fromRGB(0, 50, 0)),
              child: Center(
                child: Text(
                  showOverlay
                      ? 'Overlay Mode - Press O to exit'
                      : 'Normal Mode - Press O for overlay',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
