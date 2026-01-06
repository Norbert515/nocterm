import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/keyboard/keyboard_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Keyboard Edge Cases', () {
    late KeyboardParser parser;

    setUp(() {
      parser = KeyboardParser();
    });

    test('Multiple bytes parsed in sequence', () {
      // Test that parser handles incomplete sequences correctly
      parser.clear();

      // Single ESC press returns ESC key immediately
      var event = parser.parseBytes([0x1B]);
      expect(event, isNotNull);
      expect(event!.logicalKey, equals(LogicalKey.escape));

      // Alt+a sequence sent all at once
      parser.clear();
      event = parser.parseBytes([0x1B, 0x61]);
      expect(event, isNotNull);
      expect(event!.logicalKey, equals(LogicalKey.keyA));
      expect(event.modifiers.alt, isTrue);
    });

    test('Special characters with modifiers', () {
      // Test Tab
      parser.clear();
      final tab = parser.parseBytes([0x09]);
      expect(tab!.logicalKey, equals(LogicalKey.tab));
      expect(tab.modifiers.hasAnyModifier, isFalse);

      // Test Enter
      parser.clear();
      final enter = parser.parseBytes([0x0D]);
      expect(enter!.logicalKey, equals(LogicalKey.enter));
      expect(enter.modifiers.hasAnyModifier, isFalse);

      // Test Backspace
      parser.clear();
      final backspace = parser.parseBytes([0x7F]);
      expect(backspace!.logicalKey, equals(LogicalKey.backspace));
      expect(backspace.modifiers.hasAnyModifier, isFalse);
    });

    test('Ctrl+Letter edge cases', () {
      // Ctrl+M (0x0D) is same as Enter
      parser.clear();
      final ctrlM = parser.parseBytes([0x0D]);
      expect(ctrlM!.logicalKey, equals(LogicalKey.enter));
      // Note: This is treated as Enter, not Ctrl+M

      // Ctrl+I (0x09) is same as Tab
      parser.clear();
      final ctrlI = parser.parseBytes([0x09]);
      expect(ctrlI!.logicalKey, equals(LogicalKey.tab));
      // Note: This is treated as Tab, not Ctrl+I

      // Ctrl+H (0x08) is treated as Backspace in terminals
      parser.clear();
      final ctrlH = parser.parseBytes([0x08]);
      expect(ctrlH!.logicalKey, equals(LogicalKey.backspace));
      expect(ctrlH.modifiers.ctrl, isFalse); // Treated as backspace, not Ctrl+H
    });

    test('Complex escape sequences', () {
      // Home key (ESC [ H)
      parser.clear();
      final home = parser.parseBytes([0x1B, 0x5B, 0x48]);
      expect(home!.logicalKey, equals(LogicalKey.home));
      expect(home.modifiers.hasAnyModifier, isFalse);

      // End key (ESC [ F)
      parser.clear();
      final end = parser.parseBytes([0x1B, 0x5B, 0x46]);
      expect(end!.logicalKey, equals(LogicalKey.end));
      expect(end.modifiers.hasAnyModifier, isFalse);

      // Page Up (ESC [ 5 ~)
      parser.clear();
      final pageUp = parser.parseBytes([0x1B, 0x5B, 0x35, 0x7E]);
      expect(pageUp!.logicalKey, equals(LogicalKey.pageUp));
      expect(pageUp.modifiers.hasAnyModifier, isFalse);
    });

    test('UTF-8 character parsing', () {
      // Test single-byte ASCII
      parser.clear();
      final ascii = parser.parseBytes([0x41]); // 'A'
      expect(ascii!.character, equals('A'));
      expect(ascii.modifiers.shift, isTrue); // Uppercase implies shift

      // Test two-byte UTF-8 (é)
      parser.clear();
      final twoByte = parser.parseBytes([0xC3, 0xA9]);
      expect(twoByte!.character, equals('é'));

      // Test three-byte UTF-8 (€)
      parser.clear();
      final threeByte = parser.parseBytes([0xE2, 0x82, 0xAC]);
      expect(threeByte!.character, equals('€'));

      // Test four-byte UTF-8 (𝄞 - musical symbol)
      parser.clear();
      final fourByte = parser.parseBytes([0xF0, 0x9D, 0x84, 0x9E]);
      expect(fourByte!.character, equals('𝄞'));
    });

    test('Incomplete sequences handled correctly', () {
      // Incomplete CSI sequence
      parser.clear();
      var event = parser.parseBytes([0x1B, 0x5B]);
      expect(event, isNull); // Should wait for more bytes

      // Complete it with arrow up
      event = parser.parseBytes([0x41]);
      expect(event!.logicalKey, equals(LogicalKey.arrowUp));

      // Incomplete modified arrow sequence
      parser.clear();
      event = parser.parseBytes([0x1B, 0x5B, 0x31, 0x3B]);
      expect(event, isNull); // Should wait for modifier and direction

      event = parser.parseBytes([0x32]); // Shift modifier
      expect(event, isNull); // Still waiting for direction

      event = parser.parseBytes([0x43]); // Right arrow
      expect(event!.logicalKey, equals(LogicalKey.arrowRight));
      expect(event.modifiers.shift, isTrue);
    });

    test('Parser buffer clearing', () {
      // Add some bytes
      parser.parseBytes([0x1B, 0x5B]);

      // Clear the buffer
      parser.clear();

      // Now a simple character should work
      final event = parser.parseBytes([0x61]); // 'a'
      expect(event!.character, equals('a'));
      expect(event.logicalKey, equals(LogicalKey.keyA));
    });

    test('ModifierKeys hashCode consistency', () {
      const mod1 = ModifierKeys(ctrl: true, shift: true);
      const mod2 = ModifierKeys(ctrl: true, shift: true);
      const mod3 = ModifierKeys(ctrl: true, shift: false);

      expect(mod1.hashCode, equals(mod2.hashCode));
      expect(mod1.hashCode, isNot(equals(mod3.hashCode)));

      // Test in a Set
      // ignore: equal_elements_in_set
      final modSet = <ModifierKeys>{mod1, mod2, mod3};
      expect(modSet.length, equals(2)); // mod1 and mod2 are the same
    });

    test('KeyboardEvent toString formatting', () {
      final event1 = KeyboardEvent(
        logicalKey: LogicalKey.keyA,
        character: 'a',
        modifiers: const ModifierKeys(ctrl: true, shift: true),
      );

      expect(event1.toString(), contains('Ctrl+Shift'));
      expect(event1.toString(), contains('keyA'));
      expect(event1.toString(), contains('a'));

      final event2 = KeyboardEvent(
        logicalKey: LogicalKey.arrowUp,
        modifiers: const ModifierKeys(),
      );

      expect(event2.toString(), contains('arrowUp'));
      expect(event2.toString(), isNot(contains('modifiers: none')));
    });

    test('All arrow directions with all modifiers', () {
      final directions = [
        (0x41, LogicalKey.arrowUp),
        (0x42, LogicalKey.arrowDown),
        (0x43, LogicalKey.arrowRight),
        (0x44, LogicalKey.arrowLeft),
      ];

      final modifierTests = [
        ('1;2', true, false, false), // Shift
        ('1;3', false, true, false), // Alt
        ('1;5', false, false, true), // Ctrl
      ];

      for (final dir in directions) {
        for (final mod in modifierTests) {
          parser.clear();
          final bytes = [0x1B, 0x5B, ...mod.$1.codeUnits, dir.$1];
          final event = parser.parseBytes(bytes);

          expect(
            event!.logicalKey,
            equals(dir.$2),
            reason: 'Direction ${dir.$2} with modifier ${mod.$1}',
          );
          expect(
            event.modifiers.shift,
            equals(mod.$2),
            reason: 'Shift for ${mod.$1}',
          );
          expect(
            event.modifiers.alt,
            equals(mod.$3),
            reason: 'Alt for ${mod.$1}',
          );
          expect(
            event.modifiers.ctrl,
            equals(mod.$4),
            reason: 'Ctrl for ${mod.$1}',
          );
        }
      }
    });

    test('Function keys F1-F12', () {
      // F1-F4 use SS3 sequences
      final f1to4 = [
        ([0x1B, 0x4F, 0x50], LogicalKey.f1),
        ([0x1B, 0x4F, 0x51], LogicalKey.f2),
        ([0x1B, 0x4F, 0x52], LogicalKey.f3),
        ([0x1B, 0x4F, 0x53], LogicalKey.f4),
      ];

      for (final test in f1to4) {
        parser.clear();
        final event = parser.parseBytes(test.$1);
        expect(event!.logicalKey, equals(test.$2));
        expect(event.modifiers.hasAnyModifier, isFalse);
      }

      // F5-F12 use CSI sequences with ~
      final f5to12 = [
        ([0x1B, 0x5B, 0x31, 0x35, 0x7E], LogicalKey.f5),
        ([0x1B, 0x5B, 0x31, 0x37, 0x7E], LogicalKey.f6),
        ([0x1B, 0x5B, 0x31, 0x38, 0x7E], LogicalKey.f7),
        ([0x1B, 0x5B, 0x31, 0x39, 0x7E], LogicalKey.f8),
        ([0x1B, 0x5B, 0x32, 0x30, 0x7E], LogicalKey.f9),
        ([0x1B, 0x5B, 0x32, 0x31, 0x7E], LogicalKey.f10),
        ([0x1B, 0x5B, 0x32, 0x33, 0x7E], LogicalKey.f11),
        ([0x1B, 0x5B, 0x32, 0x34, 0x7E], LogicalKey.f12),
      ];

      for (final test in f5to12) {
        parser.clear();
        final event = parser.parseBytes(test.$1);
        expect(event!.logicalKey, equals(test.$2));
        expect(event.modifiers.hasAnyModifier, isFalse);
      }
    });
  });
}
