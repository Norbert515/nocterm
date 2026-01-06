import 'package:nocterm/src/utils/unicode_width.dart';
import 'package:test/test.dart';

void main() {
  group('Checkmark Unicode Width Issue', () {
    test('checkmark (✓) vs checkmark button (✅) width', () {
      final checkmark = '✓'; // U+2713 - Check mark (should be 1 width)
      final checkmarkButton =
          '✅'; // U+2705 - Check mark button (emoji, 2 width)

      print('Checkmark ✓:');
      print(
        '  Code: U+${checkmark.runes.first.toRadixString(16).toUpperCase()}',
      );
      print('  Current width: ${UnicodeWidth.stringWidth(checkmark)}');
      print('  Expected width: 1');

      print('\nCheckmark Button ✅:');
      print(
        '  Code: U+${checkmarkButton.runes.first.toRadixString(16).toUpperCase()}',
      );
      print('  Current width: ${UnicodeWidth.stringWidth(checkmarkButton)}');
      print('  Expected width: 2');

      // The bug: ✓ (U+2713) is currently being treated as width 2
      // because it falls in the Dingbats range (0x2700-0x27BF)
      // which is incorrectly marked as all emoji
      print(
        '\nBUG: ✓ is currently width ${UnicodeWidth.stringWidth(checkmark)}, but should be 1',
      );

      // This will fail with current implementation
      expect(
        UnicodeWidth.stringWidth(checkmark),
        equals(1),
        reason: 'Check mark (✓) should be width 1, not emoji width',
      );

      // This should pass
      expect(
        UnicodeWidth.stringWidth(checkmarkButton),
        equals(2),
        reason: 'Check mark button (✅) should be width 2 as it is an emoji',
      );
    });

    test('other common checkmark-like symbols', () {
      final symbols = {
        '✓': 1, // U+2713 Check mark
        '✔': 1, // U+2714 Heavy check mark
        '✅': 2, // U+2705 Check mark button (emoji)
        '✗': 1, // U+2717 Ballot X
        '✘': 1, // U+2718 Heavy ballot X
        '✖': 1, // U+2716 Heavy multiplication X
        '❌': 2, // U+274C Cross mark (emoji)
      };

      symbols.forEach((symbol, expectedWidth) {
        final actual = UnicodeWidth.stringWidth(symbol);
        print(
          '$symbol (U+${symbol.runes.first.toRadixString(16).toUpperCase()}): '
          'actual=$actual, expected=$expectedWidth',
        );

        expect(
          actual,
          equals(expectedWidth),
          reason:
              'Symbol $symbol should have width $expectedWidth but has $actual',
        );
      });
    });

    test('reproduce layout issue from clipboard demo', () {
      // From clipboard_demo.dart line 137
      final text1 = '✓ Has content: "test"';
      final text2 = '✗ Empty';

      print('\nLayout test:');
      print('Text 1: "$text1"');
      print('  String length: ${text1.length}');
      print('  Display width: ${UnicodeWidth.stringWidth(text1)}');

      print('\nText 2: "$text2"');
      print('  String length: ${text2.length}');
      print('  Display width: ${UnicodeWidth.stringWidth(text2)}');

      // The checkmark should be 1 width, so:
      // "✓ Has content: "test"" = 1 + 20 = 21
      expect(UnicodeWidth.stringWidth(text1), equals(21));

      // "✗ Empty" = 1 + 6 = 7
      expect(UnicodeWidth.stringWidth(text2), equals(7));
    });
  });
}
