import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';
import '../../example/scroll_demo.dart';

void main() {
  group('ScrollDemo Tab Navigation Bug', () {
    test('reproduces tab navigation causing layout changes', () async {
      await testNocterm('tab navigation bug reproduction', (tester) async {
        await tester.pumpComponent(const ScrollDemo());

        print('Initial state:');
        tester.terminalState.toString();

        // Press tab to go to ListView demo (index 1)
        await tester.sendKey(LogicalKey.tab);
        await tester.pump();
        print('\nAfter first tab (ListView):');
        tester.terminalState.toString();

        // Press tab to go to ListView.builder demo (index 2)
        await tester.sendKey(LogicalKey.tab);
        await tester.pump();
        print('\nAfter second tab (ListView.builder):');
        final secondTabState = tester.terminalState.toString();

        // Press tab to go to Scrollbar demo (index 3)
        await tester.sendKey(LogicalKey.tab);
        await tester.pump();
        print('\nAfter third tab (Scrollbar):');
        tester.terminalState.toString();

        // Press tab to cycle back to SingleChildScrollView (index 0)
        await tester.sendKey(LogicalKey.tab);
        await tester.pump();
        print('\nAfter fourth tab (back to SingleChildScrollView):');
        tester.terminalState.toString();

        // Now press tab 10 more times to see if layout changes
        print('\n--- Pressing tab 10 more times ---');
        List<String> states = [];
        for (int i = 0; i < 10; i++) {
          await tester.sendKey(LogicalKey.tab);
          await tester.pump();
          states.add(tester.terminalState.toString());
          print('\nAfter tab ${i + 5} (index ${(i + 1) % 4}):');
        }

        // Check if the states at the same tab index are different
        // After 10 tabs, we should be at index 2 (ListView.builder)
        // Compare with the initial state when we were at index 2
        print('\n--- Comparing states ---');
        print('Second tab state lines: ${secondTabState.split('\n').length}');
        print('After 14 tabs state lines: ${states.last.split('\n').length}');

        // Count specific items in the states to detect duplication
        final itemCount1 = 'Item'.allMatches(secondTabState).length;
        final itemCount2 = 'Item'.allMatches(states.last).length;
        print('Item count at second tab: $itemCount1');
        print('Item count after 14 tabs: $itemCount2');

        // Check for Row/Line count changes
        final rowCount1 = 'Row'.allMatches(secondTabState).length;
        final rowCount2 = 'Row'.allMatches(states.last).length;
        print('Row count at second tab: $rowCount1');
        print('Row count after 14 tabs: $rowCount2');

        final lineCount1 = 'Line'.allMatches(secondTabState).length;
        final lineCount2 = 'Line'.allMatches(states.last).length;
        print('Line count at second tab: $lineCount1');
        print('Line count after 14 tabs: $lineCount2');

        // The bug would manifest as increased counts
        if (itemCount2 > itemCount1 ||
            rowCount2 > rowCount1 ||
            lineCount2 > lineCount1) {
          print('\n🐛 BUG REPRODUCED: Content is accumulating!');
          print('Items increased by: ${itemCount2 - itemCount1}');
          print('Rows increased by: ${rowCount2 - rowCount1}');
          print('Lines increased by: ${lineCount2 - lineCount1}');
        }
      }, size: Size(80, 30));
    });

    test('checks specific tab content stability', () async {
      await testNocterm('tab content stability check', (tester) async {
        await tester.pumpComponent(const ScrollDemo());

        // Collect states for each tab after multiple cycles
        Map<int, List<String>> tabStates = {
          0: [], // SingleChildScrollView
          1: [], // ListView
          2: [], // ListView.builder
          3: [], // Scrollbar
        };

        // Do 3 complete cycles (12 tab presses)
        for (int cycle = 0; cycle < 3; cycle++) {
          print('\n=== Cycle ${cycle + 1} ===');
          for (int tab = 0; tab < 4; tab++) {
            await tester.sendKey(LogicalKey.tab);
            await tester.pump();

            final state = tester.terminalState.toString();
            tabStates[(cycle * 4 + tab + 1) % 4]!.add(state);

            // Count specific elements
            final itemCount = 'Item'.allMatches(state).length;
            final rowCount = 'Row'.allMatches(state).length;
            final lineCount = 'Line'.allMatches(state).length;

            print(
              'Tab $tab - Items: $itemCount, Rows: $rowCount, Lines: $lineCount',
            );
          }
        }

        // Compare states for each tab across cycles
        print('\n=== Comparing states across cycles ===');
        for (int tab = 0; tab < 4; tab++) {
          final states = tabStates[tab]!;
          if (states.length >= 2) {
            final firstState = states[0];
            final lastState = states.last;

            final firstItemCount = 'Item'.allMatches(firstState).length;
            final lastItemCount = 'Item'.allMatches(lastState).length;

            final firstRowCount = 'Row'.allMatches(firstState).length;
            final lastRowCount = 'Row'.allMatches(lastState).length;

            final firstLineCount = 'Line'.allMatches(firstState).length;
            final lastLineCount = 'Line'.allMatches(lastState).length;

            print('Tab $tab:');
            print(
              '  Items: $firstItemCount -> $lastItemCount (${lastItemCount - firstItemCount > 0 ? "INCREASED!" : "stable"})',
            );
            print(
              '  Rows: $firstRowCount -> $lastRowCount (${lastRowCount - firstRowCount > 0 ? "INCREASED!" : "stable"})',
            );
            print(
              '  Lines: $firstLineCount -> $lastLineCount (${lastLineCount - firstLineCount > 0 ? "INCREASED!" : "stable"})',
            );

            if (lastItemCount > firstItemCount ||
                lastRowCount > firstRowCount ||
                lastLineCount > firstLineCount) {
              print('  ⚠️ CONTENT ACCUMULATION DETECTED!');
            }
          }
        }
      }, size: Size(80, 30));
    });
  });
}
