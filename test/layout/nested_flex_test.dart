import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Nested Row/Column behavior', () {
    test('Row inside Row - basic nesting', () async {
      await testNocterm('row in row', (tester) async {
        print('\n=== Testing Row inside Row ===');
        await tester.pumpComponent(
          Container(
            width: 50,
            height: 10,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 5,
                  color: Colors.red,
                  child: Text('A', style: TextStyle(color: Colors.white)),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 5,
                      color: Colors.green,
                      child: Text('B', style: TextStyle(color: Colors.white)),
                    ),
                    Container(
                      width: 8,
                      height: 5,
                      color: Colors.yellow,
                      child: Text('C', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                Container(
                  width: 10,
                  height: 5,
                  color: Colors.magenta,
                  child: Text('D', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test('Column inside Column - basic nesting', () async {
      await testNocterm('column in column', (tester) async {
        print('\n=== Testing Column inside Column ===');
        await tester.pumpComponent(
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: Column(
              children: [
                Container(
                  width: 15,
                  height: 3,
                  color: Colors.red,
                  child: Text('Top', style: TextStyle(color: Colors.white)),
                ),
                Column(
                  children: [
                    Container(
                      width: 15,
                      height: 2,
                      color: Colors.green,
                      child: Text(
                        'Mid1',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Container(
                      width: 15,
                      height: 2,
                      color: Colors.yellow,
                      child: Text(
                        'Mid2',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 15,
                  height: 3,
                  color: Colors.magenta,
                  child: Text('Bot', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test('Row inside Column - mixed nesting', () async {
      await testNocterm('row in column', (tester) async {
        print('\n=== Testing Row inside Column ===');
        await tester.pumpComponent(
          Container(
            width: 30,
            height: 15,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: Column(
              children: [
                Container(
                  width: 25,
                  height: 3,
                  color: Colors.red,
                  child: Text('Header', style: TextStyle(color: Colors.white)),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 4,
                      color: Colors.green,
                      child: Text('L', style: TextStyle(color: Colors.white)),
                    ),
                    Container(
                      width: 8,
                      height: 4,
                      color: Colors.yellow,
                      child: Text('M', style: TextStyle(color: Colors.black)),
                    ),
                    Container(
                      width: 8,
                      height: 4,
                      color: Colors.cyan,
                      child: Text('R', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                Container(
                  width: 25,
                  height: 3,
                  color: Colors.magenta,
                  child: Text('Footer', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test('Column inside Row - mixed nesting opposite', () async {
      await testNocterm('column in row', (tester) async {
        print('\n=== Testing Column inside Row ===');
        await tester.pumpComponent(
          Container(
            width: 40,
            height: 12,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 10,
                  color: Colors.red,
                  child: Text('L', style: TextStyle(color: Colors.white)),
                ),
                Column(
                  children: [
                    Container(
                      width: 15,
                      height: 3,
                      color: Colors.green,
                      child: Text('Top', style: TextStyle(color: Colors.white)),
                    ),
                    Container(
                      width: 15,
                      height: 3,
                      color: Colors.yellow,
                      child: Text('Mid', style: TextStyle(color: Colors.black)),
                    ),
                    Container(
                      width: 15,
                      height: 3,
                      color: Colors.cyan,
                      child: Text('Bot', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                Container(
                  width: 8,
                  height: 10,
                  color: Colors.magenta,
                  child: Text('R', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test('Nested with Expanded - Row with expanded inner Row', () async {
      await testNocterm('expanded nested row', (tester) async {
        print('\n=== Testing Expanded in nested Row ===');
        await tester.pumpComponent(
          Container(
            width: 50,
            height: 10,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 8,
                  color: Colors.red,
                  child: Text('Fix', style: TextStyle(color: Colors.white)),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 8,
                          color: Colors.green,
                          child: Text(
                            'Exp1',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 8,
                        color: Colors.yellow,
                        child: Text(
                          'Fix2',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 8,
                          color: Colors.cyan,
                          child: Text(
                            'Exp2',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 10,
                  height: 8,
                  color: Colors.magenta,
                  child: Text('End', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test('Deep nesting - 3 levels', () async {
      await testNocterm('deep nesting', (tester) async {
        print('\n=== Testing 3-level deep nesting ===');
        await tester.pumpComponent(
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: Column(
              children: [
                Container(
                  height: 3,
                  color: Colors.red,
                  child: Text('Level 1', style: TextStyle(color: Colors.white)),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        color: Colors.green,
                        child: Text(
                          'L2',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 2,
                              color: Colors.yellow,
                              child: Text(
                                'L3-T',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                color: Colors.cyan,
                                child: Center(
                                  child: Text(
                                    'L3-C',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 2,
                              color: Colors.magenta,
                              child: Text(
                                'L3-B',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 8,
                        color: Colors.blue,
                        child: Text(
                          'L2',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 3,
                  color: Colors.grey,
                  child: Text('Level 1', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test('MainAxisSize.min behavior in nested flex', () async {
      await testNocterm('mainAxisSize min', (tester) async {
        print('\n=== Testing MainAxisSize.min in nested flex ===');
        await tester.pumpComponent(
          Container(
            width: 50,
            height: 15,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 3,
                  color: Colors.red,
                  child: Text(
                    'Full width',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 3,
                      color: Colors.green,
                      child: Text('A', style: TextStyle(color: Colors.white)),
                    ),
                    Container(
                      width: 10,
                      height: 3,
                      color: Colors.yellow,
                      child: Text('B', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                Container(
                  width: 40,
                  height: 3,
                  color: Colors.magenta,
                  child: Text(
                    'Full width',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test('CrossAxisAlignment in nested flex', () async {
      await testNocterm('cross axis alignment', (tester) async {
        print('\n=== Testing CrossAxisAlignment in nested flex ===');
        await tester.pumpComponent(
          Container(
            width: 50,
            height: 15,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 10,
                  color: Colors.red,
                  child: Text('Stretch', style: TextStyle(color: Colors.white)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 15,
                      height: 3,
                      color: Colors.green,
                      child: Text('Top', style: TextStyle(color: Colors.white)),
                    ),
                    Container(
                      width: 20,
                      height: 3,
                      color: Colors.yellow,
                      child: Text(
                        'Middle',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 3,
                      color: Colors.cyan,
                      child: Text('Bot', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                Container(
                  width: 10,
                  color: Colors.magenta,
                  child: Text('Stretch', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      }, debugPrintAfterPump: true);
    });
  });
}
