import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const MouseScrollTest());
}

class MouseScrollTest extends StatelessComponent {
  const MouseScrollTest({super.key});
  
  @override
  Component build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 3,
          width: double.infinity,
          decoration: BoxDecoration(
            border: BoxBorder.all(color: Colors.cyan),
          ),
          child: Center(
            child: Text(
              'Mouse Scroll Test - Use mouse wheel or trackpad to scroll',
              style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < 100; i++)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      'Line ${i.toString().padLeft(3, '0')}: This is scrollable content. Use your mouse wheel or trackpad to scroll!',
                      style: TextStyle(
                        color: i % 5 == 0 ? Colors.green : Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          height: 2,
          decoration: BoxDecoration(
            border: BoxBorder(top: BorderSide(color: Colors.gray)),
          ),
          child: Text(
            'ESC to exit | Mouse wheel/trackpad to scroll | Arrow keys also work',
            style: TextStyle(color: Colors.gray),
          ),
        ),
      ],
    );
  }
}