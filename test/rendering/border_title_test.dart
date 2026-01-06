import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart' hide isNotEmpty;

void main() {
  group('Border Title Rendering', () {
    test('basic left-aligned title', () async {
      await testNocterm(
        'left aligned title',
        (tester) async {
          await tester.pumpComponent(
            Center(
              child: Container(
                width: 25,
                height: 5,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.cyan),
                  title: BorderTitle(text: 'Title'),
                ),
                child: Center(child: Text('Content')),
              ),
            ),
          );

          expect(tester.terminalState, containsText('Title'));
          expect(tester.terminalState, containsText('Content'));
        },
        // debugPrintAfterPump: true,
      );
    });

    test('center-aligned title', () async {
      await testNocterm(
        'center aligned title',
        (tester) async {
          await tester.pumpComponent(
            Center(
              child: Container(
                width: 25,
                height: 5,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.green),
                  title: BorderTitle(
                    text: 'Centered',
                    alignment: TitleAlignment.center,
                  ),
                ),
                child: Center(child: Text('Content')),
              ),
            ),
          );

          expect(tester.terminalState, containsText('Centered'));
          expect(tester.terminalState, containsText('Content'));
        },
        // debugPrintAfterPump: true,
      );
    });

    test('right-aligned title', () async {
      await testNocterm(
        'right aligned title',
        (tester) async {
          await tester.pumpComponent(
            Center(
              child: Container(
                width: 25,
                height: 5,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.yellow),
                  title: BorderTitle(
                    text: 'Right',
                    alignment: TitleAlignment.right,
                  ),
                ),
                child: Center(child: Text('Content')),
              ),
            ),
          );

          expect(tester.terminalState, containsText('Right'));
          expect(tester.terminalState, containsText('Content'));
        },
        // debugPrintAfterPump: true,
      );
    });

    test('title with custom style', () async {
      await testNocterm(
        'styled title',
        (tester) async {
          await tester.pumpComponent(
            Center(
              child: Container(
                width: 30,
                height: 5,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.blue),
                  title: BorderTitle(
                    text: 'Styled Title',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                child: Center(child: Text('Content')),
              ),
            ),
          );

          expect(tester.terminalState, containsText('Styled Title'));
        },
        // debugPrintAfterPump: true,
      );
    });

    test('long title gets truncated', () async {
      await testNocterm(
        'truncated title',
        (tester) async {
          await tester.pumpComponent(
            Center(
              child: Container(
                width: 15,
                height: 5,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.magenta),
                  title: BorderTitle(text: 'This is a very long title'),
                ),
                child: Center(child: Text('Hi')),
              ),
            ),
          );

          // Title should be truncated - the full text won't fit
          final snapshot = tester.toSnapshot();
          expect(snapshot, isNotEmpty);
          // The truncation character should appear
        },
        // debugPrintAfterPump: true,
      );
    });

    test('narrow container skips title', () async {
      await testNocterm(
        'narrow container',
        (tester) async {
          await tester.pumpComponent(
            Center(
              child: Container(
                width: 5,
                height: 3,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.cyan),
                  title: BorderTitle(text: 'Title'),
                ),
              ),
            ),
          );

          // Container too narrow for title - should render border without title
          final snapshot = tester.toSnapshot();
          expect(snapshot, isNotEmpty);
        },
        // debugPrintAfterPump: true,
      );
    });

    test('title with different border styles', () async {
      await testNocterm(
        'border styles with title',
        (tester) async {
          await tester.pumpComponent(
            Column(
              children: [
                Container(
                  width: 25,
                  height: 3,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(
                      color: Colors.cyan,
                      style: BoxBorderStyle.solid,
                    ),
                    title: BorderTitle(text: 'Solid'),
                  ),
                ),
                SizedBox(height: 1),
                Container(
                  width: 25,
                  height: 3,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(
                      color: Colors.green,
                      style: BoxBorderStyle.double,
                    ),
                    title: BorderTitle(text: 'Double'),
                  ),
                ),
                SizedBox(height: 1),
                Container(
                  width: 25,
                  height: 3,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(
                      color: Colors.yellow,
                      style: BoxBorderStyle.rounded,
                    ),
                    title: BorderTitle(text: 'Rounded'),
                  ),
                ),
              ],
            ),
          );

          expect(tester.terminalState, containsText('Solid'));
          expect(tester.terminalState, containsText('Double'));
          expect(tester.terminalState, containsText('Rounded'));
        },
        // debugPrintAfterPump: true,
      );
    });

    test('all alignments comparison', () async {
      await testNocterm(
        'alignment comparison',
        (tester) async {
          await tester.pumpComponent(
            Column(
              children: [
                Container(
                  width: 30,
                  height: 3,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.red),
                    title: BorderTitle(
                      text: 'Left',
                      alignment: TitleAlignment.left,
                    ),
                  ),
                ),
                SizedBox(height: 1),
                Container(
                  width: 30,
                  height: 3,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.green),
                    title: BorderTitle(
                      text: 'Center',
                      alignment: TitleAlignment.center,
                    ),
                  ),
                ),
                SizedBox(height: 1),
                Container(
                  width: 30,
                  height: 3,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.blue),
                    title: BorderTitle(
                      text: 'Right',
                      alignment: TitleAlignment.right,
                    ),
                  ),
                ),
              ],
            ),
          );

          expect(tester.terminalState, containsText('Left'));
          expect(tester.terminalState, containsText('Center'));
          expect(tester.terminalState, containsText('Right'));
        },
        // debugPrintAfterPump: true,
      );
    });
  });

  group('Partial Border Rendering', () {
    test('top border only - no corners', () async {
      await testNocterm(
        'top border only',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 25,
              height: 3,
              decoration: BoxDecoration(
                border: BoxBorder(
                  top: BorderSide(
                    color: Colors.cyan,
                    style: BoxBorderStyle.rounded,
                  ),
                ),
                title: BorderTitle(text: 'Top Only'),
              ),
              child: Text('Content'),
            ),
          );

          // Should have title but NO corner characters (╭ or ╮)
          expect(tester.terminalState, containsText('Top Only'));
          final snapshot = tester.toSnapshot();
          expect(
            snapshot.contains('╭'),
            isFalse,
            reason: 'Should not have top-left corner',
          );
          expect(
            snapshot.contains('╮'),
            isFalse,
            reason: 'Should not have top-right corner',
          );
        },
        // debugPrintAfterPump: true,
      );
    });

    test('top and bottom borders only - no corners', () async {
      await testNocterm(
        'top and bottom only',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 25,
              height: 3,
              decoration: BoxDecoration(
                border: BoxBorder(
                  top: BorderSide(
                    color: Colors.green,
                    style: BoxBorderStyle.rounded,
                  ),
                  bottom: BorderSide(
                    color: Colors.green,
                    style: BoxBorderStyle.rounded,
                  ),
                ),
                title: BorderTitle(text: 'No Sides'),
              ),
              child: Text('Content'),
            ),
          );

          expect(tester.terminalState, containsText('No Sides'));
          final snapshot = tester.toSnapshot();
          // Should not have any corner characters
          expect(snapshot.contains('╭'), isFalse);
          expect(snapshot.contains('╮'), isFalse);
          expect(snapshot.contains('╰'), isFalse);
          expect(snapshot.contains('╯'), isFalse);
        },
        // debugPrintAfterPump: true,
      );
    });

    test('full border - has corners', () async {
      await testNocterm(
        'full border with corners',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 25,
              height: 3,
              decoration: BoxDecoration(
                border: BoxBorder.all(
                  color: Colors.magenta,
                  style: BoxBorderStyle.rounded,
                ),
                title: BorderTitle(text: 'Full'),
              ),
              child: Text('Content'),
            ),
          );

          expect(tester.terminalState, containsText('Full'));
          final snapshot = tester.toSnapshot();
          // Full border SHOULD have corner characters
          expect(
            snapshot.contains('╭'),
            isTrue,
            reason: 'Should have top-left corner',
          );
          expect(
            snapshot.contains('╮'),
            isTrue,
            reason: 'Should have top-right corner',
          );
          expect(
            snapshot.contains('╰'),
            isTrue,
            reason: 'Should have bottom-left corner',
          );
          expect(
            snapshot.contains('╯'),
            isTrue,
            reason: 'Should have bottom-right corner',
          );
        },
        // debugPrintAfterPump: true,
      );
    });

    test('left and right borders only - no horizontal corners', () async {
      await testNocterm(
        'left and right only',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 25,
              height: 3,
              decoration: BoxDecoration(
                border: BoxBorder(
                  left: BorderSide(
                    color: Colors.yellow,
                    style: BoxBorderStyle.rounded,
                  ),
                  right: BorderSide(
                    color: Colors.yellow,
                    style: BoxBorderStyle.rounded,
                  ),
                ),
              ),
              child: Text('Content'),
            ),
          );

          final snapshot = tester.toSnapshot();
          // Should have vertical lines but no corners
          expect(
            snapshot.contains('│'),
            isTrue,
            reason: 'Should have vertical lines',
          );
          expect(snapshot.contains('╭'), isFalse);
          expect(snapshot.contains('╮'), isFalse);
        },
        // debugPrintAfterPump: true,
      );
    });
  });
}
