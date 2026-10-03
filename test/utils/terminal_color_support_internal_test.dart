import 'package:nocterm/src/utils/terminal_color_support_internal.dart';
import 'package:test/test.dart';

void main() {
  group('detectTruecolorFromEnv', () {
    test('NOCTERM_TRUECOLOR overrides to true', () {
      expect(
        detectTruecolorFromEnv({'NOCTERM_TRUECOLOR': '1'}),
        isTrue,
      );
      expect(
        detectTruecolorFromEnv({'NOCTERM_TRUECOLOR': 'true'}),
        isTrue,
      );
    });

    test('NOCTERM_TRUECOLOR overrides to false', () {
      expect(
        detectTruecolorFromEnv({'NOCTERM_TRUECOLOR': '0'}),
        isFalse,
      );
      expect(
        detectTruecolorFromEnv({'NOCTERM_TRUECOLOR': 'off'}),
        isFalse,
      );
    });

    test('COLORTERM enables truecolor', () {
      expect(
        detectTruecolorFromEnv({'COLORTERM': 'truecolor'}),
        isTrue,
      );
      expect(
        detectTruecolorFromEnv({'COLORTERM': '24bit'}),
        isTrue,
      );
    });

    test('TERM enables truecolor', () {
      expect(
        detectTruecolorFromEnv({'TERM': 'xterm-truecolor'}),
        isTrue,
      );
      expect(
        detectTruecolorFromEnv({'TERM': 'screen-24bit'}),
        isTrue,
      );
    });

    test('WT_SESSION enables truecolor (Windows Terminal)', () {
      // Windows Terminal supports 24-bit color but does not set COLORTERM.
      expect(
        detectTruecolorFromEnv({'WT_SESSION': '{a1b2c3d4-...}'}),
        isTrue,
      );
      // An empty WT_SESSION should not count.
      expect(
        detectTruecolorFromEnv({'WT_SESSION': ''}),
        isFalse,
      );
    });

    test('defaults to false when no signals are present', () {
      expect(detectTruecolorFromEnv({}), isFalse);
      expect(detectTruecolorFromEnv({'TERM': 'xterm-256color'}), isFalse);
    });
  });
}
