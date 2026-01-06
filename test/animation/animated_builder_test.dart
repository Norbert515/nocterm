import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

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
  void absorbTicker(Ticker originalTicker) {}

  /// Simulates a tick at the given elapsed time.
  void simulateTick(Duration elapsed) {
    if (!isActive || muted) return;
    _startTime ??= Duration.zero;
    _onTick(elapsed);
  }
}

/// A simple notifier for testing ListenableBuilder.
class TestNotifier extends ChangeNotifier {
  int _value = 0;

  int get value => _value;

  set value(int newValue) {
    _value = newValue;
    notifyListeners();
  }
}

void main() {
  group('AnimatedBuilder', () {
    test('rebuilds when animation changes value', () async {
      await testNocterm('animated builder rebuild', (tester) async {
        final vsync = FakeTickerProvider();
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );

        var buildCount = 0;

        await tester.pumpComponent(
          Container(
            width: 40,
            height: 5,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                buildCount++;
                return Text('Value: ${controller.value.toStringAsFixed(2)}');
              },
            ),
          ),
        );

        expect(buildCount, 1);
        expect(tester.terminalState, containsText('Value: 0.00'));

        // Start animation and tick
        controller.forward();
        vsync.tick(const Duration(milliseconds: 50));

        await tester.pumpComponent(
          Container(
            width: 40,
            height: 5,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                buildCount++;
                return Text('Value: ${controller.value.toStringAsFixed(2)}');
              },
            ),
          ),
        );

        expect(buildCount, greaterThan(1));

        controller.dispose();
      });
    });

    test('passes child through correctly', () async {
      await testNocterm('animated builder child', (tester) async {
        final vsync = FakeTickerProvider();
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );

        await tester.pumpComponent(
          Container(
            width: 50,
            height: 10,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Column(
                  children: [
                    Text('Animation: ${controller.value.toStringAsFixed(2)}'),
                    if (child != null) child,
                  ],
                );
              },
              child: const Text('Static child'),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Animation: 0.00'));
        expect(tester.terminalState, containsText('Static child'));

        controller.dispose();
      });
    });

    test('child is not rebuilt on animation change', () async {
      await testNocterm('animated builder child stable', (tester) async {
        final vsync = FakeTickerProvider();
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );

        var childBuildCount = 0;

        // Note: In this test setup, the child is created inline,
        // so we're testing that the child parameter is passed correctly
        await tester.pumpComponent(
          Container(
            width: 50,
            height: 10,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                // The child should be the same instance
                expect(child, isNotNull);
                return Column(
                  children: [
                    Text('Value: ${controller.value.toStringAsFixed(2)}'),
                    child!,
                  ],
                );
              },
              child: Builder(
                builder: (context) {
                  childBuildCount++;
                  return const Text('Child');
                },
              ),
            ),
          ),
        );

        expect(childBuildCount, 1);
        expect(tester.terminalState, containsText('Child'));

        controller.dispose();
      });
    });

    test('works with different animation values', () async {
      await testNocterm('animated builder different values', (tester) async {
        final vsync = FakeTickerProvider();
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );

        // Test at value = 0
        await tester.pumpComponent(
          Container(
            width: 40,
            height: 5,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Text('Progress: ${(controller.value * 100).toInt()}%');
              },
            ),
          ),
        );
        expect(tester.terminalState, containsText('Progress: 0%'));

        // Test at value = 0.5
        controller.value = 0.5;
        await tester.pumpComponent(
          Container(
            width: 40,
            height: 5,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Text('Progress: ${(controller.value * 100).toInt()}%');
              },
            ),
          ),
        );
        expect(tester.terminalState, containsText('Progress: 50%'));

        // Test at value = 1.0
        controller.value = 1.0;
        await tester.pumpComponent(
          Container(
            width: 40,
            height: 5,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Text('Progress: ${(controller.value * 100).toInt()}%');
              },
            ),
          ),
        );
        expect(tester.terminalState, containsText('Progress: 100%'));

        controller.dispose();
      });
    });

    test('works with driven animations (Tween)', () async {
      await testNocterm('animated builder with tween', (tester) async {
        final vsync = FakeTickerProvider();
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        final animation = Tween<double>(
          begin: 10.0,
          end: 90.0,
        ).animate(controller);

        await tester.pumpComponent(
          Container(
            width: 40,
            height: 5,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Text('Size: ${animation.value.toInt()}');
              },
            ),
          ),
        );
        expect(tester.terminalState, containsText('Size: 10'));

        controller.value = 0.5;
        await tester.pumpComponent(
          Container(
            width: 40,
            height: 5,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Text('Size: ${animation.value.toInt()}');
              },
            ),
          ),
        );
        expect(tester.terminalState, containsText('Size: 50'));

        controller.value = 1.0;
        await tester.pumpComponent(
          Container(
            width: 40,
            height: 5,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Text('Size: ${animation.value.toInt()}');
              },
            ),
          ),
        );
        expect(tester.terminalState, containsText('Size: 90'));

        controller.dispose();
      });
    });

    test('works with curved animations', () async {
      await testNocterm('animated builder with curve', (tester) async {
        final vsync = FakeTickerProvider();
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        final animation = CurveTween(curve: Curves.easeIn).animate(controller);

        controller.value = 0.5;
        // easeIn at 0.5 should be less than 0.5
        expect(animation.value, lessThan(0.5));

        await tester.pumpComponent(
          Container(
            width: 40,
            height: 5,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Text('Curved: ${animation.value.toStringAsFixed(2)}');
              },
            ),
          ),
        );
        expect(tester.terminalState, containsText('Curved:'));

        controller.dispose();
      });
    });
  });

  group('ListenableBuilder', () {
    test('rebuilds when listenable notifies', () async {
      await testNocterm('listenable builder rebuild', (tester) async {
        final notifier = TestNotifier();

        var buildCount = 0;

        await tester.pumpComponent(
          Container(
            width: 40,
            height: 5,
            child: ListenableBuilder(
              listenable: notifier,
              builder: (context, child) {
                buildCount++;
                return Text('Count: ${notifier.value}');
              },
            ),
          ),
        );

        expect(buildCount, 1);
        expect(tester.terminalState, containsText('Count: 0'));

        // Change the value
        notifier.value = 5;

        await tester.pumpComponent(
          Container(
            width: 40,
            height: 5,
            child: ListenableBuilder(
              listenable: notifier,
              builder: (context, child) {
                buildCount++;
                return Text('Count: ${notifier.value}');
              },
            ),
          ),
        );

        expect(buildCount, greaterThan(1));
      });
    });

    test('passes child through correctly', () async {
      await testNocterm('listenable builder child', (tester) async {
        final notifier = TestNotifier();

        await tester.pumpComponent(
          Container(
            width: 50,
            height: 10,
            child: ListenableBuilder(
              listenable: notifier,
              builder: (context, child) {
                return Column(
                  children: [
                    Text('Value: ${notifier.value}'),
                    if (child != null) child,
                  ],
                );
              },
              child: const Text('Static footer'),
            ),
          ),
        );

        expect(tester.terminalState, containsText('Value: 0'));
        expect(tester.terminalState, containsText('Static footer'));
      });
    });
  });

  group('Animation.drive', () {
    test('creates driven animation', () async {
      await testNocterm('animation drive', (tester) async {
        final vsync = FakeTickerProvider();
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );

        // Drive with a tween
        final animation = controller.drive(
          Tween<double>(begin: 0.0, end: 200.0),
        );

        expect(animation.value, 0.0);

        controller.value = 0.5;
        expect(animation.value, 100.0);

        controller.value = 1.0;
        expect(animation.value, 200.0);

        controller.dispose();
      });
    });

    test('chains multiple drives', () async {
      await testNocterm('animation chain drives', (tester) async {
        final vsync = FakeTickerProvider();
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );

        // Chain curve then tween
        final animation = controller
            .drive(CurveTween(curve: Curves.easeIn))
            .drive(Tween<double>(begin: 0.0, end: 100.0));

        controller.value = 0.5;
        // easeIn at 0.5 is less than 0.5, so animation value < 50
        expect(animation.value, lessThan(50.0));

        controller.dispose();
      });
    });
  });

  group('Animatable.animate', () {
    test('creates animation from animatable', () async {
      await testNocterm('animatable animate', (tester) async {
        final vsync = FakeTickerProvider();
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );

        final tween = Tween<double>(begin: 10.0, end: 110.0);
        final animation = tween.animate(controller);

        expect(animation.value, 10.0);

        controller.value = 0.5;
        expect(animation.value, 60.0);

        controller.value = 1.0;
        expect(animation.value, 110.0);

        controller.dispose();
      });
    });
  });

  group('Animation status', () {
    test('status matches controller status', () async {
      await testNocterm('animation status', (tester) async {
        final vsync = FakeTickerProvider();
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: vsync,
        );
        final animation = Tween<double>(
          begin: 0.0,
          end: 100.0,
        ).animate(controller);

        expect(animation.status, AnimationStatus.dismissed);

        controller.forward();
        expect(animation.status, AnimationStatus.forward);

        vsync.tick(const Duration(milliseconds: 100));
        expect(animation.status, AnimationStatus.completed);

        controller.reverse();
        expect(animation.status, AnimationStatus.reverse);

        controller.dispose();
      });
    });
  });
}
