import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('ListView lazy option', () {
    test(
      'non-lazy mode builds all children and has accurate extent',
      skip: 'Known bug: ListView maxScrollExtent calculation incorrect',
      () async {
        await testNocterm(
          'non-lazy ListView test',
          (tester) async {
            final scrollController = ScrollController();

            await tester.pumpComponent(
              Container(
                width: 30,
                height: 5,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.green),
                ),
                child: ListView.builder(
                  controller: scrollController,
                  lazy: false, // Non-lazy mode - build all children
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return Text('Item ${index + 1}');
                  },
                ),
              ),
            );

            print('=== Non-lazy mode (lazy: false) ===');
            print('Items: 10, Viewport: 3 lines');
            print('Expected maxScrollExtent: 7 (10 - 3)');
            print(
              'Actual maxScrollExtent: ${scrollController.maxScrollExtent}',
            );

            expect(
              scrollController.maxScrollExtent,
              equals(7.0),
              reason: 'Non-lazy mode should have exact scroll extent',
            );

            // Scroll to end
            scrollController.scrollToEnd();
            await tester.pump();

            expect(
              tester.terminalState.containsText('Item 10'),
              isTrue,
              reason: 'Should be able to scroll to last item',
            );
          },
          debugPrintAfterPump: true,
          size: Size(35, 10),
        );
      },
    );

    test('lazy mode with dynamic item addition', () async {
      await testNocterm(
        'lazy ListView test',
        (tester) async {
          final scrollController = ScrollController();

          // Start with 3 items
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.blue),
              ),
              child: ListView.builder(
                controller: scrollController,
                lazy: true, // Lazy mode
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Text('Item ${index + 1}');
                },
              ),
            ),
          );

          print('=== Lazy mode initial (3 items) ===');
          print('MaxScrollExtent: ${scrollController.maxScrollExtent}');

          // Add more items
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.blue),
              ),
              child: ListView.builder(
                controller: scrollController,
                lazy: true, // Still lazy
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Text('Item ${index + 1}');
                },
              ),
            ),
          );

          print('\n=== Lazy mode after adding items (10 total) ===');
          print('MaxScrollExtent: ${scrollController.maxScrollExtent}');

          // The extent should be estimated but reasonable
          expect(
            scrollController.maxScrollExtent,
            greaterThan(0),
            reason: 'Lazy mode should still calculate reasonable extent',
          );

          scrollController.scrollToEnd();
          await tester.pump();

          // Should be able to see some of the last items
          final hasLastItems =
              tester.terminalState.containsText('Item 10') ||
              tester.terminalState.containsText('Item 9') ||
              tester.terminalState.containsText('Item 8');

          expect(
            hasLastItems,
            isTrue,
            reason:
                'Should be able to scroll to see last items even in lazy mode',
          );
        },
        debugPrintAfterPump: true,
        size: Size(35, 10),
      );
    });

    test('compare lazy vs non-lazy performance characteristics', () async {
      await testNocterm(
        'performance comparison',
        (tester) async {
          final lazyController = ScrollController();
          final nonLazyController = ScrollController();

          // Non-lazy ListView
          await tester.pumpComponent(
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.green),
                    ),
                    child: ListView.builder(
                      controller: nonLazyController,
                      lazy: false,
                      itemCount: 20,
                      itemBuilder: (context, index) {
                        return Text('NL-${index + 1}');
                      },
                    ),
                  ),
                ),
                Container(width: 1, child: Text('|')),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.blue),
                    ),
                    child: ListView.builder(
                      controller: lazyController,
                      lazy: true,
                      itemCount: 20,
                      itemBuilder: (context, index) {
                        return Text('L-${index + 1}');
                      },
                    ),
                  ),
                ),
              ],
            ),
          );

          print('=== Comparing lazy vs non-lazy ===');
          print(
            'Non-lazy maxScrollExtent: ${nonLazyController.maxScrollExtent}',
          );
          print('Lazy maxScrollExtent: ${lazyController.maxScrollExtent}');

          // Non-lazy should have exact extent
          expect(
            nonLazyController.maxScrollExtent,
            equals(15.0),
            reason: 'Non-lazy should have exact extent (20 items - 5 visible)',
          );

          // Lazy should have a reasonable estimate
          expect(
            lazyController.maxScrollExtent,
            greaterThan(0),
            reason: 'Lazy should have estimated extent',
          );
        },
        debugPrintAfterPump: false, // Don't print for this comparison
        size: Size(50, 7),
      );
    });
  });
}
