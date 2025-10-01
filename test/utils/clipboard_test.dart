import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Clipboard', () {
    test('copy encodes text in OSC 52 format', () {
      // This test verifies that copy() attempts to write OSC 52 sequences
      // We can't directly test stdout writes in unit tests, but we can verify
      // the method executes without errors
      expect(() => Clipboard.copy('Hello, World!'), returnsNormally);
    });

    test('copyToPrimary works without errors', () {
      expect(() => Clipboard.copyToPrimary('Selected text'), returnsNormally);
    });

    test('clear works without errors', () {
      expect(() => Clipboard.clear(), returnsNormally);
    });

    test('isSupported returns a boolean', () {
      final supported = Clipboard.isSupported();
      expect(supported, isA<bool>());
    });

    test('getDiagnostics returns diagnostic information', () {
      final diagnostics = Clipboard.getDiagnostics();
      expect(diagnostics, contains('Clipboard Diagnostics'));
      expect(diagnostics, contains('Has Terminal'));
      expect(diagnostics, contains('TERM'));
    });
  });

  group('ClipboardManager', () {
    setUp(() {
      // Clear clipboard before each test
      ClipboardManager.clear();
    });

    test('copy stores text in internal buffer', () {
      ClipboardManager.copy('Test text');
      expect(ClipboardManager.paste(), equals('Test text'));
      expect(ClipboardManager.hasContent(), isTrue);
    });

    test('copyToPrimary stores text in primary buffer', () {
      ClipboardManager.copyToPrimary('Primary text');
      expect(ClipboardManager.pastePrimary(), equals('Primary text'));
      expect(ClipboardManager.hasPrimaryContent(), isTrue);
    });

    test('paste returns null when buffer is empty', () {
      expect(ClipboardManager.paste(), isNull);
      expect(ClipboardManager.hasContent(), isFalse);
    });

    test('clear removes content from both buffers', () {
      ClipboardManager.copy('Clipboard text');
      ClipboardManager.copyToPrimary('Primary text');

      ClipboardManager.clear();

      expect(ClipboardManager.paste(), isNull);
      expect(ClipboardManager.pastePrimary(), isNull);
      expect(ClipboardManager.hasContent(), isFalse);
      expect(ClipboardManager.hasPrimaryContent(), isFalse);
    });

    test('copy replaces previous content', () {
      ClipboardManager.copy('First text');
      ClipboardManager.copy('Second text');

      expect(ClipboardManager.paste(), equals('Second text'));
    });

    test('handles empty string', () {
      ClipboardManager.copy('');
      expect(ClipboardManager.paste(), equals(''));
      expect(ClipboardManager.hasContent(), isFalse); // Empty string = no content
    });

    test('handles Unicode text', () {
      const unicodeText = '你好世界 🎉 Emoji';
      ClipboardManager.copy(unicodeText);
      expect(ClipboardManager.paste(), equals(unicodeText));
    });

    test('handles multi-line text', () {
      const multilineText = 'Line 1\nLine 2\nLine 3';
      ClipboardManager.copy(multilineText);
      expect(ClipboardManager.paste(), equals(multilineText));
    });

    test('maintains separate clipboard and primary buffers', () {
      ClipboardManager.copy('Clipboard content');
      ClipboardManager.copyToPrimary('Primary content');

      expect(ClipboardManager.paste(), equals('Clipboard content'));
      expect(ClipboardManager.pastePrimary(), equals('Primary content'));
    });
  });
}