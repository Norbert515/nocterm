// ignore_for_file: unused_local_variable

import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('RenderMouseRegion.hitTest', () {
    test('GestureDetector nested in MouseRegion receives tap events', () async {
      await testNocterm('nested gesture detector hit test', (tester) async {
        bool tapReceived = false;
        bool mouseEntered = false;

        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: MouseRegion(
              onEnter: (event) {
                mouseEntered = true;
              },
              child: GestureDetector(
                onTap: () {
                  tapReceived = true;
                },
                child: Container(
                  width: 20,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.red),
                  child: const Text('Tap me'),
                ),
              ),
            ),
          ),
        );

        // Simulate a tap at position (10, 2) which should be inside the container
        await tester.tap(10, 2);

        // Verify that the tap was received by the GestureDetector
        expect(
          tapReceived,
          true,
          reason: 'GestureDetector should receive tap event',
        );
      });
    });

    test(
      'MouseRegion receives hover events while child receives taps',
      () async {
        await testNocterm('both mouse region and gesture detector work', (
          tester,
        ) async {
          bool tapReceived = false;
          bool mouseEntered = false;

          await tester.pumpComponent(
            Container(
              width: 80,
              height: 24,
              child: MouseRegion(
                onEnter: (event) {
                  mouseEntered = true;
                },
                child: GestureDetector(
                  onTap: () {
                    tapReceived = true;
                  },
                  child: Container(
                    width: 20,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.blue),
                    child: const Text('Click me'),
                  ),
                ),
              ),
            ),
          );

          // Simulate mouse enter
          await tester.hover(10, 2);
          expect(
            mouseEntered,
            true,
            reason: 'MouseRegion should receive enter event',
          );

          // Simulate tap - This is the key test for the bug fix
          await tester.tap(10, 2);
          expect(
            tapReceived,
            true,
            reason: 'GestureDetector should receive tap event',
          );
        });
      },
    );

    test('opaque MouseRegion still allows child tap events', () async {
      await testNocterm('opaque mouse region with gesture detector', (
        tester,
      ) async {
        bool tapReceived = false;
        bool mouseEntered = false;

        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: MouseRegion(
              opaque: true, // This is the key property that was causing issues
              onEnter: (event) {
                mouseEntered = true;
              },
              child: GestureDetector(
                onTap: () {
                  tapReceived = true;
                },
                child: Container(
                  width: 20,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.green),
                  child: const Text('Opaque test'),
                ),
              ),
            ),
          ),
        );

        // Hover first
        await tester.hover(10, 2);
        expect(
          mouseEntered,
          true,
          reason: 'MouseRegion should receive enter event',
        );

        // Tap - the critical test for the bug fix
        await tester.tap(10, 2);
        expect(
          tapReceived,
          true,
          reason:
              'GestureDetector should receive tap even when MouseRegion is opaque',
        );
      });
    });
  });
}
