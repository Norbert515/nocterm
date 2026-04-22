// The layout-skip check uses BoxConstraints value equality. This test
// flips red if anyone swaps it back to `identical()`: a distinct-but-
// value-equal BoxConstraints on a clean render object must not re-run
// performLayout.

import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  test(
    'layout() skips performLayout when constraints are value-equal and clean',
    () {
      final render = _CountingRenderObject();

      // First layout establishes size + constraints.
      render.layout(
        BoxConstraints(minWidth: 10, maxWidth: 10, minHeight: 1, maxHeight: 1),
      );
      expect(render.performLayoutCount, 1);

      // A distinct-but-value-equal BoxConstraints must NOT trigger a
      // re-layout. This is the invariant that fails under identical().
      final distinctEqualConstraints = BoxConstraints(
        minWidth: 10,
        maxWidth: 10,
        minHeight: 1,
        maxHeight: 1,
      );
      expect(
        identical(distinctEqualConstraints, render.lastConstraints),
        isFalse,
        reason: 'constructed from the same field values but must be a '
            'separate instance - otherwise the test cannot distinguish '
            '== from identical()',
      );
      expect(distinctEqualConstraints == render.lastConstraints, isTrue);

      render.layout(distinctEqualConstraints);
      expect(
        render.performLayoutCount,
        1,
        reason: 'performLayout must not re-run when value-equal constraints '
            'arrive and the render object is not dirty',
      );

      // But marking dirty does force re-layout, even with the same value.
      render.markNeedsLayout();
      render.layout(distinctEqualConstraints);
      expect(render.performLayoutCount, 2);
    },
  );
}

class _CountingRenderObject extends RenderObject {
  int performLayoutCount = 0;
  BoxConstraints? lastConstraints;

  @override
  void performLayout() {
    performLayoutCount++;
    lastConstraints = constraints;
    size = constraints.constrain(const Size(10, 1));
  }
}
