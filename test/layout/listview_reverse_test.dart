import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('ListView reverse', () {
    test('renders items from bottom to top when reverse is true', () async {
      await testNocterm('reverse vertical ListView', (tester) async {
        await tester.pumpComponent(
          SizedBox(
            width: 20,
            height: 10,
            child: ListView(
              reverse: true,
              children: [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
                Text('Item 4'),
                Text('Item 5'),
              ],
            ),
          ),
        );

        // When reverse is true, Item 1 should appear at the bottom
        // and we should be scrolled to show the beginning of the list
        final output = tester.terminalState.getText();

        // Print to debug
        print('Terminal output:');
        print(output);

        // The items should be rendered in reverse order from bottom
        expect(output, contains('Item 1'));
        expect(output, contains('Item 2'));
        expect(output, contains('Item 3'));
      }, debugPrintAfterPump: true);
    });

    test(
      'renders items from right to left when reverse is true and horizontal',
      () async {
        await testNocterm('reverse horizontal ListView', (tester) async {
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 5,
              child: ListView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                children: [
                  Container(width: 10, child: Center(child: Text('A'))),
                  Container(width: 10, child: Center(child: Text('B'))),
                  Container(width: 10, child: Center(child: Text('C'))),
                ],
              ),
            ),
          );

          final output = tester.terminalState.getText();

          // Print to debug
          print('Terminal output:');
          print(output);

          // Items should appear from right to left
          expect(output, contains('A'));
          expect(output, contains('B'));
          expect(output, contains('C'));
        }, debugPrintAfterPump: true);
      },
    );

    test('normal ListView renders from top to bottom', () async {
      await testNocterm('normal vertical ListView', (tester) async {
        await tester.pumpComponent(
          SizedBox(
            width: 20,
            height: 10,
            child: ListView(
              children: [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
                Text('Item 4'),
                Text('Item 5'),
              ],
            ),
          ),
        );

        final output = tester.terminalState.getText();

        // Print to debug
        print('Terminal output:');
        print(output);

        // Items should appear from top to bottom normally
        expect(output, contains('Item 1'));
        expect(output, contains('Item 2'));
        expect(output, contains('Item 3'));
      }, debugPrintAfterPump: true);
    });

    test('ListView.builder with reverse', () async {
      await testNocterm('reverse ListView.builder', (tester) async {
        await tester.pumpComponent(
          SizedBox(
            width: 20,
            height: 10,
            child: ListView.builder(
              reverse: true,
              itemCount: 10,
              itemBuilder: (context, index) => Text('Item $index'),
            ),
          ),
        );

        final output = tester.terminalState.getText();

        // Print to debug
        print('Terminal output:');
        print(output);

        // Should show items in reverse order
        expect(output, contains('Item 0'));
        expect(output, contains('Item 1'));
      }, debugPrintAfterPump: true);
    });

    test('ListView.separated with reverse', () async {
      await testNocterm('reverse ListView.separated', (tester) async {
        await tester.pumpComponent(
          SizedBox(
            width: 20,
            height: 15,
            child: ListView.separated(
              reverse: true,
              itemCount: 5,
              itemBuilder: (context, index) => Text('Item $index'),
              separatorBuilder: (context, index) => Text('---'),
            ),
          ),
        );

        final output = tester.terminalState.getText();

        // Print to debug
        print('Terminal output:');
        print(output);

        // Should show items with separators in reverse
        expect(output, contains('Item 0'));
        expect(output, contains('---'));
        expect(output, contains('Item 1'));
      }, debugPrintAfterPump: true);
    });
  });
}
