import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

void main() {
  group('Overlay with Theater implementation', () {
    test('basic overlay rendering', () async {
      await testNocterm('overlay with single entry', (tester) async {
        await tester.pumpComponent(
          Overlay(
            key: GlobalKey(),
            initialEntries: [
              OverlayEntry(
                builder: (context) {
                  return Container(
                    width: 20,
                    height: 3,
                    color: Colors.blue,
                    child: Text('Entry 1'),
                  );
                },
              ),
            ],
          ),
        );

        // Check that the overlay rendered
        expect(tester.terminalState, containsText('Entry 1'));
      }, debugPrintAfterPump: true);
    });

    test('overlay with multiple entries', () async {
      await testNocterm(
        'overlay with stacked entries',
        (tester) async {
          await tester.pumpComponent(
            Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) {
                    return Container(
                      width: 30,
                      height: 5,
                      color: Colors.blue,
                      child: Text('Bottom Entry'),
                    );
                  },
                ),
                OverlayEntry(
                  builder: (context) {
                    return Positioned(
                      left: 10,
                      top: 2,
                      child: Container(
                        width: 15,
                        height: 3,
                        color: Colors.red,
                        child: Text('Top Entry'),
                      ),
                    );
                  },
                ),
              ],
            ),
          );

          // Only top entry should be visible since it overlaps the bottom one
          expect(tester.terminalState, containsText('Top Entry'));
          // Bottom entry is covered by the top entry at that position
        },
        debugPrintAfterPump: true,
        size: Size(40, 10),
      );
    });

    test('opaque entry blocks entries below', () async {
      await testNocterm('opaque overlay entry', (tester) async {
        final bottomEntry = OverlayEntry(
          builder: (context) => Container(
            width: 30,
            height: 5,
            color: Colors.blue,
            child: Text('Hidden'),
          ),
        );

        final opaqueEntry = OverlayEntry(
          opaque: true,
          builder: (context) => Container(
            width: 30,
            height: 5,
            color: Colors.green,
            child: Text('Opaque'),
          ),
        );

        await tester.pumpComponent(
          Overlay(initialEntries: [bottomEntry, opaqueEntry]),
        );

        // Only the opaque entry should be visible
        expect(tester.terminalState, containsText('Opaque'));
        // The bottom entry should not be rendered (unless maintainState is true)
        // This depends on the theater implementation correctly skipping offstage children
      }, debugPrintAfterPump: true);
    });

    test('maintainState keeps offstage entries alive', () async {
      await testNocterm('maintain state for hidden entries', (tester) async {
        int buildCount = 0;

        final bottomEntry = OverlayEntry(
          maintainState: true,
          builder: (context) {
            buildCount++;
            return Container(
              width: 30,
              height: 5,
              child: Text('Maintained: $buildCount'),
            );
          },
        );

        final opaqueEntry = OverlayEntry(
          opaque: true,
          builder: (context) => Container(
            width: 30,
            height: 5,
            color: Colors.green,
            child: Text('Opaque Top'),
          ),
        );

        await tester.pumpComponent(
          Overlay(initialEntries: [bottomEntry, opaqueEntry]),
        );

        // The bottom entry should have been built even though it's hidden
        expect(buildCount, greaterThan(0));
        expect(tester.terminalState, containsText('Opaque Top'));
      }, debugPrintAfterPump: true);
    });

    test('dynamic overlay entry insertion', () async {
      await testNocterm(
        'insert overlay entry dynamically',
        (tester) async {
          late OverlayState overlayState;

          await tester.pumpComponent(
            Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) {
                    overlayState = Overlay.of(context);
                    return Container(
                      width: 30,
                      height: 5,
                      color: Colors.blue,
                      child: Text('Initial'),
                    );
                  },
                ),
              ],
            ),
          );

          expect(tester.terminalState, containsText('Initial'));

          // Insert a new entry
          final newEntry = OverlayEntry(
            builder: (context) => Positioned(
              left: 5,
              top: 2,
              child: Container(
                width: 20,
                height: 3,
                color: Colors.red,
                child: Text('Inserted'),
              ),
            ),
          );

          overlayState.insert(newEntry);
          await tester.pump();

          // The inserted entry should be visible (it's positioned and overlaps partially)
          expect(tester.terminalState, containsText('Inserted'));
          // Initial might not be visible if covered

          // Remove the inserted entry
          newEntry.remove();
          await tester.pump();

          // Only initial entry should remain
          expect(tester.terminalState, containsText('Initial'));
          expect(tester.terminalState, isNot(containsText('Inserted')));
        },
        debugPrintAfterPump: true,
        size: Size(40, 10),
      );
    });

    test('overlay entry markNeedsBuild', () async {
      await testNocterm('rebuild overlay entry on demand', (tester) async {
        int buildCount = 0;
        late OverlayEntry entry;

        entry = OverlayEntry(
          builder: (context) {
            buildCount++;
            return Container(
              width: 30,
              height: 5,
              child: Text('Build: $buildCount'),
            );
          },
        );

        await tester.pumpComponent(Overlay(initialEntries: [entry]));

        final initialBuildCount = buildCount;
        expect(tester.terminalState, containsText('Build: $initialBuildCount'));

        // Mark entry as needing rebuild
        entry.markNeedsBuild();
        await tester.pump();

        // Build count should have increased
        expect(buildCount, greaterThan(initialBuildCount));
        expect(tester.terminalState, containsText('Build: $buildCount'));
      }, debugPrintAfterPump: true);
    });
  });
}
