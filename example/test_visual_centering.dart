import 'package:nocterm/nocterm.dart';

void main() {
  runApp(const VisualCenteringDemo());
}

class VisualCenteringDemo extends StatelessComponent {
  const VisualCenteringDemo();

  @override
  Component build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show centering with different emoji positions
          DecoratedBox(
            decoration: BoxDecoration(
              border: BoxBorder.all(
                color: Color.fromRGB(255, 255, 255),
                width: 1,
              ),
            ),
            child: SizedBox(
              width: 45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text('|-------- CENTER --------|'),
                  Text('No emoji here'),
                  Text('✨ Emoji at start'),
                  Text('Emoji at end ✨'),
                  Text('In ✨ middle'),
                  Text('✨ Both ends ✨'),
                  Text('Multiple ✨✨✨ emojis'),
                ],
              ),
            ),
          ),
          SizedBox(height: 2),
          // Compare actual vs expected
          DecoratedBox(
            decoration: BoxDecoration(
              border: BoxBorder.all(
                color: Color.fromRGB(255, 255, 255),
                width: 1,
              ),
            ),
            child: SizedBox(
              width: 45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text('Expected centering:'),
                  Text('✨ Features:'),
                  Text('Should align here ^'),
                  SizedBox(height: 1),
                  Text('But emoji width causes:'),
                  Text('✨ Features:'),
                  Text('   ^ Shifts left by 1'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
