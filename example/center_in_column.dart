import 'package:nocterm/nocterm.dart';

void main() {
  runApp(const CenterInColumn());
}

class CenterInColumn extends StatelessComponent {
  const CenterInColumn({super.key});

  @override
  Component build(BuildContext context) {
    return Column(
      children: [
        Center(child: Text('Hello, World!')),
        Center(child: Text('Hello, World!')),
      ],
    );
  }
}
