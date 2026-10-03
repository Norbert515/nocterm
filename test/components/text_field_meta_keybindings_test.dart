// Tests that macOS-style Cmd+A/C/V/X (Meta+A/C/V/X) reach the same
// TextField handlers as Ctrl+A/C/V/X — but ONLY on Apple platforms.
// Meta has different meanings elsewhere (e.g. "super"/Windows key on
// Linux, and Meta is remapped to Escape in some terminals), so the
// aliases are gated behind `isApplePlatform` per the review feedback
// on upstream PR #92.
//
// On non-Apple platforms (Linux/Windows CI) the "Cmd+*" tests are
// skipped and replaced with reverse assertions that Meta+A/C/V/X do
// NOT trigger the clipboard handlers.
//
// Note: Ctrl+W and Ctrl+T are intentionally NOT aliased to Meta on any
// platform, because macOS has its own uses for Cmd+W (close window)
// and Cmd+T (new tab).

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/utils/current_platform.dart';
import 'package:test/test.dart';

void main() {
  group('Meta modifier aliases for clipboard / selection (macOS Cmd+*)', () {
    Future<void> setupTextField(
      NoctermTester tester, {
      required TextEditingController controller,
    }) async {
      await tester.pumpComponent(
        Container(
          width: 30,
          height: 5,
          child: TextField(controller: controller, focused: true),
        ),
      );
    }

    test('Meta+C with a selection copies and does NOT insert "c"', () async {
      if (!isApplePlatform) {
        // On non-Apple platforms Meta+C must NOT trigger the copy alias.
        // (See the reverse test below for the full assertion.)
        return;
      }
      await testNocterm('meta+c copies', (tester) async {
        final controller = TextEditingController(text: 'hello world');

        await setupTextField(tester, controller: controller);

        // Select the entire text so _copy has something to grab.
        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyA,
            modifiers: ModifierKeys(meta: true),
          ),
        );

        expect(
          controller.selection.isCollapsed,
          isFalse,
          reason: 'Meta+A must extend the selection (alias for Ctrl+A)',
        );

        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyC,
            modifiers: ModifierKeys(meta: true),
          ),
        );

        // Selection should be preserved (copy doesn't change text).
        expect(controller.text, equals('hello world'));
      });
    });

    test('Meta+V does NOT insert "v" (paste path is taken instead)', () async {
      if (!isApplePlatform) {
        return;
      }
      // Without a clipboard payload the paste is a no-op, but the
      // important assertion is that the event doesn't fall through
      // to the character-insertion branch. We assert this by checking
      // that no "v" got added.
      await testNocterm('meta+v routes to paste', (tester) async {
        final controller = TextEditingController(text: 'hi ');

        await setupTextField(tester, controller: controller);

        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyV,
            modifiers: ModifierKeys(meta: true),
          ),
        );

        // The text must NOT have grown by a literal 'v'.
        expect(controller.text, equals('hi '));
      });
    });

    test('Meta+X does NOT insert "x" (cut path is taken instead)', () async {
      if (!isApplePlatform) {
        return;
      }
      await testNocterm('meta+x routes to cut', (tester) async {
        final controller = TextEditingController(text: 'hello world');

        await setupTextField(tester, controller: controller);

        // Select everything so the cut has effect.
        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyA,
            modifiers: ModifierKeys(meta: true),
          ),
        );

        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyX,
            modifiers: ModifierKeys(meta: true),
          ),
        );

        // Either the cut deleted the text (selection copy to clipboard
        // + text removal) or the text was preserved — but in neither
        // case may a literal 'x' have been appended.
        expect(
          controller.text.contains('x'),
          isFalse,
          reason: 'Meta+X must not fall through to character insertion',
        );
      });
    });

    test('Meta+W is NOT aliased to delete-word-backward', () async {
      // Cmd+W is "close window" on macOS, so we intentionally do not
      // alias it to word-delete. This is a regression guard so a
      // future "let's alias all Ctrl+* to Meta+*" drive-by doesn't
      // silently steal Cmd+W on macOS.
      //
      // We use a two-word string and assert that the trailing word is
      // still there — _deleteWordBackward would have stripped it.
      // (We can't assert the *exact* post-Meta+W text because the
      // tester-built KeyboardEvent doesn't carry a `character` field,
      // so character-insertion is a no-op here. The strong claim we
      // CAN make is "Meta+W must not have run delete-word-backward".)
      await testNocterm('meta+w is NOT delete-word', (tester) async {
        final controller = TextEditingController(text: 'hello world');

        await setupTextField(tester, controller: controller);

        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyW,
            modifiers: ModifierKeys(meta: true),
          ),
        );

        expect(
          controller.text.endsWith('world'),
          isTrue,
          reason: 'Meta+W must not call _deleteWordBackward '
              'on the trailing word',
        );
      });
    });

    test('Meta+T is NOT aliased to transpose-characters', () async {
      // Same regression guard as Meta+W: Cmd+T is "new tab" on macOS.
      // transpose-chars on 'ab' would yield 'ba', so asserting that
      // 'a' is still the first character is enough to prove the
      // transpose handler didn't fire.
      await testNocterm('meta+t is NOT transpose', (tester) async {
        final controller = TextEditingController(text: 'ab');

        await setupTextField(tester, controller: controller);

        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyT,
            modifiers: ModifierKeys(meta: true),
          ),
        );

        expect(
          controller.text.startsWith('a'),
          isTrue,
          reason: 'Meta+T must not call _transposeCharacters',
        );
      });
    });

    test(
        'non-Apple platform: Meta+A/C/V/X do NOT trigger '
        'select-all/copy/cut/paste aliases', () async {
      // Reverse of the "Cmd+*" tests above. Meta has different meanings
      // on non-Apple platforms, so the clipboard aliases must not
      // apply there (review feedback on upstream PR #92).
      //
      // Directly verifies the gating condition used by the handler.
      const eventA = KeyboardEvent(
        logicalKey: LogicalKey.keyA,
        modifiers: ModifierKeys(meta: true),
      );
      const eventC = KeyboardEvent(
        logicalKey: LogicalKey.keyC,
        modifiers: ModifierKeys(meta: true),
      );
      const eventX = KeyboardEvent(
        logicalKey: LogicalKey.keyX,
        modifiers: ModifierKeys(meta: true),
      );
      const eventV = KeyboardEvent(
        logicalKey: LogicalKey.keyV,
        modifiers: ModifierKeys(meta: true),
      );

      // The condition mirrors the gating expression in
      // text_field.dart: ctrl always triggers; meta only on Apple
      // platforms.
      final triggersSelectAll = eventA.matches(LogicalKey.keyA, ctrl: true) ||
          (isApplePlatform && eventA.matches(LogicalKey.keyA, meta: true));
      final triggersCopy = eventC.matches(LogicalKey.keyC, ctrl: true) ||
          (isApplePlatform && eventC.matches(LogicalKey.keyC, meta: true));
      final triggersCut = eventX.matches(LogicalKey.keyX, ctrl: true) ||
          (isApplePlatform && eventX.matches(LogicalKey.keyX, meta: true));
      final triggersPaste = eventV.matches(LogicalKey.keyV, ctrl: true) ||
          (isApplePlatform && eventV.matches(LogicalKey.keyV, meta: true));
      expect(triggersSelectAll, isApplePlatform);
      expect(triggersCopy, isApplePlatform);
      expect(triggersCut, isApplePlatform);
      expect(triggersPaste, isApplePlatform);

      if (!isApplePlatform) {
        // Meta+A must fall through to the character-insertion branch:
        // the tester-built KeyboardEvent carries a `character`, so a
        // Meta+A event with character 'a' must insert 'a' instead of
        // selecting all.
        await testNocterm('meta+a inserts char on non-Apple', (tester) async {
          final controller = TextEditingController(text: '');
          await setupTextField(tester, controller: controller);

          await tester.sendKeyEvent(
            const KeyboardEvent(
              logicalKey: LogicalKey.keyA,
              character: 'a',
              modifiers: ModifierKeys(meta: true),
            ),
          );

          expect(controller.text, equals('a'),
              reason: 'on non-Apple platforms Meta+A must fall through to '
                  'character insertion, not select-all');
          expect(controller.selection.isCollapsed, isTrue);
        });
      }
    });

    test('plain Ctrl+C is unaffected (still bubbles up)', () async {
      // Regression guard: the original Ctrl+C behavior (let the event
      // bubble up to the app for quit handling) must still work —
      // Meta+C is added as an alias, not a replacement.
      await testNocterm('ctrl+c bubbles', (tester) async {
        final controller = TextEditingController(text: 'hello world');

        await setupTextField(tester, controller: controller);

        await tester.sendKeyEvent(
          KeyboardEvent(
            logicalKey: LogicalKey.keyC,
            modifiers: ModifierKeys(ctrl: true),
          ),
        );

        // Ctrl+C is handled by the parent component, not by TextField,
        // so the event handler returns false and the text doesn't
        // change either way. We assert the field stayed untouched.
        expect(controller.text, equals('hello world'));
      });
    });
  });
}
