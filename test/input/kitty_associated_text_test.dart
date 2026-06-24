import 'package:nocterm/src/keyboard/input_event.dart';
import 'package:nocterm/src/keyboard/input_parser.dart';
import 'package:nocterm/src/keyboard/logical_key.dart';
import 'package:test/test.dart';

/// Tests for the 4-part form of the Kitty keyboard protocol
/// (`CSI codepoint ; modifiers ; base ; text u`), used by
/// terminals to surface IME-committed text. The 4th part is
/// percent-encoded UTF-8 (so "你好" arrives as
/// `%E4%BD%A0%E5%A5%BD`).
///
/// 2- and 3-part forms (the only ones supported before this
/// work) are regression-tested at the bottom.
void main() {
  group('InputParser — Kitty 4-part form (associated text)', () {
    late InputParser parser;

    setUp(() {
      parser = InputParser();
    });

    test('4-part: ASCII associated text becomes the character', () {
      // ESC [ 1 1 6 ; 1 ; 1 ; t o o l u
      //   codepoint 116 = 't', no modifiers, base layout 1, text "tool"
      // Realistic Chinese-IME shape: user typed "tool" pinyin,
      // confirmed candidate, terminal emits this kitty sequence.
      parser.addBytes('\x1B[116;1;1;tool u'.codeUnits);
      final event = parser.parseNext();
      expect(event, isA<KeyboardInputEvent>(),
          reason: 'must be a KeyboardInputEvent — NOT a PasteInputEvent. '
              'If it were a PasteInputEvent, the IME text would be '
              'routed through the paste path and could be misread '
              'as a file drop (e.g. "tool" → [directory: .../tool]).');
      final keyEvent = (event! as KeyboardInputEvent).event;
      expect(keyEvent.character, 'tool');
    });

    test('4-part: CJK associated text is percent-decoded to a Dart '
        'String', () {
      // Per the Kitty spec, the associated text is percent-encoded
      // UTF-8, so the IME output "你好" arrives as
      // "%E4%BD%A0%E5%A5%BD" (one byte becomes three chars). The
      // codepoint 20320 (0x4F60) is the base layout key for '你'
      // on a US keyboard — the IME replaces the character with its
      // own output, which is what must reach the focused widget.
      parser.addBytes('\x1B[20320;1;1;%E4%BD%A0%E5%A5%BD u'.codeUnits);
      final event = parser.parseNext();
      expect(event, isA<KeyboardInputEvent>());
      final keyEvent = (event! as KeyboardInputEvent).event;
      expect(keyEvent.character, '你好');
    });

    test('4-part: percent-encoded special chars (space)', () {
      // "hello world" — the space is percent-encoded as %20 per
      // the Kitty spec.
      parser.addBytes('\x1B[116;1;1;hello%20world u'.codeUnits);
      final event = parser.parseNext();
      final keyEvent = (event! as KeyboardInputEvent).event;
      expect(keyEvent.character, 'hello world');
    });

    test('4-part: percent-encoded UTF-8 CJK bytes', () {
      // "你好" UTF-8 = E4 BD A0 E5 A5 BD → percent-encoded.
      // The terminal always percent-encodes non-ASCII bytes per
      // spec, so the parser must decode them back to a Dart
      // String (interpreted as UTF-8).
      parser.addBytes('\x1B[116;1;1;%E4%BD%A0%E5%A5%BD u'.codeUnits);
      final event = parser.parseNext();
      final keyEvent = (event! as KeyboardInputEvent).event;
      expect(keyEvent.character, '你好');
    });

    test('4-part: Shift modifier is preserved alongside the text', () {
      // mod 2 = shift (1 + bitmask 1). Associated text is the
      // capitalised form; the TextField uses `character` to
      // insert, so the capitalisation is what the user sees.
      parser.addBytes('\x1B[116;2;1;Tool u'.codeUnits);
      final event = parser.parseNext();
      final keyEvent = (event! as KeyboardInputEvent).event;
      expect(keyEvent.character, 'Tool');
      expect(keyEvent.modifiers.shift, isTrue);
      expect(keyEvent.modifiers.ctrl, isFalse);
    });

    test('4-part: codepoint still drives logicalKey', () {
      // codepoint 13 = Enter. An IME commit that happens to be on
      // the Enter key (e.g. confirming a candidate with Enter on
      // a Japanese IME) should still report the Enter logical key
      // so any focused widget's `onKeyEvent` sees a regular
      // Enter, not a text insertion.
      parser.addBytes('\x1B[13;1;1;enter u'.codeUnits);
      final event = parser.parseNext();
      final keyEvent = (event! as KeyboardInputEvent).event;
      expect(keyEvent.logicalKey, LogicalKey.enter);
      expect(keyEvent.character, 'enter');
    });

    test('4-part: empty associated text falls back to codepoint '
        'character', () {
      // Some terminals may send an empty 4th part instead of
      // dropping to the 3-part form. Treat it as "no text" and
      // fall back to the codepoint-derived character.
      parser.addBytes('\x1B[116;1;1; u'.codeUnits);
      final event = parser.parseNext();
      final keyEvent = (event! as KeyboardInputEvent).event;
      expect(keyEvent.character, 't',
          reason: 'empty associated text → use codepoint character');
    });

    test('4-part: two sequences back-to-back parse independently', () {
      // Simulates a user confirming two IME candidates quickly:
      // "tool" then "foo". Each emits its own 4-part sequence;
      // the parser must yield two independent KeyboardInputEvents.
      parser.addBytes('\x1B[116;1;1;tool u\x1B[97;1;1;foo u'.codeUnits);
      final chars = <String>[];
      InputEvent? event;
      while ((event = parser.parseNext()) != null) {
        if (event is KeyboardInputEvent) {
          chars.add(event.event.character ?? '');
        }
      }
      expect(chars, ['tool', 'foo']);
    });

    test('4-part: sequence with sub-parameters in codepoint', () {
      // "report alternate keys" mode uses colon sub-parameters.
      // 13:10 means "Enter with numpad layout". The associated
      // text path must not break on these.
      parser.addBytes('\x1B[13:10;1;1;enter u'.codeUnits);
      final event = parser.parseNext();
      final keyEvent = (event! as KeyboardInputEvent).event;
      expect(keyEvent.logicalKey, LogicalKey.enter);
      expect(keyEvent.character, 'enter');
    });

    test('regression: 2-part form (just codepoint) still works', () {
      parser.addBytes('\x1B[13u'.codeUnits);
      final event = parser.parseNext();
      final keyEvent = (event! as KeyboardInputEvent).event;
      expect(keyEvent.logicalKey, LogicalKey.enter);
    });

    test('regression: 3-part form (codepoint + modifiers) still works',
        () {
      parser.addBytes('\x1B[116;1u'.codeUnits);
      final event = parser.parseNext();
      final keyEvent = (event! as KeyboardInputEvent).event;
      expect(keyEvent.character, 't');
      expect(keyEvent.modifiers.hasAnyModifier, isFalse);
    });

    test('regression: 3-part form with Ctrl modifier', () {
      parser.addBytes('\x1B[97;5u'.codeUnits);
      final event = parser.parseNext();
      final keyEvent = (event! as KeyboardInputEvent).event;
      expect(keyEvent.logicalKey, LogicalKey.keyA);
      expect(keyEvent.modifiers.ctrl, isTrue);
    });

    test('5-part form: parser degrades to per-byte parsing instead '
        'of treating it as a (broken) 4-part sequence', () {
      // The Kitty spec defines 1-4 part sequences; 5+ is
      // non-standard. The parser must not (a) hang on the input
      // and (b) must NOT misinterpret it as a 4-part sequence
      // that silently swallows the trailing "extra" into the
      // associated text. The right behavior is to fail validation
      // of the kitty sequence and fall through to the per-byte
      // character parser, which is what non-kitty bytes do.
      parser.addBytes('\x1B[116;1;1;text;extra u'.codeUnits);

      // Drain the parser. The exact number of events is an
      // implementation detail; the invariants we check are:
      //   1) the parser makes progress (no hang),
      //   2) no single KeyboardInputEvent carries a multi-char
      //      `character` (which would mean a broken 4-part
      //      interpretation produced a huge associated-text blob).
      final charLengths = <int>[];
      var progressed = false;
      InputEvent? event;
      while ((event = parser.parseNext()) != null) {
        progressed = true;
        if (event is KeyboardInputEvent && event.event.character != null) {
          charLengths.add(event.event.character!.length);
        }
      }
      expect(progressed, isTrue,
          reason: 'parser must make progress and not hang on '
              'malformed input');
      expect(charLengths.every((n) => n <= 1), isTrue,
          reason: 'no event should carry a multi-char `character` '
              '— that would mean a 4-part interpretation snuck '
              'through. Got char lengths: $charLengths');
    });

    test('regression: bracketed paste in the same stream still '
        'parses independently', () {
      // A realistic mixed stream: a file drop (bracketed paste)
      // followed by an IME commit (4-part kitty).
      final bytes = <int>[
        ...'\x1B[200~'.codeUnits,
        ...'/Users/me/notes.md'.codeUnits,
        ...'\x1B[201~'.codeUnits,
        ...'\x1B[116;1;1;tool u'.codeUnits,
      ];
      parser.addBytes(bytes);

      final events = <String>[];
      InputEvent? event;
      while ((event = parser.parseNext()) != null) {
        if (event is PasteInputEvent) {
          events.add('paste:${event.text}');
        } else if (event is KeyboardInputEvent) {
          events.add('key:${event.event.character}');
        }
      }
      expect(events, [
        'paste:/Users/me/notes.md',
        'key:tool',
      ]);
    });
  });
}
