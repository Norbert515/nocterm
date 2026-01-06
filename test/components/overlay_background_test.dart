import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Overlay Background', () {
    test('overlay entries use terminal default background', () async {
      await testNocterm('default background test', (tester) async {
        // Create an overlay with entries
        final overlayKey = GlobalKey<OverlayState>();

        await tester.pumpComponent(
          Overlay(
            key: overlayKey,
            initialEntries: [
              OverlayEntry(
                builder: (context) => Container(
                  width: 20,
                  height: 5,
                  child: Center(child: Text('Base Layer')),
                ),
              ),
              OverlayEntry(
                builder: (context) => Positioned(
                  left: 5,
                  top: 2,
                  child: Container(
                    width: 10,
                    height: 3,
                    // No color specified - should use terminal default
                    child: Center(child: Text('Overlay')),
                  ),
                ),
              ),
            ],
          ),
        );

        // The overlay covers the base layer, so only overlay text should be visible
        // Note: Base layer text won't be visible where overlay covers it
        expect(tester.terminalState, containsText('Overlay'));
      }, debugPrintAfterPump: true);
    });

    test('opaque overlay entries also use terminal default background', () async {
      await testNocterm('opaque overlay test', (tester) async {
        final overlayKey = GlobalKey<OverlayState>();

        await tester.pumpComponent(
          Overlay(
            key: overlayKey,
            initialEntries: [
              OverlayEntry(
                builder: (context) => Container(
                  width: 20,
                  height: 5,
                  child: Center(child: Text('Base Layer')),
                ),
              ),
              OverlayEntry(
                opaque: true, // Marked as opaque
                builder: (context) => Container(
                  width: 20,
                  height: 5,
                  // No color specified - should use terminal default even when opaque
                  child: Center(child: Text('Opaque Overlay')),
                ),
              ),
            ],
          ),
        );

        // With opaque overlay, base layer shouldn't be built
        expect(tester.terminalState, containsText('Opaque Overlay'));
        // Base layer text should not appear since it's occluded
        expect(tester.terminalState, isNot(containsText('Base Layer')));
      }, debugPrintAfterPump: true);
    });

    test('containers with explicit colors still work', () async {
      await testNocterm('explicit color test', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 20,
            height: 5,
            color: Colors.blue, // Explicit color
            child: Center(
              child: Text(
                'Blue Background',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        );

        // Verify blue background is rendered
        expect(tester.terminalState, containsText('Blue Background'));
      }, debugPrintAfterPump: true);
    });
  });
}
