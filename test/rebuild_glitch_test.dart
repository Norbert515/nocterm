import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart' hide isEmpty;

void main() {
  group('Rebuild glitch test', () {
    test('conditional widget insertion should preserve correct order', () async {
      await testNocterm(
        'verify rebuild glitch',
        (tester) async {
          print('\n=== Initial render (includeAtStart = false) ===');
          await tester.pumpComponent(HotReloadGlitchTest());
          
          // Initially should only show "Second"
          var initialState = tester.terminalState;
          print('Initial render shows:');
          print(initialState);
          expect(initialState, containsText('Second'));
          expect(initialState, isNot(containsText('First')));
          
          // Wait for the delayed setState
          print('\n=== After 700ms delay (includeAtStart = true) ===');
          await tester.pump(Duration(milliseconds: 800));
          
          var afterDelayState = tester.terminalState;
          print('After setState shows:');
          print(afterDelayState);
          
          // Both should be visible now
          expect(afterDelayState, containsText('First'));
          expect(afterDelayState, containsText('Second'));
          
          // Check the order - "First" should appear BEFORE "Second"
          var terminalText = afterDelayState.getText();
          var lines = terminalText.split('\n');
          int firstIndex = -1;
          int secondIndex = -1;
          
          for (int i = 0; i < lines.length; i++) {
            if (lines[i].contains('First') && firstIndex == -1) {
              firstIndex = i;
            }
            if (lines[i].contains('Second') && secondIndex == -1) {
              secondIndex = i;
            }
          }
          
          print('\n=== Order verification ===');
          print('First appears at line: $firstIndex');
          print('Second appears at line: $secondIndex');
          
          // The bug: First appears AFTER Second (should be before)
          if (firstIndex > secondIndex) {
            print('BUG DETECTED: First ($firstIndex) appears after Second ($secondIndex)');
            print('Expected: First should appear before Second');
          }
          
          expect(firstIndex, lessThan(secondIndex), 
            reason: 'First should appear before Second in the Column');
        },
        debugPrintAfterPump: true,
      );
    });
  });
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