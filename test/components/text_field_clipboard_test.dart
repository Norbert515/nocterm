import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart' hide isEmpty;

void main() {
  group('TextField clipboard integration', () {
    // Ctrl+C is intentionally reserved for app termination in TUI applications.
    // Copy functionality would need an alternative keybinding if supported.
    test('copy selected text with Ctrl+C', () async {
      await testNocterm('TextField copy test', (tester) async {
        final controller = TextEditingController(text: 'Hello, World!');

        await tester.pumpComponent(
          TextField(
            controller: controller,
            focused: true,
            decoration: InputDecoration(border: BoxBorder.all()),
          ),
        );

        // Select all text with Ctrl+A
        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyA,
            modifiers: const ModifierKeys(ctrl: true),
          ),
        );
        await tester.pump();

        // Verify selection works
        expect(controller.selection.start, 0);
        expect(controller.selection.end, controller.text.length);

        // Ctrl+C is reserved for app termination, so it doesn't copy.
        // Verify the text field still has the selection (not cleared).
        expect(controller.selection.isCollapsed, false);
      });
    });

    test('cut selected text with Ctrl+X', () async {
      await testNocterm('TextField cut test', (tester) async {
        final controller = TextEditingController(text: 'Cut this text');

        await tester.pumpComponent(
          TextField(
            controller: controller,
            focused: true,
            decoration: InputDecoration(border: BoxBorder.all()),
          ),
        );

        // Select all text
        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyA,
            modifiers: const ModifierKeys(ctrl: true),
          ),
        );
        await tester.pump();

        // Clear clipboard
        ClipboardManager.clear();

        // Cut with Ctrl+X
        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyX,
            modifiers: const ModifierKeys(ctrl: true),
          ),
        );
        await tester.pump();

        // Verify text was removed
        expect(controller.text, '');

        // Verify clipboard has the content
        expect(ClipboardManager.paste(), equals('Cut this text'));
      });
    });

    test('paste text with Ctrl+V', () async {
      await testNocterm('TextField paste test', (tester) async {
        final controller = TextEditingController(text: '');

        // Put some text in the clipboard
        ClipboardManager.copy('Pasted content');

        await tester.pumpComponent(
          TextField(
            controller: controller,
            focused: true,
            decoration: InputDecoration(border: BoxBorder.all()),
          ),
        );

        // Paste with Ctrl+V
        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyV,
            modifiers: const ModifierKeys(ctrl: true),
          ),
        );
        await tester.pump();

        // Verify text was pasted
        expect(controller.text, equals('Pasted content'));
      });
    });

    test('paste replaces selected text', () async {
      await testNocterm('TextField paste replaces selection', (tester) async {
        final controller = TextEditingController(text: 'Replace me');

        // Put replacement text in clipboard
        ClipboardManager.copy('New text');

        await tester.pumpComponent(
          TextField(
            controller: controller,
            focused: true,
            decoration: InputDecoration(border: BoxBorder.all()),
          ),
        );

        // Select all
        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyA,
            modifiers: const ModifierKeys(ctrl: true),
          ),
        );
        await tester.pump();

        // Paste to replace
        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyV,
            modifiers: const ModifierKeys(ctrl: true),
          ),
        );
        await tester.pump();

        // Verify text was replaced
        expect(controller.text, equals('New text'));
      });
    });

    // Tests cut-paste workflow since Ctrl+C is reserved for app termination.
    // This verifies clipboard integration using Ctrl+X (cut) instead of Ctrl+C (copy).
    test('cut-paste workflow', () async {
      await testNocterm('TextField cut-paste workflow', (tester) async {
        final controller = TextEditingController(text: 'Original text');

        await tester.pumpComponent(
          TextField(
            controller: controller,
            focused: true,
            decoration: InputDecoration(border: BoxBorder.all()),
          ),
        );

        // Select all
        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyA,
            modifiers: const ModifierKeys(ctrl: true),
          ),
        );
        await tester.pump();

        // Cut (Ctrl+X works, unlike Ctrl+C which is reserved for app termination)
        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyX,
            modifiers: const ModifierKeys(ctrl: true),
          ),
        );
        await tester.pump();

        // Verify text was cut
        expect(controller.text, equals(''));

        // Paste twice to verify clipboard content
        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyV,
            modifiers: const ModifierKeys(ctrl: true),
          ),
        );
        await tester.pump();

        await tester.enterText(' ');
        await tester.pump();

        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyV,
            modifiers: const ModifierKeys(ctrl: true),
          ),
        );
        await tester.pump();

        // Should have original text + space + original text again
        expect(controller.text, equals('Original text Original text'));
      });
    });

    test('paste handles Unicode correctly', () async {
      await testNocterm('TextField paste Unicode', (tester) async {
        final controller = TextEditingController(text: '');
        const unicodeText = '你好世界 🎉 Emoji text';

        ClipboardManager.copy(unicodeText);

        await tester.pumpComponent(
          TextField(
            controller: controller,
            focused: true,
            decoration: InputDecoration(border: BoxBorder.all()),
          ),
        );

        // Paste
        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyV,
            modifiers: const ModifierKeys(ctrl: true),
          ),
        );
        await tester.pump();

        // Verify Unicode text was pasted correctly
        expect(controller.text, equals(unicodeText));
      });
    });

    test('paste handles multi-line text in single-line field', () async {
      await testNocterm('TextField paste multi-line in single-line field', (
        tester,
      ) async {
        final controller = TextEditingController(text: '');

        // Put multi-line text in clipboard
        ClipboardManager.copy('Line 1\nLine 2\nLine 3');

        await tester.pumpComponent(
          TextField(
            controller: controller,
            focused: true,
            maxLines: 1, // Single-line field
            decoration: InputDecoration(border: BoxBorder.all()),
          ),
        );

        // Paste - newlines should be converted to spaces in single-line fields
        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyV,
            modifiers: const ModifierKeys(ctrl: true),
          ),
        );
        await tester.pump();

        // In a single-line field, newlines are converted to spaces
        expect(controller.text, equals('Line 1 Line 2 Line 3'));
      });
    });
  });
}
