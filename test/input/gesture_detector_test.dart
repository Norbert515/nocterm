import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('GestureDetector', () {
    test('visual development - tap visualization', () async {
      await testNocterm('tap visualization', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 20,
                height: 5,
                decoration: BoxDecoration(border: BoxBorder.all()),
                child: const Text('Click me'),
              ),
            ),
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test('triggers onTap on click', () async {
      await testNocterm('onTap callback', (tester) async {
        int tapCount = 0;

        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: GestureDetector(
              onTap: () => tapCount++,
              child: Container(
                width: 10,
                height: 3,
                child: const Text('Tap me'),
              ),
            ),
          ),
        );

        expect(tapCount, 0);

        // Tap inside the detector
        await tester.tap(5, 1);

        expect(tapCount, 1);

        // Tap again
        await tester.tap(7, 2);

        expect(tapCount, 2);
      });
    });

    test('triggers onTapDown and onTapUp', () async {
      await testNocterm('onTapDown and onTapUp callbacks', (tester) async {
        bool tapDownCalled = false;
        bool tapUpCalled = false;
        double? downX, downY;
        double? upX, upY;

        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: GestureDetector(
              onTapDown: (details) {
                tapDownCalled = true;
                downX = details.localPosition.dx;
                downY = details.localPosition.dy;
              },
              onTapUp: (details) {
                tapUpCalled = true;
                upX = details.localPosition.dx;
                upY = details.localPosition.dy;
              },
              child: Container(
                width: 10,
                height: 3,
                child: const Text('Tap me'),
              ),
            ),
          ),
        );

        expect(tapDownCalled, false);
        expect(tapUpCalled, false);

        // Perform tap
        await tester.tap(5, 1);

        expect(tapDownCalled, true);
        expect(tapUpCalled, true);
        expect(downX, closeTo(5.0, 0.1));
        expect(downY, closeTo(1.0, 0.1));
        expect(upX, closeTo(5.0, 0.1));
        expect(upY, closeTo(1.0, 0.1));
      });
    });

    test('triggers onDoubleTap on double click', () async {
      await testNocterm('onDoubleTap callback', (tester) async {
        int doubleTapCount = 0;

        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: GestureDetector(
              onDoubleTap: () => doubleTapCount++,
              child: Container(
                width: 10,
                height: 3,
                child: const Text('Double tap'),
              ),
            ),
          ),
        );

        expect(doubleTapCount, 0);

        // First tap
        await tester.tap(5, 1);
        expect(doubleTapCount, 0);

        // Second tap quickly (should trigger double tap)
        await tester.tap(5, 1);

        // Double tap should be triggered
        expect(doubleTapCount, 1);
      });
    });

    test(
      'triggers onLongPress when held',
      skip: 'Known issue: Long press timer not advancing in test environment',
      () async {
        await testNocterm('onLongPress callback', (tester) async {
          int longPressCount = 0;

          await tester.pumpComponent(
            Container(
              width: 80,
              height: 24,
              child: GestureDetector(
                onLongPress: () => longPressCount++,
                child: Container(
                  width: 10,
                  height: 3,
                  child: const Text('Long press'),
                ),
              ),
            ),
          );

          expect(longPressCount, 0);

          // Press and hold
          await tester.press(5, 1);

          // Wait for long press duration
          await tester.pump(const Duration(milliseconds: 600));

          expect(longPressCount, 1);

          // Release
          await tester.release(5, 1);
        });
      },
    );

    test('does not trigger onTap outside detector', () async {
      await testNocterm('no tap outside', (tester) async {
        int tapCount = 0;

        // Use Stack with Positioned to create a small GestureDetector
        // that doesn't fill its parent. This properly tests hit testing
        // boundaries.
        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () => tapCount++,
                    child: Container(
                      width: 10,
                      height: 3,
                      child: const Text('Tap me'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // Tap outside the detector (which is positioned at 0,0 with size 10x3)
        await tester.tap(50, 10);

        expect(tapCount, 0);
      });
    });

    test('HitTestBehavior.deferToChild defers to child', () async {
      await testNocterm('deferToChild behavior', (tester) async {
        int outerTaps = 0;
        int innerTaps = 0;

        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: () => outerTaps++,
              child: Container(
                width: 20,
                height: 10,
                child: GestureDetector(
                  onTap: () => innerTaps++,
                  child: Container(
                    width: 10,
                    height: 5,
                    child: const Text('Inner'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Tap on inner detector
        await tester.tap(5, 2);

        // Both should register
        expect(innerTaps, 1);
        expect(outerTaps, 1);
      });
    });

    test('HitTestBehavior.opaque blocks hits behind', () async {
      await testNocterm('opaque behavior', (tester) async {
        int topTaps = 0;
        int bottomTaps = 0;

        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => bottomTaps++,
                  child: Container(
                    width: 20,
                    height: 10,
                    child: const Text('Bottom'),
                  ),
                ),
                Positioned(
                  left: 5,
                  top: 5,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => topTaps++,
                    child: Container(
                      width: 10,
                      height: 5,
                      child: const Text('Top'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // Tap on overlapping area
        await tester.tap(8, 7);

        // Only top should register with opaque behavior
        expect(topTaps, 1);
        expect(bottomTaps, 0);
      });
    });

    test(
      'onLongPressStart and onLongPressEnd callbacks',
      skip: 'Known issue: Long press timer not advancing in test environment',
      () async {
        await testNocterm('long press start and end', (tester) async {
          bool longPressStarted = false;
          bool longPressEnded = false;
          double? startX, startY;
          double? endX, endY;

          await tester.pumpComponent(
            Container(
              width: 80,
              height: 24,
              child: GestureDetector(
                onLongPressStart: (details) {
                  longPressStarted = true;
                  startX = details.localPosition.dx;
                  startY = details.localPosition.dy;
                },
                onLongPressEnd: (details) {
                  longPressEnded = true;
                  endX = details.localPosition.dx;
                  endY = details.localPosition.dy;
                },
                child: Container(
                  width: 10,
                  height: 3,
                  child: const Text('Long press'),
                ),
              ),
            ),
          );

          // Press
          await tester.press(5, 1);

          // Wait for long press
          await tester.pump(const Duration(milliseconds: 600));

          expect(longPressStarted, true);
          expect(longPressEnded, false);

          // Release
          await tester.release(5, 1);

          expect(longPressEnded, true);
          expect(startX, closeTo(5.0, 0.1));
          expect(startY, closeTo(1.0, 0.1));
          expect(endX, closeTo(5.0, 0.1));
          expect(endY, closeTo(1.0, 0.1));
        });
      },
    );
  });
}
