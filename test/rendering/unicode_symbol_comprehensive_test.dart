import 'package:nocterm/src/utils/unicode_width.dart';
import 'package:test/test.dart';

void main() {
  group('Unicode Symbol Width - Comprehensive Test', () {
    test('text symbols (width 1) vs emoji symbols (width 2)', () {
      // Text symbols - should be width 1
      final textSymbols = {
        '✓': 'Check mark',
        '✔': 'Heavy check mark',
        '✗': 'Ballot X',
        '✘': 'Heavy ballot X',
        '✖': 'Heavy multiplication X',
        '⚠': 'Warning sign',
        '☎': 'Telephone',
        '☑': 'Ballot box with check',
        '☒': 'Ballot box with X',
        '★': 'Black star',
        '☆': 'White star',
        '♠': 'Black spade suit',
        '♣': 'Black club suit',
        '♥': 'Black heart suit',
        '♦': 'Black diamond suit',
      };

      // Emoji symbols - should be width 2
      final emojiSymbols = {
        '✅': 'Check mark button (emoji)',
        '❌': 'Cross mark (emoji)',
        '❎': 'Cross mark button (emoji)',
        '✨': 'Sparkles',
        '⭐': 'Star (emoji)',
        '☀': 'Sun',
        '☁': 'Cloud',
        '☂': 'Umbrella',
        '⚡': 'High voltage',
        '⚽': 'Soccer ball',
        '⛄': 'Snowman',
      };

      print('\n=== TEXT SYMBOLS (width 1) ===');
      textSymbols.forEach((symbol, name) {
        final width = UnicodeWidth.stringWidth(symbol);
        final code = symbol.runes.first;
        print(
          '$symbol U+${code.toRadixString(16).toUpperCase().padLeft(4, '0')} '
          'width=$width $name',
        );
        expect(width, equals(1), reason: '$name should be width 1');
      });

      print('\n=== EMOJI SYMBOLS (width 2) ===');
      emojiSymbols.forEach((symbol, name) {
        final width = UnicodeWidth.stringWidth(symbol);
        final code = symbol.runes.first;
        print(
          '$symbol U+${code.toRadixString(16).toUpperCase().padLeft(4, '0')} '
          'width=$width $name',
        );
        expect(width, equals(2), reason: '$name should be width 2');
      });
    });

    test('layout alignment with mixed symbols', () {
      final lines = [
        '✓ Success',
        '✗ Failed',
        '⚠ Warning',
        '✅ Emoji Success',
        '❌ Emoji Failed',
      ];

      print('\n=== LAYOUT TEST ===');
      for (final line in lines) {
        final width = UnicodeWidth.stringWidth(line);
        print('$line (width: $width)');
      }

      // Text symbols should result in same total width
      expect(UnicodeWidth.stringWidth('✓ Success'), equals(9));
      expect(UnicodeWidth.stringWidth('✗ Failed'), equals(8));
      expect(UnicodeWidth.stringWidth('⚠ Warning'), equals(9));

      // Emoji symbols add extra width (emoji is 2, so +1 compared to text symbol)
      expect(UnicodeWidth.stringWidth('✅ Emoji Success'), equals(16));
      expect(UnicodeWidth.stringWidth('❌ Emoji Failed'), equals(15));
    });

    test('demonstrates the fix for layout overflow issues', () {
      // This is the original bug: when ✓ was calculated as width 2,
      // it caused layout overflow in containers

      final containerWidth = 30;
      final text = '✓ Has content: "test"';
      final textWidth = UnicodeWidth.stringWidth(text);

      print('\nContainer width: $containerWidth');
      print('Text: "$text"');
      print('Text width: $textWidth');
      print('Fits in container: ${textWidth <= containerWidth}');

      // With the fix, this should fit (21 <= 30)
      // Before the fix, it was 22 which also fit, but was incorrect
      expect(
        textWidth,
        equals(21),
        reason: 'Text with ✓ symbol should be calculated correctly',
      );
      expect(
        textWidth <= containerWidth,
        isTrue,
        reason: 'Text should fit in container',
      );
    });
  });
}
