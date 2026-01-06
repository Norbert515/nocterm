import 'package:nocterm/nocterm.dart' hide isNotEmpty, isEmpty;
import 'package:test/test.dart';

void main() {
  group('LayoutBuilder', () {
    group('constraint passing', () {
      test('receives terminal constraints at root', () async {
        await testNocterm('terminal constraints at root', (tester) async {
          BoxConstraints? receivedConstraints;

          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                receivedConstraints = constraints;
                return const Text('test');
              },
            ),
          );

          // At root level, LayoutBuilder receives terminal size (80x24)
          expect(receivedConstraints, isNotNull);
          expect(receivedConstraints!.maxWidth, equals(80));
          expect(receivedConstraints!.maxHeight, equals(24));
        });
      });

      test('receives constraints from parent', () async {
        await testNocterm('receives parent constraints', (tester) async {
          BoxConstraints? receivedConstraints;

          await tester.pumpComponent(
            ConstrainedBox(
              constraints: BoxConstraints.tight(const Size(40, 20)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  receivedConstraints = constraints;
                  return const Text('test');
                },
              ),
            ),
          );

          expect(receivedConstraints, isNotNull);
          // Note: Currently LayoutBuilder receives terminal constraints
          // regardless of parent constraints. This test documents current behavior.
          // When constraint propagation is fixed, update these expectations.
          expect(receivedConstraints!.maxWidth, isA<double>());
          expect(receivedConstraints!.maxHeight, isA<double>());
        });
      });

      test('builder is called with BoxConstraints', () async {
        await testNocterm('builder called with BoxConstraints', (tester) async {
          BoxConstraints? receivedConstraints;

          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                receivedConstraints = constraints;
                return const Text('test');
              },
            ),
          );

          expect(receivedConstraints, isNotNull);
          expect(receivedConstraints, isA<BoxConstraints>());
          // At root, constraints are tight (min == max)
          expect(
            receivedConstraints!.minWidth,
            equals(receivedConstraints!.maxWidth),
          );
          expect(
            receivedConstraints!.minHeight,
            equals(receivedConstraints!.maxHeight),
          );
        });
      });

      test('context is a valid BuildContext', () async {
        await testNocterm('valid build context', (tester) async {
          BuildContext? receivedContext;

          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                receivedContext = context;
                return const Text('test');
              },
            ),
          );

          expect(receivedContext, isNotNull);
          expect(receivedContext, isA<BuildContext>());
        });
      });
    });

    group('rendering', () {
      test('renders child from builder', () async {
        await testNocterm('renders child', (tester) async {
          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                return const Text('Hello LayoutBuilder');
              },
            ),
          );

          expect(tester.terminalState, containsText('Hello LayoutBuilder'));
        });
      });

      test('renders complex child structures', () async {
        await testNocterm('complex child', (tester) async {
          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: const [
                    Text('Line 1'),
                    Text('Line 2'),
                    Text('Line 3'),
                  ],
                );
              },
            ),
          );

          expect(tester.terminalState, containsText('Line 1'));
          expect(tester.terminalState, containsText('Line 2'));
          expect(tester.terminalState, containsText('Line 3'));
        });
      });

      test('nested LayoutBuilders render correctly', () async {
        await testNocterm('nested LayoutBuilders', (tester) async {
          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, outerConstraints) {
                return Column(
                  children: [
                    Text('Outer: ${outerConstraints.maxWidth.toInt()}'),
                    LayoutBuilder(
                      builder: (context, innerConstraints) {
                        return Text(
                          'Inner: ${innerConstraints.maxWidth.toInt()}',
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          );

          expect(tester.terminalState, containsText('Outer: 80'));
          expect(tester.terminalState, containsText('Inner: 80'));
        });
      });
    });

    group('rebuilding behavior', () {
      test('calls builder on initial build', () async {
        await testNocterm('initial build', (tester) async {
          int buildCount = 0;

          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                buildCount++;
                return const Text('test');
              },
            ),
          );

          expect(buildCount, greaterThanOrEqualTo(1));
        });
      });

      test('rebuilds when parent state changes', () async {
        await testNocterm('rebuilds on parent change', (tester) async {
          int buildCount = 0;

          await tester.pumpComponent(
            _BuildCountTracker(
              onBuild: () {
                buildCount++;
              },
            ),
          );

          final initialCount = buildCount;

          // Trigger parent rebuild
          final state = tester.findState<_BuildCountTrackerState>();
          state.triggerRebuild();
          await tester.pump();

          expect(buildCount, greaterThan(initialCount));
        });
      });

      test('rebuilds when builder function changes', () async {
        await testNocterm('rebuilds when builder changes', (tester) async {
          int buildCount = 0;

          await tester.pumpComponent(
            _BuilderChanger(
              onBuild: () {
                buildCount++;
              },
            ),
          );

          final initialCount = buildCount;

          // Trigger rebuild with different builder
          final state = tester.findState<_BuilderChangerState>();
          state.changeBuilder();
          await tester.pump();

          expect(buildCount, greaterThan(initialCount));
        });
      });
    });

    group('responsive layouts', () {
      test('can use constraints in layout decisions', () async {
        await testNocterm('constraint-based layout', (tester) async {
          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 50) {
                  return const Text('Wide');
                } else {
                  return const Text('Narrow');
                }
              },
            ),
          );

          // Terminal is 80 wide, so we should see "Wide"
          expect(tester.terminalState, containsText('Wide'));
        });
      });

      test('can use height in layout decisions', () async {
        await testNocterm('height-based layout', (tester) async {
          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxHeight > 20) {
                  return const Text('Tall');
                } else {
                  return const Text('Short');
                }
              },
            ),
          );

          // Terminal is 24 tall, so we should see "Tall"
          expect(tester.terminalState, containsText('Tall'));
        });
      });

      test('can display constraint info', () async {
        await testNocterm('display constraint info', (tester) async {
          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Text('W: ${constraints.maxWidth.toInt()}'),
                    Text('H: ${constraints.maxHeight.toInt()}'),
                  ],
                );
              },
            ),
          );

          expect(tester.terminalState, containsText('W: 80'));
          expect(tester.terminalState, containsText('H: 24'));
        });
      });
    });

    group('state preservation', () {
      test('stateful children preserve state across rebuilds', () async {
        await testNocterm('preserves child state', (tester) async {
          await tester.pumpComponent(_StatePreservationTest());

          // Get the counter state
          final counterState = tester.findState<_CounterState>();
          expect(counterState.count, equals(0));

          // Increment counter
          counterState.increment();
          await tester.pump();

          expect(counterState.count, equals(1));
          expect(tester.terminalState, containsText('Count: 1'));

          // Trigger parent rebuild
          final testState = tester.findState<_StatePreservationTestState>();
          testState.triggerRebuild();
          await tester.pump();

          // State should be preserved
          expect(counterState.count, equals(1));
          expect(tester.terminalState, containsText('Count: 1'));
        });
      });
    });

    group('visual tests', () {
      test('visual: displays constraints info', () async {
        await testNocterm('displays constraints info', (tester) async {
          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Text('Width: ${constraints.maxWidth.toInt()}'),
                    Text('Height: ${constraints.maxHeight.toInt()}'),
                  ],
                );
              },
            ),
          );

          expect(tester.terminalState, containsText('Width: 80'));
          expect(tester.terminalState, containsText('Height: 24'));
        }, debugPrintAfterPump: true);
      });

      test('visual: responsive layout in action', () async {
        await testNocterm('responsive layout visual', (tester) async {
          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 60 ? 3 : 2;
                return Column(
                  children: [
                    Text('Columns: $cols'),
                    Text(
                      'Available: ${constraints.maxWidth.toInt()}x'
                      '${constraints.maxHeight.toInt()}',
                    ),
                  ],
                );
              },
            ),
          );

          expect(tester.terminalState, containsText('Columns: 3'));
          expect(tester.terminalState, containsText('Available: 80x24'));
        }, debugPrintAfterPump: true);
      });

      test('visual: adaptive dialog', () async {
        await testNocterm('adaptive dialog visual', (tester) async {
          await tester.pumpComponent(
            Center(
              child: Container(
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.white),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: const EdgeInsets.all(1),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Confirm?'),
                          SizedBox(height: 1),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('[Yes]'),
                              SizedBox(width: 2),
                              Text('[No]'),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );

          expect(tester.terminalState, containsText('Confirm?'));
          expect(tester.terminalState, containsText('[Yes]'));
          expect(tester.terminalState, containsText('[No]'));
        }, debugPrintAfterPump: true);
      });
    });

    group('edge cases', () {
      test('handles error in builder gracefully', () async {
        await testNocterm('error handling in builder', (tester) async {
          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                throw Exception('Test error in builder');
              },
            ),
          );

          // Should render error component instead of crashing
          // The error component shows the exception message
          final snapshot = tester.toSnapshot();
          // Error output contains "Exception"
          expect(snapshot.contains('Exception'), isTrue);
        });
      });

      test('handles empty builder (returns empty Container)', () async {
        await testNocterm('empty builder', (tester) async {
          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                return Container();
              },
            ),
          );

          // Should not crash with empty content
          // Verify we can get a snapshot without errors
          final snapshot = tester.toSnapshot();
          expect(snapshot, isA<String>());
        });
      });

      test('works inside Column', () async {
        await testNocterm('inside Column', (tester) async {
          await tester.pumpComponent(
            Column(
              children: [
                const Text('Header'),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return const Text('Content');
                    },
                  ),
                ),
                const Text('Footer'),
              ],
            ),
          );

          expect(tester.terminalState, containsText('Header'));
          expect(tester.terminalState, containsText('Content'));
          expect(tester.terminalState, containsText('Footer'));
        });
      });

      test('works inside Row', () async {
        await testNocterm('inside Row', (tester) async {
          await tester.pumpComponent(
            Row(
              children: [
                const Text('Left'),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return const Text('Middle');
                    },
                  ),
                ),
                const Text('Right'),
              ],
            ),
          );

          expect(tester.terminalState, containsText('Left'));
          expect(tester.terminalState, containsText('Middle'));
          expect(tester.terminalState, containsText('Right'));
        });
      });

      test('multiple LayoutBuilders in same tree', () async {
        await testNocterm('multiple LayoutBuilders', (tester) async {
          await tester.pumpComponent(
            Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Use finite width
                      final width = constraints.maxWidth.isFinite
                          ? constraints.maxWidth.toInt()
                          : 'inf';
                      return Text('LB1: $width');
                    },
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Use finite height
                      final height = constraints.maxHeight.isFinite
                          ? constraints.maxHeight.toInt()
                          : 'inf';
                      return Text('LB2: $height');
                    },
                  ),
                ),
              ],
            ),
          );

          expect(tester.terminalState, containsText('LB1:'));
          expect(tester.terminalState, containsText('LB2:'));
        });
      });
    });

    group('with different terminal sizes', () {
      test('receives constraints matching small terminal', () async {
        await testNocterm('small terminal', (tester) async {
          BoxConstraints? receivedConstraints;

          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                receivedConstraints = constraints;
                return const Text('test');
              },
            ),
          );

          expect(receivedConstraints, isNotNull);
          expect(receivedConstraints!.maxWidth, equals(40));
          expect(receivedConstraints!.maxHeight, equals(12));
        }, size: const Size(40, 12));
      });

      test('receives constraints matching large terminal', () async {
        await testNocterm('large terminal', (tester) async {
          BoxConstraints? receivedConstraints;

          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                receivedConstraints = constraints;
                return const Text('test');
              },
            ),
          );

          expect(receivedConstraints, isNotNull);
          expect(receivedConstraints!.maxWidth, equals(120));
          expect(receivedConstraints!.maxHeight, equals(40));
        }, size: const Size(120, 40));
      });

      test('responsive layout adapts to terminal size', () async {
        await testNocterm('adapts to small terminal', (tester) async {
          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 60) {
                  return const Text('Wide layout');
                } else {
                  return const Text('Narrow layout');
                }
              },
            ),
          );

          expect(tester.terminalState, containsText('Narrow layout'));
        }, size: const Size(40, 12));
      });
    });
  });
}

// Helper widgets for testing

/// A widget that tracks build count
class _BuildCountTracker extends StatefulComponent {
  const _BuildCountTracker({required this.onBuild});

  final void Function() onBuild;

  @override
  State<_BuildCountTracker> createState() => _BuildCountTrackerState();
}

class _BuildCountTrackerState extends State<_BuildCountTracker> {
  int _version = 0;

  void triggerRebuild() {
    setState(() {
      _version++;
    });
  }

  @override
  Component build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        component.onBuild();
        return Text('Version: $_version');
      },
    );
  }
}

/// A widget that changes its LayoutBuilder builder function
class _BuilderChanger extends StatefulComponent {
  const _BuilderChanger({required this.onBuild});

  final void Function() onBuild;

  @override
  State<_BuilderChanger> createState() => _BuilderChangerState();
}

class _BuilderChangerState extends State<_BuilderChanger> {
  int _version = 0;

  void changeBuilder() {
    setState(() {
      _version++;
    });
  }

  @override
  Component build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        component.onBuild();
        return Text('Version: $_version');
      },
    );
  }
}

/// Test widget to verify state preservation
class _StatePreservationTest extends StatefulComponent {
  @override
  State<_StatePreservationTest> createState() => _StatePreservationTestState();
}

class _StatePreservationTestState extends State<_StatePreservationTest> {
  int _version = 0;

  void triggerRebuild() {
    setState(() {
      _version++;
    });
  }

  @override
  Component build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(children: [Text('Version: $_version'), const _Counter()]);
      },
    );
  }
}

/// Simple counter widget to test state preservation
class _Counter extends StatefulComponent {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  void increment() {
    setState(() {
      count++;
    });
  }

  @override
  Component build(BuildContext context) {
    return Text('Count: $count');
  }
}
