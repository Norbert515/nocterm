import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Stack', () {
    test('Positioned.fill should fill entire Stack', () async {
      await testNocterm('positioned fill background', (tester) async {
        await tester.pumpComponent(
          Container(
            width: 40,
            height: 10,
            child: Stack(
              children: [
                // Background should fill entire 40x10 area
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(style: BoxBorderStyle.double),
                    ),
                    child: const Center(child: Text('BG')),
                  ),
                ),
                // Small positioned element
                Positioned(
                  left: 2,
                  top: 1,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      border: BoxBorder.all(),
                      color: const Color.fromRGB(100, 100, 200),
                    ),
                    child: const Text('TL'),
                  ),
                ),
              ],
            ),
          ),
        );

        print('Stack with Positioned.fill background:');
        print('Expected: 40x10 container with border filling entire area');
        print('Actual output:');
      }, debugPrintAfterPump: true);
    });

    test('Stack sizing with different child configurations', () async {
      await testNocterm('stack sizing test', (tester) async {
        print('\n=== Test 1: Stack with explicit size ===');
        await tester.pumpComponent(
          Container(
            width: 30,
            height: 8,
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.double),
            ),
            child: const Stack(children: [Text('Stack content')]),
          ),
        );

        await tester.pump();

        print('\n=== Test 2: Stack with Positioned.fill ===');
        await tester.pumpComponent(
          Container(
            width: 30,
            height: 8,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(border: BoxBorder.all()),
                    child: const Center(child: Text('Fill')),
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pump();

        print('\n=== Test 3: Stack with mixed children ===');
        await tester.pumpComponent(
          Container(
            width: 30,
            height: 8,
            child: Stack(
              children: [
                // Non-positioned child
                Container(
                  width: 15,
                  height: 4,
                  decoration: BoxDecoration(border: BoxBorder.all()),
                  child: const Text('Non-pos'),
                ),
                // Positioned.fill child
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(style: BoxBorderStyle.double),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }, debugPrintAfterPump: true);
    });

    test('Positioned.fill constraints', () async {
      await testNocterm('positioned fill constraints', (tester) async {
        print('\n=== Testing Positioned.fill constraints ===');

        await tester.pumpComponent(
          Container(
            width: 25,
            height: 6,
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.rounded),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  left: 0,
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGB(100, 100, 100),
                    ),
                    child: const Center(child: Text('FILL')),
                  ),
                ),
                Positioned(left: 1, top: 1, child: const Text('P')),
              ],
            ),
          ),
        );

        print('\nThe filled container should occupy the entire 25x6 space');
      }, debugPrintAfterPump: true);
    });
  });
}
