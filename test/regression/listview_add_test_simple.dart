import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  test('ListView dynamic add simple', () async {
    await testNocterm(
      'dynamic add test',
      (tester) async {
        final scrollController = ScrollController();

        // Start with 3 items
        await tester.pumpComponent(
          Container(
            width: 20,
            height: 5,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: ListView.builder(
              controller: scrollController,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Text('Item ${index + 1}');
              },
            ),
          ),
        );

        print('=== Initial (3 items) ===');
        print('MaxScrollExtent: ${scrollController.maxScrollExtent}');

        // Now rebuild with 10 items
        await tester.pumpComponent(
          Container(
            width: 20,
            height: 5,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: ListView.builder(
              controller: scrollController,
              itemCount: 10,
              itemBuilder: (context, index) {
                return Text('Item ${index + 1}');
              },
            ),
          ),
        );

        print('\n=== After adding items (10 total) ===');
        print('MaxScrollExtent: ${scrollController.maxScrollExtent}');

        // Try scrolling
        scrollController.scrollToEnd();
        await tester.pump();

        print('\n=== After scrollToEnd ===');
        print('Offset: ${scrollController.offset}');
        print('MaxScrollExtent: ${scrollController.maxScrollExtent}');

        expect(
          scrollController.maxScrollExtent,
          greaterThan(0),
          reason: 'Should be able to scroll with 10 items',
        );

        expect(
          tester.terminalState.containsText('Item 10') ||
              tester.terminalState.containsText('Item 9'),
          isTrue,
          reason: 'Should see last items after scrolling',
        );
      },
      debugPrintAfterPump: true,
      size: Size(30, 10),
    );
  });
}
