import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/keyboard/keyboard_event.dart';
import 'package:test/test.dart';

void main() {
  group('TextField Vertical Selection', () {
    test('Shift+Up/Down should extend selection in multiline fields', () async {
      await testNocterm(
        'vertical selection',
        (tester) async {
          final controller = TextEditingController(text: 'Line 1\nLine 2\nLine 3');

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              decoration: BoxDecoration(border: BoxBorder.all()),
              child: TextField(
                controller: controller,
                focused: true,
                maxLines: 3,
              ),
            ),
          );

          print('Initial text:');
          print(controller.text);
          print('Initial selection: base=${controller.selection.baseOffset}, extent=${controller.selection.extentOffset}');

          // Move cursor to middle of Line 2 (position after "Line 2")
          for (int i = 0; i < 8; i++) {
            await tester.sendKey(LogicalKey.arrowLeft);
          }

          print('\nAfter positioning cursor:');
          print('Selection: base=${controller.selection.baseOffset}, extent=${controller.selection.extentOffset}');

          // Select upward with Shift+Up
          await tester.sendKeyEvent(KeyboardEvent(
            logicalKey: LogicalKey.arrowUp,
            modifiers: ModifierKeys(shift: true),
          ));

          print('\nAfter Shift+Up:');
          print('Selection: base=${controller.selection.baseOffset}, extent=${controller.selection.extentOffset}');
          if (!controller.selection.isCollapsed) {
            final selected = controller.text.substring(controller.selection.start, controller.selection.end);
            print('Selected text: "${selected.replaceAll('\n', '\\\\n')}"');
          }

          // Select downward with Shift+Down (should extend further)
          await tester.sendKeyEvent(KeyboardEvent(
            logicalKey: LogicalKey.arrowDown,
            modifiers: ModifierKeys(shift: true),
          ));
          await tester.sendKeyEvent(KeyboardEvent(
            logicalKey: LogicalKey.arrowDown,
            modifiers: ModifierKeys(shift: true),
          ));

          print('\nAfter Shift+Down twice:');
          print('Selection: base=${controller.selection.baseOffset}, extent=${controller.selection.extentOffset}');
          if (!controller.selection.isCollapsed) {
            final selected = controller.text.substring(controller.selection.start, controller.selection.end);
            print('Selected text: "${selected.replaceAll('\n', '\\\\n')}"');
          }

          // Verify selection spans multiple lines
          expect(controller.selection.isCollapsed, false);
          expect(controller.selection.start < controller.selection.end, true);

          // The selection should include text from multiple lines
          final selectedText = controller.text.substring(controller.selection.start, controller.selection.end);
          expect(selectedText.contains('\n'), true, reason: 'Selection should span multiple lines');
        },
        debugPrintAfterPump: true,
      );
    });

    test('vertical movement without shift should collapse selection', () async {
      await testNocterm(
        'collapse selection on vertical movement',
        (tester) async {
          final controller = TextEditingController(text: 'First line\nSecond line\nThird line');

          await tester.pumpComponent(
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(border: BoxBorder.all()),
              child: TextField(
                controller: controller,
                focused: true,
                maxLines: 3,
              ),
            ),
          );

          // Select all text
          await tester.sendKeyEvent(KeyboardEvent(
            logicalKey: LogicalKey.keyA,
            modifiers: ModifierKeys(ctrl: true),
          ));

          print('After Ctrl+A:');
          print('Selection: base=${controller.selection.baseOffset}, extent=${controller.selection.extentOffset}');
          expect(controller.selection.isCollapsed, false);

          // Move up without shift - should collapse selection
          await tester.sendKey(LogicalKey.arrowUp);

          print('\nAfter Arrow Up (no shift):');
          print('Selection: base=${controller.selection.baseOffset}, extent=${controller.selection.extentOffset}');
          expect(controller.selection.isCollapsed, true);
        },
        debugPrintAfterPump: true,
      );
    });
  });
}