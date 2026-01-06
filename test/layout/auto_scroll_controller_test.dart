import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('AutoScrollController', () {
    test('auto-scrolls when content is added while at bottom', () async {
      await testNocterm('auto-scroll at bottom', (tester) async {
        final scrollController = AutoScrollController();
        final items = List.generate(5, (i) => 'Message ${i + 1}');

        await tester.pumpComponent(
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Text(items[index]);
                  },
                ),
              ),
            ],
          ),
        );

        // Initially should be at top
        expect(scrollController.offset, 0);
        expect(scrollController.isAutoScrollEnabled, isTrue);

        // Add more items to trigger scrolling
        items.addAll(List.generate(20, (i) => 'Message ${i + 6}'));

        await tester.pumpComponent(
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Text(items[index]);
                  },
                ),
              ),
            ],
          ),
        );

        // Wait for post-frame callback
        await tester.pump();

        // Should have scrolled to bottom
        expect(scrollController.atEnd, isTrue);
        expect(scrollController.isAutoScrollEnabled, isTrue);
      }, size: Size(40, 10));
    });

    test('disables auto-scroll when user scrolls up', () async {
      await testNocterm('disable auto-scroll on manual scroll', (tester) async {
        final scrollController = AutoScrollController(autoScrollThreshold: 10);
        final items = List.generate(30, (i) => 'Message ${i + 1}');

        await tester.pumpComponent(
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Text(items[index]);
                  },
                ),
              ),
            ],
          ),
        );

        // Scroll to bottom first
        scrollController.scrollToEnd();
        await tester.pump();
        expect(scrollController.isAutoScrollEnabled, isTrue);

        // Scroll up more than threshold
        scrollController.scrollUp(15);
        expect(scrollController.isAutoScrollEnabled, isFalse);

        // Add new items
        items.addAll(['New Message 1', 'New Message 2']);

        await tester.pumpComponent(
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Text(items[index]);
                  },
                ),
              ),
            ],
          ),
        );

        await tester.pump();

        // Should NOT have auto-scrolled
        expect(scrollController.atEnd, isFalse);
        expect(scrollController.isAutoScrollEnabled, isFalse);
      }, size: Size(40, 10));
    });

    test('re-enables auto-scroll when user scrolls back to bottom', () async {
      await testNocterm('re-enable auto-scroll at bottom', (tester) async {
        final scrollController = AutoScrollController(autoScrollThreshold: 10);
        final items = List.generate(30, (i) => 'Message ${i + 1}');

        await tester.pumpComponent(
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Text(items[index]);
                  },
                ),
              ),
            ],
          ),
        );

        // Start at bottom
        scrollController.scrollToEnd();
        await tester.pump();
        expect(scrollController.isAutoScrollEnabled, isTrue);

        // Scroll up to disable auto-scroll
        scrollController.scrollUp(20);
        expect(scrollController.isAutoScrollEnabled, isFalse);

        // Scroll back to bottom
        scrollController.scrollToEnd();
        expect(scrollController.isAutoScrollEnabled, isTrue);

        // Add new items
        items.add('New Message');

        await tester.pumpComponent(
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Text(items[index]);
                  },
                ),
              ),
            ],
          ),
        );

        await tester.pump();

        // Should have auto-scrolled
        expect(scrollController.atEnd, isTrue);
        expect(scrollController.isAutoScrollEnabled, isTrue);
      }, size: Size(40, 10));
    });

    test('manual control methods work correctly', () async {
      await testNocterm('manual control methods', (tester) async {
        final scrollController = AutoScrollController();
        final items = List.generate(30, (i) => 'Message ${i + 1}');

        await tester.pumpComponent(
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Text(items[index]);
                  },
                ),
              ),
            ],
          ),
        );

        // Manually disable auto-scroll
        scrollController.disableAutoScroll();
        expect(scrollController.isAutoScrollEnabled, isFalse);

        // Add items - should not auto-scroll
        items.add('New Message');
        await tester.pumpComponent(
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Text(items[index]);
                  },
                ),
              ),
            ],
          ),
        );
        await tester.pump();

        expect(scrollController.atEnd, isFalse);

        // Manually enable and scroll to bottom
        scrollController.scrollToBottom();
        expect(scrollController.isAutoScrollEnabled, isTrue);
        expect(scrollController.atEnd, isTrue);
      }, size: Size(40, 10));
    });
  });

  // Note: Post-frame callback tests would require a full TerminalBinding instance
  // which is not available in the test environment. The functionality is tested
  // indirectly through the AutoScrollController tests above.
}
