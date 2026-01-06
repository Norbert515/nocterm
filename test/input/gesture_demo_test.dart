import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

import '../../example/gesture_demo.dart';

void main() {
  group(
    'Gesture Demo',
    skip:
        'Known issue: GestureDemo uses nested constraints that need refactoring',
    () {
      test('visual development - initial render', () async {
        await testNocterm(
          'gesture demo renders correctly',
          (tester) async {
            await tester.pumpComponent(const GestureDemoApp());
          },
          debugPrintAfterPump: true,
          size: const Size(100, 50),
        );
      });

      test('renders all zones and labels', () async {
        await testNocterm('all zones visible', (tester) async {
          await tester.pumpComponent(const GestureDemoApp());

          // Verify all zone labels are present
          expect(tester.terminalState, containsText('TAP ME'));
          expect(tester.terminalState, containsText('DOUBLE TAP'));
          expect(tester.terminalState, containsText('LONG PRESS'));
          expect(tester.terminalState, containsText('HOVER ME'));
          expect(tester.terminalState, containsText('COMBINED'));
          expect(tester.terminalState, containsText('Event Log'));
        }, size: const Size(100, 50));
      });

      test('tap zone interaction', () async {
        await testNocterm('tap updates state', (tester) async {
          bool tapped = false;

          await tester.pumpComponent(
            _TestTapComponent(onTapCallback: () => tapped = true),
          );

          // Tap
          await tester.tap(10, 5);

          // Verify tap was registered
          expect(tapped, true);
        });
      });

      test('double-tap detection', () async {
        await testNocterm('double tap increments counter', (tester) async {
          int doubleTapCount = 0;

          await tester.pumpComponent(
            _TestDoubleTapComponent(
              onDoubleTapCallback: () => doubleTapCount++,
            ),
          );

          // Double tap
          await tester.tap(10, 5);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(10, 5);

          // Verify double-tap was registered
          expect(doubleTapCount, 1);
        });
      });

      test('long press detection', () async {
        await testNocterm('long press triggers callback', (tester) async {
          bool longPressStarted = false;
          bool longPressCompleted = false;

          await tester.pumpComponent(
            _TestLongPressComponent(
              onLongPressStartCallback: () => longPressStarted = true,
              onLongPressCallback: () => longPressCompleted = true,
            ),
          );

          // Long press
          await tester.press(10, 5);
          await tester.pump(const Duration(milliseconds: 600));
          await tester.release(10, 5);

          // Verify long press was registered
          expect(longPressStarted, true);
          expect(longPressCompleted, true);
        });
      });

      test('hover region detection', () async {
        await testNocterm('hover changes state', (tester) async {
          bool isHovering = false;

          await tester.pumpComponent(
            _TestHoverComponent(
              onEnterCallback: () => isHovering = true,
              onExitCallback: () => isHovering = false,
            ),
          );

          // Hover
          await tester.hover(10, 5);

          // Verify hover was registered
          expect(isHovering, true);
        });
      });

      test('combined zone - tap and hover', () async {
        await testNocterm('combined zone handles multiple gestures', (
          tester,
        ) async {
          bool isHovering = false;
          int tapCount = 0;

          await tester.pumpComponent(
            _TestCombinedComponent(
              onEnterCallback: () => isHovering = true,
              onTapCallback: () => tapCount++,
            ),
          );

          // Hover first
          await tester.hover(15, 5);
          expect(isHovering, true);

          // Tap while hovering
          await tester.tap(15, 5);
          expect(tapCount, 1);
        });
      });

      test('visual test - demo app renders', () async {
        await testNocterm('gesture demo at default size', (tester) async {
          await tester.pumpComponent(const GestureDemoApp());

          // Should render without overflow at proper size
          expect(tester.terminalState, containsText('GESTURE DETECTOR DEMO'));
          expect(tester.terminalState, containsText('Count: 0'));
        }, size: const Size(100, 50));
      });

      test('position tracking in callbacks', () async {
        await testNocterm('tap provides position details', (tester) async {
          Offset? tapPosition;

          await tester.pumpComponent(
            _TestPositionComponent(
              onTapDownCallback: (details) =>
                  tapPosition = details.localPosition,
            ),
          );

          // Tap at specific position
          await tester.tap(15, 8);

          // Verify position was captured
          expect(tapPosition, isNotNull);
          expect(tapPosition!.dx, 15.0);
          expect(tapPosition!.dy, 8.0);
        });
      });
    },
  );
}

// Helper test components
class _TestTapComponent extends StatefulComponent {
  const _TestTapComponent({required this.onTapCallback});

  final VoidCallback onTapCallback;

  @override
  State<_TestTapComponent> createState() => _TestTapComponentState();
}

class _TestTapComponentState extends State<_TestTapComponent> {
  int tapCount = 0;

  @override
  Component build(BuildContext context) {
    return Container(
      width: 100,
      height: 50,
      child: GestureDetector(
        onTap: () {
          component.onTapCallback();
          setState(() {
            tapCount++;
          });
        },
        child: Container(
          width: 30,
          height: 10,
          decoration: BoxDecoration(border: BoxBorder.all()),
          child: Center(child: Text('Tap count: $tapCount')),
        ),
      ),
    );
  }
}

class _TestDoubleTapComponent extends StatefulComponent {
  const _TestDoubleTapComponent({required this.onDoubleTapCallback});

  final VoidCallback onDoubleTapCallback;

  @override
  State<_TestDoubleTapComponent> createState() =>
      _TestDoubleTapComponentState();
}

class _TestDoubleTapComponentState extends State<_TestDoubleTapComponent> {
  int doubleTapCount = 0;

  @override
  Component build(BuildContext context) {
    return Container(
      width: 100,
      height: 50,
      child: GestureDetector(
        onDoubleTap: () {
          component.onDoubleTapCallback();
          setState(() {
            doubleTapCount++;
          });
        },
        child: Container(
          width: 30,
          height: 10,
          decoration: BoxDecoration(border: BoxBorder.all()),
          child: Center(child: Text('Double taps: $doubleTapCount')),
        ),
      ),
    );
  }
}

class _TestLongPressComponent extends StatelessComponent {
  const _TestLongPressComponent({
    required this.onLongPressStartCallback,
    required this.onLongPressCallback,
  });

  final VoidCallback onLongPressStartCallback;
  final VoidCallback onLongPressCallback;

  @override
  Component build(BuildContext context) {
    return Container(
      width: 100,
      height: 50,
      child: GestureDetector(
        onLongPress: onLongPressCallback,
        onLongPressStart: (details) => onLongPressStartCallback(),
        child: Container(
          width: 30,
          height: 10,
          decoration: BoxDecoration(border: BoxBorder.all()),
          child: const Center(child: Text('Long press me')),
        ),
      ),
    );
  }
}

class _TestHoverComponent extends StatelessComponent {
  const _TestHoverComponent({
    required this.onEnterCallback,
    required this.onExitCallback,
  });

  final VoidCallback onEnterCallback;
  final VoidCallback onExitCallback;

  @override
  Component build(BuildContext context) {
    return Container(
      width: 100,
      height: 50,
      child: MouseRegion(
        onEnter: (event) => onEnterCallback(),
        onExit: (event) => onExitCallback(),
        child: Container(
          width: 30,
          height: 10,
          decoration: BoxDecoration(border: BoxBorder.all()),
          child: const Center(child: Text('Hover me')),
        ),
      ),
    );
  }
}

class _TestCombinedComponent extends StatelessComponent {
  const _TestCombinedComponent({
    required this.onEnterCallback,
    required this.onTapCallback,
  });

  final VoidCallback onEnterCallback;
  final VoidCallback onTapCallback;

  @override
  Component build(BuildContext context) {
    return Container(
      width: 100,
      height: 50,
      child: MouseRegion(
        onEnter: (event) => onEnterCallback(),
        child: GestureDetector(
          onTap: onTapCallback,
          child: Container(
            width: 40,
            height: 10,
            decoration: BoxDecoration(border: BoxBorder.all()),
            child: const Center(child: Text('Tap and hover')),
          ),
        ),
      ),
    );
  }
}

class _TestPositionComponent extends StatelessComponent {
  const _TestPositionComponent({required this.onTapDownCallback});

  final Function(TapDownDetails) onTapDownCallback;

  @override
  Component build(BuildContext context) {
    return Container(
      width: 100,
      height: 50,
      child: GestureDetector(
        onTapDown: onTapDownCallback,
        child: Container(
          width: 40,
          height: 10,
          decoration: BoxDecoration(border: BoxBorder.all()),
          child: const Center(child: Text('Tap for position')),
        ),
      ),
    );
  }
}
