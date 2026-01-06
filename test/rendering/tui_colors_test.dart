import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('TUI Color Rendering', () {
    test('basic foreground colors', () async {
      await testNocterm('foreground colors', (tester) async {
        await tester.pumpComponent(
          Column(
            children: const [
              Text('Red text', style: TextStyle(color: Colors.red)),
              Text('Green text', style: TextStyle(color: Colors.green)),
              Text('Blue text', style: TextStyle(color: Colors.blue)),
              Text('Yellow text', style: TextStyle(color: Colors.yellow)),
              Text('Magenta text', style: TextStyle(color: Colors.magenta)),
              Text('Cyan text', style: TextStyle(color: Colors.cyan)),
              Text('White text', style: TextStyle(color: Colors.white)),
              Text('Black text', style: TextStyle(color: Colors.black)),
              Text('Gray text', style: TextStyle(color: Colors.gray)),
            ],
          ),
        );

        expect(tester.terminalState, containsText('Red text'));
        expect(tester.terminalState, containsText('Green text'));
        expect(tester.terminalState, containsText('Blue text'));
        expect(tester.terminalState, containsText('Yellow text'));
        expect(tester.terminalState, containsText('Magenta text'));
        expect(tester.terminalState, containsText('Cyan text'));
        expect(tester.terminalState, containsText('White text'));
        expect(tester.terminalState, containsText('Black text'));
        expect(tester.terminalState, containsText('Gray text'));
      });
    });

    test('background colors', () async {
      await testNocterm('background colors', (tester) async {
        await tester.pumpComponent(
          Column(
            children: const [
              Text(
                'White on red',
                style: TextStyle(
                  color: Colors.white,
                  backgroundColor: Colors.red,
                ),
              ),
              Text(
                'Black on green',
                style: TextStyle(
                  color: Colors.black,
                  backgroundColor: Colors.green,
                ),
              ),
              Text(
                'Yellow on blue',
                style: TextStyle(
                  color: Colors.yellow,
                  backgroundColor: Colors.blue,
                ),
              ),
              Text(
                'Cyan on magenta',
                style: TextStyle(
                  color: Colors.cyan,
                  backgroundColor: Colors.magenta,
                ),
              ),
              Text(
                'Magenta on cyan',
                style: TextStyle(
                  color: Colors.magenta,
                  backgroundColor: Colors.cyan,
                ),
              ),
              Text(
                'Blue on yellow',
                style: TextStyle(
                  color: Colors.blue,
                  backgroundColor: Colors.yellow,
                ),
              ),
            ],
          ),
        );

        expect(tester.terminalState, containsText('White on red'));
        expect(tester.terminalState, containsText('Black on green'));
        expect(tester.terminalState, containsText('Yellow on blue'));
        expect(tester.terminalState, containsText('Cyan on magenta'));
        expect(tester.terminalState, containsText('Magenta on cyan'));
        expect(tester.terminalState, containsText('Blue on yellow'));
      });
    });

    test('text styles', () async {
      await testNocterm('text styles', (tester) async {
        await tester.pumpComponent(
          Column(
            children: const [
              Text('Bold text', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                'Italic text',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              Text(
                'Underlined text',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
              Text('Dim text', style: TextStyle(fontWeight: FontWeight.dim)),
              Text(
                'Bold and red',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              Text(
                'Italic and blue',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.blue,
                ),
              ),
              Text(
                'Underlined green',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        );

        expect(tester.terminalState, containsText('Bold text'));
        expect(tester.terminalState, containsText('Italic text'));
        expect(tester.terminalState, containsText('Underlined text'));
        expect(tester.terminalState, containsText('Dim text'));
        expect(tester.terminalState, containsText('Bold and red'));
        expect(tester.terminalState, containsText('Italic and blue'));
        expect(tester.terminalState, containsText('Underlined green'));

        // Check that styled text is detected
        expect(
          tester.terminalState,
          hasStyledText('Bold text', TextStyle(fontWeight: FontWeight.bold)),
        );
        expect(
          tester.terminalState,
          hasStyledText('Italic text', TextStyle(fontStyle: FontStyle.italic)),
        );
      });
    });

    test('RGB colors', () async {
      await testNocterm('RGB colors', (tester) async {
        await tester.pumpComponent(
          Column(
            children: [
              Text(
                'Orange (255,128,0)',
                style: TextStyle(color: Color.fromRGB(255, 128, 0)),
              ),
              Text(
                'Purple (128,0,255)',
                style: TextStyle(color: Color.fromRGB(128, 0, 255)),
              ),
              Text(
                'Teal (0,128,128)',
                style: TextStyle(color: Color.fromRGB(0, 128, 128)),
              ),
              Text(
                'Pink (255,192,203)',
                style: TextStyle(color: Color.fromRGB(255, 192, 203)),
              ),
              Text(
                'Brown (139,69,19)',
                style: TextStyle(color: Color.fromRGB(139, 69, 19)),
              ),
              Text(
                'Lime (0,255,0)',
                style: TextStyle(color: Color.fromRGB(0, 255, 0)),
              ),
            ],
          ),
        );

        expect(tester.terminalState, containsText('Orange (255,128,0)'));
        expect(tester.terminalState, containsText('Purple (128,0,255)'));
        expect(tester.terminalState, containsText('Teal (0,128,128)'));
        expect(tester.terminalState, containsText('Pink (255,192,203)'));
        expect(tester.terminalState, containsText('Brown (139,69,19)'));
        expect(tester.terminalState, containsText('Lime (0,255,0)'));
      });
    });

    test('combined styles', () async {
      await testNocterm('combined styles', (tester) async {
        await tester.pumpComponent(
          Column(
            children: const [
              Text(
                'Bold red on yellow',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  backgroundColor: Colors.yellow,
                ),
              ),
              Text(
                'Italic underlined blue',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
              ),
              Text(
                'Dim green on black',
                style: TextStyle(
                  fontWeight: FontWeight.dim,
                  color: Colors.green,
                  backgroundColor: Colors.black,
                ),
              ),
              Text(
                'Bold italic magenta',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.magenta,
                ),
              ),
            ],
          ),
        );

        expect(tester.terminalState, containsText('Bold red on yellow'));
        expect(tester.terminalState, containsText('Italic underlined blue'));
        expect(tester.terminalState, containsText('Dim green on black'));
        expect(tester.terminalState, containsText('Bold italic magenta'));
      });
    });

    test('color in containers', () async {
      await testNocterm('colors in containers', (tester) async {
        await tester.pumpComponent(
          Column(
            children: [
              Container(
                color: Color.fromRGB(0, 0, 64),
                padding: const EdgeInsets.all(2),
                child: Text(
                  'White text on dark blue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 1),
              Container(
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.red),
                  color: Color.fromRGB(64, 0, 0),
                ),
                padding: const EdgeInsets.all(2),
                child: Text(
                  'Yellow text in red border',
                  style: TextStyle(color: Colors.yellow),
                ),
              ),
              SizedBox(height: 1),
              Container(
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.green, width: 2),
                ),
                padding: const EdgeInsets.all(1),
                child: Text(
                  'Green double border',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        expect(tester.terminalState, containsText('White text on dark blue'));
        expect(tester.terminalState, containsText('Yellow text in red border'));
        expect(tester.terminalState, containsText('Green double border'));
      });
    });

    // Visual test for manual inspection
    test(
      'colors visual test',
      skip: 'Run with debugPrintAfterPump for visual inspection',
      () async {
        await testNocterm(
          'colors visual',
          (tester) async {
            await tester.pumpComponent(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '=== TUI Colors Test ===',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Basic Colors:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: const [
                      Text('█', style: TextStyle(color: Colors.red)),
                      Text('█', style: TextStyle(color: Colors.green)),
                      Text('█', style: TextStyle(color: Colors.blue)),
                      Text('█', style: TextStyle(color: Colors.yellow)),
                      Text('█', style: TextStyle(color: Colors.magenta)),
                      Text('█', style: TextStyle(color: Colors.cyan)),
                      Text('█', style: TextStyle(color: Colors.white)),
                      Text(
                        '█',
                        style: TextStyle(
                          color: Colors.black,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Backgrounds:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: const [
                      Text(
                        ' R ',
                        style: TextStyle(
                          color: Colors.white,
                          backgroundColor: Colors.red,
                        ),
                      ),
                      Text(
                        ' G ',
                        style: TextStyle(
                          color: Colors.black,
                          backgroundColor: Colors.green,
                        ),
                      ),
                      Text(
                        ' B ',
                        style: TextStyle(
                          color: Colors.white,
                          backgroundColor: Colors.blue,
                        ),
                      ),
                      Text(
                        ' Y ',
                        style: TextStyle(
                          color: Colors.black,
                          backgroundColor: Colors.yellow,
                        ),
                      ),
                      Text(
                        ' M ',
                        style: TextStyle(
                          color: Colors.white,
                          backgroundColor: Colors.magenta,
                        ),
                      ),
                      Text(
                        ' C ',
                        style: TextStyle(
                          color: Colors.black,
                          backgroundColor: Colors.cyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Styles:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Bold',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Italic',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const Text(
                    'Underline',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                  const Text(
                    'Dim',
                    style: TextStyle(fontWeight: FontWeight.dim),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'RGB Colors:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Orange',
                    style: TextStyle(color: Color.fromRGB(255, 165, 0)),
                  ),
                  Text(
                    'Pink',
                    style: TextStyle(color: Color.fromRGB(255, 192, 203)),
                  ),
                  Text(
                    'Purple',
                    style: TextStyle(color: Color.fromRGB(128, 0, 128)),
                  ),
                  Text(
                    'Teal',
                    style: TextStyle(color: Color.fromRGB(0, 128, 128)),
                  ),
                ],
              ),
            );

            expect(tester.terminalState, containsText('TUI Colors Test'));
          },
          // debugPrintAfterPump: true, // Uncomment to see visual output
        );
      },
    );
  });
}
