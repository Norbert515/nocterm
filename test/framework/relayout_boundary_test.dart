import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('relayout boundaries', () {
    test('child laid out without parent size dependency relayouts alone', () {
      var visualUpdates = 0;
      final owner = PipelineOwner()
        ..onNeedsVisualUpdate = () {
          visualUpdates++;
        };
      final parent = _BoundaryParent(parentUsesChildSize: false);
      final child = _CountingBox();
      parent.child = child;
      parent.attach(owner);

      parent.layout(BoxConstraints.tight(const Size(20, 5)));
      expect(parent.layoutCount, 1);
      expect(child.layoutCount, 1);

      parent.layoutCount = 0;
      child.layoutCount = 0;
      visualUpdates = 0;

      child.markNeedsLayout();

      expect(child.needsLayout, isTrue);
      expect(parent.needsLayout, isFalse);
      expect(parent.needsPaint, isTrue);
      expect(visualUpdates, greaterThan(0));

      owner.flushLayout();

      expect(parent.layoutCount, 0);
      expect(child.layoutCount, 1);
      expect(child.needsLayout, isFalse);
    });

    test('child laid out with parent size dependency propagates layout', () {
      final owner = PipelineOwner();
      final parent = _BoundaryParent(parentUsesChildSize: true);
      final child = _CountingBox();
      parent.child = child;
      parent.attach(owner);

      parent.layout(BoxConstraints.tight(const Size(20, 5)));
      parent.layoutCount = 0;
      child.layoutCount = 0;

      child.markNeedsLayout();

      expect(child.needsLayout, isTrue);
      expect(parent.needsLayout, isTrue);

      parent.layout(BoxConstraints.tight(const Size(20, 5)));

      expect(parent.layoutCount, 1);
      expect(child.layoutCount, 1);
      expect(parent.needsLayout, isFalse);
      expect(child.needsLayout, isFalse);
    });
  });
}

class _BoundaryParent extends RenderObject
    with RenderObjectWithChildMixin<RenderObject> {
  _BoundaryParent({required this.parentUsesChildSize});

  final bool parentUsesChildSize;
  int layoutCount = 0;

  @override
  void performLayout() {
    layoutCount++;
    child?.layout(
      BoxConstraints.tight(const Size(8, 2)),
      parentUsesSize: parentUsesChildSize,
    );
    size = constraints.constrain(
      parentUsesChildSize ? child?.size ?? Size.zero : const Size(20, 5),
    );
  }
}

class _CountingBox extends RenderObject {
  int layoutCount = 0;

  @override
  void performLayout() {
    layoutCount++;
    size = constraints.constrain(const Size(1, 1));
  }
}
