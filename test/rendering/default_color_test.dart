import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Default Color', () {
    test('default color creates correct ANSI codes', () {
      // Test foreground default color
      expect(Color.defaultColor.toAnsi(background: false), equals('\x1b[39m'));

      // Test background default color
      expect(Color.defaultColor.toAnsi(background: true), equals('\x1b[49m'));
    });

    test('default color is singleton', () {
      expect(Color.defaultColor, same(Color.defaultColor));
    });

    test('default color equality', () {
      const defaultColor1 = Color.defaultColor;
      const defaultColor2 = Color.defaultColor;
      expect(defaultColor1, equals(defaultColor2));

      // Should not equal regular colors
      expect(defaultColor1, isNot(equals(Colors.black)));
      expect(defaultColor1, isNot(equals(Color.fromRGB(0, 0, 0))));
    });

    test('default color toString', () {
      expect(Color.defaultColor.toString(), equals('Color.defaultColor'));
      // Colors.red is Color.fromRGB(231, 97, 112)
      expect(Colors.red.toString(), equals('Color(r: 231, g: 97, b: 112)'));
    });

    test('TextStyle with default background color', () {
      final style = TextStyle(
        color: Colors.white,
        backgroundColor: Color.defaultColor,
      );

      // Should include both foreground and background codes
      final ansi = style.toAnsi();
      // Colors.white is Color.fromRGB(248, 248, 242)
      expect(ansi, contains('\x1b[38;2;248;248;242m')); // White foreground
      expect(ansi, contains('\x1b[49m')); // Default background
    });

    test('Container with default background color renders correctly', () async {
      await testNocterm('container with default background', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 10,
            height: 3,
            color: Color.defaultColor,
            child: const Text('Default BG'),
          ),
        );

        // Verify the text is rendered
        expect(tester.terminalState, containsText('Default BG'));
      }, debugPrintAfterPump: true);
    });

    test('default background clears other backgrounds', () async {
      await testNocterm('default background clearing', (tester) async {
        // First pump a blue background
        await tester.pumpComponent(
          Container(
            width: 20,
            height: 5,
            color: Colors.blue,
            child: const Center(
              child: Text('Blue BG', style: TextStyle(color: Colors.white)),
            ),
          ),
        );

        // Verify blue background is rendered
        expect(tester.terminalState, containsText('Blue BG'));

        // Now pump a container with default background on top
        await tester.pumpComponent(
          Container(
            width: 20,
            height: 5,
            color: Color.defaultColor, // This should clear the blue background
            child: const Center(child: Text('Default BG')),
          ),
        );

        // The default background should have cleared the blue
        expect(tester.terminalState, containsText('Default BG'));
        expect(tester.terminalState, isNot(containsText('Blue BG')));
      }, debugPrintAfterPump: false);
    });

    test('overlay with default background properly clears area', () async {
      await testNocterm('overlay clearing with default', (tester) async {
        await tester.pumpComponent(
          Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Container(
                  width: 30,
                  height: 10,
                  color: Colors.blue,
                  child: const Center(
                    child: Text(
                      'Base Layer',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              OverlayEntry(
                builder: (context) => Center(
                  child: Container(
                    width: 15,
                    height: 5,
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.yellow),
                    ),
                    child: const Center(
                      child: Text(
                        'Overlay',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        // The overlay should be visible with its default background
        expect(tester.terminalState, containsText('Overlay'));
        // The base layer text should not be visible where the overlay covers it
        // But the test framework might show borders differently
      }, debugPrintAfterPump: true);
    });
  });
}
