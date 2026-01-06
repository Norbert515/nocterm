import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  test('debug ListView extent', () async {
    await testNocterm(
      'debug test',
      (tester) async {
        final scrollController = ScrollController();

        await tester.pumpComponent(
          Container(
            width: 20,
            height: 5, // Small viewport to force scrolling
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

        print('Viewport height: 5 (3 visible lines after borders)');
        print('Total items: 10');
        print('Expected maxScrollExtent: ~7 (10 items - 3 visible)');
        print('Actual maxScrollExtent: ${scrollController.maxScrollExtent}');

        expect(
          scrollController.maxScrollExtent,
          greaterThan(0),
          reason: 'With 10 items and small viewport, should need scrolling',
        );
      },
      debugPrintAfterPump: true,
      size: Size(30, 10),
    );
  });
}
