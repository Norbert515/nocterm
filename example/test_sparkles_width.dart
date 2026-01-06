import 'package:nocterm/src/utils/unicode_width.dart';

void main() {
  // Test the sparkles emoji specifically
  final sparkles = '✨';
  final sparklesCode = sparkles.runes.first;

  print('Sparkles emoji (✨) analysis:');
  print('  Unicode: U+${sparklesCode.toRadixString(16).toUpperCase()}');
  print('  Decimal: $sparklesCode');
  print('  Our width calculation: ${UnicodeWidth.runeWidth(sparklesCode)}');

  // Check our emoji detection
  print('\nChecking detection logic:');
  print(
    '  Is in range 0x2600-0x26FF? ${sparklesCode >= 0x2600 && sparklesCode <= 0x26FF}',
  );
  print(
    '  Is in range 0x2700-0x27BF? ${sparklesCode >= 0x2700 && sparklesCode <= 0x27BF}',
  );
  print('  Specific check for 0x2728? ${sparklesCode == 0x2728}');

  // Test other similar characters
  print('\nOther character widths:');
  final tests = [
    '⭐', // Star
    '💫', // Dizzy
    '🌟', // Glowing star
    '☀', // Sun
    '☁', // Cloud
    'A', // Regular ASCII
    '中', // CJK
  ];

  for (final char in tests) {
    final code = char.runes.first;
    final width = UnicodeWidth.runeWidth(code);
    print(
      '  "$char" (U+${code.toRadixString(16).toUpperCase().padLeft(4, '0')}): width = $width',
    );
  }
}
