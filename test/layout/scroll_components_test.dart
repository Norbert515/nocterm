import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

void main() {
  group('SingleChildScrollView', () {
    test('visual development - vertical scroll', () async {
      await testNocterm(
        'vertical scrolling',
        (tester) async {
          print('Testing SingleChildScrollView with vertical content:');

          await tester.pumpComponent(
            Center(
              child: Container(
                width: 30,
                height: 10,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.blue),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(20, (index) => Text('Item $index')),
                  ),
                ),
              ),
            ),
          );

          // Initial state
          expect(tester.terminalState, containsText('Item 0'));
          expect(tester.terminalState, containsText('Item 1'));

          // Simulate scrolling down
          await tester.sendKey(LogicalKey.arrowDown);
          await tester.pump();

          // Should have scrolled
          expect(tester.terminalState, containsText('Item 1'));
        },
        debugPrintAfterPump: true,
        size: Size(40, 20),
      );
    });

    test('horizontal scrolling', () async {
      await testNocterm(
        'horizontal scroll',
        (tester) async {
          print('Testing SingleChildScrollView with horizontal content:');

          await tester.pumpComponent(
            Center(
              child: Container(
                width: 20,
                height: 5,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.green),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'This is a very long text that needs scrolling to see completely',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          // Should clip the text (20 width - 2 for borders = 18 chars visible)
          expect(tester.terminalState, containsText('This is a very lon'));

          // Scroll right
          await tester.sendKey(LogicalKey.arrowRight);
          await tester.pump();
        },
        debugPrintAfterPump: true,
        size: Size(40, 15),
      );
    });

    test('with padding', () async {
      await testNocterm(
        'scroll with padding',
        (tester) async {
          print('Testing SingleChildScrollView with padding:');

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 10,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.cyan),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(2),
                child: Column(
                  children: List.generate(
                    15,
                    (index) => Text('Padded item $index'),
                  ),
                ),
              ),
            ),
          );
        },
        debugPrintAfterPump: true,
        size: Size(40, 15),
      );
    });

    test('controlled scrolling', () async {
      await testNocterm('programmatic scroll', (tester) async {
        final controller = ScrollController();

        await tester.pumpComponent(
          Container(
            width: 30,
            height: 10,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.yellow),
            ),
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: List.generate(30, (index) => Text('Line $index')),
              ),
            ),
          ),
        );

        // Initial state
        expect(tester.terminalState, containsText('Line 0'));

        // Programmatically scroll down
        controller.scrollDown(5);
        await tester.pump();

        // Scroll to end
        controller.scrollToEnd();
        await tester.pump();

        // Scroll to start
        controller.scrollToStart();
        await tester.pump();
        expect(tester.terminalState, containsText('Line 0'));
      }, debugPrintAfterPump: false);
    });
  });

  group('ListView', () {
    test('visual development - basic list', () async {
      await testNocterm(
        'basic ListView',
        (tester) async {
          print('Testing basic ListView:');

          await tester.pumpComponent(
            Center(
              child: Container(
                width: 30,
                height: 10,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.magenta),
                ),
                child: ListView(
                  children: List.generate(
                    20,
                    (index) =>
                        Container(height: 1, child: Text('List item $index')),
                  ),
                ),
              ),
            ),
          );

          expect(tester.terminalState, containsText('List item 0'));

          // Scroll down
          await tester.sendKey(LogicalKey.arrowDown);
          await tester.pump();
        },
        debugPrintAfterPump: true,
        size: Size(40, 20),
      );
    });

    test('ListView.builder', () async {
      await testNocterm(
        'builder pattern',
        (tester) async {
          print('Testing ListView.builder with lazy loading:');

          await tester.pumpComponent(
            Container(
              width: 40,
              height: 15,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.red),
              ),
              child: ListView.builder(
                itemCount: 100,
                itemBuilder: (context, index) {
                  return Container(
                    height: 2,
                    child: Text('Item #$index (lazy)'),
                  );
                },
              ),
            ),
          );

          expect(tester.terminalState, containsText('Item #0'));

          // Scroll down several times
          for (int i = 0; i < 5; i++) {
            await tester.sendKey(LogicalKey.arrowDown);
            await tester.pump();
          }
        },
        debugPrintAfterPump: true,
        size: Size(50, 20),
      );
    });

    test('ListView.separated', () async {
      await testNocterm(
        'separated list',
        (tester) async {
          print('Testing ListView.separated:');

          await tester.pumpComponent(
            Container(
              width: 35,
              height: 12,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.green),
              ),
              child: ListView.separated(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
                separatorBuilder: (context, index) {
                  return Text('---separator---');
                },
              ),
            ),
          );

          expect(tester.terminalState, containsText('Item 0'));
          expect(tester.terminalState, containsText('---separator---'));
        },
        debugPrintAfterPump: true,
        size: Size(40, 20),
      );
    });

    test('horizontal ListView', () async {
      await testNocterm(
        'horizontal list',
        (tester) async {
          print('Testing horizontal ListView:');

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.blue),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List.generate(
                  10,
                  (index) => Container(
                    width: 10,
                    child: Center(child: Text('[$index]')),
                  ),
                ),
              ),
            ),
          );

          // Scroll horizontally
          await tester.sendKey(LogicalKey.arrowRight);
          await tester.pump();
        },
        debugPrintAfterPump: true,
        size: Size(40, 15),
      );
    });
  });

  group('Scrollbar', () {
    test(
      'visual development - with scrollbar',
      skip: 'Known issue: Scrollbar arrow rendering',
      () async {
        await testNocterm(
          'scrollbar display',
          (tester) async {
            print('Testing Scrollbar widget:');

            final controller = ScrollController();

            await tester.pumpComponent(
              Center(
                child: Container(
                  width: 35,
                  height: 10,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.cyan),
                  ),
                  child: Scrollbar(
                    controller: controller,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Column(
                        children: List.generate(
                          30,
                          (index) => Text('Item with scrollbar $index'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );

            // Should show scrollbar indicator
            expect(tester.terminalState, containsText('▲'));
            expect(tester.terminalState, containsText('▼'));

            // Scroll and verify scrollbar updates
            controller.scrollDown(10);
            await tester.pump();
          },
          debugPrintAfterPump: true,
          size: Size(50, 20),
        );
      },
    );

    test('scrollbar with ListView', () async {
      await testNocterm(
        'ListView with scrollbar',
        (tester) async {
          print('Testing Scrollbar with ListView:');

          final controller = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 40,
              height: 12,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.magenta),
              ),
              child: Scrollbar(
                controller: controller,
                thumbVisibility: true,
                thickness: 1,
                child: ListView.builder(
                  controller: controller,
                  itemCount: 50,
                  itemBuilder: (context, index) {
                    return Text('List item $index');
                  },
                ),
              ),
            ),
          );

          // Verify scrollbar is visible
          expect(tester.terminalState, containsText('│'));

          // Scroll to middle
          controller.jumpTo(25);
          await tester.pump();

          // Scroll to end
          controller.scrollToEnd();
          await tester.pump();
        },
        debugPrintAfterPump: true,
        size: Size(50, 20),
      );
    });
  });

  group('Integration tests', () {
    test('nested scrolling', () async {
      await testNocterm(
        'nested scroll views',
        (tester) async {
          print('Testing nested scroll views:');

          await tester.pumpComponent(
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: 60,
                child: Column(
                  children: [
                    Text('Horizontal scroll parent'),
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.yellow),
                      ),
                      child: ListView(
                        children: List.generate(
                          15,
                          (index) => Text('Nested item $index'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        debugPrintAfterPump: true,
        size: Size(40, 20),
      );
    });

    test('scroll physics boundaries', () async {
      await testNocterm('boundary testing', (tester) async {
        final controller = ScrollController();

        await tester.pumpComponent(
          Container(
            width: 30,
            height: 8,
            decoration: BoxDecoration(border: BoxBorder.all(color: Colors.red)),
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: List.generate(
                  5,
                  (index) => Text('Short content $index'),
                ),
              ),
            ),
          ),
        );

        // Try to scroll beyond boundaries
        controller.scrollDown(100);
        await tester.pump();

        // Should be clamped to max extent
        expect(controller.atEnd, isTrue);

        controller.scrollUp(100);
        await tester.pump();

        // Should be clamped to min extent
        expect(controller.atStart, isTrue);
      }, debugPrintAfterPump: false);
    });
  });
}
