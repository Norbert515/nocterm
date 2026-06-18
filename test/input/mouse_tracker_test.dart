import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/rendering/mouse_hit_test.dart';
import 'package:nocterm/src/rendering/mouse_tracker.dart';
import 'package:test/test.dart';

void main() {
  group('MouseTracker', () {
    test('does not keep annotations invalidated during hover dispatch', () {
      final tracker = MouseTracker();
      final renderObject = _AnnotationRenderObject();
      int exitCount = 0;

      late final MouseTrackerAnnotation annotation;
      annotation = MouseTrackerAnnotation(
        onHover: (_) {
          annotation.validForMouseTracker = false;
        },
        onExit: (_) {
          exitCount++;
        },
        renderObject: renderObject,
      );
      renderObject.annotation = annotation;

      final result = MouseHitTestResult()
        ..addWithPosition(target: renderObject, localPosition: Offset.zero);

      tracker.updateAnnotations(
        result,
        const MouseEvent(
          button: MouseButton.left,
          x: 0,
          y: 0,
          pressed: false,
          isMotion: true,
        ),
      );
      tracker.clear(
        const MouseEvent(
          button: MouseButton.left,
          x: 1,
          y: 1,
          pressed: false,
          isMotion: true,
        ),
      );

      expect(
        exitCount,
        0,
        reason: 'Invalid annotations should not be retained for later events',
      );
    });
  });
}

class _AnnotationRenderObject extends RenderObject
    with MouseTrackerAnnotationProvider {
  @override
  MouseTrackerAnnotation? annotation;

  @override
  void performLayout() {
    size = Size.zero;
  }
}
