import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

/// A helper widget for testing that provides setState functionality
class StatefulBuilder extends StatefulComponent {
  const StatefulBuilder({super.key, required this.builder});

  final Component Function(BuildContext, StateSetter) builder;

  @override
  State<StatefulBuilder> createState() => _StatefulBuilderState();
}

class _StatefulBuilderState extends State<StatefulBuilder> {
  @override
  Component build(BuildContext context) {
    return component.builder(context, setState);
  }
}

/// Simple test component that displays two pieces of text
class TwoTexts extends StatelessComponent {
  const TwoTexts({required this.text1, required this.text2});

  final String text1;
  final String text2;

  @override
  Component build(BuildContext context) {
    return Column(children: [Text(text1), Text(text2)]);
  }
}

void main() {
  group('Theme showcase content update', () {
    test(
      'Text widget updates when string changes via StatefulBuilder',
      () async {
        await testNocterm('text updates on setState', (tester) async {
          String textValue = 'Initial Text';
          late void Function() updateText;

          await tester.pumpComponent(
            StatefulBuilder(
              builder: (context, setState) {
                updateText = () {
                  setState(() {
                    textValue = 'Updated Text';
                  });
                };
                return Text(textValue);
              },
            ),
          );

          print('Initial state:');
          expect(tester.terminalState, containsText('Initial Text'));

          // Trigger the update
          updateText();
          await tester.pump();

          print('After update:');
          expect(tester.terminalState, containsText('Updated Text'));
        }, debugPrintAfterPump: true);
      },
    );

    test('theme name updates when index changes', () async {
      await testNocterm('theme name updates', (tester) async {
        const themes = ['Dark (Default)', 'Light', 'Nord'];
        int currentIndex = 0;
        late void Function() nextTheme;

        await tester.pumpComponent(
          StatefulBuilder(
            builder: (context, setState) {
              nextTheme = () {
                setState(() {
                  currentIndex = (currentIndex + 1) % themes.length;
                });
              };

              final themeName = themes[currentIndex];
              return TuiTheme(
                data: TuiThemeData.dark,
                child: Column(
                  children: [
                    Text('Theme: $themeName'),
                    Text('Index: $currentIndex'),
                  ],
                ),
              );
            },
          ),
        );

        print('Initial - should show Dark:');
        expect(tester.terminalState, containsText('Theme: Dark (Default)'));
        expect(tester.terminalState, containsText('Index: 0'));

        // Switch to next theme
        nextTheme();
        await tester.pump();

        print('After first switch - should show Light:');
        expect(tester.terminalState, containsText('Theme: Light'));
        expect(tester.terminalState, containsText('Index: 1'));

        // Switch again
        nextTheme();
        await tester.pump();

        print('After second switch - should show Nord:');
        expect(tester.terminalState, containsText('Theme: Nord'));
        expect(tester.terminalState, containsText('Index: 2'));
      }, debugPrintAfterPump: true);
    });

    test('TwoTexts component updates when props change', () async {
      await testNocterm('TwoTexts updates', (tester) async {
        String t1 = 'First';
        String t2 = 'Second';
        late void Function() updateTexts;

        await tester.pumpComponent(
          StatefulBuilder(
            builder: (context, setState) {
              updateTexts = () {
                setState(() {
                  t1 = 'Updated First';
                  t2 = 'Updated Second';
                });
              };
              return TwoTexts(text1: t1, text2: t2);
            },
          ),
        );

        print('Initial:');
        expect(tester.terminalState, containsText('First'));
        expect(tester.terminalState, containsText('Second'));

        updateTexts();
        await tester.pump();

        print('After update:');
        expect(tester.terminalState, containsText('Updated First'));
        expect(tester.terminalState, containsText('Updated Second'));
      }, debugPrintAfterPump: true);
    });

    test('Column with direct Text children updates', () async {
      await testNocterm('Column direct Text updates', (tester) async {
        String textValue = 'Initial';
        late void Function() updateText;

        await tester.pumpComponent(
          StatefulBuilder(
            builder: (context, setState) {
              updateText = () {
                setState(() {
                  textValue = 'Changed';
                });
              };
              // Direct Column with Text - no intermediate StatelessComponent
              return Column(children: [Text(textValue)]);
            },
          ),
        );

        print('Initial:');
        expect(tester.terminalState, containsText('Initial'));

        updateText();
        await tester.pump();

        print('After update:');
        expect(tester.terminalState, containsText('Changed'));
      }, debugPrintAfterPump: true);
    });

    test('TuiTheme wrapper prevents Column text updates', () async {
      await testNocterm('TuiTheme blocks updates', (tester) async {
        String textValue = 'Before';
        late void Function() updateText;

        await tester.pumpComponent(
          StatefulBuilder(
            builder: (context, setState) {
              updateText = () {
                setState(() {
                  textValue = 'After';
                });
              };
              // Same structure as theme showcase: TuiTheme -> Column -> Text
              return TuiTheme(
                data: TuiThemeData.dark,
                child: Column(children: [Text(textValue)]),
              );
            },
          ),
        );

        print('Initial:');
        expect(tester.terminalState, containsText('Before'));

        updateText();
        await tester.pump();

        print('After update (should say After):');
        expect(tester.terminalState, containsText('After'));
      }, debugPrintAfterPump: true);
    });
  });
}
