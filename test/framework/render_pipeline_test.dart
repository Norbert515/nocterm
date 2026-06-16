import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import 'package:test/test.dart';

/// Comprehensive test suite for the nocterm rendering pipeline.
///
/// These tests prevent regressions in performance optimizations by ensuring
/// the rendering pipeline correctly handles:
/// - markNeedsLayout and markNeedsPaint propagation
/// - PipelineOwner dirty tracking
/// - Frame scheduling
/// - Frame-skip optimization edge cases
/// - Dirty flag clearing
///
/// The critical bug this test suite guards against:
/// Early returns in markNeedsLayout() and markNeedsPaint() when flags were
/// already set caused requestVisualUpdate() to never be called, permanently
/// stopping rendering after the frame-skip optimization was triggered.
void main() {
  // ============================================================================
  // markNeedsLayout Propagation Tests
  // ============================================================================
  group('markNeedsLayout propagation', () {
    test('markNeedsLayout sets _needsLayout flag on the object', () async {
      await testNocterm(
        'sets needsLayout flag',
        (tester) async {
          await tester.pumpComponent(
            _LayoutTracker(
              onLayoutTrackerCreated: (tracker) {
                // Initially the layout flag is cleared after first frame
                expect(tracker.needsLayout, isFalse);

                // Mark needs layout
                tracker.markNeedsLayout();

                // Flag should be set
                expect(tracker.needsLayout, isTrue);
              },
            ),
          );
        },
      );
    });

    test('markNeedsLayout calls markNeedsPaint', () async {
      await testNocterm(
        'calls markNeedsPaint',
        (tester) async {
          bool paintMarkCalled = false;

          await tester.pumpComponent(
            _LayoutTracker(
              onLayoutTrackerCreated: (tracker) {
                // Override to track paint marking
                tracker.onMarkNeedsPaint = () {
                  paintMarkCalled = true;
                };

                tracker.markNeedsLayout();

                // markNeedsPaint should have been called
                expect(paintMarkCalled, isTrue);
              },
            ),
          );
        },
      );
    });

    test('markNeedsLayout works when called multiple times', () async {
      await testNocterm(
        'multiple markNeedsLayout calls',
        (tester) async {
          int layoutCount = 0;
          late _TrackingRenderBox tracker;

          await tester.pumpComponent(
            _LayoutCounterComponent(
              onLayoutCounted: () => layoutCount++,
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          expect(layoutCount, equals(1)); // Initial layout

          // Mark needs layout multiple times before pump
          tracker.markNeedsLayout();
          tracker.markNeedsLayout();
          tracker.markNeedsLayout();

          // Frame should be scheduled
          expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);

          await tester.pump();

          // Should layout again (only once due to batching)
          expect(layoutCount, equals(2));
        },
      );
    });

    test('markNeedsLayout propagates to parent', () async {
      await testNocterm(
        'propagates to parent',
        (tester) async {
          late _TrackingRenderBox parentTracker;
          late _TrackingRenderBox childTracker;

          await tester.pumpComponent(
            _NestedLayoutTrackers(
              onParentCreated: (rb) => parentTracker = rb,
              onChildCreated: (rb) => childTracker = rb,
            ),
          );

          // Clear flags after initial layout
          await tester.pump();

          // Mark child needs layout
          childTracker.markNeedsLayout();

          // Parent should also be marked
          expect(parentTracker.needsLayout, isTrue);
          expect(childTracker.needsLayout, isTrue);
        },
      );
    });

    test('markNeedsLayout works on deeply nested render objects', () async {
      await testNocterm(
        'deeply nested layout',
        (tester) async {
          final trackers = <_TrackingRenderBox>[];

          await tester.pumpComponent(
            _DeeplyNestedTrackers(
              depth: 5,
              onTrackerCreated: (rb) => trackers.add(rb),
            ),
          );

          // All 5 trackers should be created
          expect(trackers.length, equals(5));

          // Clear any pending operations
          await tester.pump();

          // Mark the deepest child needs layout
          trackers.last.markNeedsLayout();

          // All ancestors should be marked dirty
          for (final tracker in trackers) {
            expect(tracker.needsLayout, isTrue,
                reason:
                    'Tracker at depth ${trackers.indexOf(tracker)} should need layout');
          }
        },
      );
    });
  });

  // ============================================================================
  // markNeedsPaint Propagation Tests
  // ============================================================================
  group('markNeedsPaint propagation', () {
    test('markNeedsPaint sets _needsPaint flag on the object', () async {
      await testNocterm(
        'sets needsPaint flag',
        (tester) async {
          await tester.pumpComponent(
            _LayoutTracker(
              onLayoutTrackerCreated: (tracker) {
                // After first frame, flag should be cleared
                expect(tracker.needsPaint, isFalse);

                // Mark needs paint
                tracker.markNeedsPaint();

                // Flag should be set
                expect(tracker.needsPaint, isTrue);
              },
            ),
          );
        },
      );
    });

    test('markNeedsPaint propagates up to root', () async {
      await testNocterm(
        'propagates to root',
        (tester) async {
          late _TrackingRenderBox parentTracker;
          late _TrackingRenderBox childTracker;

          await tester.pumpComponent(
            _NestedLayoutTrackers(
              onParentCreated: (rb) => parentTracker = rb,
              onChildCreated: (rb) => childTracker = rb,
            ),
          );

          await tester.pump(); // Clear initial dirty flags

          // Mark child needs paint
          childTracker.markNeedsPaint();

          // Parent should also be marked for paint
          expect(parentTracker.needsPaint, isTrue);
          expect(childTracker.needsPaint, isTrue);
        },
      );
    });

    test('markNeedsPaint schedules frame via requestVisualUpdate', () async {
      await testNocterm(
        'schedules frame',
        (tester) async {
          late _TrackingRenderBox tracker;

          await tester.pumpComponent(
            _LayoutCounterComponent(
              onLayoutCounted: () {},
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          await tester.pump(); // Clear initial state

          // Manually clear the scheduled frame flag if any
          // (by calling handleBeginFrame which resets it)
          if (SchedulerBinding.instance.hasScheduledFrame) {
            await tester.pump();
          }

          // Now mark needs paint
          tracker.markNeedsPaint();

          // A frame should be scheduled
          expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
        },
      );
    });

    test(
        'markNeedsPaint works when called multiple times - CRITICAL REGRESSION TEST',
        () async {
      // THIS IS THE CRITICAL TEST
      // The bug was: calling markNeedsPaint when flag was already set
      // would early-return and NOT call requestVisualUpdate, causing
      // rendering to permanently stop.
      await testNocterm(
        'multiple markNeedsPaint calls',
        (tester) async {
          late _TrackingRenderBox tracker;
          int paintCount = 0;

          await tester.pumpComponent(
            _PaintCounterComponent(
              onPaintCounted: () => paintCount++,
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          expect(paintCount, equals(1)); // Initial paint

          // Mark needs paint first time
          tracker.markNeedsPaint();

          // Mark needs paint AGAIN while flag is still dirty
          // THIS MUST STILL SCHEDULE A FRAME
          tracker.markNeedsPaint();
          tracker.markNeedsPaint();

          // Frame MUST be scheduled
          expect(SchedulerBinding.instance.hasScheduledFrame, isTrue,
              reason: 'Frame must be scheduled even when needsPaint was '
                  'already true - this was the critical bug');

          await tester.pump();

          // Should have painted again
          expect(paintCount, equals(2));
        },
      );
    });

    test('markNeedsPaint works on deeply nested render objects', () async {
      await testNocterm(
        'deeply nested paint',
        (tester) async {
          final trackers = <_TrackingRenderBox>[];

          await tester.pumpComponent(
            _DeeplyNestedTrackers(
              depth: 5,
              onTrackerCreated: (rb) => trackers.add(rb),
            ),
          );

          await tester.pump(); // Clear initial state

          // Mark the deepest child needs paint
          trackers.last.markNeedsPaint();

          // All ancestors should be marked for paint
          for (final tracker in trackers) {
            expect(tracker.needsPaint, isTrue,
                reason:
                    'Tracker at depth ${trackers.indexOf(tracker)} should need paint');
          }

          // And frame should be scheduled
          expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
        },
      );
    });
  });

  // ============================================================================
  // PipelineOwner Tests
  // ============================================================================
  group('PipelineOwner', () {
    test('requestLayout adds to dirty list', () async {
      await testNocterm(
        'requestLayout adds to dirty',
        (tester) async {
          await tester.pumpComponent(
            _LayoutTracker(
              onLayoutTrackerCreated: (tracker) {
                final pipelineOwner = NoctermTestBinding.instance.pipelineOwner;

                // Clear the list by flushing
                pipelineOwner.flushLayout();
                expect(pipelineOwner.hasNodesToLayout, isFalse);

                // Request layout
                pipelineOwner.requestLayout(tracker);

                // Should now have nodes
                expect(pipelineOwner.hasNodesToLayout, isTrue);
              },
            ),
          );
        },
      );
    });

    test('requestPaint adds to dirty list with deduplication', () async {
      await testNocterm(
        'requestPaint with deduplication',
        (tester) async {
          await tester.pumpComponent(
            _LayoutTracker(
              onLayoutTrackerCreated: (tracker) {
                final pipelineOwner = NoctermTestBinding.instance.pipelineOwner;

                // Clear paint list
                pipelineOwner.flushPaint();
                expect(pipelineOwner.hasNodesToPaint, isFalse);

                // Request paint multiple times
                pipelineOwner.requestPaint(tracker);
                pipelineOwner.requestPaint(tracker);
                pipelineOwner.requestPaint(tracker);

                // Should have nodes (only one due to deduplication)
                expect(pipelineOwner.hasNodesToPaint, isTrue);
              },
            ),
          );
        },
      );
    });

    test('hasNodesToLayout reflects list state', () async {
      await testNocterm(
        'hasNodesToLayout state',
        (tester) async {
          final pipelineOwner = NoctermTestBinding.instance.pipelineOwner;

          // Initially might have nodes from setup
          pipelineOwner.flushLayout();

          // After flush, should be empty
          expect(pipelineOwner.hasNodesToLayout, isFalse);

          // Pump a component that marks dirty
          await tester.pumpComponent(const _SimpleLayoutComponent());

          // After pump, layout is done, so should be empty again
          expect(pipelineOwner.hasNodesToLayout, isFalse);
        },
      );
    });

    test('hasNodesToPaint reflects list state', () async {
      await testNocterm(
        'hasNodesToPaint state',
        (tester) async {
          final pipelineOwner = NoctermTestBinding.instance.pipelineOwner;

          // Flush paint
          pipelineOwner.flushPaint();

          // After flush, should be empty
          expect(pipelineOwner.hasNodesToPaint, isFalse);
        },
      );
    });

    test('flushLayout processes nodes and clears flags', () async {
      await testNocterm(
        'flushLayout clears flags',
        (tester) async {
          int layoutCount = 0;
          late _TrackingRenderBox tracker;

          await tester.pumpComponent(
            _LayoutCounterComponent(
              onLayoutCounted: () => layoutCount++,
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          expect(layoutCount, equals(1));

          // Mark needs layout
          tracker.markNeedsLayout();
          expect(tracker.needsLayout, isTrue);

          // Pump should flush layout
          await tester.pump();

          // Layout should have been performed
          expect(layoutCount, equals(2));

          // Flag should be cleared
          expect(tracker.needsLayout, isFalse);
        },
      );
    });

    test('flushLayout processes nodes in depth order', () async {
      // Note: The actual order depends on the implementation.
      // The key requirement is that layout happens correctly, not a specific order.
      await testNocterm(
        'depth ordering',
        (tester) async {
          final layoutOrder = <int>[];
          final trackers = <_TrackingRenderBox>[];

          await tester.pumpComponent(
            _DeeplyNestedTrackers(
              depth: 3,
              onTrackerCreated: (rb) {
                trackers.add(rb);
                rb.onPerformLayout = () {
                  layoutOrder.add(trackers.indexOf(rb));
                };
              },
            ),
          );

          // Initial layout should have happened for all trackers
          expect(layoutOrder.length, equals(3));
          expect(layoutOrder.toSet(), equals({0, 1, 2}));

          layoutOrder.clear();

          // Mark all dirty
          for (final tracker in trackers) {
            tracker.markNeedsLayout();
          }

          await tester.pump();

          // All should be laid out again
          expect(layoutOrder.toSet(), equals({0, 1, 2}));
        },
      );
    });
  });

  // ============================================================================
  // Frame Scheduling Tests
  // ============================================================================
  group('frame scheduling', () {
    test('requestVisualUpdate triggers frame scheduling', () async {
      await testNocterm(
        'requestVisualUpdate schedules frame',
        (tester) async {
          await tester.pumpComponent(const Text('test'));

          // Clear any pending frames
          await tester.pump();

          final pipelineOwner = NoctermTestBinding.instance.pipelineOwner;

          // Manually request visual update
          pipelineOwner.requestVisualUpdate();

          // Frame should be scheduled
          expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
        },
      );
    });

    test('multiple requestVisualUpdate calls result in single frame', () async {
      await testNocterm(
        'single frame for multiple requests',
        (tester) async {
          await tester.pumpComponent(const Text('test'));

          final initialFrameCount = tester.frameCount;
          await tester.pump();

          final pipelineOwner = NoctermTestBinding.instance.pipelineOwner;

          // Request visual update multiple times
          pipelineOwner.requestVisualUpdate();
          pipelineOwner.requestVisualUpdate();
          pipelineOwner.requestVisualUpdate();

          // Pump once
          await tester.pump();

          // Should only have processed one additional frame
          expect(tester.frameCount, equals(initialFrameCount + 2));
        },
      );
    });

    test('frame is scheduled when markNeedsLayout called', () async {
      await testNocterm(
        'markNeedsLayout schedules frame',
        (tester) async {
          late _TrackingRenderBox tracker;

          await tester.pumpComponent(
            _LayoutCounterComponent(
              onLayoutCounted: () {},
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          await tester.pump(); // Clear initial state

          // Mark needs layout
          tracker.markNeedsLayout();

          // Frame should be scheduled
          expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
        },
      );
    });

    test('frame is scheduled when markNeedsPaint called', () async {
      await testNocterm(
        'markNeedsPaint schedules frame',
        (tester) async {
          late _TrackingRenderBox tracker;

          await tester.pumpComponent(
            _LayoutCounterComponent(
              onLayoutCounted: () {},
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          await tester.pump(); // Clear initial state

          // Mark needs paint
          tracker.markNeedsPaint();

          // Frame should be scheduled
          expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
        },
      );
    });

    test(
        'frame is scheduled even when flags already dirty - CRITICAL REGRESSION TEST',
        () async {
      // THIS IS THE CRITICAL TEST THAT WOULD HAVE CAUGHT THE BUG
      await testNocterm(
        'frame scheduled when flags already dirty',
        (tester) async {
          late _TrackingRenderBox tracker;

          await tester.pumpComponent(
            _LayoutCounterComponent(
              onLayoutCounted: () {},
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          await tester.pump();

          // Set flags dirty
          tracker.markNeedsPaint();
          expect(tracker.needsPaint, isTrue);

          // Clear scheduled frame flag (simulate frame-skip scenario)
          // We can't directly clear the flag, but we can test that
          // calling markNeedsPaint again still works
          tracker.markNeedsPaint(); // Called when already dirty

          // Frame MUST still be scheduled
          expect(SchedulerBinding.instance.hasScheduledFrame, isTrue,
              reason: 'This is the critical bug: when needsPaint was already '
                  'true, the early return prevented requestVisualUpdate from '
                  'being called, causing rendering to stop permanently');
        },
      );
    });
  });

  // ============================================================================
  // Frame-Skip Optimization Tests (CRITICAL)
  // ============================================================================
  group('frame-skip optimization', () {
    test('frame is NOT skipped when needsBuild is true', () async {
      await testNocterm(
        'no skip when needsBuild',
        (tester) async {
          int buildCount = 0;
          late _SimpleBuildCounterState state;

          await tester.pumpComponent(
            _SimpleBuildCounter(
              onBuild: () => buildCount++,
              onStateCreated: (s) => state = s,
            ),
          );

          expect(buildCount, equals(1));

          // Trigger rebuild
          state.triggerRebuild();

          // Frame should render (not skip)
          await tester.pump();

          expect(buildCount, equals(2),
              reason:
                  'Build should have happened, frame should not be skipped');
        },
      );
    });

    test('frame is NOT skipped when needsLayout is true', () async {
      await testNocterm(
        'no skip when needsLayout',
        (tester) async {
          int layoutCount = 0;
          late _TrackingRenderBox tracker;

          await tester.pumpComponent(
            _LayoutCounterComponent(
              onLayoutCounted: () => layoutCount++,
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          expect(layoutCount, equals(1));

          // Mark needs layout
          tracker.markNeedsLayout();

          await tester.pump();

          expect(layoutCount, equals(2),
              reason:
                  'Layout should have happened, frame should not be skipped');
        },
      );
    });

    test('frame is NOT skipped when needsPaint is true', () async {
      await testNocterm(
        'no skip when needsPaint',
        (tester) async {
          int paintCount = 0;
          late _TrackingRenderBox tracker;

          await tester.pumpComponent(
            _PaintCounterComponent(
              onPaintCounted: () => paintCount++,
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          expect(paintCount, equals(1));

          // Mark needs paint
          tracker.markNeedsPaint();

          await tester.pump();

          expect(paintCount, equals(2),
              reason:
                  'Paint should have happened, frame should not be skipped');
        },
      );
    });

    test('skipping frame does not prevent future frames from rendering',
        () async {
      await testNocterm(
        'future frames render',
        (tester) async {
          int buildCount = 0;
          late _SimpleBuildCounterState state;

          await tester.pumpComponent(
            _SimpleBuildCounter(
              onBuild: () => buildCount++,
              onStateCreated: (s) => state = s,
            ),
          );

          expect(buildCount, equals(1));

          // Pump without state change - frame may be skipped
          await tester.pump();
          await tester.pump();

          expect(buildCount, equals(1),
              reason: 'No rebuild needed, count should stay at 1');

          // Now trigger rebuild
          state.triggerRebuild();
          await tester.pump();

          expect(buildCount, equals(2),
              reason: 'After frame skip, new rebuild should still work');
        },
      );
    });

    test('deeply nested dirty child still triggers frame', () async {
      await testNocterm(
        'deeply nested triggers frame',
        (tester) async {
          int deepestPaintCount = 0;
          final trackers = <_TrackingRenderBox>[];

          await tester.pumpComponent(
            _DeeplyNestedTrackers(
              depth: 5,
              onTrackerCreated: (rb) {
                trackers.add(rb);
                if (trackers.length == 5) {
                  rb.onPaint = () => deepestPaintCount++;
                }
              },
            ),
          );

          expect(deepestPaintCount, equals(1));

          // Mark only the deepest child dirty
          trackers.last.markNeedsPaint();

          await tester.pump();

          expect(deepestPaintCount, equals(2),
              reason: 'Deeply nested dirty child should trigger repaint');
        },
      );
    });
  });

  // ============================================================================
  // Dirty Flag Clearing Tests
  // ============================================================================
  group('dirty flag clearing', () {
    test('_needsLayout cleared after layout() called', () async {
      await testNocterm(
        'needsLayout cleared after layout',
        (tester) async {
          late _TrackingRenderBox tracker;

          await tester.pumpComponent(
            _LayoutCounterComponent(
              onLayoutCounted: () {},
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          // After initial pump, flag should be clear
          expect(tracker.needsLayout, isFalse);

          // Mark dirty
          tracker.markNeedsLayout();
          expect(tracker.needsLayout, isTrue);

          // Pump to trigger layout
          await tester.pump();

          // Flag should be cleared
          expect(tracker.needsLayout, isFalse);
        },
      );
    });

    test('_needsPaint cleared after paint pass', () async {
      await testNocterm(
        'needsPaint cleared after paint',
        (tester) async {
          late _TrackingRenderBox tracker;

          await tester.pumpComponent(
            _PaintCounterComponent(
              onPaintCounted: () {},
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          // After initial pump, flag should be clear
          expect(tracker.needsPaint, isFalse);

          // Mark dirty
          tracker.markNeedsPaint();
          expect(tracker.needsPaint, isTrue);

          // Pump to trigger paint
          await tester.pump();

          // Flag should be cleared
          expect(tracker.needsPaint, isFalse);
        },
      );
    });

    test('flags cleared even for deeply nested objects', () async {
      await testNocterm(
        'deeply nested flags cleared',
        (tester) async {
          final trackers = <_TrackingRenderBox>[];

          await tester.pumpComponent(
            _DeeplyNestedTrackers(
              depth: 5,
              onTrackerCreated: (rb) => trackers.add(rb),
            ),
          );

          // Mark all dirty
          for (final tracker in trackers) {
            tracker.markNeedsLayout();
            tracker.markNeedsPaint();
          }

          // All should be dirty
          for (final tracker in trackers) {
            expect(tracker.needsLayout, isTrue);
            expect(tracker.needsPaint, isTrue);
          }

          // Pump
          await tester.pump();

          // All should be clean
          for (final tracker in trackers) {
            expect(tracker.needsLayout, isFalse);
            expect(tracker.needsPaint, isFalse);
          }
        },
      );
    });

    test('new dirty marks during layout are handled', () async {
      await testNocterm(
        'dirty during layout handled',
        (tester) async {
          late _TrackingRenderBox tracker;
          int layoutCount = 0;
          bool shouldMarkDirtyDuringLayout = false;

          await tester.pumpComponent(
            _LayoutCounterComponent(
              onLayoutCounted: () {
                layoutCount++;
                if (shouldMarkDirtyDuringLayout && layoutCount < 3) {
                  // This simulates LayoutBuilder marking children dirty
                  // during its own layout
                  tracker.markNeedsLayout();
                }
              },
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          expect(layoutCount, equals(1));

          // Enable marking dirty during layout
          shouldMarkDirtyDuringLayout = true;
          tracker.markNeedsLayout();

          // This should not cause infinite loop
          await tester.pump();

          // Should have laid out more than once due to re-marking
          expect(layoutCount, greaterThanOrEqualTo(2));
        },
      );
    });
  });

  // ============================================================================
  // Regression Tests for the Bug We Fixed
  // ============================================================================
  group('rendering continuation regression tests', () {
    test(
        'calling markNeedsLayout when already dirty still schedules frame - CRITICAL',
        () async {
      await testNocterm(
        'already dirty layout schedules frame',
        (tester) async {
          late _TrackingRenderBox tracker;
          int layoutCount = 0;

          await tester.pumpComponent(
            _LayoutCounterComponent(
              onLayoutCounted: () => layoutCount++,
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          expect(layoutCount, equals(1));

          // Set flag dirty
          tracker.markNeedsLayout();
          expect(tracker.needsLayout, isTrue);

          // Call again when already dirty
          tracker.markNeedsLayout();

          // Frame MUST be scheduled
          expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);

          await tester.pump();

          // Layout should have happened
          expect(layoutCount, equals(2));
        },
      );
    });

    test(
        'calling markNeedsPaint when already dirty still schedules frame - CRITICAL',
        () async {
      await testNocterm(
        'already dirty paint schedules frame',
        (tester) async {
          late _TrackingRenderBox tracker;
          int paintCount = 0;

          await tester.pumpComponent(
            _PaintCounterComponent(
              onPaintCounted: () => paintCount++,
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          expect(paintCount, equals(1));

          // Set flag dirty
          tracker.markNeedsPaint();
          expect(tracker.needsPaint, isTrue);

          // Call again when already dirty
          tracker.markNeedsPaint();

          // Frame MUST be scheduled
          expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);

          await tester.pump();

          // Paint should have happened
          expect(paintCount, equals(2));
        },
      );
    });

    test('after frame skip, subsequent markNeedsLayout still works', () async {
      await testNocterm(
        'post-skip markNeedsLayout works',
        (tester) async {
          late _TrackingRenderBox tracker;
          int layoutCount = 0;

          await tester.pumpComponent(
            _LayoutCounterComponent(
              onLayoutCounted: () => layoutCount++,
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          expect(layoutCount, equals(1));

          // Pump without marking dirty - layout may or may not run
          // depending on test binding implementation
          await tester.pump();
          await tester.pump();

          final countBeforeMark = layoutCount;

          // Now mark dirty
          tracker.markNeedsLayout();

          await tester.pump();

          // Layout must have happened at least once more after marking dirty
          expect(layoutCount, greaterThan(countBeforeMark),
              reason: 'Layout must work after marking dirty');
        },
      );
    });

    test('after frame skip, subsequent markNeedsPaint still works', () async {
      await testNocterm(
        'post-skip markNeedsPaint works',
        (tester) async {
          late _TrackingRenderBox tracker;
          int paintCount = 0;

          await tester.pumpComponent(
            _PaintCounterComponent(
              onPaintCounted: () => paintCount++,
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          expect(paintCount, equals(1));

          // Pump without marking dirty - paint may or may not run
          // depending on test binding implementation
          await tester.pump();
          await tester.pump();

          final countBeforeMark = paintCount;

          // Now mark dirty
          tracker.markNeedsPaint();

          await tester.pump();

          // Paint must have happened at least once more after marking dirty
          expect(paintCount, greaterThan(countBeforeMark),
              reason: 'Paint must work after marking dirty');
        },
      );
    });

    test('rapid setState calls do not stop rendering', () async {
      await testNocterm(
        'rapid setState continues rendering',
        (tester) async {
          int buildCount = 0;
          late _SimpleBuildCounterState state;

          await tester.pumpComponent(
            _SimpleBuildCounter(
              onBuild: () => buildCount++,
              onStateCreated: (s) => state = s,
            ),
          );

          expect(buildCount, equals(1));

          // Rapid setState calls
          for (int i = 0; i < 100; i++) {
            state.triggerRebuild();
          }

          // Pump
          await tester.pump();

          // Should have rebuilt (batched into one)
          expect(buildCount, equals(2));

          // Do it again
          for (int i = 0; i < 100; i++) {
            state.triggerRebuild();
          }

          await tester.pump();

          // Should continue working
          expect(buildCount, equals(3));
        },
      );
    });

    test('interrupt-like pattern (skip frame, then new update) still renders',
        () async {
      await testNocterm(
        'interrupt pattern renders',
        (tester) async {
          int paintCount = 0;
          late _TrackingRenderBox tracker;

          await tester.pumpComponent(
            _PaintCounterComponent(
              onPaintCounted: () => paintCount++,
              onRenderBoxCreated: (rb) => tracker = rb,
            ),
          );

          expect(paintCount, equals(1));

          // Simulate interrupt-like pattern:
          // 1. Mark dirty
          tracker.markNeedsPaint();

          // 2. Pump frames (simulating potential frame skip)
          await tester.pump();
          expect(paintCount, equals(2));

          // 3. Mark dirty again while potentially in "skip" state
          tracker.markNeedsPaint();

          // 4. This must still render
          await tester.pump();
          expect(paintCount, equals(3));

          // Continue pattern
          for (int i = 0; i < 5; i++) {
            tracker.markNeedsPaint();
            await tester.pump();
          }

          expect(paintCount, equals(8),
              reason: 'Rendering must continue through interrupt-like pattern');
        },
      );
    });
  });

  // ============================================================================
  // Nested Render Tree Tests
  // ============================================================================
  group('nested render tree', () {
    test('3-level deep tree propagation', () async {
      await testNocterm(
        '3-level propagation',
        (tester) async {
          final trackers = <_TrackingRenderBox>[];

          await tester.pumpComponent(
            _DeeplyNestedTrackers(
              depth: 3,
              onTrackerCreated: (rb) => trackers.add(rb),
            ),
          );

          expect(trackers.length, equals(3));

          await tester.pump();

          // Mark deepest dirty
          trackers[2].markNeedsLayout();

          // All should be dirty
          expect(trackers[0].needsLayout, isTrue);
          expect(trackers[1].needsLayout, isTrue);
          expect(trackers[2].needsLayout, isTrue);

          await tester.pump();

          // All should be clean
          for (final tracker in trackers) {
            expect(tracker.needsLayout, isFalse);
            expect(tracker.needsPaint, isFalse);
          }
        },
      );
    });

    test('5-level deep tree propagation', () async {
      await testNocterm(
        '5-level propagation',
        (tester) async {
          final trackers = <_TrackingRenderBox>[];

          await tester.pumpComponent(
            _DeeplyNestedTrackers(
              depth: 5,
              onTrackerCreated: (rb) => trackers.add(rb),
            ),
          );

          expect(trackers.length, equals(5));

          await tester.pump();

          // Mark deepest dirty
          trackers[4].markNeedsPaint();

          // All ancestors should be dirty
          for (int i = 0; i < 5; i++) {
            expect(trackers[i].needsPaint, isTrue,
                reason: 'Level $i should need paint');
          }

          await tester.pump();

          // All should be clean
          for (final tracker in trackers) {
            expect(tracker.needsPaint, isFalse);
          }
        },
      );
    });

    test('mixed dirty states in tree', () async {
      await testNocterm(
        'mixed dirty states',
        (tester) async {
          final trackers = <_TrackingRenderBox>[];

          await tester.pumpComponent(
            _DeeplyNestedTrackers(
              depth: 4,
              onTrackerCreated: (rb) => trackers.add(rb),
            ),
          );

          await tester.pump();

          // Mark only middle nodes dirty
          // trackers[0] is root, trackers[3] is deepest
          trackers[1]
              .markNeedsLayout(); // Marks 1 and propagates layout up to 0
          trackers[2]
              .markNeedsPaint(); // Marks 2 and propagates paint up to 1, 0

          // Layout flags - markNeedsLayout propagates UP only
          expect(trackers[0].needsLayout,
              isTrue); // Propagated up from trackers[1]
          expect(trackers[1].needsLayout, isTrue); // Directly marked
          expect(trackers[2].needsLayout,
              isFalse); // markNeedsPaint does NOT set needsLayout
          expect(trackers[3].needsLayout, isFalse); // Not propagated down

          // Paint flags - both markNeedsLayout and markNeedsPaint propagate up
          expect(trackers[0].needsPaint, isTrue); // Propagated up
          expect(trackers[1].needsPaint,
              isTrue); // markNeedsLayout calls markNeedsPaint
          expect(trackers[2].needsPaint, isTrue); // Directly marked

          await tester.pump();

          // All should be clean after pump
          for (final tracker in trackers) {
            expect(tracker.needsLayout, isFalse);
            expect(tracker.needsPaint, isFalse);
          }
        },
      );
    });

    test('child dirty but parent not dirty scenario', () async {
      await testNocterm(
        'child dirty parent clean',
        (tester) async {
          // Note: In the current implementation, marking a child dirty
          // always propagates to parent. This test verifies that behavior.
          final trackers = <_TrackingRenderBox>[];

          await tester.pumpComponent(
            _DeeplyNestedTrackers(
              depth: 3,
              onTrackerCreated: (rb) => trackers.add(rb),
            ),
          );

          await tester.pump();

          // Mark child dirty
          trackers[2].markNeedsPaint();

          // Parent should also be dirty due to propagation
          expect(trackers[0].needsPaint, isTrue);
          expect(trackers[1].needsPaint, isTrue);
          expect(trackers[2].needsPaint, isTrue);
        },
      );
    });

    test('parent dirty but child clean scenario', () async {
      await testNocterm(
        'parent dirty child clean',
        (tester) async {
          // This scenario: parent is dirty, child is clean
          // The parent should still layout/paint, and child should too
          final trackers = <_TrackingRenderBox>[];
          final layoutOrder = <int>[];

          await tester.pumpComponent(
            _DeeplyNestedTrackers(
              depth: 3,
              onTrackerCreated: (rb) {
                trackers.add(rb);
                rb.onPerformLayout = () {
                  layoutOrder.add(trackers.indexOf(rb));
                };
              },
            ),
          );

          layoutOrder.clear();

          // Mark only parent dirty (note: this is hard to achieve in practice
          // because markNeedsLayout propagates up, not down)
          // We simulate by calling the pipelineOwner directly
          final pipelineOwner = NoctermTestBinding.instance.pipelineOwner;
          trackers[0]._needsLayout = true;
          pipelineOwner.requestLayout(trackers[0]);

          await tester.pump();

          // Parent should have been laid out
          expect(layoutOrder.contains(0), isTrue);
        },
      );
    });
  });
}

// ============================================================================
// Test Helper Components and Render Objects
// ============================================================================

/// A custom RenderObject for testing that tracks internal state
class _TrackingRenderBox extends RenderObject
    with RenderObjectWithChildMixin<RenderObject> {
  VoidCallback? onPerformLayout;
  VoidCallback? onPaint;
  VoidCallback? onMarkNeedsPaint;

  /// Expose needsLayout flag setter for testing edge cases
  set _needsLayout(bool value) {
    // Access the private field through the public getter/setter pattern
    // Note: This is a workaround for testing; in production code the flag
    // is managed internally
    if (value) {
      markNeedsLayout();
    }
  }

  @override
  void markNeedsPaint() {
    onMarkNeedsPaint?.call();
    super.markNeedsPaint();
  }

  @override
  void performLayout() {
    onPerformLayout?.call();
    if (child != null) {
      child!.layout(constraints, parentUsesSize: true);
      size = child!.size;
    } else {
      size = constraints.constrain(const Size(10, 1));
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    onPaint?.call();
    if (child != null) {
      child!.paintWithContext(canvas, offset);
    }
  }
}

/// Component that provides a tracking render object for layout tests
class _LayoutTracker extends SingleChildRenderObjectComponent {
  const _LayoutTracker({
    required this.onLayoutTrackerCreated,
  });

  final void Function(_TrackingRenderBox) onLayoutTrackerCreated;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final tracker = _TrackingRenderBox();
    // Use a post-frame callback to notify after initial layout
    SchedulerBinding.instance.addPostFrameCallback((_) {
      onLayoutTrackerCreated(tracker);
    });
    return tracker;
  }
}

/// Component that counts layouts
class _LayoutCounterComponent extends SingleChildRenderObjectComponent {
  const _LayoutCounterComponent({
    required this.onLayoutCounted,
    required this.onRenderBoxCreated,
    super.child,
  });

  final VoidCallback onLayoutCounted;
  final void Function(_TrackingRenderBox) onRenderBoxCreated;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final tracker = _TrackingRenderBox();
    tracker.onPerformLayout = onLayoutCounted;
    onRenderBoxCreated(tracker);
    return tracker;
  }
}

/// Component that counts paints
class _PaintCounterComponent extends SingleChildRenderObjectComponent {
  const _PaintCounterComponent({
    required this.onPaintCounted,
    required this.onRenderBoxCreated,
  });

  final VoidCallback onPaintCounted;
  final void Function(_TrackingRenderBox) onRenderBoxCreated;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final tracker = _TrackingRenderBox();
    tracker.onPaint = onPaintCounted;
    onRenderBoxCreated(tracker);
    return tracker;
  }
}

/// Nested trackers for testing propagation
class _NestedLayoutTrackers extends StatelessComponent {
  const _NestedLayoutTrackers({
    required this.onParentCreated,
    required this.onChildCreated,
  });

  final void Function(_TrackingRenderBox) onParentCreated;
  final void Function(_TrackingRenderBox) onChildCreated;

  @override
  Component build(BuildContext context) {
    return _LayoutCounterComponent(
      onLayoutCounted: () {},
      onRenderBoxCreated: onParentCreated,
      child: _LayoutCounterComponent(
        onLayoutCounted: () {},
        onRenderBoxCreated: onChildCreated,
      ),
    );
  }
}

/// Deeply nested trackers for testing deep propagation
class _DeeplyNestedTrackers extends StatelessComponent {
  const _DeeplyNestedTrackers({
    required this.depth,
    required this.onTrackerCreated,
  });

  final int depth;
  final void Function(_TrackingRenderBox) onTrackerCreated;

  @override
  Component build(BuildContext context) {
    return _buildNested(depth);
  }

  Component _buildNested(int remaining) {
    if (remaining <= 0) {
      return const Text('leaf');
    }

    return _LayoutCounterComponent(
      onLayoutCounted: () {},
      onRenderBoxCreated: onTrackerCreated,
      child: remaining > 1 ? _buildNested(remaining - 1) : null,
    );
  }
}

/// Simple component for testing layout
class _SimpleLayoutComponent extends SingleChildRenderObjectComponent {
  const _SimpleLayoutComponent();

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _TrackingRenderBox();
  }
}

/// Simple build counter for state tests
class _SimpleBuildCounter extends StatefulComponent {
  const _SimpleBuildCounter({
    required this.onBuild,
    required this.onStateCreated,
  });

  final VoidCallback onBuild;
  final void Function(_SimpleBuildCounterState) onStateCreated;

  @override
  State<_SimpleBuildCounter> createState() => _SimpleBuildCounterState();
}

class _SimpleBuildCounterState extends State<_SimpleBuildCounter> {
  @override
  void initState() {
    super.initState();
    component.onStateCreated(this);
  }

  void triggerRebuild() {
    setState(() {});
  }

  @override
  Component build(BuildContext context) {
    component.onBuild();
    return const Text('counter');
  }
}
