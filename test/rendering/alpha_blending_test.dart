import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Color alpha support', () {
    test('Color.fromARGB creates color with alpha', () {
      const color = Color.fromARGB(128, 255, 0, 0);
      expect(color.alpha, equals(128));
      expect(color.red, equals(255));
      expect(color.green, equals(0));
      expect(color.blue, equals(0));
    });

    test('Color defaults to fully opaque', () {
      const color = Color(0xFF0000);
      expect(color.alpha, equals(255));
      expect(color.a, equals(1.0));
    });

    test('Color.fromRGB defaults to fully opaque', () {
      const color = Color.fromRGB(255, 0, 0);
      expect(color.alpha, equals(255));
      expect(color.a, equals(1.0));
    });

    test('normalized color channels work correctly', () {
      const color = Color.fromARGB(128, 255, 128, 0);
      expect(color.a, closeTo(0.5, 0.01));
      expect(color.r, closeTo(1.0, 0.01));
      expect(color.g, closeTo(0.5, 0.01));
      expect(color.b, closeTo(0.0, 0.01));
    });

    test('withOpacity creates new color with opacity', () {
      const color = Color(0xFF0000);
      final transparent = color.withOpacity(0.5);

      expect(transparent.alpha, equals(128));
      expect(transparent.red, equals(255));
      expect(transparent.green, equals(0));
      expect(transparent.blue, equals(0));
    });

    test('withAlpha creates new color with alpha', () {
      const color = Color(0xFF0000);
      final transparent = color.withAlpha(128);

      expect(transparent.alpha, equals(128));
      expect(transparent.red, equals(255));
      expect(transparent.green, equals(0));
      expect(transparent.blue, equals(0));
    });

    test('color equality includes alpha', () {
      const color1 = Color.fromARGB(255, 255, 0, 0);
      const color2 = Color.fromARGB(255, 255, 0, 0);
      const color3 = Color.fromARGB(128, 255, 0, 0);

      expect(color1, equals(color2));
      expect(color1, isNot(equals(color3)));
    });

    test('color toString includes alpha when not fully opaque', () {
      const opaque = Color.fromRGB(255, 0, 0);
      const transparent = Color.fromARGB(128, 255, 0, 0);

      expect(opaque.toString(), equals('Color(r: 255, g: 0, b: 0)'));
      expect(
        transparent.toString(),
        equals('Color(a: 128, r: 255, g: 0, b: 0)'),
      );
    });
  });

  group('Color.alphaBlend', () {
    test('fully opaque foreground returns foreground', () {
      const fg = Color.fromARGB(255, 255, 0, 0);
      const bg = Color.fromARGB(255, 0, 0, 255);

      final result = Color.alphaBlend(fg, bg);
      expect(result.red, equals(255));
      expect(result.green, equals(0));
      expect(result.blue, equals(0));
    });

    test('fully transparent foreground returns background', () {
      const fg = Color.fromARGB(0, 255, 0, 0);
      const bg = Color.fromARGB(255, 0, 0, 255);

      final result = Color.alphaBlend(fg, bg);
      expect(result.red, equals(0));
      expect(result.green, equals(0));
      expect(result.blue, equals(255));
    });

    test('50% alpha blends colors evenly', () {
      const fg = Color.fromARGB(128, 255, 0, 0); // 50% red
      const bg = Color.fromARGB(255, 0, 0, 255); // 100% blue

      final result = Color.alphaBlend(fg, bg);

      // Result should be roughly 50% red + 50% blue
      expect(result.red, greaterThan(100));
      expect(result.blue, greaterThan(100));
    });

    test('blending white over black with 50% alpha produces gray', () {
      const fg = Color.fromARGB(128, 255, 255, 255);
      const bg = Color.fromARGB(255, 0, 0, 0);

      final result = Color.alphaBlend(fg, bg);

      // Should be roughly 50% gray
      expect(result.red, closeTo(128, 5));
      expect(result.green, closeTo(128, 5));
      expect(result.blue, closeTo(128, 5));
    });

    test('blending produces opaque result', () {
      const fg = Color.fromARGB(128, 255, 0, 0);
      const bg = Color.fromARGB(255, 0, 0, 255);

      final result = Color.alphaBlend(fg, bg);

      // Result should be fully opaque since terminal doesn't support alpha
      expect(result.alpha, equals(255));
    });

    test('blending multiple layers', () {
      const bottom = Color.fromRGB(0, 0, 255); // Blue background
      const middle = Color.fromARGB(128, 0, 255, 0); // 50% green
      const top = Color.fromARGB(64, 255, 0, 0); // 25% red

      // Blend from bottom to top
      final step1 = Color.alphaBlend(middle, bottom);
      final result = Color.alphaBlend(top, step1);

      // Result should have components from all three colors
      expect(result.red, greaterThan(0));
      expect(result.green, greaterThan(0));
      expect(result.blue, greaterThan(0));
    });
  });

  group('Alpha blending rendering', () {
    test(
      'text with semi-transparent foreground blends with background',
      () async {
        await testNocterm(
          'semi-transparent text',
          (tester) async {
            await tester.pumpComponent(
              Container(
                color: Colors.blue,
                child: Text(
                  'Hello',
                  style: TextStyle(color: Colors.red.withOpacity(0.5)),
                ),
              ),
            );

            // Text should be rendered (can't easily verify exact blended color in test)
            expect(tester.terminalState, containsText('Hello'));
          },
          // debugPrintAfterPump: true, // Uncomment to see visual output
        );
      },
    );

    test('semi-transparent background blends with existing background', () async {
      await testNocterm(
        'semi-transparent background',
        (tester) async {
          await tester.pumpComponent(
            Stack(
              children: [
                Container(
                  width: 30,
                  color: Colors.blue,
                  child: const Text('Base Layer'),
                ),
                Positioned(
                  left: 10,
                  top: 0,
                  child: Container(
                    color: Colors.red.withOpacity(0.5),
                    child: const Text('Overlay'),
                  ),
                ),
              ],
            ),
          );

          // The overlay partially covers the base, so we check for parts that should be visible
          expect(tester.terminalState, containsText('Base'));
          expect(tester.terminalState, containsText('Overlay'));
        },
        // debugPrintAfterPump: true, // Uncomment to see visual output
      );
    });

    test('multiple layers of transparency stack correctly', () async {
      await testNocterm(
        'layered transparency',
        (tester) async {
          await tester.pumpComponent(
            Stack(
              children: [
                Container(
                  width: 20,
                  height: 5,
                  color: Colors.white,
                  child: const Text('Bottom'),
                ),
                Positioned(
                  left: 0,
                  top: 1,
                  child: Container(
                    width: 20,
                    height: 3,
                    color: Colors.blue.withOpacity(0.5),
                    child: const Text('Middle'),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 2,
                  child: Container(
                    width: 20,
                    height: 1,
                    color: Colors.red.withOpacity(0.5),
                    child: const Text('Top'),
                  ),
                ),
              ],
            ),
          );

          expect(tester.terminalState, containsText('Bottom'));
          expect(tester.terminalState, containsText('Middle'));
          expect(tester.terminalState, containsText('Top'));
        },
        // debugPrintAfterPump: true, // Uncomment to see visual output
      );
    });

    test('text with transparent foreground over colored background', () async {
      await testNocterm(
        'transparent text on colored bg',
        (tester) async {
          await tester.pumpComponent(
            Container(
              color: Colors.green,
              padding: const EdgeInsets.all(2),
              child: Text(
                'Faded Text',
                style: TextStyle(color: Colors.white.withOpacity(0.3)),
              ),
            ),
          );

          expect(tester.terminalState, containsText('Faded Text'));
        },
        // debugPrintAfterPump: true, // Uncomment to see visual output
      );
    });

    test('zero opacity makes color fully transparent', () async {
      await testNocterm('fully transparent text', (tester) async {
        await tester.pumpComponent(
          Container(
            color: Colors.blue,
            child: Text(
              'Invisible',
              style: TextStyle(color: Colors.red.withOpacity(0.0)),
            ),
          ),
        );

        // Text should still be there (just same color as background)
        expect(tester.terminalState, containsText('Invisible'));
      });
    });

    test('full opacity works same as before', () async {
      await testNocterm('fully opaque colors', (tester) async {
        await tester.pumpComponent(
          Container(
            color: Colors.blue.withOpacity(1.0),
            child: Text(
              'Solid',
              style: TextStyle(color: Colors.red.withOpacity(1.0)),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Solid'));
      });
    });
  });

  group('Alpha blending edge cases', () {
    test('blending with defaultColor', () {
      const fg = Color.fromARGB(128, 255, 0, 0);
      const bg = Color.defaultColor;

      // Should not throw
      final result = Color.alphaBlend(fg, bg);
      expect(result.alpha, equals(255));
    });

    test('very low alpha values', () {
      const fg = Color.fromARGB(1, 255, 0, 0);
      const bg = Color.fromARGB(255, 0, 0, 255);

      final result = Color.alphaBlend(fg, bg);

      // Should be almost entirely background
      expect(result.blue, greaterThan(250));
    });

    test('very high alpha values', () {
      const fg = Color.fromARGB(254, 255, 0, 0);
      const bg = Color.fromARGB(255, 0, 0, 255);

      final result = Color.alphaBlend(fg, bg);

      // Should be almost entirely foreground
      expect(result.red, greaterThan(250));
    });
  });

  group('Visual development tests', () {
    test('visual: alpha gradient on colored background', () async {
      await testNocterm(
        'alpha gradient visualization',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 40,
              height: 10,
              color: Colors.blue,
              child: Column(
                children: [
                  Text(
                    '100%',
                    style: TextStyle(color: Colors.white.withOpacity(1.0)),
                  ),
                  Text(
                    ' 80%',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                  Text(
                    ' 60%',
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                  Text(
                    ' 40%',
                    style: TextStyle(color: Colors.white.withOpacity(0.4)),
                  ),
                  Text(
                    ' 20%',
                    style: TextStyle(color: Colors.white.withOpacity(0.2)),
                  ),
                  Text(
                    '  0%',
                    style: TextStyle(color: Colors.white.withOpacity(0.0)),
                  ),
                ],
              ),
            ),
          );

          expect(tester.terminalState, containsText('100%'));
          expect(tester.terminalState, containsText('0%'));
        },
        // debugPrintAfterPump: true, // ENABLE THIS to see the gradient
      );
    });

    test('visual: semi-transparent overlay effect', () async {
      await testNocterm(
        'overlay effect',
        (tester) async {
          await tester.pumpComponent(
            Stack(
              children: [
                Container(
                  width: 30,
                  height: 7,
                  color: Colors.green,
                  child: const Column(
                    children: [
                      Text('Base content here'),
                      Text('More text below'),
                      Text('Even more text'),
                    ],
                  ),
                ),
                Positioned(
                  left: 5,
                  top: 2,
                  child: Container(
                    width: 20,
                    height: 3,
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: Text('OVERLAY')),
                  ),
                ),
              ],
            ),
          );

          expect(tester.terminalState, containsText('OVERLAY'));
          expect(tester.terminalState, containsText('Base content'));
        },
        // debugPrintAfterPump: true, // ENABLE THIS to see the overlay
      );
    });
  });
}
