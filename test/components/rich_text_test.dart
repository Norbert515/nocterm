import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/components/rich_text.dart';
import 'package:test/test.dart';

void main() {
  group('RichText', () {
    test('renders simple text span', () async {
      await testNocterm('simple text span', (tester) async {
        await tester.pumpComponent(
          RichText(
            text: const TextSpan(
              text: 'Hello, World!',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Hello, World!'));
      }, debugPrintAfterPump: true);
    });

    test('renders nested text spans with different styles', () async {
      await testNocterm('nested text spans', (tester) async {
        await tester.pumpComponent(
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(text: 'This is '),
                TextSpan(
                  text: 'bold',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' and this is '),
                TextSpan(
                  text: 'italic',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                TextSpan(text: ' text.'),
              ],
            ),
          ),
        );

        expect(
          tester.terminalState,
          containsText('This is bold and this is italic text.'),
        );
      }, debugPrintAfterPump: true);
    });

    test('renders colored text spans', () async {
      await testNocterm('colored text spans', (tester) async {
        await tester.pumpComponent(
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Red ',
                  style: TextStyle(color: Colors.red),
                ),
                TextSpan(
                  text: 'Green ',
                  style: TextStyle(color: Colors.green),
                ),
                TextSpan(
                  text: 'Blue',
                  style: TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),
        );

        expect(tester.terminalState, containsText('Red Green Blue'));
      }, debugPrintAfterPump: true);
    });

    test('handles text wrapping', () async {
      await testNocterm('text wrapping', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 20,
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(text: 'This is a '),
                  TextSpan(
                    text: 'very long',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' piece of text that should wrap properly.'),
                ],
              ),
            ),
          ),
        );

        // The text should wrap within the 20 character width
        expect(tester.terminalState, containsText('This is a very long'));
        expect(tester.terminalState, containsText('piece of text that'));
        expect(tester.terminalState, containsText('should wrap'));
      }, debugPrintAfterPump: true);
    });

    test('handles mixed styles with backgrounds', () async {
      await testNocterm('mixed styles with backgrounds', (tester) async {
        await tester.pumpComponent(
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(text: 'Normal '),
                TextSpan(
                  text: 'highlighted',
                  style: TextStyle(
                    color: Colors.black,
                    backgroundColor: Colors.yellow,
                  ),
                ),
                TextSpan(text: ' text with '),
                TextSpan(
                  text: 'code',
                  style: TextStyle(
                    color: Colors.green,
                    backgroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );

        expect(
          tester.terminalState,
          containsText('Normal highlighted text with code'),
        );
      }, debugPrintAfterPump: true);
    });

    test('respects text alignment', () async {
      await testNocterm('text alignment', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RichText(
                  text: const TextSpan(text: 'Left'),
                  textAlign: TextAlign.left,
                ),
                RichText(
                  text: const TextSpan(text: 'Center'),
                  textAlign: TextAlign.center,
                ),
                RichText(
                  text: const TextSpan(text: 'Right'),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        );

        // Check that text appears at different positions
        expect(tester.terminalState, containsText('Left'));
        expect(tester.terminalState, containsText('Center'));
        expect(tester.terminalState, containsText('Right'));
      }, debugPrintAfterPump: true);
    });

    test(
      'handles overflow with ellipsis',
      skip: 'Feature not implemented: RichText overflow ellipsis',
      () async {
        await testNocterm('overflow with ellipsis', (tester) async {
          await tester.pumpComponent(
            Container(
              width: 15,
              child: RichText(
                text: const TextSpan(
                  text: 'This is a very long text that should be truncated',
                ),
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );

          // Should show ellipsis at the end
          expect(tester.terminalState, containsText('...'));
        }, debugPrintAfterPump: true);
      },
    );

    test(
      'handles max lines constraint',
      skip: 'Feature not implemented: RichText maxLines',
      () async {
        await testNocterm('max lines constraint', (tester) async {
          await tester.pumpComponent(
            Container(
              width: 20,
              child: RichText(
                text: const TextSpan(
                  text:
                      'This is a very long piece of text that should wrap across multiple lines but be limited to only two lines maximum.',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );

          // Should only show 2 lines with ellipsis
          // We can check that the text is truncated by looking for the ellipsis
          expect(tester.terminalState, containsText('...'));
        }, debugPrintAfterPump: true);
      },
    );
  });
}
