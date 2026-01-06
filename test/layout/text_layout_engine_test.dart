import 'package:test/test.dart';
import 'package:nocterm/src/text/text_layout_engine.dart';

void main() {
  group('TextLayoutEngine', () {
    group('Basic word wrapping', () {
      test('wraps text at word boundaries', () {
        final config = TextLayoutConfig(maxWidth: 10, softWrap: true);

        final result = TextLayoutEngine.layout('Hello world test', config);

        expect(result.lines, ['Hello ', 'world test']);
        expect(result.actualWidth, 10);
        expect(result.actualHeight, 2);
      });

      test('preserves explicit newlines', () {
        final config = TextLayoutConfig(maxWidth: 20, softWrap: true);

        final result = TextLayoutEngine.layout('Hello\nworld', config);

        expect(result.lines, ['Hello', 'world']);
        expect(result.actualHeight, 2);
      });

      test('handles empty lines', () {
        final config = TextLayoutConfig(maxWidth: 20, softWrap: true);

        final result = TextLayoutEngine.layout('Hello\n\nworld', config);

        expect(result.lines, ['Hello', '', 'world']);
        expect(result.actualHeight, 3);
      });

      test('wraps long sentences', () {
        final config = TextLayoutConfig(maxWidth: 15, softWrap: true);

        final result = TextLayoutEngine.layout(
          'This is a very long sentence that needs wrapping',
          config,
        );

        expect(result.lines, [
          'This is a very ',
          'long sentence ',
          'that needs ',
          'wrapping',
        ]);
      });
    });

    group('Long word breaking', () {
      test('breaks words longer than max width', () {
        final config = TextLayoutConfig(maxWidth: 5, softWrap: true);

        final result = TextLayoutEngine.layout('Supercalifragilistic', config);

        expect(result.lines[0], 'Super');
        expect(result.lines[1], 'calif');
        expect(result.lines[2], 'ragil');
        expect(result.lines[3], 'istic');
      });

      test('handles mixed content with long words', () {
        final config = TextLayoutConfig(maxWidth: 8, softWrap: true);

        final result = TextLayoutEngine.layout(
          'Hello verylongword test',
          config,
        );

        expect(result.lines, ['Hello ', 'verylong', 'word ', 'test']);
      });
    });

    group('No wrap mode', () {
      test('does not wrap when softWrap is false', () {
        final config = TextLayoutConfig(maxWidth: 5, softWrap: false);

        final result = TextLayoutEngine.layout('Hello world', config);

        expect(result.lines, ['Hello world']);
        expect(result.didOverflowWidth, true);
        expect(result.actualWidth, 11);
      });

      test('respects newlines even without soft wrap', () {
        final config = TextLayoutConfig(maxWidth: 5, softWrap: false);

        final result = TextLayoutEngine.layout('Hello\nworld', config);

        expect(result.lines, ['Hello', 'world']);
        expect(result.actualHeight, 2);
      });
    });

    group('Max lines constraint', () {
      test('limits lines to maxLines', () {
        final config = TextLayoutConfig(
          maxWidth: 10,
          softWrap: true,
          maxLines: 2,
        );

        final result = TextLayoutEngine.layout(
          'This is a very long text that spans multiple lines',
          config,
        );

        expect(result.lines.length, 2);
        expect(result.didOverflowHeight, true);
      });

      test('adds ellipsis when overflow is ellipsis', () {
        final config = TextLayoutConfig(
          maxWidth: 10,
          softWrap: true,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );

        final result = TextLayoutEngine.layout(
          'This is a very long text that spans multiple lines',
          config,
        );

        expect(result.lines.length, 2);
        expect(result.lines.last.endsWith('...'), true);
        expect(result.didOverflowHeight, true);
      });

      test('ellipsis respects max width', () {
        final config = TextLayoutConfig(
          maxWidth: 10,
          softWrap: true,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

        final result = TextLayoutEngine.layout('Hello world test', config);

        expect(result.lines.length, 1);
        // The word wrapper puts "Hello " on first line, then adds ellipsis
        expect(result.lines[0], 'Hello ...');
        // Should fit within max width (10 chars)
        expect(result.lines[0].length, lessThanOrEqualTo(10));
      });
    });

    group('Text alignment', () {
      test('calculates left alignment offset', () {
        final offset = TextLayoutEngine.calculateAlignmentOffset(
          'Hello',
          10,
          TextAlign.left,
        );

        expect(offset, 0);
      });

      test('calculates right alignment offset', () {
        final offset = TextLayoutEngine.calculateAlignmentOffset(
          'Hello', // 5 chars
          10,
          TextAlign.right,
        );

        expect(offset, 5);
      });

      test('calculates center alignment offset', () {
        final offset = TextLayoutEngine.calculateAlignmentOffset(
          'Hello', // 5 chars
          10,
          TextAlign.center,
        );

        expect(offset, 2.5);
      });
    });

    group('Text justification', () {
      test('justifies text by adding spaces', () {
        final justified = TextLayoutEngine.justifyLine(
          'Hello world',
          15,
          isLastLine: false,
        );

        expect(justified.length, 15);
        expect(justified.startsWith('Hello'), true);
        expect(justified.endsWith('world'), true);
        expect(justified.contains('  '), true); // Should have extra spaces
      });

      test('does not justify last line', () {
        final justified = TextLayoutEngine.justifyLine(
          'Hello world',
          15,
          isLastLine: true,
        );

        expect(justified, 'Hello world');
      });

      test('does not justify single word', () {
        final justified = TextLayoutEngine.justifyLine(
          'Hello',
          10,
          isLastLine: false,
        );

        expect(justified, 'Hello');
      });

      test('distributes spaces evenly', () {
        final justified = TextLayoutEngine.justifyLine(
          'The quick fox',
          20,
          isLastLine: false,
        );

        expect(justified.length, 20);
        // "The quick fox" = 11 chars, need 9 spaces across 2 gaps
        // Should get 4-5 spaces per gap
        expect(RegExp(r'\s+').allMatches(justified).length, 2);
      });
    });

    group('Unicode support', () {
      test('handles emoji correctly', () {
        final config = TextLayoutConfig(maxWidth: 10, softWrap: true);

        // Emoji typically take 2 columns
        final result = TextLayoutEngine.layout('Hello 😀 world', config);

        // "Hello " = 6, "😀" = 2, " " = 1 = 9 total (fits)
        // "world" = 5 (next line)
        expect(result.lines.length, 2);
      });

      test('handles CJK characters', () {
        final config = TextLayoutConfig(maxWidth: 10, softWrap: true);

        // CJK characters typically take 2 columns each
        final result = TextLayoutEngine.layout('你好世界 test', config);

        // "你好世界" = 8 columns, " test" = 5
        expect(result.lines.length, 2);
      });
    });

    group('Edge cases', () {
      test('handles empty string', () {
        final config = TextLayoutConfig(maxWidth: 10, softWrap: true);

        final result = TextLayoutEngine.layout('', config);

        expect(result.lines, ['']);
        expect(result.actualWidth, 0);
        expect(result.actualHeight, 1);
      });

      test('handles single character', () {
        final config = TextLayoutConfig(maxWidth: 10, softWrap: true);

        final result = TextLayoutEngine.layout('a', config);

        expect(result.lines, ['a']);
        expect(result.actualWidth, 1);
      });

      test('handles only spaces', () {
        final config = TextLayoutConfig(maxWidth: 5, softWrap: true);

        final result = TextLayoutEngine.layout('     ', config);

        expect(result.lines, ['     ']);
      });

      test('handles maxWidth of 1', () {
        final config = TextLayoutConfig(maxWidth: 1, softWrap: true);

        final result = TextLayoutEngine.layout('abc', config);

        expect(result.lines, ['a', 'b', 'c']);
        expect(result.actualHeight, 3);
      });
    });
  });
}
