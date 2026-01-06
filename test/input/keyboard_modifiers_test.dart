import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/keyboard/keyboard_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Keyboard Modifiers', () {
    late KeyboardParser parser;

    setUp(() {
      parser = KeyboardParser();
    });

    test('ModifierKeys equality and toString', () {
      const mod1 = ModifierKeys(ctrl: true, shift: false);
      const mod2 = ModifierKeys(ctrl: true, shift: false);
      const mod3 = ModifierKeys(ctrl: false, shift: true);

      expect(mod1, equals(mod2));
      expect(mod1, isNot(equals(mod3)));
      expect(mod1.toString(), equals('Ctrl'));
      expect(mod3.toString(), equals('Shift'));

      const mod4 = ModifierKeys(ctrl: true, shift: true, alt: true);
      expect(mod4.toString(), equals('Ctrl+Shift+Alt'));

      const mod5 = ModifierKeys();
      expect(mod5.toString(), equals('none'));
    });

    test('KeyboardEvent matches method', () {
      final event1 = KeyboardEvent(
        logicalKey: LogicalKey.keyA,
        modifiers: const ModifierKeys(ctrl: true),
      );

      expect(event1.matches(LogicalKey.keyA, ctrl: true), isTrue);
      expect(
        event1.matches(LogicalKey.keyA),
        isTrue,
      ); // Not specifying modifiers means any state is OK
      expect(event1.matches(LogicalKey.keyB, ctrl: true), isFalse);
      expect(event1.matches(LogicalKey.keyA, ctrl: false), isFalse);
      expect(event1.matches(LogicalKey.keyA, ctrl: true, shift: false), isTrue);
    });

    test('Parse regular characters', () {
      // Lowercase 'a'
      final eventA = parser.parseBytes([0x61]);
      expect(eventA, isNotNull);
      expect(
        eventA!.logicalKey,
        equals(LogicalKey.keyA),
      ); // Same key for both cases
      expect(eventA.character, equals('a'));
      expect(eventA.modifiers.shift, isFalse);

      // Uppercase 'A' - should detect shift
      parser.clear();
      final eventShiftA = parser.parseBytes([0x41]);
      expect(eventShiftA, isNotNull);
      expect(
        eventShiftA!.logicalKey,
        equals(LogicalKey.keyA),
      ); // Same key for both cases
      expect(eventShiftA.character, equals('A'));
      expect(eventShiftA.modifiers.shift, isTrue);
    });

    test('Parse Ctrl combinations', () {
      // Ctrl+A (0x01)
      final event = parser.parseBytes([0x01]);
      expect(event, isNotNull);
      expect(event!.logicalKey, equals(LogicalKey.keyA));
      expect(event.modifiers.ctrl, isTrue);
      expect(event.modifiers.shift, isFalse);
      expect(event.modifiers.alt, isFalse);
    });

    test('Parse Alt combinations', () {
      // Alt+a (ESC followed by 'a')
      final event = parser.parseBytes([0x1B, 0x61]);
      expect(event, isNotNull);
      expect(event!.logicalKey, equals(LogicalKey.keyA));
      expect(event.character, equals('a'));
      expect(event.modifiers.alt, isTrue);
      expect(event.modifiers.ctrl, isFalse);
      expect(event.modifiers.shift, isFalse);
    });

    test('Parse Shift+Tab', () {
      // Shift+Tab (ESC [ Z)
      final event = parser.parseBytes([0x1B, 0x5B, 0x5A]);
      expect(event, isNotNull);
      expect(event!.logicalKey, equals(LogicalKey.tab));
      expect(event.modifiers.shift, isTrue);
      expect(event.modifiers.ctrl, isFalse);
      expect(event.modifiers.alt, isFalse);
    });

    test('Parse arrow keys with modifiers', () {
      // Regular arrow up
      parser.clear();
      final arrowUp = parser.parseBytes([0x1B, 0x5B, 0x41]);
      expect(arrowUp, isNotNull);
      expect(arrowUp!.logicalKey, equals(LogicalKey.arrowUp));
      expect(arrowUp.modifiers.hasAnyModifier, isFalse);

      // Shift+Arrow Up (ESC [ 1 ; 2 A)
      parser.clear();
      final shiftArrowUp = parser.parseBytes([
        0x1B,
        0x5B,
        0x31,
        0x3B,
        0x32,
        0x41,
      ]);
      expect(shiftArrowUp, isNotNull);
      expect(shiftArrowUp!.logicalKey, equals(LogicalKey.arrowUp));
      expect(shiftArrowUp.modifiers.shift, isTrue);
      expect(shiftArrowUp.modifiers.ctrl, isFalse);

      // Alt+Arrow Up (ESC [ 1 ; 3 A)
      parser.clear();
      final altArrowUp = parser.parseBytes([
        0x1B,
        0x5B,
        0x31,
        0x3B,
        0x33,
        0x41,
      ]);
      expect(altArrowUp, isNotNull);
      expect(altArrowUp!.logicalKey, equals(LogicalKey.arrowUp));
      expect(altArrowUp.modifiers.alt, isTrue);
      expect(altArrowUp.modifiers.shift, isFalse);

      // Ctrl+Arrow Up (ESC [ 1 ; 5 A)
      parser.clear();
      final ctrlArrowUp = parser.parseBytes([
        0x1B,
        0x5B,
        0x31,
        0x3B,
        0x35,
        0x41,
      ]);
      expect(ctrlArrowUp, isNotNull);
      expect(ctrlArrowUp!.logicalKey, equals(LogicalKey.arrowUp));
      expect(ctrlArrowUp.modifiers.ctrl, isTrue);
      expect(ctrlArrowUp.modifiers.shift, isFalse);
    });

    test('Parse function keys', () {
      // F1 (ESC O P)
      parser.clear();
      final f1 = parser.parseBytes([0x1B, 0x4F, 0x50]);
      expect(f1, isNotNull);
      expect(f1!.logicalKey, equals(LogicalKey.f1));
      expect(f1.modifiers.hasAnyModifier, isFalse);

      // F5 (ESC [ 1 5 ~)
      parser.clear();
      final f5 = parser.parseBytes([0x1B, 0x5B, 0x31, 0x35, 0x7E]);
      expect(f5, isNotNull);
      expect(f5!.logicalKey, equals(LogicalKey.f5));
      expect(f5.modifiers.hasAnyModifier, isFalse);
    });

    test('Convenience getters on KeyboardEvent', () {
      final event = KeyboardEvent(
        logicalKey: LogicalKey.keyA,
        modifiers: const ModifierKeys(
          ctrl: true,
          shift: true,
          alt: false,
          meta: false,
        ),
      );

      expect(event.isControlPressed, isTrue);
      expect(event.isShiftPressed, isTrue);
      expect(event.isAltPressed, isFalse);
      expect(event.isMetaPressed, isFalse);
    });

    test('ModifierKeys copyWith', () {
      const original = ModifierKeys(ctrl: true, shift: false);
      final modified = original.copyWith(shift: true);

      expect(original.ctrl, isTrue);
      expect(original.shift, isFalse);
      expect(modified.ctrl, isTrue);
      expect(modified.shift, isTrue);
    });
  });
}
