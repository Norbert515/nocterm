import 'package:nocterm/src/utils/unicode_width.dart';
import 'package:test/test.dart';

void main() {
  test('warning symbol width', () {
    final warning = '⚠';
    final warningCode = warning.runes.first;

    print('Warning symbol: $warning');
    print('  Codepoint: U+${warningCode.toRadixString(16).toUpperCase()}');
    print('  Current width: ${UnicodeWidth.stringWidth(warning)}');
    print('  Expected width: 1 (text symbol, not emoji)');

    // ⚠ (U+26A0) is in the Miscellaneous Symbols range (0x2600-0x26FF)
    // It's currently being treated as emoji (width 2)
    // but it should be width 1
    expect(
      UnicodeWidth.stringWidth(warning),
      equals(1),
      reason: 'Warning symbol ⚠ should be width 1',
    );
  });

  test('various symbols in Miscellaneous Symbols range', () {
    final symbols = {
      '⚠': 1, // U+26A0 Warning sign (text symbol)
      '☀': 2, // U+2600 Sun (emoji)
      '☁': 2, // U+2601 Cloud (emoji)
      '☂': 2, // U+2602 Umbrella (emoji presentation by default)
      '☎': 1, // U+260E Telephone (text symbol)
      '☑': 1, // U+2611 Ballot box with check (text symbol)
      '☒': 1, // U+2612 Ballot box with X (text symbol)
      '★': 1, // U+2605 Black star (text symbol)
      '☆': 1, // U+2606 White star (text symbol)
      '♠': 1, // U+2660 Black spade suit (text symbol)
      '♣': 1, // U+2663 Black club suit (text symbol)
      '♥': 1, // U+2665 Black heart suit (text symbol)
      '♦': 1, // U+2666 Black diamond suit (text symbol)
    };

    symbols.forEach((symbol, expectedWidth) {
      final actual = UnicodeWidth.stringWidth(symbol);
      final code = symbol.runes.first;
      print(
        '$symbol (U+${code.toRadixString(16).toUpperCase()}): '
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
}
