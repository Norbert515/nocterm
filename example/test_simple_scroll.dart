import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const TestSimpleScroll());
}

class TestSimpleScroll extends StatelessComponent {
  const TestSimpleScroll({super.key});

  @override
  Component build(BuildContext context) {
    return Center(
      child: Container(
        width: 30,
        height: 10,
        decoration: BoxDecoration(border: BoxBorder.all(color: Colors.blue)),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text('Line 1'),
              Text('Line 2'),
              Text('Line 3'),
              Text('Line 4'),
              Text('Line 5'),
              Text('Line 6'),
              Text('Line 7'),
              Text('Line 8'),
              Text('Line 9'),
              Text('Line 10'),
              Text('Line 11'),
              Text('Line 12'),
              Text('Line 13'),
              Text('Line 14'),
              Text('Line 15'),
            ],
          ),
        ),
      ),
    );
  }
}
