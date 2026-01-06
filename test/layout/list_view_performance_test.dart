import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('ListView Performance', () {
    test(
      'visual test - ListView should render without continuous updates',
      () async {
        await testNocterm(
          'list view visual',
          (tester) async {
            await tester.pumpComponent(
              Container(
                width: 40,
                height: 10,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.blue),
                ),
                child: ListView.builder(
                  itemCount: 50,
                  itemBuilder: (context, index) {
                    return Text('Item $index');
                  },
                ),
              ),
            );

            // Should see the first few items
            expect(tester.terminalState, containsText('Item 0'));
            expect(tester.terminalState, containsText('Item 1'));

            // Scroll down
            final controller = ScrollController();
            await tester.pumpComponent(
              Container(
                width: 40,
                height: 10,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.blue),
                ),
                child: ListView.builder(
                  controller: controller,
                  itemCount: 50,
                  itemBuilder: (context, index) {
                    return Text('Item $index');
                  },
                ),
              ),
            );

            controller.scrollDown(10);
            await tester.pump();

            // Should see different items after scrolling
            expect(tester.terminalState, containsText('Item 10'));
          },
          // debugPrintAfterPump: true, // Uncomment to see visual output
        );
      },
    );
  });
}
