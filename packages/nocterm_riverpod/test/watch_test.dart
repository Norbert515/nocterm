import 'package:nocterm/nocterm.dart';
import 'package:nocterm_riverpod/nocterm_riverpod.dart';
import 'package:test/test.dart';

void main() {
  group('context.watch', () {
    test('watch triggers rebuilds when provider changes', () async {
      final counterProvider = StateProvider<int>((ref) => 0);
      int buildCount = 0;

      await testNocterm('watch rebuilds', (tester) async {
        await tester.pumpComponent(
          ProviderScope(
            child: _WatchTestComponent(
              builder: (context) {
                buildCount++;
                final count = context.watch(counterProvider);
                return Column(
                  children: [
                    Text('Count: $count'),
                    Text('Builds: $buildCount'),
                    KeyboardListener(
                      onKeyEvent: (key) {
                        if (key == LogicalKey.arrowUp) {
                          context.read(counterProvider.notifier).state++;
                        }
                        return false;
                      },
                      child: const Text('Press up to increment'),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        // Initial build
        expect(buildCount, 1);
        expect(tester.terminalState, containsText('Count: 0'));
        expect(tester.terminalState, containsText('Builds: 1'));

        // Increment counter - should trigger rebuild
        await tester.sendKey(LogicalKey.arrowUp);
        await tester.pump();

        expect(buildCount, 2);
        expect(tester.terminalState, containsText('Count: 1'));
        expect(tester.terminalState, containsText('Builds: 2'));

        // Increment again
        await tester.sendKey(LogicalKey.arrowUp);
        await tester.pump();

        expect(buildCount, 3);
        expect(tester.terminalState, containsText('Count: 2'));
        expect(tester.terminalState, containsText('Builds: 3'));
      });
    });

    test('watch with multiple providers', () async {
      final nameProvider = StateProvider<String>((ref) => 'Alice');
      final ageProvider = StateProvider<int>((ref) => 30);
      int buildCount = 0;

      await testNocterm('multiple watches', (tester) async {
        await tester.pumpComponent(
          ProviderScope(
            child: _WatchTestComponent(
              builder: (context) {
                buildCount++;
                final name = context.watch(nameProvider);
                final age = context.watch(ageProvider);

                return Column(
                  children: [
                    Text('$name is $age years old'),
                    Text('Builds: $buildCount'),
                    KeyboardListener(
                      onKeyEvent: (key) {
                        if (key == LogicalKey.arrowUp) {
                          context.read(ageProvider.notifier).state++;
                        } else if (key == LogicalKey.arrowRight) {
                          context.read(nameProvider.notifier).state = 'Bob';
                        }
                        return false;
                      },
                      child: const Text('Up: age, Right: name'),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        // Initial build
        expect(buildCount, 1);
        expect(tester.terminalState, containsText('Alice is 30 years old'));

        // Change age
        await tester.sendKey(LogicalKey.arrowUp);
        await tester.pump();

        expect(buildCount, 2);
        expect(tester.terminalState, containsText('Alice is 31 years old'));

        // Change name
        await tester.sendKey(LogicalKey.arrowRight);
        await tester.pump();

        expect(buildCount, 3);
        expect(tester.terminalState, containsText('Bob is 31 years old'));
      });
    });

    test('watch with computed provider', () async {
      final counterProvider = StateProvider<int>((ref) => 10);
      final doubledProvider = Provider<int>((ref) {
        final count = ref.watch(counterProvider);
        return count * 2;
      });

      int buildCount = 0;

      await testNocterm('computed provider', (tester) async {
        await tester.pumpComponent(
          ProviderScope(
            child: _WatchTestComponent(
              builder: (context) {
                buildCount++;
                final doubled = context.watch(doubledProvider);

                return Column(
                  children: [
                    Text('Doubled: $doubled'),
                    Text('Builds: $buildCount'),
                    KeyboardListener(
                      onKeyEvent: (key) {
                        if (key == LogicalKey.arrowUp) {
                          context.read(counterProvider.notifier).state++;
                        }
                        return false;
                      },
                      child: const Text('Press up to increment'),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        // Initial build
        expect(buildCount, 1);
        expect(tester.terminalState, containsText('Doubled: 20'));

        // Increment base counter
        await tester.sendKey(LogicalKey.arrowUp);
        await tester.pump();

        expect(buildCount, 2);
        expect(tester.terminalState, containsText('Doubled: 22'));
      });
    });

    test('nested ProviderScopes with watch', () async {
      final colorProvider = StateProvider<String>((ref) => 'blue');

      await testNocterm('nested scopes', (tester) async {
        await tester.pumpComponent(
          ProviderScope(
            child: Column(
              children: [
                _WatchTestComponent(
                  builder: (context) {
                    final color = context.watch(colorProvider);
                    return Text('Outer: $color');
                  },
                ),
                ProviderScope(
                  overrides: [colorProvider.overrideWith((ref) => 'red')],
                  child: _WatchTestComponent(
                    builder: (context) {
                      final color = context.watch(colorProvider);
                      return Text('Inner: $color');
                    },
                  ),
                ),
                KeyboardListener(
                  onKeyEvent: (key) {
                    if (key == LogicalKey.arrowUp) {
                      // This won't work as expected since we're outside the scope
                      // but it's here for testing
                    }
                    return false;
                  },
                  child: const Text('Controls'),
                ),
              ],
            ),
          ),
        );

        expect(tester.terminalState, containsText('Outer: blue'));
        expect(tester.terminalState, containsText('Inner: red'));
      });
    });

    test('watch does not create duplicate subscriptions', () async {
      final counterProvider = StateProvider<int>((ref) => 0);
      final rebuildTrigger = StateProvider<int>((ref) => 0);
      int watchCallCount = 0;

      await testNocterm('no duplicate subscriptions', (tester) async {
        await tester.pumpComponent(
          ProviderScope(
            child: _WatchTestComponent(
              builder: (context) {
                // Watch counter (track how many times watch is called)
                watchCallCount++;
                final count = context.watch(counterProvider);

                // Also watch another provider to trigger rebuilds
                context.watch(rebuildTrigger);

                return Column(
                  children: [
                    Text('Count: $count'),
                    Text('Watch calls: $watchCallCount'),
                    KeyboardListener(
                      onKeyEvent: (key) {
                        if (key == LogicalKey.arrowUp) {
                          context.read(counterProvider.notifier).state++;
                        } else if (key == LogicalKey.arrowRight) {
                          // Trigger rebuild without changing counter
                          context.read(rebuildTrigger.notifier).state++;
                        }
                        return false;
                      },
                      child: const Text('Up: counter, Right: rebuild'),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        // Initial build
        expect(watchCallCount, 1);

        // Trigger rebuild without changing counter
        await tester.sendKey(LogicalKey.arrowRight);
        await tester.pump();

        // Watch was called again but shouldn't create duplicate subscription
        expect(watchCallCount, 2);

        // Now change the counter
        await tester.sendKey(LogicalKey.arrowUp);
        await tester.pump();

        // Should only rebuild once despite multiple watch calls
        expect(watchCallCount, 3);
        expect(tester.terminalState, containsText('Count: 1'));
      });
    });
  });

  group('context.listen', () {
    test('listen receives updates without rebuilding', () async {
      final counterProvider = StateProvider<int>((ref) => 0);

      await testNocterm('listen without rebuild', (tester) async {
        await tester.pumpComponent(
          ProviderScope(
            child: _ListenTestComponent(counterProvider: counterProvider),
          ),
        );

        // Initial state
        expect(tester.terminalState, containsText('Last value: 0'));
        expect(tester.terminalState, containsText('Build count: 1'));

        // Increment counter
        await tester.sendKey(LogicalKey.arrowUp);
        await tester.pump();

        // Value updated but build count stays the same
        expect(tester.terminalState, containsText('Last value: 1'));
        expect(tester.terminalState, containsText('Build count: 1'));

        // Increment again
        await tester.sendKey(LogicalKey.arrowUp);
        await tester.pump();

        expect(tester.terminalState, containsText('Last value: 2'));
        expect(tester.terminalState, containsText('Build count: 1'));
      });
    });
  });
}

// Test component that uses watch
class _WatchTestComponent extends StatelessComponent {
  const _WatchTestComponent({required this.builder});

  final ComponentBuilder builder;

  @override
  Component build(BuildContext context) {
    return builder(context);
  }
}

// Test component that uses listen
class _ListenTestComponent extends StatefulComponent {
  const _ListenTestComponent({required this.counterProvider});

  final StateProvider<int> counterProvider;

  @override
  State<_ListenTestComponent> createState() => _ListenTestComponentState();
}

class _ListenTestComponentState extends State<_ListenTestComponent> {
  int lastValue = 0;
  int buildCount = 0;

  @override
  void initState() {
    super.initState();
    lastValue = context.read(component.counterProvider);

    // Listen to changes without rebuilding
    context.listen<int>(component.counterProvider, (previous, next) {
      setState(() {
        lastValue = next;
      });
    });
  }

  @override
  Component build(BuildContext context) {
    buildCount++;

    return Column(
      children: [
        Text('Last value: $lastValue'),
        Text('Build count: $buildCount'),
        KeyboardListener(
          onKeyEvent: (key) {
            if (key == LogicalKey.arrowUp) {
              context.read(component.counterProvider.notifier).state++;
            }
            return false;
          },
          child: const Text('Press up to increment'),
        ),
      ],
    );
  }
}
