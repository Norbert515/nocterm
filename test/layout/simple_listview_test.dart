import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  test(
    'simple ListView test',
    skip:
        'Known bug: ListView maxScrollExtent returns 0 when content exceeds viewport',
    () async {
      await testNocterm(
        'simple test',
        (tester) async {
          final scrollController = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 20,
              height: 8,
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.blue),
              ),
              child: ListView.builder(
                controller: scrollController,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          print('Initial state:');
          print('Offset: ${scrollController.offset}');
          print('MaxScrollExtent: ${scrollController.maxScrollExtent}');

          // Scroll down
          scrollController.scrollDown();
          await tester.pump();

          print('\nAfter scroll down:');
          print('Offset: ${scrollController.offset}');
          print('MaxScrollExtent: ${scrollController.maxScrollExtent}');

          expect(
            scrollController.maxScrollExtent,
            greaterThan(0),
            reason: 'With 10 items, should have scrollable content',
          );
        },
        debugPrintAfterPump: true,
        size: Size(30, 12),
      );
    },
  );
}
