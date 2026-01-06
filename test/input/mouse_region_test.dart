import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('MouseRegion', () {
    test('visual development - hover visualization', () async {
      await testNocterm('hover visualization', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: MouseRegion(
              onHover: (_) {},
              child: Container(
                width: 20,
                height: 5,
                decoration: BoxDecoration(border: BoxBorder.all()),
                child: const Text('Hover over me'),
              ),
            ),
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test('triggers onEnter when mouse enters', () async {
      await testNocterm('onEnter callback', (tester) async {
        bool entered = false;
        int enterX = -1;
        int enterY = -1;

        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: MouseRegion(
              onEnter: (event) {
                entered = true;
                enterX = event.x;
                enterY = event.y;
              },
              child: Container(
                width: 10,
                height: 3,
                child: const Text('Target'),
              ),
            ),
          ),
        );

        expect(entered, false);

        // Move mouse into the region
        await tester.hover(5, 1);

        expect(entered, true);
        expect(enterX, 5);
        expect(enterY, 1);
      });
    });

    test('triggers onExit when mouse leaves', () async {
      await testNocterm('onExit callback', (tester) async {
        bool exited = false;
        int exitX = -1;
        int exitY = -1;

        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: Align(
              alignment: Alignment.topLeft,
              child: MouseRegion(
                onExit: (event) {
                  exited = true;
                  exitX = event.x;
                  exitY = event.y;
                },
                child: Container(
                  width: 10,
                  height: 3,
                  child: const Text('Target'),
                ),
              ),
            ),
          ),
        );

        // Move mouse into the region first
        await tester.hover(5, 1);
        expect(exited, false);

        // Move mouse out of the region
        await tester.hover(15, 1);

        expect(exited, true);
        expect(exitX, 15);
        expect(exitY, 1);
      });
    });

    test('triggers onHover when mouse moves inside', () async {
      await testNocterm('onHover callback', (tester) async {
        int hoverCount = 0;
        int lastX = -1;
        int lastY = -1;

        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: MouseRegion(
              onHover: (event) {
                hoverCount++;
                lastX = event.x;
                lastY = event.y;
              },
              child: Container(
                width: 10,
                height: 3,
                child: const Text('Target'),
              ),
            ),
          ),
        );

        expect(hoverCount, 0);

        // Move mouse to different positions inside the region
        await tester.hover(2, 1);
        expect(hoverCount, 1);
        expect(lastX, 2);
        expect(lastY, 1);

        await tester.hover(5, 2);
        expect(hoverCount, 2);
        expect(lastX, 5);
        expect(lastY, 2);
      });
    });

    test('does not trigger callbacks outside region', () async {
      await testNocterm('no callbacks outside region', (tester) async {
        bool entered = false;
        bool hovered = false;

        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: Align(
              alignment: Alignment.topLeft,
              child: MouseRegion(
                onEnter: (_) => entered = true,
                onHover: (_) => hovered = true,
                child: Container(
                  width: 10,
                  height: 3,
                  child: const Text('Target'),
                ),
              ),
            ),
          ),
        );

        // Move mouse outside the region
        await tester.hover(50, 10);

        expect(entered, false);
        expect(hovered, false);
      });
    });

    test('respects opaque flag for hit testing', () async {
      await testNocterm('opaque hit testing', (tester) async {
        bool topEntered = false;
        bool bottomEntered = false;

        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: Stack(
              children: [
                MouseRegion(
                  onEnter: (_) => bottomEntered = true,
                  child: Container(
                    width: 20,
                    height: 10,
                    child: const Text('Bottom'),
                  ),
                ),
                Positioned(
                  left: 5,
                  top: 5,
                  child: MouseRegion(
                    opaque: true,
                    onEnter: (_) => topEntered = true,
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

        // Hover over the top region (which overlaps bottom)
        await tester.hover(8, 7);

        // With opaque=true, only top should receive the event
        expect(topEntered, true);
        expect(bottomEntered, false);
      });
    });

    test('nested MouseRegions trigger correctly', () async {
      await testNocterm('nested regions', (tester) async {
        bool outerEntered = false;
        bool innerEntered = false;

        await tester.pumpComponent(
          Container(
            width: 80,
            height: 24,
            child: MouseRegion(
              onEnter: (_) => outerEntered = true,
              child: Container(
                width: 20,
                height: 10,
                child: MouseRegion(
                  onEnter: (_) => innerEntered = true,
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

        // Hover over inner region
        await tester.hover(5, 2);

        // Both should be entered
        expect(outerEntered, true);
        expect(innerEntered, true);
      });
    });
  });
}
