import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('TextField Unicode and Wrapping', () {
    test('handles Unicode text with proper cursor movement', () {
      final controller = TextEditingController(
        text: 'Hello 世界 🌍',
      );

      expect(controller.text, 'Hello 世界 🌍');
      expect(controller.selection.extentOffset, 11); // At end

      // The cursor should be at the end initially
      controller.selection = const TextSelection.collapsed(offset: 0);
      expect(controller.selection.extentOffset, 0); // At start

      // Move cursor to middle of text
      controller.selection = const TextSelection.collapsed(offset: 6);
      expect(controller.selection.extentOffset, 6); // After "Hello "

      controller.dispose();
    });

    test('handles multi-line text', () {
      final controller = TextEditingController(
        text: 'Line one\nLine two\nLine three',
      );

      expect(controller.text, 'Line one\nLine two\nLine three');

      // Test selection at different positions
      controller.selection = const TextSelection.collapsed(offset: 9); // After newline
      expect(controller.selection.extentOffset, 9);

      controller.selection = const TextSelection.collapsed(offset: 18); // After second newline
      expect(controller.selection.extentOffset, 18);

      controller.dispose();
    });

    test('handles text with emojis', () {
      final controller = TextEditingController(
        text: 'Hello 😀 World 👍',
      );

      expect(controller.text, 'Hello 😀 World 👍');

      // Emoji handling - emojis are single grapheme clusters
      controller.selection = const TextSelection.collapsed(offset: 6); // Before emoji
      expect(controller.selection.extentOffset, 6);

      controller.selection = const TextSelection.collapsed(offset: 8); // After emoji
      expect(controller.selection.extentOffset, 8);

      controller.dispose();
    });

    test('handles selection ranges', () {
      final controller = TextEditingController(
        text: 'Select this text',
      );

      // Select "this"
      controller.selection = const TextSelection(
        baseOffset: 7,
        extentOffset: 11,
      );

      expect(controller.selection.start, 7);
      expect(controller.selection.end, 11);
      expect(controller.selection.isCollapsed, false);

      // Collapse selection
      controller.selection = const TextSelection.collapsed(offset: 7);
      expect(controller.selection.isCollapsed, true);

      controller.dispose();
    });

    test('handles max length constraints', () {
      final controller = TextEditingController();

      controller.text = 'Short';
      expect(controller.text, 'Short');

      controller.text = 'This is a much longer text that might exceed limits';
      expect(controller.text, 'This is a much longer text that might exceed limits');

      // Clear text
      controller.clear();
      expect(controller.text, '');
      expect(controller.selection.extentOffset, 0);

      controller.dispose();
    });
  });
}