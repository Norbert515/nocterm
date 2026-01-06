import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Column inside Column - detailed analysis', () {
    test('Simple Column in Column - constraint flow', () async {
      await testNocterm('column in column constraints', (tester) async {
        print('\n=== Column in Column - Constraint Flow ===');
        print('Outer Column has finite height from Container (20)');
        print('Inner Column should receive infinite height during measurement');

        await tester.pumpComponent(
          Container(
            width: 30,
            height: 20,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: Column(
              children: [
                Container(
                  width: 25,
                  height: 3,
                  color: Colors.red,
                  child: Text('Top', style: TextStyle(color: Colors.white)),
                ),
                // This inner Column should receive infinite height constraint
                Column(
                  children: [
                    Container(
                      width: 25,
                      height: 2,
                      color: Colors.green,
                      child: Text('A', style: TextStyle(color: Colors.white)),
                    ),
                    Container(
                      width: 25,
                      height: 2,
                      color: Colors.yellow,
                      child: Text('B', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                Container(
                  width: 25,
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

    test('Column in Column with IntrinsicHeight wrapper', () async {
      await testNocterm('column with intrinsic height', (tester) async {
        print('\n=== Column in Column with IntrinsicHeight ===');
        print(
          'IntrinsicHeight should measure children first, then provide finite constraint',
        );

        await tester.pumpComponent(
          Container(
            width: 30,
            height: 20,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: Column(
              children: [
                Container(
                  width: 25,
                  height: 3,
                  color: Colors.red,
                  child: Text('Top', style: TextStyle(color: Colors.white)),
                ),
                // Wrap inner Column with IntrinsicHeight (if implemented)
                // For now, use SizedBox as a workaround
                SizedBox(
                  height: 4, // Explicit height
                  child: Column(
                    children: [
                      Container(
                        width: 25,
                        height: 2,
                        color: Colors.green,
                        child: Text('A', style: TextStyle(color: Colors.white)),
                      ),
                      Container(
                        width: 25,
                        height: 2,
                        color: Colors.yellow,
                        child: Text('B', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 25,
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

    test('Column in Column with Expanded wrapper', () async {
      await testNocterm('column with expanded', (tester) async {
        print('\n=== Column in Column with Expanded ===');
        print('Expanded should give finite constraints to inner Column');

        await tester.pumpComponent(
          Container(
            width: 30,
            height: 20,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: Column(
              children: [
                Container(
                  width: 25,
                  height: 3,
                  color: Colors.red,
                  child: Text('Top', style: TextStyle(color: Colors.white)),
                ),
                // Expanded gives finite height to inner Column
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 25,
                        height: 2,
                        color: Colors.green,
                        child: Text('A', style: TextStyle(color: Colors.white)),
                      ),
                      Container(
                        width: 25,
                        height: 2,
                        color: Colors.yellow,
                        child: Text('B', style: TextStyle(color: Colors.black)),
                      ),
                      // This will expand to fill remaining space
                      Expanded(
                        child: Container(
                          width: 25,
                          color: Colors.cyan,
                          child: Text(
                            'Fill',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 25,
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

    test('Column in Column with Flexible wrapper', () async {
      await testNocterm('column with flexible', (tester) async {
        print('\n=== Column in Column with Flexible ===');
        print('Flexible should give bounded constraints to inner Column');

        await tester.pumpComponent(
          Container(
            width: 30,
            height: 20,
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue),
            ),
            child: Column(
              children: [
                Container(
                  width: 25,
                  height: 3,
                  color: Colors.red,
                  child: Text('Top', style: TextStyle(color: Colors.white)),
                ),
                // Flexible gives bounded height to inner Column
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Shrink to fit content
                    children: [
                      Container(
                        width: 25,
                        height: 2,
                        color: Colors.green,
                        child: Text('A', style: TextStyle(color: Colors.white)),
                      ),
                      Container(
                        width: 25,
                        height: 2,
                        color: Colors.yellow,
                        child: Text('B', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 25,
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

    test('Comparing MainAxisSize.max vs MainAxisSize.min', () async {
      await testNocterm('mainAxisSize comparison', (tester) async {
        print('\n=== MainAxisSize.max vs MainAxisSize.min ===');
        print('MainAxisSize.min should size Column to its content');
        print('MainAxisSize.max should expand to available space');

        await tester.pumpComponent(
          Row(
            children: [
              // Left: MainAxisSize.max (default)
              Container(
                width: 25,
                height: 20,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.blue),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: 20,
                      height: 3,
                      color: Colors.red,
                      child: Text('MAX', style: TextStyle(color: Colors.white)),
                    ),
                    Container(
                      width: 20,
                      height: 3,
                      color: Colors.green,
                      child: Text(
                        'Size',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 5),
              // Right: MainAxisSize.min
              Container(
                width: 25,
                height: 20,
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.cyan),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 3,
                      color: Colors.yellow,
                      child: Text('MIN', style: TextStyle(color: Colors.black)),
                    ),
                    Container(
                      width: 20,
                      height: 3,
                      color: Colors.magenta,
                      child: Text(
                        'Size',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }, debugPrintAfterPump: true);
    });
  });
}
