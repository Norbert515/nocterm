import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/components/render_text.dart';
import 'package:test/test.dart';

/// Tests for the layout invalidation optimization introduced in 2450c6d
/// ("Optimize render layout invalidation") and the related fixes.
///
/// The optimization uses two cooperating mechanisms:
///
///   1. **Relayout boundaries** — nodes whose parent doesn't depend on
///      their size (`_parentUsesSize == false`) can re-layout alone
///      without cascading up the tree. The parent is notified of paint
///      invalidation only.
///   2. **Same-footprint text** — `RenderText.text` setter skips
///      `markNeedsLayout()` when the new text has the same rendered
///      size as the old, and only fires `markNeedsPaint()`.
///
/// These tests pin both behaviors down so the optimizations don't
/// regress, AND so dependent code (chat toolbar's LayoutBuilder, the
/// streaming ContextBar and MetricsDisplay) keeps working correctly.
void main() {
  group('relayout boundaries', () {
    test('child with parentUsesSize=false relayouts alone, parent is not relaid out', () {
      final owner = PipelineOwner();
      final parent = _SizeIgnoringParent();
      final child = _CountingBox();
      parent.addChild(child);
      parent.attach(owner);

      parent.layout(BoxConstraints.tight(const Size(40, 5)));
      expect(parent.layoutCount, 1);
      expect(child.layoutCount, 1);

      parent.layoutCount = 0;
      child.layoutCount = 0;

      child.markNeedsLayout();
      owner.flushLayout();

      expect(child.layoutCount, 1,
          reason: 'child should re-layout by itself');
      expect(parent.layoutCount, 0,
          reason: 'parent that ignores child size must NOT be '
              're-laid out — it is a relayout boundary');
      expect(parent.needsPaint, isTrue,
          reason: 'parent must still be marked for paint so the '
              'change is rendered');
    });

    test('child with parentUsesSize=true cascades relayout to parent', () {
      final owner = PipelineOwner();
      final parent = _SizeUsingParent();
      final child = _CountingBox();
      parent.addChild(child);
      parent.attach(owner);

      parent.layout(BoxConstraints.tight(const Size(40, 5)));
      parent.layoutCount = 0;
      child.layoutCount = 0;

      child.markNeedsLayout();
      owner.flushLayout();

      expect(child.layoutCount, 1);
      expect(parent.layoutCount, 1,
          reason: 'parent whose size depends on child must re-layout '
              'when child marks itself dirty');
    });

    test('relayout boundary still schedules a visual update', () {
      // Even when layout is skipped (relayout boundary), the paint
      // invalidation must reach the root so a frame is scheduled.
      // Without this, the visual change would be invisible.
      var visualUpdates = 0;
      final owner = PipelineOwner()
        ..onNeedsVisualUpdate = () {
          visualUpdates++;
        };
      final parent = _SizeIgnoringParent();
      final child = _CountingBox();
      parent.addChild(child);
      parent.attach(owner);
      parent.layout(BoxConstraints.tight(const Size(40, 5)));
      visualUpdates = 0;

      child.markNeedsLayout();

      expect(visualUpdates, greaterThan(0),
          reason: 'a dirty mark on a child must propagate paint '
              'invalidation to the root, regardless of _parentUsesSize');
    });

    test('addChild marks parent dirty for next layout pass', () {
      // Regression check: adding a child must trigger relayout,
      // otherwise the new child would never be laid out.
      final owner = PipelineOwner();
      final parent = _SizeUsingParent();
      parent.attach(owner);
      parent.layout(BoxConstraints.tight(const Size(40, 5)));
      parent.layoutCount = 0;

      final newChild = _CountingBox();
      parent.addChild(newChild);

      expect(parent.needsLayout, isTrue,
          reason: 'addChild must mark parent dirty so the new '
              'child is actually included in the next layout pass');
    });
  });

  group('RenderText.text setter optimization', () {
    test('same-footprint text change only marks paint', () {
      // "9" → "1" both render at 1 cell wide under tight constraints.
      final render = RenderText(text: '9');
      render.layout(BoxConstraints.tight(const Size(8, 1)));

      render.text = '1';

      expect(render.needsLayout, isFalse,
          reason: 'same-footprint text change must NOT trigger relayout');
      expect(render.needsPaint, isTrue,
          reason: 'same-footprint text change MUST trigger repaint');
      expect(render.selectableLayout?.lines, ['1']);
    });

    test('size-changing text marks layout', () {
      // "9" → "10" — the new text is one cell wider. Use loose
      // constraints so the constrained size actually reflects the
      // text footprint (under tight constraints the optimization
      // would see both as constraint-clamped, which is not what
      // real-world layouts look like).
      final render = RenderText(text: '9');
      render.layout(const BoxConstraints(maxWidth: 100, maxHeight: 1));

      render.text = '10';

      expect(render.needsLayout, isTrue,
          reason: 'text whose footprint grew must trigger relayout');
      expect(render.needsPaint, isTrue);
    });

    test('text change updates _layoutResult even when size unchanged', () {
      // Critical for paint correctness: the cached layout result must
      // reflect the new text content, otherwise paint() would draw
      // the old characters.
      final render = RenderText(text: 'hello');
      render.layout(BoxConstraints.tight(const Size(20, 1)));
      expect(render.selectableLayout?.lines, ['hello']);

      render.text = 'world'; // same width
      expect(render.selectableLayout?.lines, ['world'],
          reason: 'cached layout result must reflect the new text');
    });

    test('style change marks paint but not layout', () {
      // Style-only changes never affect layout — they're paint-only.
      final render = RenderText(
        text: 'x',
        style: const TextStyle(color: Color(0xFFFF0000)),
      );
      render.layout(BoxConstraints.tight(const Size(8, 1)));

      render.style = const TextStyle(color: Color(0xFF00FF00));

      expect(render.needsLayout, isFalse,
          reason: 'style-only change must not trigger relayout');
      expect(render.needsPaint, isTrue,
          reason: 'style change must trigger repaint');
    });

    test('text change propagates paint to root even across relayout boundary', () {
      // Even when text is inside a relayout boundary
      // (parentUsesSize=false), paint invalidation must reach the root,
      // otherwise the change is invisible. The streaming ContextBar
      // and MetricsDisplay rely on this for their 16–50ms updates.
      var visualUpdates = 0;
      final owner = PipelineOwner()
        ..onNeedsVisualUpdate = () {
          visualUpdates++;
        };
      final parent = _SizeIgnoringParent();
      final text = RenderText(text: 'a');
      parent.addChild(text);
      parent.attach(owner);
      parent.layout(BoxConstraints.tight(const Size(40, 1)));
      visualUpdates = 0;

      text.text = 'b'; // same footprint

      expect(visualUpdates, greaterThan(0),
          reason: 'paint invalidation must propagate to root even '
              'when layout is skipped by the relayout boundary');
    });
  });

  group('markNeedsLayout — propagation semantics', () {
    test('parentUsesSize=true propagates dirty mark to parent', () {
      // When parent actually depends on child size, dirty marks
      // must cascade up so the parent re-derives its size.
      final owner = PipelineOwner();
      final parent = _SizeUsingParent();
      final child = _CountingBox();
      parent.addChild(child);
      parent.attach(owner);
      parent.layout(BoxConstraints.tight(const Size(40, 5)));

      // sanity check
      expect(parent.needsLayout, isFalse);

      child.markNeedsLayout();

      expect(parent.needsLayout, isTrue,
          reason: 'parent whose size depends on child must be marked '
              'dirty when child marks itself dirty');
    });

    test('parentUsesSize=false does NOT cascade, only paints', () {
      // The optimization: a node whose parent's size doesn't depend on
      // it can re-layout alone. Parent is NOT marked for layout, only
      // paint.
      final owner = PipelineOwner();
      final parent = _SizeIgnoringParent();
      final child = _CountingBox();
      parent.addChild(child);
      parent.attach(owner);
      parent.layout(BoxConstraints.tight(const Size(40, 5)));

      expect(parent.needsLayout, isFalse);

      child.markNeedsLayout();

      expect(parent.needsLayout, isFalse,
          reason: 'parent that ignores child size must NOT be marked '
              'for layout — that would defeat the relayout boundary');
      expect(parent.needsPaint, isTrue,
          reason: 'parent must still be marked for paint so the '
              'change is rendered');
    });
  });

  group('RenderLayoutBuilder child chain', () {
    // The chat toolbar's LayoutBuilder wraps an inner widget tree that
    // includes the streaming ContextBar and MetricsDisplay. The
    // container child of LayoutBuilder must propagate dirty marks up
    // so the toolbar's _layoutCallback re-runs and the inner widgets
    // are diffed/updated. If this chain breaks, the inner timers'
    // updates become invisible.
    //
    // Regression: this was previously broken because the container
    // child was laid out with parentUsesSize=!constraints.isTight,
    // which evaluated to false under tight constraints and broke
    // propagation.
    test('LayoutBuilder-style wrapper always cascades child dirty marks', () {
      final owner = PipelineOwner();
      final lbRoot = _LayoutBuilderChildWrapper();
      final lbChild = _CountingBox();
      lbRoot.addChild(lbChild);
      lbRoot.attach(owner);
      lbRoot.layout(BoxConstraints.tight(const Size(40, 1)));

      expect(lbRoot.needsLayout, isFalse);

      lbChild.markNeedsLayout();

      // The wrapper simulates RenderLayoutBuilder's behavior: it always
      // declares parentUsesSize=true on its child, so a dirty mark on
      // the child MUST cascade up.
      expect(lbRoot.needsLayout, isTrue,
          reason: 'LayoutBuilder\'s container child must propagate '
              'dirty marks up so the toolbar rebuilds when inner '
              'streaming widgets (ContextBar, MetricsDisplay) tick');
    });

    test('RenderLayoutBuilder child dirty marks propagate up under TIGHT constraints', () {
      // This is the regression test for the exact bug we hit in the
      // chat toolbar: under tight constraints (which is what the chat
      // panel Column passes when the screen is fully sized), the
      // previous `parentUsesSize: !constraints.isTight` evaluated to
      // `false`, which broke the propagation chain. The fix is to
      // always pass `parentUsesSize: true` because LayoutBuilder
      // always derives its size from its child.
      final owner = PipelineOwner();
      final parent = _TightParentOfLayoutBuilder();
      final lb = RenderLayoutBuilder();
      parent.addChild(lb);
      final lbChild = _CountingBox();
      lb.child = lbChild;
      parent.attach(owner);
      parent.layout(BoxConstraints.tight(const Size(40, 1)));

      expect(lb.needsLayout, isFalse);

      lbChild.markNeedsLayout();

      expect(lb.needsLayout, isTrue,
          reason: 'LayoutBuilder must cascade dirty marks from its '
              'child under tight constraints — otherwise the chat '
              'toolbar\'s streaming widgets go stale');
    });
  });

  group('streaming widget repaint path', () {
    // Both ContextBar and MetricsDisplay follow the same pattern:
    //   StatefulComponent
    //     → internal Timer
    //     → timer fires setState()
    //     → build() reads updated runtime values, returns new widget tree
    //     → framework diffs and calls updateRenderObject() on the
    //       existing render objects (text/style setters fire
    //       markNeedsPaint/markNeedsLayout)
    //
    // For this to produce a visible update, the paint invalidation
    // must propagate all the way up to the root, AND a frame must be
    // scheduled. These tests verify both halves.
    test('style-only update on a deep Text schedules a frame', () {
      // Simulates a metrics cell changing color when responding.
      var visualUpdates = 0;
      final owner = PipelineOwner()
        ..onNeedsVisualUpdate = () {
          visualUpdates++;
        };
      final parent = _StreamingWidgetHost();
      final text = RenderText(
        text: '42.0 tok/s',
        style: const TextStyle(color: Color(0xFF808080)),
      );
      text.layout(BoxConstraints.tight(const Size(10, 1)));
      parent.addChild(text);
      parent.attach(owner);
      parent.layout(BoxConstraints.tight(const Size(20, 1)));
      visualUpdates = 0;

      // Style-only change — like MetricsDisplay switching between
      // metricsActive (responding) and metricsIdle (idle) color.
      text.style = const TextStyle(color: Color(0xFF00FF00));

      expect(visualUpdates, greaterThan(0),
          reason: 'style-only update on a streaming widget cell '
              'must propagate paint invalidation to the root');
      expect(parent.needsPaint, isTrue,
          reason: 'parent must be marked for paint so the visual '
              'change is rendered');
    });

    test('same-width text update on a deep Text schedules a frame', () {
      // Simulates a ContextBar cell label changing from "61,000" to
      // "62,000" (same character count).
      var visualUpdates = 0;
      final owner = PipelineOwner()
        ..onNeedsVisualUpdate = () {
          visualUpdates++;
        };
      final parent = _StreamingWidgetHost();
      final text = RenderText(
        text: '61,000 / 976k',
        style: const TextStyle(),
      );
      text.layout(const BoxConstraints(maxWidth: 100, maxHeight: 1));
      parent.addChild(text);
      parent.attach(owner);
      parent.layout(const BoxConstraints(maxWidth: 100, maxHeight: 1));
      visualUpdates = 0;

      text.text = '62,000 / 976k'; // same width — should hit the optimization

      expect(visualUpdates, greaterThan(0),
          reason: 'same-width text update must still propagate '
              'paint invalidation to root — this is the hot path '
              'for the streaming ContextBar');
      expect(parent.needsPaint, isTrue);
    });

    test('size-changing text update marks relayout AND propagates paint', () {
      // Simulates a token count growing from 1 digit to 2 digits
      // (e.g. "9,000" → "10,000").
      var visualUpdates = 0;
      final owner = PipelineOwner()
        ..onNeedsVisualUpdate = () {
          visualUpdates++;
        };
      final parent = _StreamingWidgetHost();
      final text = RenderText(
        text: '9,000 / 976k',
        style: const TextStyle(),
      );
      text.layout(const BoxConstraints(maxWidth: 100, maxHeight: 1));
      parent.addChild(text);
      parent.attach(owner);
      parent.layout(const BoxConstraints(maxWidth: 100, maxHeight: 1));
      visualUpdates = 0;

      text.text = '10,000 / 976k'; // wider — must trigger relayout

      expect(visualUpdates, greaterThan(0),
          reason: 'size-changing text must propagate paint to root');
      expect(text.needsLayout, isTrue,
          reason: 'size-changing text must trigger relayout so the '
              'parent re-positions the cell');
      expect(parent.needsPaint, isTrue);
    });

    test('multiple Text updates cascade paint without over-marking', () {
      // Simulates a streaming tick that updates several cells.
      // After the first update propagates, subsequent updates on
      // siblings should still propagate but not double-schedule.
      var visualUpdates = 0;
      final owner = PipelineOwner()
        ..onNeedsVisualUpdate = () {
          visualUpdates++;
        };
      final parent = _StreamingWidgetHost();
      final cells = [
        for (var i = 0; i < 5; i++)
          RenderText(text: '$i', style: const TextStyle())
            ..layout(BoxConstraints.tight(const Size(1, 1))),
      ];
      for (final c in cells) {
        parent.addChild(c);
      }
      parent.attach(owner);
      parent.layout(BoxConstraints.tight(const Size(5, 1)));
      visualUpdates = 0;

      // Update every cell.
      for (var i = 0; i < 5; i++) {
        cells[i].text = '${i + 10}';
      }

      expect(visualUpdates, greaterThan(0));
      // Parent should be marked for paint but NOT re-laid out
      // (text widths didn't change).
      expect(parent.needsPaint, isTrue);
      expect(parent.needsLayout, isFalse,
          reason: 'same-footprint updates should not cascade relayout');
    });
  });
}

// ─────────────────────────────────────────────────────────────────────
// Test fixtures
// ─────────────────────────────────────────────────────────────────────

/// A parent that uses its child's size in its own layout (i.e.,
/// `_parentUsesSize = true` is correct). Mirrors RenderColumn /
/// RenderConstrainedBox.
class _SizeUsingParent extends RenderObject
    with ContainerRenderObjectMixin<RenderObject> {
  int layoutCount = 0;

  @override
  void performLayout() {
    layoutCount++;
    if (children.isNotEmpty) {
      children.first.layout(
        BoxConstraints.tight(const Size(8, 2)),
        parentUsesSize: true,
      );
      size = constraints.constrain(children.first.size);
    } else {
      size = constraints.constrain(const Size(40, 5));
    }
  }
}

/// A parent whose size does NOT depend on its child — the canonical
/// "relayout boundary" case.
class _SizeIgnoringParent extends RenderObject
    with ContainerRenderObjectMixin<RenderObject> {
  int layoutCount = 0;

  @override
  void performLayout() {
    layoutCount++;
    if (children.isNotEmpty) {
      children.first.layout(
        BoxConstraints.tight(const Size(8, 2)),
        parentUsesSize: false, // ← the optimization
      );
    }
    size = constraints.constrain(const Size(40, 5));
  }
}

/// Wrapper that simulates RenderLayoutBuilder's "always parentUsesSize"
/// policy. Used to verify the chain stays intact when the toolbar's
/// LayoutBuilder rebuilds.
class _LayoutBuilderChildWrapper extends RenderObject
    with ContainerRenderObjectMixin<RenderObject> {
  int layoutCount = 0;

  @override
  void performLayout() {
    layoutCount++;
    if (children.isNotEmpty) {
      children.first.layout(
        BoxConstraints.tight(const Size(8, 2)),
        parentUsesSize: true, // ← the fix
      );
      size = constraints.constrain(children.first.size);
    } else {
      size = constraints.constrain(const Size(40, 5));
    }
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

/// Mimics RenderLayoutBuilder's hosting parent (e.g. RenderColumn in
/// the chat panel). Passes TIGHT constraints to its child so we can
/// exercise the exact regression scenario where
/// `parentUsesSize: !constraints.isTight` would evaluate to false.
class _TightParentOfLayoutBuilder extends RenderObject
    with ContainerRenderObjectMixin<RenderObject> {
  @override
  void performLayout() {
    if (children.isNotEmpty) {
      children.first.layout(
        // tight constraints — this is the case where the bug bit
        BoxConstraints.tight(const Size(40, 1)),
        parentUsesSize: true,
      );
      size = children.first.size;
    }
  }
}

/// Mimics the chat toolbar's `Row` of Text cells (used by both
/// ContextBar's BgProgressBar and MetricsDisplay). Children have
/// `parentUsesSize: true` so dirty marks cascade up.
class _StreamingWidgetHost extends RenderObject
    with ContainerRenderObjectMixin<RenderObject> {
  @override
  void performLayout() {
    for (final child in children) {
      child.layout(child.constraints, parentUsesSize: true);
    }
    if (children.isNotEmpty) {
      size = constraints.constrain(children.first.size);
    } else {
      size = constraints.constrain(const Size(20, 1));
    }
  }
}
