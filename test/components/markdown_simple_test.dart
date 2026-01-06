import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('MarkdownText Simple', () {
    test('renders simple paragraph without wrapping', () async {
      await testNocterm('simple paragraph', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 100, // Wide enough to not wrap
            child: const MarkdownText('First paragraph.'),
          ),
        );

        expect(tester.terminalState, containsText('First paragraph.'));
      }, debugPrintAfterPump: true);
    });

    test(
      'renders two paragraphs',
      skip: 'Known issue: Markdown paragraph spacing',
      () async {
        await testNocterm('two paragraphs', (tester) async {
          await tester.pumpComponent(
            Container(
              width: 100, // Wide enough to not wrap
              child: const MarkdownText('''First paragraph.

Second paragraph.'''),
            ),
          );

          print('=== Two Paragraphs Output ===');
          final output = tester.terminalState.toString();
          final lines = output.split('\n');
          for (int i = 0; i < lines.length && i < 10; i++) {
            print('Line $i: "${lines[i]}"');
          }

          expect(tester.terminalState, containsText('First paragraph.'));
          expect(tester.terminalState, containsText('Second paragraph.'));
        }, debugPrintAfterPump: true);
      },
    );

    test('renders plain text spans correctly', () async {
      await testNocterm('plain text spans', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 100,
            child: const MarkdownText('This is plain text with no formatting.'),
          ),
        );

        expect(
          tester.terminalState,
          containsText('This is plain text with no formatting.'),
        );
      }, debugPrintAfterPump: true);
    });

    test('check line-by-line output', () async {
      await testNocterm('line by line', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 50,
            child: const MarkdownText('''First.

Second.

Third.'''),
          ),
        );

        print('=== Line by Line Output ===');
        final lines = tester.terminalState.toString().split('\n');
        int contentLineCount = 0;
        for (int i = 0; i < lines.length; i++) {
          final trimmed = lines[i].trim();
          if (trimmed.isNotEmpty && !trimmed.contains('Instance of')) {
            print('Content line $contentLineCount: "$trimmed"');
            contentLineCount++;
          }
        }

        expect(tester.terminalState, containsText('First.'));
        expect(tester.terminalState, containsText('Second.'));
        expect(tester.terminalState, containsText('Third.'));
      }, debugPrintAfterPump: true);
    });
  });
}
