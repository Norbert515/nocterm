import 'package:nocterm/nocterm.dart';

void main() {
  runApp(const ColumnOrderTest());
}

class ColumnOrderTest extends StatelessComponent {
  const ColumnOrderTest({super.key});

  @override
  Component build(BuildContext context) {
    return Column(
      children: [
        Text('1'),
        SomeWidget(),
        Text('2'),
      ],
    );
  }
}

class SomeWidget extends StatelessComponent {
  const SomeWidget({super.key});

  @override
  Component build(BuildContext context) {
    return Container(
      color: Colors.red,
      child: Text('SomeWidget'),
    );
  }
}
