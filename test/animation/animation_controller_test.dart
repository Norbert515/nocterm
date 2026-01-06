import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart' hide isEmpty;

/// A fake ticker provider for testing animations.
class FakeTickerProvider implements TickerProvider {
  final List<FakeTicker> _tickers = [];

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = FakeTicker(onTick);
    _tickers.add(ticker);
    return ticker;
  }

  /// Simulates a frame tick at the given elapsed time for all active tickers.
  void tick(Duration elapsed) {
    for (final ticker in _tickers) {
      if (ticker.isActive) {
        ticker.simulateTick(elapsed);
      }
    }
  }

  /// Advances time by the given duration across multiple frames.
  void advance(Duration duration, {int frameCount = 10}) {
    final frameTime = duration ~/ frameCount;
    for (var i = 1; i <= frameCount; i++) {
      tick(frameTime * i);
    }
  }
}

/// A fake ticker that can be manually controlled for testing.
class FakeTicker implements Ticker {
  FakeTicker(this._onTick);

  final TickerCallback _onTick;
  TickerFuture? _future;
  Duration? _startTime;
  bool _muted = false;

  @override
  String? debugLabel;

  @override
  bool get muted => _muted;

  @override
  set muted(bool value) {
    _muted = value;
  }

  @override
  bool get isTicking => _future != null;

  @override
  bool get isActive => _future != null;

  @override
  bool get shouldScheduleTick => !muted && isActive;

  @override
  TickerFuture start() {
    assert(!isActive, 'Ticker already started');
    _future = TickerFuture.complete();
    _startTime = Duration.zero;
    return _future!;
  }

  @override
  void stop({bool canceled = true}) {
    if (!isActive) return;
    _future = null;
    _startTime = null;
  }

  @override
  void dispose() {
    if (isActive) {
      stop(canceled: true);
    }
  }

  @override
  void absorbTicker(Ticker originalTicker) {
    // Not implemented for testing
  }

  /// Simulates a tick at the given elapsed time.
  void simulateTick(Duration elapsed) {
    if (!isActive || muted) return;
    _startTime ??= Duration.zero;
    _onTick(elapsed);
  }
}

void main() {
  group('AnimationController', () {
    late FakeTickerProvider vsync;

    setUp(() {
      vsync = FakeTickerProvider();
    });

    group('initialization', () {
      test('initial value defaults to lowerBound', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: vsync,
        );
        expect(controller.value, 0.0);
        controller.dispose();
      });

      test('initial value can be specified', () {
        final controller = AnimationController(
          value: 0.5,
          duration: const Duration(milliseconds: 300),
          vsync: vsync,
        );
        expect(controller.value, 0.5);
        controller.dispose();
      });

      test('initial status is dismissed when value equals lowerBound', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: vsync,
        );
        expect(controller.status, AnimationStatus.dismissed);
        controller.dispose();
      });

      test('initial status is completed when value equals upperBound', () {
        final controller = AnimationController(
          value: 1.0,
          duration: const Duration(milliseconds: 300),
          vsync: vsync,
        );
        expect(controller.status, AnimationStatus.completed);
        controller.dispose();
      });

      test('custom bounds are respected', () {
        final controller = AnimationController(
          value: 5.0,
          lowerBound: 0.0,
          upperBound: 10.0,
          duration: const Duration(milliseconds: 300),
          vsync: vsync,
        );
        expect(controller.value, 5.0);
        expect(controller.lowerBound, 0.0);
        expect(controller.upperBound, 10.0);
        controller.dispose();
      });
    });

    group('value setter', () {
      test('stops animation and sets value', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: vsync,
        );
        controller.forward();
        expect(controller.isAnimating, isTrue);

        controller.value = 0.5;
        expect(controller.isAnimating, isFalse);
        expect(controller.value, 0.5);
        controller.dispose();
      });

      test('clamps value to bounds', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: vsync,
        );
        controller.value = 2.0;
        expect(controller.value, 1.0);

        controller.value = -1.0;
        expect(controller.value, 0.0);
        controller.dispose();
      });

      test('notifies listeners when value changes', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: vsync,
        );
        var listenerCalled = false;
        controller.addListener(() {
          listenerCalled = true;
        });

        controller.value = 0.5;
        expect(listenerCalled, isTrue);
        controller.dispose();
      });
    });

    group('forward', () {
      test('starts animation towards upperBound', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: vsync,
        );
        controller.forward();
        expect(controller.isAnimating, isTrue);
        expect(controller.status, AnimationStatus.forward);
        controller.dispose();
      });

      test('animates value from current to upperBound', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        controller.forward();

        // Simulate animation progress
        vsync.tick(const Duration(milliseconds: 50));
        expect(controller.value, greaterThan(0.0));
        expect(controller.value, lessThan(1.0));

        vsync.tick(const Duration(milliseconds: 100));
        expect(controller.value, 1.0);
        expect(controller.status, AnimationStatus.completed);
        controller.dispose();
      });

      test('can start from a specific value', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        controller.forward(from: 0.5);
        expect(controller.value, 0.5);
        expect(controller.isAnimating, isTrue);
        controller.dispose();
      });
    });

    group('reverse', () {
      test('starts animation towards lowerBound', () {
        final controller = AnimationController(
          value: 1.0,
          duration: const Duration(milliseconds: 300),
          vsync: vsync,
        );
        controller.reverse();
        expect(controller.isAnimating, isTrue);
        expect(controller.status, AnimationStatus.reverse);
        controller.dispose();
      });

      test('animates value from current to lowerBound', () {
        final controller = AnimationController(
          value: 1.0,
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        controller.reverse();

        vsync.tick(const Duration(milliseconds: 50));
        expect(controller.value, lessThan(1.0));
        expect(controller.value, greaterThan(0.0));

        vsync.tick(const Duration(milliseconds: 100));
        expect(controller.value, 0.0);
        expect(controller.status, AnimationStatus.dismissed);
        controller.dispose();
      });

      test('uses reverseDuration if specified', () {
        final controller = AnimationController(
          value: 1.0,
          duration: const Duration(milliseconds: 100),
          reverseDuration: const Duration(milliseconds: 200),
          vsync: vsync,
        );
        controller.reverse();

        // At 100ms, should not be complete yet because reverse takes 200ms
        vsync.tick(const Duration(milliseconds: 100));
        expect(controller.value, greaterThan(0.0));

        vsync.tick(const Duration(milliseconds: 200));
        expect(controller.value, 0.0);
        controller.dispose();
      });
    });

    group('stop', () {
      test('stops the animation', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: vsync,
        );
        controller.forward();
        expect(controller.isAnimating, isTrue);

        controller.stop();
        expect(controller.isAnimating, isFalse);
        controller.dispose();
      });

      test('preserves current value', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        controller.forward();
        vsync.tick(const Duration(milliseconds: 50));
        final valueBeforeStop = controller.value;

        controller.stop();
        expect(controller.value, valueBeforeStop);
        controller.dispose();
      });
    });

    group('reset', () {
      test('sets value to lowerBound', () {
        final controller = AnimationController(
          value: 0.5,
          duration: const Duration(milliseconds: 300),
          vsync: vsync,
        );
        controller.reset();
        expect(controller.value, 0.0);
        expect(controller.status, AnimationStatus.dismissed);
        controller.dispose();
      });

      test('stops animation if running', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: vsync,
        );
        controller.forward();
        controller.reset();
        expect(controller.isAnimating, isFalse);
        expect(controller.value, 0.0);
        controller.dispose();
      });
    });

    group('animateTo', () {
      test('animates to a specific target', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        controller.animateTo(0.5);

        vsync.tick(const Duration(milliseconds: 100));
        expect(controller.value, closeTo(0.5, 0.01));
        controller.dispose();
      });

      test('respects custom duration', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        controller.animateTo(1.0, duration: const Duration(milliseconds: 200));

        // At 100ms, should not be at target yet
        vsync.tick(const Duration(milliseconds: 100));
        expect(controller.value, lessThan(1.0));

        vsync.tick(const Duration(milliseconds: 200));
        expect(controller.value, 1.0);
        controller.dispose();
      });

      test('applies curve', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        controller.animateTo(1.0, curve: Curves.easeIn);

        // EaseIn starts slow
        vsync.tick(const Duration(milliseconds: 50));
        expect(controller.value, lessThan(0.5));
        controller.dispose();
      });
    });

    group('repeat', () {
      test('repeats the animation', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        controller.repeat();

        // First iteration
        vsync.tick(const Duration(milliseconds: 50));
        expect(controller.value, closeTo(0.5, 0.01));

        vsync.tick(const Duration(milliseconds: 100));
        expect(controller.value, closeTo(0.0, 0.01));

        // Second iteration
        vsync.tick(const Duration(milliseconds: 150));
        expect(controller.value, closeTo(0.5, 0.01));

        controller.dispose();
      });

      test('can reverse on each iteration', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        controller.repeat(reverse: true);

        // First iteration (forward)
        vsync.tick(const Duration(milliseconds: 50));
        expect(controller.value, closeTo(0.5, 0.01));

        vsync.tick(const Duration(milliseconds: 100));
        expect(controller.value, closeTo(1.0, 0.01));

        // Second iteration (reverse)
        vsync.tick(const Duration(milliseconds: 150));
        expect(controller.value, closeTo(0.5, 0.01));

        vsync.tick(const Duration(milliseconds: 200));
        expect(controller.value, closeTo(0.0, 0.01));

        controller.dispose();
      });
    });

    group('listeners', () {
      test('addListener and removeListener work correctly', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        var callCount = 0;
        void listener() => callCount++;

        controller.addListener(listener);
        controller.forward();
        vsync.tick(const Duration(milliseconds: 50));
        expect(callCount, greaterThan(0));

        final countBeforeRemove = callCount;
        controller.removeListener(listener);
        vsync.tick(const Duration(milliseconds: 75));
        expect(callCount, countBeforeRemove);
        controller.dispose();
      });

      test('multiple listeners are all called', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        var count1 = 0;
        var count2 = 0;
        controller.addListener(() => count1++);
        controller.addListener(() => count2++);

        controller.forward();
        vsync.tick(const Duration(milliseconds: 50));

        expect(count1, greaterThan(0));
        expect(count2, greaterThan(0));
        controller.dispose();
      });
    });

    group('status listeners', () {
      test('addStatusListener and removeStatusListener work correctly', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        final statuses = <AnimationStatus>[];
        void statusListener(AnimationStatus status) => statuses.add(status);

        controller.addStatusListener(statusListener);
        controller.forward();
        expect(statuses, contains(AnimationStatus.forward));

        vsync.tick(const Duration(milliseconds: 100));
        expect(statuses, contains(AnimationStatus.completed));

        controller.removeStatusListener(statusListener);
        statuses.clear();
        controller.reverse();
        // Status listener was removed, so no new statuses should be recorded
        expect(statuses.length, 0);
        controller.dispose();
      });

      test('status changes appropriately during animation', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        final statuses = <AnimationStatus>[];
        controller.addStatusListener(statuses.add);

        expect(controller.status, AnimationStatus.dismissed);

        controller.forward();
        expect(statuses.last, AnimationStatus.forward);

        vsync.tick(const Duration(milliseconds: 100));
        expect(statuses.last, AnimationStatus.completed);

        controller.reverse();
        expect(statuses.last, AnimationStatus.reverse);

        vsync.tick(const Duration(milliseconds: 200));
        expect(statuses.last, AnimationStatus.dismissed);

        controller.dispose();
      });
    });

    group('unbounded controller', () {
      test('allows values outside 0-1 range', () {
        final controller = AnimationController.unbounded(
          value: 50.0,
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );

        expect(controller.value, 50.0);
        expect(controller.lowerBound, double.negativeInfinity);
        expect(controller.upperBound, double.infinity);
        controller.dispose();
      });
    });

    group('dispose', () {
      test('stops animation and clears listeners', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: vsync,
        );
        controller.addListener(() {});
        controller.forward();

        controller.dispose();
        expect(controller.isAnimating, isFalse);

        // After dispose, controller should be stopped
      });
    });

    group('velocity', () {
      test('returns 0 when not animating', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        expect(controller.velocity, 0.0);
        controller.dispose();
      });

      test('returns non-zero when animating', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        controller.forward();
        vsync.tick(const Duration(milliseconds: 50));
        expect(controller.velocity, isNot(equals(0.0)));
        controller.dispose();
      });
    });

    group('isAnimating and status helpers', () {
      test('isDismissed is true when status is dismissed', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        expect(controller.isDismissed, isTrue);
        expect(controller.isCompleted, isFalse);
        controller.dispose();
      });

      test('isCompleted is true when status is completed', () {
        final controller = AnimationController(
          value: 1.0,
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        expect(controller.isCompleted, isTrue);
        expect(controller.isDismissed, isFalse);
        controller.dispose();
      });

      test('isAnimating is true during animation', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        expect(controller.isAnimating, isFalse);
        controller.forward();
        expect(controller.isAnimating, isTrue);
        controller.stop();
        expect(controller.isAnimating, isFalse);
        controller.dispose();
      });
    });

    group('drive', () {
      test('chains with an Animatable', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        final animation = controller.drive(
          Tween<double>(begin: 0.0, end: 100.0),
        );

        expect(animation.value, 0.0);

        controller.forward();
        vsync.tick(const Duration(milliseconds: 50));
        expect(animation.value, closeTo(50.0, 1.0));

        vsync.tick(const Duration(milliseconds: 100));
        expect(animation.value, 100.0);

        controller.dispose();
      });

      test('chains with CurveTween', () {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        final animation = controller
            .drive(CurveTween(curve: Curves.easeIn))
            .drive(Tween<double>(begin: 0.0, end: 100.0));

        controller.forward();
        vsync.tick(const Duration(milliseconds: 50));
        // EaseIn at t=0.5 is less than 0.5, so value should be less than 50
        expect(animation.value, lessThan(50.0));

        controller.dispose();
      });
    });
  });

  group('AnimationStatus', () {
    test('all statuses are distinct', () {
      expect(AnimationStatus.dismissed, isNot(equals(AnimationStatus.forward)));
      expect(AnimationStatus.forward, isNot(equals(AnimationStatus.reverse)));
      expect(AnimationStatus.reverse, isNot(equals(AnimationStatus.completed)));
      expect(
        AnimationStatus.completed,
        isNot(equals(AnimationStatus.dismissed)),
      );
    });
  });
}
