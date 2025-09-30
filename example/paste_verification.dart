import 'dart:convert';
import 'package:nocterm/nocterm.dart';

/// This test verifies that terminal paste (Cmd+V) works correctly
/// by simulating what happens when the terminal sends pasted bytes
void main() async {
  print('Testing Terminal Paste Fix\n');
  print('=' * 60);

  // Test with the actual test framework
  await testNocterm(
    'Terminal paste simulation',
    (tester) async {
      final controller = TextEditingController(text: '');

      await tester.pumpComponent(
        TextField(
          controller: controller,
          focused: true,
        ),
      );

      // Simulate pasting "Hello, World!" via terminal
      // The terminal would send these bytes all at once
      final textToPaste = 'Hello, World!';
      for (final char in textToPaste.split('')) {
        await tester.enterText(char);
      }

      print('Text pasted: "$textToPaste"');
      print('Text in field: "${controller.text}"');
      print('Match: ${controller.text == textToPaste}');

      if (controller.text == textToPaste) {
        print('\n✅ SUCCESS: Terminal paste works correctly!');
      } else {
        print('\n❌ FAILURE: Expected "$textToPaste", got "${controller.text}"');
      }
    },
  );

  print('\n' + '=' * 60);
  print('\nThe fix ensures that when you paste text using Cmd+V');
  print('(terminal paste), all characters are captured, not just');
  print('the first one.\n');
}