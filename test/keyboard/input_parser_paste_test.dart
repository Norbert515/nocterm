import 'dart:convert';
import 'package:nocterm/src/keyboard/input_parser.dart';
import 'package:nocterm/src/keyboard/input_event.dart';
import 'package:test/test.dart';

void main() {
  group('InputParser pasting', () {
    test('should parse multiple characters when pasted', () {
      final parser = InputParser();

      // Simulate pasting "Hello" - all bytes come at once
      final bytes = 'Hello'.codeUnits;
      parser.addBytes(bytes);

      // Should parse each character individually
      final events = <String>[];
      while (true) {
        final event = parser.parseNext();
        if (event == null) break;

        if (event is KeyboardInputEvent) {
          if (event.event.character != null) {
            events.add(event.event.character!);
          }
        }
      }

      // Should have parsed all 5 characters
      expect(events, equals(['H', 'e', 'l', 'l', 'o']));
    });

    test('should parse Unicode text when pasted', () {
      final parser = InputParser();

      // Simulate pasting "Hello 世界 🎉"
      final text = 'Hello 世界 🎉';
      final bytes = utf8.encode(text); // Use UTF-8 encoding
      parser.addBytes(bytes);

      final events = <String>[];
      while (true) {
        final event = parser.parseNext();
        if (event == null) break;

        if (event is KeyboardInputEvent) {
          if (event.event.character != null) {
            events.add(event.event.character!);
          }
        }
      }

      // Should have parsed all characters correctly
      // Join the events back to compare the full text
      expect(events.join(''), equals(text));
    });

    test('should handle large paste operations', () {
      final parser = InputParser();

      // Simulate pasting a large text
      final text = 'The quick brown fox jumps over the lazy dog. ' * 10;
      final bytes = text.codeUnits;
      parser.addBytes(bytes);

      final events = <String>[];
      while (true) {
        final event = parser.parseNext();
        if (event == null) break;

        if (event is KeyboardInputEvent) {
          if (event.event.character != null) {
            events.add(event.event.character!);
          }
        }
      }

      // Should have parsed all characters
      expect(events.length, equals(text.length));
      expect(events.join(''), equals(text));
    });

    test('should not lose characters in mixed input', () {
      final parser = InputParser();

      // Add "Hel"
      parser.addBytes('Hel'.codeUnits);
      final e1 = parser.parseNext();
      expect((e1 as KeyboardInputEvent).event.character, 'H');

      // Add more while parsing
      parser.addBytes('lo'.codeUnits);

      // Continue parsing
      final events = <String>['H'];
      while (true) {
        final event = parser.parseNext();
        if (event == null) break;

        if (event is KeyboardInputEvent) {
          if (event.event.character != null) {
            events.add(event.event.character!);
          }
        }
      }

      // Should have all 5 characters
      expect(events, equals(['H', 'e', 'l', 'l', 'o']));
    });
  });
}