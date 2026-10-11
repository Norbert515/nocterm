import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/keyboard/keyboard_parser.dart';
import 'package:nocterm/src/keyboard/input_parser.dart';
import 'package:nocterm/src/keyboard/input_event.dart';
import 'package:test/test.dart';

void main() {
  group('Kitty keyboard protocol', () {
    group('KeyboardParser', () {
      late KeyboardParser parser;

      setUp(() {
        parser = KeyboardParser();
      });

      test('Shift+Enter: \\x1b[13;2u', () {
        parser.clear();
        // ESC [ 1 3 ; 2 u
        final event =
            parser.parseBytes([0x1B, 0x5B, 0x31, 0x33, 0x3B, 0x32, 0x75]);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.enter));
        expect(event.modifiers.shift, isTrue);
        expect(event.modifiers.ctrl, isFalse);
        expect(event.modifiers.alt, isFalse);
      });

      test('Ctrl+Enter: \\x1b[13;5u', () {
        parser.clear();
        // ESC [ 1 3 ; 5 u
        final event =
            parser.parseBytes([0x1B, 0x5B, 0x31, 0x33, 0x3B, 0x35, 0x75]);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.enter));
        expect(event.modifiers.ctrl, isTrue);
        expect(event.modifiers.shift, isFalse);
      });

      test('Alt+Enter: \\x1b[13;3u', () {
        parser.clear();
        // ESC [ 1 3 ; 3 u
        final event =
            parser.parseBytes([0x1B, 0x5B, 0x31, 0x33, 0x3B, 0x33, 0x75]);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.enter));
        expect(event.modifiers.alt, isTrue);
        expect(event.modifiers.shift, isFalse);
        expect(event.modifiers.ctrl, isFalse);
      });

      test('Ctrl+Shift+Enter: \\x1b[13;6u', () {
        parser.clear();
        // modifier 6 = 1 + 5 (shift=1, ctrl=4, bitmask=5)
        final event =
            parser.parseBytes([0x1B, 0x5B, 0x31, 0x33, 0x3B, 0x36, 0x75]);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.enter));
        expect(event.modifiers.shift, isTrue);
        expect(event.modifiers.ctrl, isTrue);
        expect(event.modifiers.alt, isFalse);
      });

      test('Enter without modifier: \\x1b[13u', () {
        parser.clear();
        // ESC [ 1 3 u
        final event = parser.parseBytes([0x1B, 0x5B, 0x31, 0x33, 0x75]);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.enter));
        expect(event.modifiers.hasAnyModifier, isFalse);
      });

      test('Shift+Tab: \\x1b[9;2u', () {
        parser.clear();
        final event = parser.parseBytes([0x1B, 0x5B, 0x39, 0x3B, 0x32, 0x75]);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.tab));
        expect(event.modifiers.shift, isTrue);
      });

      test('Ctrl+a: \\x1b[97;5u', () {
        parser.clear();
        // codepoint 97 = 'a', modifier 5 = ctrl
        final bytes = '\x1B[97;5u'.codeUnits;
        final event = parser.parseBytes(bytes);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.keyA));
        expect(event.modifiers.ctrl, isTrue);
      });

      test('Shift+a: \\x1b[97;2u', () {
        parser.clear();
        final bytes = '\x1B[97;2u'.codeUnits;
        final event = parser.parseBytes(bytes);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.keyA));
        expect(event.modifiers.shift, isTrue);
      });

      test('Escape with no modifier: \\x1b[27u', () {
        parser.clear();
        final bytes = '\x1B[27u'.codeUnits;
        final event = parser.parseBytes(bytes);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.escape));
        expect(event.modifiers.hasAnyModifier, isFalse);
      });

      test('Backspace with ctrl: \\x1b[127;5u', () {
        parser.clear();
        final bytes = '\x1B[127;5u'.codeUnits;
        final event = parser.parseBytes(bytes);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.backspace));
        expect(event.modifiers.ctrl, isTrue);
      });

      test('Meta+Enter: \\x1b[13;9u', () {
        parser.clear();
        // modifier 9 = 1 + 8 (meta=8, bitmask=8)
        final bytes = '\x1B[13;9u'.codeUnits;
        final event = parser.parseBytes(bytes);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.enter));
        expect(event.modifiers.meta, isTrue);
        expect(event.modifiers.shift, isFalse);
      });

      test('Enter with colon sub-params: \\x1b[13:10u', () {
        parser.clear();
        // "report alternate keys" may produce colon sub-parameters
        final bytes = '\x1B[13:10u'.codeUnits;
        final event = parser.parseBytes(bytes);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.enter));
        expect(event.modifiers.hasAnyModifier, isFalse);
      });

      test('Shift+Enter with colon sub-params: \\x1b[13:10;2u', () {
        parser.clear();
        final bytes = '\x1B[13:10;2u'.codeUnits;
        final event = parser.parseBytes(bytes);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.enter));
        expect(event.modifiers.shift, isTrue);
      });

      test('Key with colon sub-params in modifier: \\x1b[97;5:1u', () {
        parser.clear();
        // codepoint 97 = 'a', modifier 5 = ctrl, event type 1
        final bytes = '\x1B[97;5:1u'.codeUnits;
        final event = parser.parseBytes(bytes);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.keyA));
        expect(event.modifiers.ctrl, isTrue);
      });

      test('Ctrl+J via kitty: \\x1b[106;5u (newline fallback)', () {
        parser.clear();
        // codepoint 106 = 'j', modifier 5 = ctrl
        final bytes = '\x1B[106;5u'.codeUnits;
        final event = parser.parseBytes(bytes);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.keyJ));
        expect(event.character, equals('j'));
        expect(event.modifiers.ctrl, isTrue);
      });
    });

    group('InputParser', () {
      late InputParser parser;

      setUp(() {
        parser = InputParser();
      });

      test('Shift+Enter via kitty protocol', () {
        // ESC [ 1 3 ; 2 u
        parser.addBytes([0x1B, 0x5B, 0x31, 0x33, 0x3B, 0x32, 0x75]);
        final event = parser.parseNext();
        expect(event, isA<KeyboardInputEvent>());
        final keyEvent = (event as KeyboardInputEvent).event;
        expect(keyEvent.logicalKey, equals(LogicalKey.enter));
        expect(keyEvent.modifiers.shift, isTrue);
      });

      test('Ctrl+Enter via kitty protocol', () {
        parser.addBytes([0x1B, 0x5B, 0x31, 0x33, 0x3B, 0x35, 0x75]);
        final event = parser.parseNext();
        expect(event, isA<KeyboardInputEvent>());
        final keyEvent = (event as KeyboardInputEvent).event;
        expect(keyEvent.logicalKey, equals(LogicalKey.enter));
        expect(keyEvent.modifiers.ctrl, isTrue);
      });

      test('Enter with colon sub-params via kitty', () {
        // \x1b[13:10u — Enter with alternate key sub-parameter
        parser.addBytes('\x1B[13:10u'.codeUnits);
        final event = parser.parseNext();
        expect(event, isA<KeyboardInputEvent>());
        final keyEvent = (event as KeyboardInputEvent).event;
        expect(keyEvent.logicalKey, equals(LogicalKey.enter));
        expect(keyEvent.modifiers.hasAnyModifier, isFalse);
      });

      test('Shift+Enter with colon sub-params via kitty', () {
        parser.addBytes('\x1B[13:10;2u'.codeUnits);
        final event = parser.parseNext();
        expect(event, isA<KeyboardInputEvent>());
        final keyEvent = (event as KeyboardInputEvent).event;
        expect(keyEvent.logicalKey, equals(LogicalKey.enter));
        expect(keyEvent.modifiers.shift, isTrue);
      });

      test('kitty sequence followed by regular character', () {
        // Shift+Enter followed by 'a'
        parser.addBytes([0x1B, 0x5B, 0x31, 0x33, 0x3B, 0x32, 0x75, 0x61]);

        final event1 = parser.parseNext();
        expect(event1, isA<KeyboardInputEvent>());
        final keyEvent1 = (event1 as KeyboardInputEvent).event;
        expect(keyEvent1.logicalKey, equals(LogicalKey.enter));
        expect(keyEvent1.modifiers.shift, isTrue);

        final event2 = parser.parseNext();
        expect(event2, isA<KeyboardInputEvent>());
        final keyEvent2 = (event2 as KeyboardInputEvent).event;
        expect(keyEvent2.logicalKey, equals(LogicalKey.keyA));
        expect(keyEvent2.character, equals('a'));
      });
    });
  });

  group('modifyOtherKeys protocol', () {
    group('KeyboardParser', () {
      late KeyboardParser parser;

      setUp(() {
        parser = KeyboardParser();
      });

      test('Shift+Enter: \\x1b[27;2;13~', () {
        parser.clear();
        final bytes = '\x1B[27;2;13~'.codeUnits;
        final event = parser.parseBytes(bytes);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.enter));
        expect(event.modifiers.shift, isTrue);
        expect(event.modifiers.ctrl, isFalse);
      });

      test('Ctrl+Enter: \\x1b[27;5;13~', () {
        parser.clear();
        final bytes = '\x1B[27;5;13~'.codeUnits;
        final event = parser.parseBytes(bytes);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.enter));
        expect(event.modifiers.ctrl, isTrue);
        expect(event.modifiers.shift, isFalse);
      });

      test('Alt+Enter: \\x1b[27;3;13~', () {
        parser.clear();
        final bytes = '\x1B[27;3;13~'.codeUnits;
        final event = parser.parseBytes(bytes);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.enter));
        expect(event.modifiers.alt, isTrue);
      });

      test('Ctrl+Shift+a: \\x1b[27;6;97~', () {
        parser.clear();
        // modifier 6 = 1 + 5 (shift=1, ctrl=4)
        final bytes = '\x1B[27;6;97~'.codeUnits;
        final event = parser.parseBytes(bytes);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.keyA));
        expect(event.modifiers.shift, isTrue);
        expect(event.modifiers.ctrl, isTrue);
      });

      test('Shift+Tab: \\x1b[27;2;9~', () {
        parser.clear();
        final bytes = '\x1B[27;2;9~'.codeUnits;
        final event = parser.parseBytes(bytes);
        expect(event, isNotNull);
        expect(event!.logicalKey, equals(LogicalKey.tab));
        expect(event.modifiers.shift, isTrue);
      });
    });

    group('InputParser', () {
      late InputParser parser;

      setUp(() {
        parser = InputParser();
      });

      test('Shift+Enter via modifyOtherKeys', () {
        final bytes = '\x1B[27;2;13~'.codeUnits;
        parser.addBytes(bytes);
        final event = parser.parseNext();
        expect(event, isA<KeyboardInputEvent>());
        final keyEvent = (event as KeyboardInputEvent).event;
        expect(keyEvent.logicalKey, equals(LogicalKey.enter));
        expect(keyEvent.modifiers.shift, isTrue);
      });

      test('modifyOtherKeys does not match non-27 marker', () {
        // This is a regular F5 key: ESC[15~
        final bytes = '\x1B[15~'.codeUnits;
        parser.addBytes(bytes);
        final event = parser.parseNext();
        expect(event, isA<KeyboardInputEvent>());
        final keyEvent = (event as KeyboardInputEvent).event;
        // Should be parsed as F5, not as modifyOtherKeys
        expect(keyEvent.logicalKey, equals(LogicalKey.f5));
      });
    });
  });

  group('Modifier bitmask decoding', () {
    late KeyboardParser parser;

    setUp(() {
      parser = KeyboardParser();
    });

    test('modifier 1 = no modifiers (bitmask 0)', () {
      parser.clear();
      // Enter with modifier value 1 (bitmask = 0)
      final bytes = '\x1B[13;1u'.codeUnits;
      final event = parser.parseBytes(bytes);
      expect(event, isNotNull);
      expect(event!.modifiers.hasAnyModifier, isFalse);
    });

    test('modifier 2 = shift (bitmask 1)', () {
      parser.clear();
      final bytes = '\x1B[13;2u'.codeUnits;
      final event = parser.parseBytes(bytes);
      expect(event!.modifiers.shift, isTrue);
      expect(event.modifiers.alt, isFalse);
      expect(event.modifiers.ctrl, isFalse);
      expect(event.modifiers.meta, isFalse);
    });

    test('modifier 3 = alt (bitmask 2)', () {
      parser.clear();
      final bytes = '\x1B[13;3u'.codeUnits;
      final event = parser.parseBytes(bytes);
      expect(event!.modifiers.alt, isTrue);
      expect(event.modifiers.shift, isFalse);
    });

    test('modifier 4 = shift+alt (bitmask 3)', () {
      parser.clear();
      final bytes = '\x1B[13;4u'.codeUnits;
      final event = parser.parseBytes(bytes);
      expect(event!.modifiers.shift, isTrue);
      expect(event.modifiers.alt, isTrue);
      expect(event.modifiers.ctrl, isFalse);
    });

    test('modifier 5 = ctrl (bitmask 4)', () {
      parser.clear();
      final bytes = '\x1B[13;5u'.codeUnits;
      final event = parser.parseBytes(bytes);
      expect(event!.modifiers.ctrl, isTrue);
      expect(event.modifiers.shift, isFalse);
    });

    test('modifier 6 = shift+ctrl (bitmask 5)', () {
      parser.clear();
      final bytes = '\x1B[13;6u'.codeUnits;
      final event = parser.parseBytes(bytes);
      expect(event!.modifiers.shift, isTrue);
      expect(event.modifiers.ctrl, isTrue);
      expect(event.modifiers.alt, isFalse);
    });

    test('modifier 7 = alt+ctrl (bitmask 6)', () {
      parser.clear();
      final bytes = '\x1B[13;7u'.codeUnits;
      final event = parser.parseBytes(bytes);
      expect(event!.modifiers.alt, isTrue);
      expect(event.modifiers.ctrl, isTrue);
      expect(event.modifiers.shift, isFalse);
    });

    test('modifier 8 = shift+alt+ctrl (bitmask 7)', () {
      parser.clear();
      final bytes = '\x1B[13;8u'.codeUnits;
      final event = parser.parseBytes(bytes);
      expect(event!.modifiers.shift, isTrue);
      expect(event.modifiers.alt, isTrue);
      expect(event.modifiers.ctrl, isTrue);
      expect(event.modifiers.meta, isFalse);
    });

    test('modifier 9 = meta/super (bitmask 8)', () {
      parser.clear();
      final bytes = '\x1B[13;9u'.codeUnits;
      final event = parser.parseBytes(bytes);
      expect(event!.modifiers.meta, isTrue);
      expect(event.modifiers.shift, isFalse);
      expect(event.modifiers.alt, isFalse);
      expect(event.modifiers.ctrl, isFalse);
    });
  });

  group('Existing sequences still work with protocol enabled', () {
    late KeyboardParser parser;

    setUp(() {
      parser = KeyboardParser();
    });

    test('plain Enter (0x0D) still works', () {
      parser.clear();
      final event = parser.parseBytes([0x0D]);
      expect(event!.logicalKey, equals(LogicalKey.enter));
      expect(event.modifiers.hasAnyModifier, isFalse);
    });

    test('plain Tab (0x09) still works', () {
      parser.clear();
      final event = parser.parseBytes([0x09]);
      expect(event!.logicalKey, equals(LogicalKey.tab));
    });

    test('arrow keys still work', () {
      parser.clear();
      final event = parser.parseBytes([0x1B, 0x5B, 0x41]);
      expect(event!.logicalKey, equals(LogicalKey.arrowUp));
    });

    test('Shift+Tab (ESC[Z) still works', () {
      parser.clear();
      final event = parser.parseBytes([0x1B, 0x5B, 0x5A]);
      expect(event!.logicalKey, equals(LogicalKey.tab));
      expect(event.modifiers.shift, isTrue);
    });

    test('Ctrl+A (0x01) still works', () {
      parser.clear();
      final event = parser.parseBytes([0x01]);
      expect(event!.logicalKey, equals(LogicalKey.keyA));
      expect(event.modifiers.ctrl, isTrue);
    });

    test('0x0A (LF) is parsed as Enter for terminal compatibility', () {
      parser.clear();
      final event = parser.parseBytes([0x0A]);
      expect(event!.logicalKey, equals(LogicalKey.enter));
      expect(event.modifiers.hasAnyModifier, isFalse);
      // Some terminals (e.g. Warp) send 0x0A for Enter.
      // With kitty protocol active, Ctrl+J arrives as \x1b[106;5u instead.
    });

    test('F5 (ESC[15~) still works and is not confused with modifyOtherKeys',
        () {
      parser.clear();
      final event = parser.parseBytes([0x1B, 0x5B, 0x31, 0x35, 0x7E]);
      expect(event!.logicalKey, equals(LogicalKey.f5));
      expect(event.modifiers.hasAnyModifier, isFalse);
    });
  });

  group('Ctrl+C under the kitty protocol', () {
    // With the protocol active a terminal reports Ctrl+C as an escape
    // sequence rather than the raw 0x03 byte. The tty only raises SIGINT
    // for the byte, so the escape form has to reach the app as an ordinary
    // Ctrl+C event - it is the only notice the app gets that the user asked
    // to quit.
    InputParser parse(List<int> bytes) => InputParser()..addBytes(bytes);

    KeyboardEvent keyEventFor(List<int> bytes) {
      final event = parse(bytes).parseNext();
      expect(event, isA<KeyboardInputEvent>());
      return (event as KeyboardInputEvent).event;
    }

    test('ESC[99;5u parses as Ctrl+C, same as the raw 0x03 byte', () {
      final fromEscape = keyEventFor('\x1b[99;5u'.codeUnits);
      final fromByte = keyEventFor([0x03]);

      expect(fromEscape.logicalKey, equals(LogicalKey.keyC));
      expect(fromEscape.modifiers.ctrl, isTrue);
      expect(fromEscape.modifiers.shift, isFalse);

      expect(fromByte.logicalKey, equals(fromEscape.logicalKey));
      expect(fromByte.modifiers.ctrl, equals(fromEscape.modifiers.ctrl));
    });

    test('ESC[99;6u is Ctrl+Shift+C and is distinguishable', () {
      // Terminals bind Ctrl+Shift+C to copy, so it must not read as a quit.
      final event = keyEventFor('\x1b[99;6u'.codeUnits);
      expect(event.logicalKey, equals(LogicalKey.keyC));
      expect(event.modifiers.ctrl, isTrue);
      expect(event.modifiers.shift, isTrue);
    });
  });
}
