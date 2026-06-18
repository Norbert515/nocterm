import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Mouse button state', () {
    testNocterm('motion release after normal press clears button', (
      tester,
    ) async {
      int tapCount = 0;

      await tester.pumpComponent(
        Container(
          width: 80,
          height: 24,
          child: GestureDetector(
            onTap: () => tapCount++,
            child: Container(
              width: 20,
              height: 5,
              child: const Center(child: Text('[Click me]')),
            ),
          ),
        ),
      );

      await tester.sendMouseEvent(
        const MouseEvent(
          button: MouseButton.left,
          x: 10,
          y: 2,
          pressed: true,
        ),
      );

      await tester.sendMouseEvent(
        const MouseEvent(
          button: MouseButton.left,
          x: 10,
          y: 2,
          pressed: false,
          isMotion: true,
        ),
      );

      expect(
        tapCount,
        1,
        reason: 'Motion-marked release should still complete the click',
      );

      await tester.tap(10, 2);
      expect(
        tapCount,
        2,
        reason: 'Subsequent clicks should not inherit a stuck button state',
      );
    });
  });
}
