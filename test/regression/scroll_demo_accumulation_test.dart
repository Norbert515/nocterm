import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';
import '../../example/scroll_demo.dart';

void main() {
  test('check for content accumulation after multiple tab switches', () async {
    await testNocterm(
      'tab accumulation test',
      (tester) async {
        await tester.pumpComponent(const ScrollDemo());

        // Helper function to count items in current view
        int countItems(String pattern) {
          final state = tester.terminalState.toString();
          return pattern.allMatches(state).length;
        }

        // Record initial state for each tab
        Map<int, Map<String, int>> initialCounts = {};

        // First pass - record initial counts
        for (int i = 0; i < 4; i++) {
          if (i > 0) {
            await tester.sendKey(LogicalKey.tab);
            await tester.pump();
          }

          initialCounts[i] = {
            'Item': countItems('Item'),
            'Row': countItems('Row'),
            'Line': countItems('Line'),
          };

          print('Tab $i initial counts: ${initialCounts[i]}');
        }

        // Do 10 more complete cycles
        print('\n--- Pressing Tab 40 more times (10 complete cycles) ---');
        for (int cycle = 0; cycle < 10; cycle++) {
          for (int tab = 0; tab < 4; tab++) {
            await tester.sendKey(LogicalKey.tab);
            await tester.pump();
          }
        }

        // Record final state for each tab
        Map<int, Map<String, int>> finalCounts = {};

        // Final pass - record final counts
        for (int i = 0; i < 4; i++) {
          await tester.sendKey(LogicalKey.tab);
          await tester.pump();

          finalCounts[i] = {
            'Item': countItems('Item'),
            'Row': countItems('Row'),
            'Line': countItems('Line'),
          };

          print('Tab $i final counts: ${finalCounts[i]}');
        }

        // Check for accumulation
        print('\n--- Checking for accumulation ---');
        bool hasAccumulation = false;

        for (int i = 0; i < 4; i++) {
          for (String key in ['Item', 'Row', 'Line']) {
            final initial = initialCounts[i]![key]!;
            final final_ = finalCounts[i]![key]!;

            if (final_ > initial) {
              print('🐛 Tab $i: $key count increased from $initial to $final_');
              hasAccumulation = true;
            }
          }
        }

        if (hasAccumulation) {
          print(
            '\n⚠️ BUG CONFIRMED: Content is accumulating after tab switches!',
          );
        } else {
          print('\n✅ No accumulation detected - counts remain stable');
        }

        // Also check the terminal output visually
        print('\n--- Final terminal state ---');
        print(tester.renderToString());

        expect(
          hasAccumulation,
          isFalse,
          reason: 'Content should not accumulate after tab switches',
        );
      },
      size: Size(100, 50), // Larger size to see more content
    );
  });
}
