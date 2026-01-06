import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const SimpleScrollTest());
}

class SimpleScrollTest extends StatefulComponent {
  const SimpleScrollTest({super.key});

  @override
  State<SimpleScrollTest> createState() => _SimpleScrollTestState();
}

class _SimpleScrollTestState extends State<SimpleScrollTest> {
  final scrollController = ScrollController();
  @override
  Component build(BuildContext context) {
    return Center(
      child: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(border: BoxBorder.all(color: Colors.blue)),
        margin: EdgeInsets.all(10),
        child: Scrollbar(
          thumbVisibility: true,
          controller: scrollController,
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                for (int i = 0; i < 50; i++)
                  Text('Line $i: This is scrollable content'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
