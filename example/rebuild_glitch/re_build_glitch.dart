import 'package:nocterm/nocterm.dart';

void main() {
  runApp(HotReloadGlitchTest());
}

class HotReloadGlitchTest extends StatefulComponent {
  @override
  State<HotReloadGlitchTest> createState() => _HotReloadGlitchTestState();
}

class _HotReloadGlitchTestState extends State<HotReloadGlitchTest> {
  bool includeAtStart = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 700), () {
      setState(() {
        includeAtStart = true;
      });
    });
  }

  @override
  Component build(BuildContext context) {
    return Column(
      children: [
        if (includeAtStart) WrappedText(text: 'First'),
        Text('Second'),
      ],
    );
  }
}

class WrappedText extends StatelessComponent {
  const WrappedText({required this.text});

  final String text;

  @override
  Component build(BuildContext context) {
    return Text(text);
  }
}
