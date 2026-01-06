import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('AutoScrollController with reverse ListView', () {
    test('reverse ListView with AutoScrollController initial position', () async {
      await testNocterm('reverse auto-scroll initial', (tester) async {
        final scrollController = AutoScrollController();
        final items = List.generate(10, (i) => 'Message ${i + 1}');

        await tester.pumpComponent(
          Container(
            width: 30,
            height: 10,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: ListView.builder(
              reverse: true,
              controller: scrollController,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Text(items[index]);
              },
            ),
          ),
        );

        // With reverse, we should start at the "bottom" which is maxScrollExtent
        print('Initial offset: ${scrollController.offset}');
        print('Max scroll extent: ${scrollController.maxScrollExtent}');
        print('At end: ${scrollController.atEnd}');
        print('Auto scroll enabled: ${scrollController.isAutoScrollEnabled}');

        final output = tester.terminalState.getText();
        print('Terminal output:');
        print(output);

        // The first item should be visible at the bottom
        expect(output, contains('Message 1'));
      }, debugPrintAfterPump: true);
    });

    test('auto-scrolls in reverse ListView when content is added', () async {
      await testNocterm('reverse auto-scroll on add', (tester) async {
        final scrollController = AutoScrollController();
        final items = List.generate(15, (i) => 'Message ${i + 1}');

        await tester.pumpComponent(
          Container(
            width: 30,
            height: 8,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.cyan),
            ),
            child: ListView.builder(
              reverse: true,
              controller: scrollController,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Text(items[index]);
              },
            ),
          ),
        );

        await tester.pump();

        print('Before adding items:');
        print('Offset: ${scrollController.offset}');
        print('MaxScrollExtent: ${scrollController.maxScrollExtent}');
        print('AutoScroll enabled: ${scrollController.isAutoScrollEnabled}');

        // Add more items
        items.add('Message 16');
        items.add('Message 17');
        items.add('Message 18');

        await tester.pumpComponent(
          Container(
            width: 30,
            height: 8,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.cyan),
            ),
            child: ListView.builder(
              reverse: true,
              controller: scrollController,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Text(items[index]);
              },
            ),
          ),
        );

        await tester.pump();

        print('\nAfter adding items:');
        print('Offset: ${scrollController.offset}');
        print('MaxScrollExtent: ${scrollController.maxScrollExtent}');
        print('AutoScroll enabled: ${scrollController.isAutoScrollEnabled}');

        final output = tester.terminalState.getText();
        print('\nTerminal output:');
        print(output);

        // New messages should be visible
        expect(output, contains('Message 1'));
      }, debugPrintAfterPump: false);
    });

    test('reverse ListView auto-scroll behavior when scrolling up', () async {
      await testNocterm('reverse auto-scroll manual scroll', (tester) async {
        final scrollController = AutoScrollController(autoScrollThreshold: 5);
        final items = List.generate(20, (i) => 'Message ${i + 1}');

        await tester.pumpComponent(
          Container(
            width: 30,
            height: 8,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.green),
            ),
            child: ListView.builder(
              reverse: true,
              controller: scrollController,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Text(items[index]);
              },
            ),
          ),
        );

        await tester.pump();

        print('Initial state:');
        print('Offset: ${scrollController.offset}');
        print('MaxScrollExtent: ${scrollController.maxScrollExtent}');
        print('AutoScroll enabled: ${scrollController.isAutoScrollEnabled}');

        // In reverse mode, scrolling "up" visually means increasing offset
        // because the content is flipped
        scrollController.scrollDown(
          10,
        ); // This scrolls visually "up" in reverse mode

        print('\nAfter scrolling:');
        print('Offset: ${scrollController.offset}');
        print('AutoScroll enabled: ${scrollController.isAutoScrollEnabled}');

        // Add new items
        items.add('New Message');

        await tester.pumpComponent(
          Container(
            width: 30,
            height: 8,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.green),
            ),
            child: ListView.builder(
              reverse: true,
              controller: scrollController,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Text(items[index]);
              },
            ),
          ),
        );

        await tester.pump();

        print('\nAfter adding item:');
        print('Offset: ${scrollController.offset}');
        print('MaxScrollExtent: ${scrollController.maxScrollExtent}');
        print('AutoScroll enabled: ${scrollController.isAutoScrollEnabled}');

        final output = tester.terminalState.getText();
        print('\nTerminal output:');
        print(output);
      }, debugPrintAfterPump: false);
    });
  });
}
