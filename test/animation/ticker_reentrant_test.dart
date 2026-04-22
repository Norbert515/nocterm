import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Ticker re-entrant restart', () {
    late NoctermTestBinding binding;

    setUp(() {
      binding = NoctermTestBinding();
    });

    tearDown(() {
      binding.shutdown();
    });

    test(
      'restart from inside onTick does not orphan the prior callback',
      () async {
        // Mirrors the AnimationController scenario where a status listener calls
        // forward(from: 0) when the simulation completes during _tick:
        //   1. Frame fires Ticker._tick.
        //   2. _onTick stops and restarts the ticker (registers a new transient
        //      callback).
        //   3. Ticker._tick must not reschedule itself a second time, or it
        //      orphans the inner registration in the scheduler.
        int tickCount = 0;
        bool restarted = false;
        late Ticker ticker;

        ticker = Ticker((_) {
          tickCount++;
          if (!restarted) {
            restarted = true;
            ticker.stop();
            ticker.start();
          }
        });

        ticker.start();

        final t1 = Duration(
          microseconds: DateTime.now().microsecondsSinceEpoch,
        );
        binding.handleBeginFrame(t1);
        expect(tickCount, 1);

        // Without the fix, frame 2 would fire two callbacks (the orphan plus the
        // outer reschedule), incrementing tickCount twice.
        binding.handleBeginFrame(t1 + const Duration(milliseconds: 16));
        expect(tickCount, 2);

        ticker.dispose();
      },
    );
  });
}
