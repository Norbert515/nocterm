import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('SchedulerBinding Frame Batching', () {
    test('multiple setState calls batch into single frame', () async {
      int buildCount = 0;
      late TestBatchingComponentState state;

      await testNocterm('batching test', (tester) async {
        await tester.pumpComponent(
          TestBatchingComponent(
            onBuild: () => buildCount++,
            onStateCreated: (s) => state = s,
          ),
        );

        // Initial build
        expect(buildCount, 1);
        buildCount = 0;

        // Call setState 10 times rapidly
        for (int i = 0; i < 10; i++) {
          state.triggerSetState();
        }

        // Should only schedule ONE frame (not 10)
        expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);

        // Pump the frame
        await tester.pump();

        // Should have only rebuilt ONCE (not 10 times)
        expect(buildCount, 1);
      });
    });

    test('rapid events batch into single frame', () async {
      int renderCount = 0;
      late TestEventComponentState state;

      await testNocterm('rapid events test', (tester) async {
        await tester.pumpComponent(
          TestEventComponent(
            onRender: () => renderCount++,
            onStateCreated: (s) => state = s,
          ),
        );

        // Initial render
        expect(renderCount, 1);
        renderCount = 0;

        // Simulate 100 rapid scroll events
        for (int i = 0; i < 100; i++) {
          state.handleEvent(i);
        }

        // All events processed, state updated 100 times
        expect(state.value, 99);

        // But only ONE frame scheduled
        expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);

        // Pump once
        await tester.pump();

        // Should have rendered only ONCE (not 100 times)
        expect(renderCount, 1);
      });
    });

    test('post-frame callbacks execute after frame', () async {
      final executionOrder = <String>[];

      await testNocterm('post-frame callback test', (tester) async {
        await tester.pumpComponent(
          TestCallbackComponent(
            onBuild: () => executionOrder.add('build'),
            onPostFrame: () => executionOrder.add('post-frame'),
          ),
        );

        // Check execution order
        expect(executionOrder, ['build', 'post-frame']);
      });
    });

    test('frame phases execute in correct order', () async {
      final phases = <SchedulerPhase>[];

      await testNocterm('frame phase test', (tester) async {
        // Register callbacks in different phases
        SchedulerBinding.instance.scheduleFrameCallback((timeStamp) {
          phases.add(SchedulerPhase.transientCallbacks);
        });

        SchedulerBinding.instance.addPersistentFrameCallback((timeStamp) {
          phases.add(SchedulerPhase.persistentCallbacks);
        });

        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          phases.add(SchedulerPhase.postFrameCallbacks);
        });

        // Trigger a frame
        SchedulerBinding.instance.scheduleFrame();
        await tester.pump();

        // Check phases executed in order
        expect(phases, [
          SchedulerPhase.transientCallbacks,
          SchedulerPhase.persistentCallbacks,
          SchedulerPhase.postFrameCallbacks,
        ]);
      });
    });
  });
}

// Test component that counts builds
class TestBatchingComponent extends StatefulComponent {
  const TestBatchingComponent({
    super.key,
    required this.onBuild,
    required this.onStateCreated,
  });

  final VoidCallback onBuild;
  final void Function(TestBatchingComponentState) onStateCreated;

  @override
  State<TestBatchingComponent> createState() => TestBatchingComponentState();
}

class TestBatchingComponentState extends State<TestBatchingComponent> {
  @override
  void initState() {
    super.initState();
    component.onStateCreated(this);
  }

  void triggerSetState() {
    setState(() {});
  }

  @override
  Component build(BuildContext context) {
    component.onBuild();
    return const Text('Test');
  }
}

// Test component for rapid events
class TestEventComponent extends StatefulComponent {
  const TestEventComponent({
    super.key,
    required this.onRender,
    required this.onStateCreated,
  });

  final VoidCallback onRender;
  final void Function(TestEventComponentState) onStateCreated;

  @override
  State<TestEventComponent> createState() => TestEventComponentState();
}

class TestEventComponentState extends State<TestEventComponent> {
  int _value = 0;
  int get value => _value;

  @override
  void initState() {
    super.initState();
    component.onStateCreated(this);
  }

  void handleEvent(int value) {
    setState(() {
      _value = value;
    });
  }

  @override
  Component build(BuildContext context) {
    component.onRender();
    return Text('Value: $_value');
  }
}

// Test component for post-frame callbacks
class TestCallbackComponent extends StatefulComponent {
  const TestCallbackComponent({
    super.key,
    required this.onBuild,
    required this.onPostFrame,
  });

  final VoidCallback onBuild;
  final VoidCallback onPostFrame;

  @override
  State<TestCallbackComponent> createState() => TestCallbackComponentState();
}

class TestCallbackComponentState extends State<TestCallbackComponent> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      component.onPostFrame();
    });
  }

  @override
  Component build(BuildContext context) {
    component.onBuild();
    return const Text('Test');
  }
}
