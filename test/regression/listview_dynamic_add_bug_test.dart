import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('ListView dynamic item addition bug', () {
    test(
      'items added after screen is full should be scrollable',
      skip: 'Known bug: ListView maxScrollExtent not updating when items added',
      () async {
        await testNocterm(
          'ListView dynamic add bug reproduction',
          (tester) async {
            // Initial items that will fill the viewport
            final items = <String>['Item 1', 'Item 2', 'Item 3'];
            final scrollController = ScrollController();

            // Build the ListView as a simple stateful component
            await tester.pumpComponent(
              _TestListView(items: items, scrollController: scrollController),
            );

            // Check initial state
            print('=== Initial state (3 items) ===');
            print('ScrollController offset: ${scrollController.offset}');
            print(
              'ScrollController maxScrollExtent: ${scrollController.maxScrollExtent}',
            );
            expect(tester.terminalState, containsText('Item 1'));
            expect(tester.terminalState, containsText('Item 2'));
            expect(tester.terminalState, containsText('Item 3'));

            // Add more items to overflow the viewport
            for (int i = 4; i <= 10; i++) {
              items.add('Item $i');
            }

            await tester.pumpComponent(
              _TestListView(items: items, scrollController: scrollController),
            );

            print('\n=== After adding items 4-10 ===');
            print('Total items: ${items.length}');
            print('ScrollController offset: ${scrollController.offset}');
            print(
              'ScrollController maxScrollExtent: ${scrollController.maxScrollExtent}',
            );

            // Try to scroll to the end
            print('\n=== Attempting to scroll to end ===');
            scrollController.scrollToEnd();
            await tester.pump();

            print('After scrollToEnd:');
            print('ScrollController offset: ${scrollController.offset}');
            print(
              'ScrollController maxScrollExtent: ${scrollController.maxScrollExtent}',
            );

            // Check if we can see the last items
            final hasItem10 = tester.terminalState.containsText('Item 10');
            final hasItem9 = tester.terminalState.containsText('Item 9');
            final hasItem8 = tester.terminalState.containsText('Item 8');

            print('\nVisible items after scroll:');
            print('Item 10 visible: $hasItem10');
            print('Item 9 visible: $hasItem9');
            print('Item 8 visible: $hasItem8');

            // THIS SHOULD PASS BUT WILL FAIL DUE TO THE BUG
            expect(
              hasItem10 || hasItem9 || hasItem8,
              isTrue,
              reason:
                  'After scrolling to end, at least one of the last items should be visible',
            );
          },
          debugPrintAfterPump: true,
          size: Size(40, 10),
        );
      },
    );

    test('comparison: ListView with known itemCount works correctly', () async {
      await testNocterm(
        'ListView with itemCount specified',
        (tester) async {
          final scrollController = ScrollController();
          final items = List.generate(20, (i) => 'Item ${i + 1}');

          // Build ListView with itemCount specified
          await tester.pumpComponent(
            Column(
              children: [
                Text('Total: ${items.length} items'),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.green),
                    ),
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount:
                          items.length, // Key difference: itemCount is known
                      itemBuilder: (context, index) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 1,
                          ),
                          child: Text(items[index]),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );

          print('=== ListView with known itemCount ===');
          print('Initial maxScrollExtent: ${scrollController.maxScrollExtent}');

          // Scroll to end
          scrollController.scrollToEnd();
          await tester.pump();

          print('After scrollToEnd:');
          print('Offset: ${scrollController.offset}');
          print('MaxScrollExtent: ${scrollController.maxScrollExtent}');

          // Should see the last items
          expect(
            tester.terminalState.containsText('Item 20') ||
                tester.terminalState.containsText('Item 19') ||
                tester.terminalState.containsText('Item 18'),
            isTrue,
            reason: 'With known itemCount, scrolling should work correctly',
          );
        },
        debugPrintAfterPump: true,
        size: Size(40, 10),
      );
    });
  });
}

// Helper widget for testing
class _TestListView extends StatelessComponent {
  final List<String> items;
  final ScrollController scrollController;

  const _TestListView({required this.items, required this.scrollController});

  @override
  Component build(BuildContext context) {
    return Column(
      children: [
        Text('Items: ${items.length}'),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: ListView.builder(
              controller: scrollController,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.all(1),
                  child: Text(items[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
