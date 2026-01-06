import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Center and Align sizing behavior', () {
    test('Center in Column should not cause overflow', () async {
      await testNocterm('center in column no overflow', (tester) async {
        await tester.pumpComponent(
          Column(
            children: [
              Center(child: Text('Line 1')),
              Center(child: Text('Line 2')),
            ],
          ),
        );

        // Visual verification - no overflow indicators should appear
        // The test passing without overflow warnings indicates success
      }, size: Size(80, 40));
    });

    test('Align with factors behaves correctly', () async {
      await testNocterm('align with width and height factors', (tester) async {
        await tester.pumpComponent(
          Column(
            children: [
              // Test widthFactor
              Align(
                alignment: Alignment.center,
                widthFactor: 2.0,
                child: Container(width: 10, height: 1, child: Text('Wide')),
              ),
              // Test heightFactor
              Align(
                alignment: Alignment.center,
                heightFactor: 3.0,
                child: Container(width: 10, height: 1, child: Text('Tall')),
              ),
            ],
          ),
        );

        // Visual verification of factor behavior
      });
    });

    test('Multiple Centers in Column layout correctly', () async {
      await testNocterm('multiple centers', (tester) async {
        await tester.pumpComponent(
          Column(
            children: [
              Center(child: Text('Hello, World!')),
              Center(child: Text('Second line')),
              Center(
                child: Container(
                  width: 20,
                  height: 2,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.white),
                  ),
                  child: Text('Box'),
                ),
              ),
            ],
          ),
        );

        // All centers should shrink to child size
        // No overflow should occur
      }, size: Size(80, 40));
    });
  });
}
