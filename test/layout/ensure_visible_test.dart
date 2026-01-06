import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

void main() {
  group('ScrollController.ensureVisible', () {
    test('does not scroll when item is fully visible', () {
      final controller = ScrollController();

      // Simulate a viewport of 10 units tall, scrolled to position 5
      controller.updateMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 10,
      );
      controller.jumpTo(5);

      // Item at position 8 with extent 2 (ends at 10) is fully visible
      controller.ensureVisible(itemOffset: 8, itemExtent: 2);

      // Should not have scrolled
      expect(controller.offset, equals(5));
    });

    test('scrolls down to show item below viewport', () {
      final controller = ScrollController();

      controller.updateMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 10,
      );
      controller.jumpTo(0);

      // Item at position 15 with extent 2 is below viewport (0-10)
      controller.ensureVisible(itemOffset: 15, itemExtent: 2);

      // Should scroll down so item is at bottom: offset = 17 - 10 = 7
      expect(controller.offset, equals(7));
    });

    test('scrolls up to show item above viewport', () {
      final controller = ScrollController();

      controller.updateMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 10,
      );
      controller.jumpTo(20);

      // Item at position 5 with extent 2 is above viewport (20-30)
      controller.ensureVisible(itemOffset: 5, itemExtent: 2);

      // Should scroll up to show item at top: offset = 5
      expect(controller.offset, equals(5));
    });

    test('simulates list navigation scenario', () {
      final controller = ScrollController();

      // Viewport of 5 units (showing 5 items at once)
      controller.updateMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 15, // 20 items - 5 visible = 15
        viewportDimension: 5,
      );

      // Start at item 0
      controller.jumpTo(0);
      expect(controller.offset, equals(0));

      // Navigate down to item 5 (beyond visible area)
      // Item 5 should be made visible at bottom of viewport
      controller.ensureVisible(itemOffset: 5, itemExtent: 1);
      expect(controller.offset, equals(1)); // Scrolled to show items 1-5

      // Navigate down to item 10
      controller.ensureVisible(itemOffset: 10, itemExtent: 1);
      expect(controller.offset, equals(6)); // Scrolled to show items 6-10

      // Navigate back up to item 8 (still visible)
      controller.ensureVisible(itemOffset: 8, itemExtent: 1);
      expect(
        controller.offset,
        equals(6),
      ); // No scroll needed, item 8 is visible

      // Navigate to item 0 (way above)
      controller.ensureVisible(itemOffset: 0, itemExtent: 1);
      expect(controller.offset, equals(0)); // Scrolled to top
    });

    test('handles items larger than viewport', () {
      final controller = ScrollController();

      controller.updateMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 100,
        viewportDimension: 10,
      );
      controller.jumpTo(0);

      // Item at position 5 with extent 15 (larger than viewport)
      // Should scroll to show the start of the item
      controller.ensureVisible(itemOffset: 5, itemExtent: 15);

      // Should scroll to show start of item
      expect(controller.offset, equals(5));
    });

    test('respects scroll extent bounds', () {
      final controller = ScrollController();

      controller.updateMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 20,
        viewportDimension: 10,
      );
      controller.jumpTo(0);

      // Try to ensure visible an item at position 18 with extent 5
      // This would require scrolling to 18 + 5 - 10 = 13
      controller.ensureVisible(itemOffset: 18, itemExtent: 5);

      // Should scroll to show the item (13 is within bounds)
      expect(controller.offset, equals(13));

      // Now try an item that would require scrolling beyond maxScrollExtent
      // Item at 25 with extent 2 would need offset = 27 - 10 = 17
      controller.ensureVisible(itemOffset: 25, itemExtent: 2);

      // ensureVisible calculates 27 - 10 = 17, jumpTo clamps to that value
      // (17 is actually within maxScrollExtent of 20)
      expect(controller.offset, equals(17));
    });
  });

  group('ScrollController.ensureIndexVisible', () {
    test('scrolls to make index visible in fixed-height ListView', () async {
      await testNocterm('index-based ensureVisible with fixed height', (
        tester,
      ) async {
        final controller = ScrollController();
        final app = _TestListViewApp(controller: controller, itemCount: 20);

        await tester.pumpComponent(app);

        // Initially at top
        expect(controller.offset, equals(0));

        // Navigate to item 15 (beyond visible area)
        // Note: This will scroll to show item 15 at the bottom of the viewport
        controller.ensureIndexVisible(index: 15);

        // Need to pump again to see the scroll take effect
        await tester.pump();

        // Should have scrolled to show item 15
        // With viewport of 10, showing item 15 means we need to scroll past items 0-5
        // So offset should be at least 6 (to show items 6-15)
        expect(controller.offset, greaterThanOrEqualTo(6));
      }, size: const Size(40, 10));
    });

    test('does not scroll when index is already visible', () async {
      await testNocterm('no scroll when already visible', (tester) async {
        final controller = ScrollController();
        final app = _TestListViewApp(controller: controller, itemCount: 20);

        await tester.pumpComponent(app);

        // Item 2 should be visible at the top
        final initialOffset = controller.offset;
        controller.ensureIndexVisible(index: 2);
        await tester.pump();

        // Should not have scrolled
        expect(controller.offset, equals(initialOffset));
      }, size: const Size(40, 10));
    });
  });
}

/// Test app with fixed-height items
class _TestListViewApp extends StatefulComponent {
  const _TestListViewApp({required this.controller, required this.itemCount});

  final ScrollController controller;
  final int itemCount;

  @override
  State<_TestListViewApp> createState() => _TestListViewAppState();
}

class _TestListViewAppState extends State<_TestListViewApp> {
  @override
  Component build(BuildContext context) {
    return ListView.builder(
      controller: component.controller,
      itemCount: component.itemCount,
      lazy: false, // Explicitly set to non-lazy mode for testing
      itemBuilder: (context, index) {
        return Text('Item $index');
      },
    );
  }
}
