import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';
import '../../example/scroll_demo.dart';

void main() {
  test('no lifecycle errors when switching tabs rapidly', () async {
    await testNocterm('rapid tab switching', (tester) async {
      await tester.pumpComponent(const ScrollDemo());

      // Rapidly switch tabs 20 times
      for (int i = 0; i < 20; i++) {
        await tester.sendKey(LogicalKey.tab);
        await tester.pump();
      }

      // If we get here without errors, the test passes
      expect(true, isTrue, reason: 'No lifecycle errors occurred');
    }, size: Size(80, 50));
  });
}
