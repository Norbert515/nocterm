import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/keyboard/keyboard_event.dart';
import 'package:nocterm/nocterm_test.dart';
import 'package:test/test.dart';

void main() {
  group('TextField Selection', () {
    test('selection should be visible when using Shift+Arrow keys', () async {
      await testNocterm(
        'text selection rendering',
        (tester) async {
          final controller = TextEditingController(text: 'Hello World');

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              decoration: BoxDecoration(border: BoxBorder.all()),
              child: TextField(
                controller: controller,
                focused: true,
                selectionColor: Colors.blue, // Explicitly set selection color
                cursorColor: Colors.green,
                style: TextStyle(color: Colors.white),
              ),
            ),
          );

          print('Initial state with cursor at end:');
          print('Controller text: "${controller.text}"');
          print('Selection: base=${controller.selection.baseOffset}, extent=${controller.selection.extentOffset}');

          // Move cursor to beginning
          for (int i = 0; i < 11; i++) {
            await tester.sendKey(LogicalKey.arrowLeft);
          }

          print('\nAfter moving to beginning:');
          print('Selection: base=${controller.selection.baseOffset}, extent=${controller.selection.extentOffset}');

          // Select "Hello" using Shift+Right
          for (int i = 0; i < 5; i++) {
            await tester.sendKeyEvent(KeyboardEvent(
              logicalKey: LogicalKey.arrowRight,
              modifiers: ModifierKeys(shift: true),
            ));
            print('After Shift+Right ${i+1}: base=${controller.selection.baseOffset}, extent=${controller.selection.extentOffset}');
          }

          print('\nFinal selection state:');
          print('Selection start: ${controller.selection.start}');
          print('Selection end: ${controller.selection.end}');
          print('Is collapsed: ${controller.selection.isCollapsed}');

          // Check that selection is not collapsed
          expect(controller.selection.isCollapsed, false);
          expect(controller.selection.start, 0);
          expect(controller.selection.end, 5);
        },
        debugPrintAfterPump: true,
      );
    });

    test('Ctrl+A should select all text', () async {
      await testNocterm(
        'select all functionality',
        (tester) async {
          final controller = TextEditingController(text: 'Test selection');

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 3,
              decoration: BoxDecoration(border: BoxBorder.all()),
              child: TextField(
                controller: controller,
                focused: true,
                selectionColor: Colors.cyan,
                cursorColor: Colors.yellow,
              ),
            ),
          );

          print('Initial state:');
          print('Text: "${controller.text}"');
          print('Selection: base=${controller.selection.baseOffset}, extent=${controller.selection.extentOffset}');

          // Select all with Ctrl+A
          await tester.sendKeyEvent(KeyboardEvent(
            logicalKey: LogicalKey.keyA,
            modifiers: ModifierKeys(ctrl: true),
          ));

          print('\nAfter Ctrl+A:');
          print('Selection: base=${controller.selection.baseOffset}, extent=${controller.selection.extentOffset}');
          print('Selected text: "${controller.text.substring(controller.selection.start, controller.selection.end)}"');

          expect(controller.selection.start, 0);
          expect(controller.selection.end, controller.text.length);
        },
        debugPrintAfterPump: true,
      );
    });

    test('typing should replace selected text', () async {
      await testNocterm(
        'replace selection with typed text',
        (tester) async {
          final controller = TextEditingController(text: 'Replace this text');

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 3,
              decoration: BoxDecoration(border: BoxBorder.all()),
              child: TextField(
                controller: controller,
                focused: true,
                selectionColor: Colors.magenta,
              ),
            ),
          );

          print('Initial text: "${controller.text}"');

          // Select "this"
          for (int i = 0; i < 5; i++) {
            await tester.sendKey(LogicalKey.arrowLeft);
          }
          for (int i = 0; i < 4; i++) {
            await tester.sendKeyEvent(KeyboardEvent(
              logicalKey: LogicalKey.arrowLeft,
              modifiers: ModifierKeys(shift: true),
            ));
          }

          print('After selection:');
          print('Selected: "${controller.text.substring(controller.selection.start, controller.selection.end)}"');

          // Type "that"
          await tester.enterText('that');

          print('After typing "that": "${controller.text}"');

          expect(controller.text, 'Replace that text');
        },
        debugPrintAfterPump: true,
      );
    });

    test('visual selection highlighting', () async {
      await testNocterm(
        'check selection background color',
        (tester) async {
          final controller = TextEditingController(text: 'ABCDEFGHIJ');

          await tester.pumpComponent(
            Container(
              width: 20,
              height: 3,
              decoration: BoxDecoration(border: BoxBorder.all()),
              padding: EdgeInsets.all(1),
              child: TextField(
                controller: controller,
                focused: true,
                selectionColor: Colors.blue,
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white, backgroundColor: Colors.black),
              ),
            ),
          );

          print('Initial state - no selection:');
          await tester.pump();

          // Move to start and select first 5 characters
          for (int i = 0; i < 10; i++) {
            await tester.sendKey(LogicalKey.arrowLeft);
          }

          print('\nSelecting first 5 characters:');
          for (int i = 0; i < 5; i++) {
            await tester.sendKeyEvent(KeyboardEvent(
              logicalKey: LogicalKey.arrowRight,
              modifiers: ModifierKeys(shift: true),
            ));
          }

          print('Selection: start=${controller.selection.start}, end=${controller.selection.end}');
          print('Selected text: "${controller.text.substring(controller.selection.start, controller.selection.end)}"');
        },
        debugPrintAfterPump: true,
      );
    });
  });
}