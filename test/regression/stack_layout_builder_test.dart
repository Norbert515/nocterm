import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

/// Regression tests for the Stack repaint bug with LayoutBuilder.
///
/// Bug description: When a Positioned.fill child containing a LayoutBuilder
/// transitions from a small widget (SizedBox) to a large widget tree (Column
/// with many Rows), the second child of the Stack would stop rendering.
///
/// The fix implemented `invokeLayoutCallback` mechanism that properly merges
/// newly created render objects into the layout pipeline during layout.
void main() {
  group('Stack with LayoutBuilder regression tests', () {
    group('basic Stack with LayoutBuilder', () {
      test(
        'renders both children when LayoutBuilder has simple content',
        () async {
          await testNocterm('basic stack layout builder', (tester) async {
            await tester.pumpComponent(
              Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          color: const Color.fromRGB(50, 50, 50),
                          child: const Text('BACKGROUND'),
                        );
                      },
                    ),
                  ),
                  Center(child: Text('FOREGROUND')),
                ],
              ),
            );

            expect(tester.terminalState, containsText('BACKGROUND'));
            expect(tester.terminalState, containsText('FOREGROUND'));
          });
        },
      );

      test(
        'renders both children when LayoutBuilder has complex content',
        () async {
          await testNocterm('complex layout builder content', (tester) async {
            await tester.pumpComponent(
              Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          children: [
                            for (int i = 0; i < 10; i++)
                              Row(
                                children: [
                                  for (int j = 0; j < 5; j++) Text('[$i,$j]'),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  Center(child: Text('OVERLAY')),
                ],
              ),
            );

            // Both the grid content and overlay should be visible
            expect(tester.terminalState, containsText('[0,0]'));
            expect(tester.terminalState, containsText('OVERLAY'));
          });
        },
      );
    });

    group('SizedBox to Grid transition', () {
      test(
        'foreground remains visible after transition to large grid',
        () async {
          await testNocterm('sized box to grid transition', (tester) async {
            // First render with SizedBox (minimal content)
            await tester.pumpComponent(_TogglableGridStack(showGrid: false));

            expect(tester.terminalState, containsText('CENTERED_TEXT'));

            // Toggle to grid view (large widget tree)
            await tester.pumpComponent(_TogglableGridStack(showGrid: true));

            // The foreground text MUST still be visible after the transition
            expect(tester.terminalState, containsText('CENTERED_TEXT'));
            // Grid content should also be visible
            expect(tester.terminalState, containsText('[0,0]'));
          });
        },
      );

      test('foreground remains visible with stateful toggle', () async {
        await testNocterm('stateful grid toggle', (tester) async {
          await tester.pumpComponent(const _StatefulGridToggle());

          // Initial state: showGrid is false, just SizedBox
          expect(tester.terminalState, containsText('FOREGROUND_LABEL'));

          // Find and trigger the state change
          final state = tester.findState<_StatefulGridToggleState>();
          state.toggleGrid();
          await tester.pump();

          // After toggle: foreground MUST still be visible
          expect(tester.terminalState, containsText('FOREGROUND_LABEL'));
          // Grid should now be visible
          expect(tester.terminalState, containsText('['));
        });
      });
    });

    group('Grid to SizedBox transition', () {
      test(
        'foreground remains visible after transition back to SizedBox',
        () async {
          await testNocterm('grid to sized box transition', (tester) async {
            // Start with grid view
            await tester.pumpComponent(_TogglableGridStack(showGrid: true));

            expect(tester.terminalState, containsText('CENTERED_TEXT'));
            expect(tester.terminalState, containsText('[0,0]'));

            // Toggle back to SizedBox
            await tester.pumpComponent(_TogglableGridStack(showGrid: false));

            // Foreground must still be visible
            expect(tester.terminalState, containsText('CENTERED_TEXT'));
            // Grid content should not be visible
            expect(tester.terminalState, isNot(containsText('[0,0]')));
          });
        },
      );
    });

    group('multiple toggles', () {
      test('rapid toggles do not break rendering', () async {
        await testNocterm('rapid toggle test', (tester) async {
          await tester.pumpComponent(const _StatefulGridToggle());

          final state = tester.findState<_StatefulGridToggleState>();

          // Perform multiple rapid toggles
          for (int i = 0; i < 5; i++) {
            state.toggleGrid();
            await tester.pump();

            // Foreground MUST always be visible
            expect(
              tester.terminalState,
              containsText('FOREGROUND_LABEL'),
              reason: 'Foreground should be visible after toggle $i',
            );
          }
        });
      });

      test('alternating content changes preserve foreground', () async {
        await testNocterm('alternating content', (tester) async {
          await tester.pumpComponent(const _StatefulGridToggle());

          final state = tester.findState<_StatefulGridToggleState>();

          // Toggle on
          state.toggleGrid();
          await tester.pump();
          expect(tester.terminalState, containsText('FOREGROUND_LABEL'));

          // Toggle off
          state.toggleGrid();
          await tester.pump();
          expect(tester.terminalState, containsText('FOREGROUND_LABEL'));

          // Toggle on again
          state.toggleGrid();
          await tester.pump();
          expect(tester.terminalState, containsText('FOREGROUND_LABEL'));

          // Toggle off again
          state.toggleGrid();
          await tester.pump();
          expect(tester.terminalState, containsText('FOREGROUND_LABEL'));
        });
      });
    });

    group('LayoutBuilder with complex content in Stack', () {
      test('deeply nested widgets in LayoutBuilder work correctly', () async {
        await testNocterm('deeply nested content', (tester) async {
          await tester.pumpComponent(
            Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Create a deeply nested widget tree
                      return Column(
                        children: [
                          Container(
                            child: Row(
                              children: [
                                Text('DEEP_LEFT'),
                                Expanded(
                                  child: Center(child: Text('DEEP_CENTER')),
                                ),
                                Text('DEEP_RIGHT'),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Center(child: Text('DEEP_OVERLAY')),
              ],
            ),
          );

          expect(tester.terminalState, containsText('DEEP_LEFT'));
          expect(tester.terminalState, containsText('DEEP_CENTER'));
          expect(tester.terminalState, containsText('DEEP_OVERLAY'));
        });
      });
    });

    group('LayoutBuilder with constraint-based decisions', () {
      test(
        'foreground visible when LayoutBuilder changes based on constraints',
        () async {
          await testNocterm('constraint based layout', (tester) async {
            await tester.pumpComponent(
              Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 40) {
                          // Wide layout - create many widgets
                          return Column(
                            children: [
                              for (int i = 0; i < 5; i++)
                                Row(
                                  children: [
                                    Text('Wide Row $i'),
                                    const SizedBox(width: 2),
                                    Text('Extra content'),
                                  ],
                                ),
                            ],
                          );
                        } else {
                          // Narrow layout - minimal widgets
                          return const Text('Narrow');
                        }
                      },
                    ),
                  ),
                  Center(child: Text('CONSTRAINT_OVERLAY')),
                ],
              ),
            );

            // Standard terminal is 80 wide, so we should see wide layout
            expect(tester.terminalState, containsText('Wide Row'));
            expect(tester.terminalState, containsText('CONSTRAINT_OVERLAY'));
          });
        },
      );

      test('foreground visible in narrow terminal', () async {
        await testNocterm('narrow terminal test', (tester) async {
          await tester.pumpComponent(
            Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 50) {
                        return Column(
                          children: [
                            for (int i = 0; i < 10; i++) Text('Wide: $i'),
                          ],
                        );
                      } else {
                        return const Text('NARROW_MODE');
                      }
                    },
                  ),
                ),
                Center(child: Text('NARROW_OVERLAY')),
              ],
            ),
          );

          // In narrow terminal, should see narrow mode
          expect(tester.terminalState, containsText('NARROW_MODE'));
          expect(tester.terminalState, containsText('NARROW_OVERLAY'));
        }, size: const Size(40, 12));
      });
    });

    group('error handling in LayoutBuilder', () {
      test(
        'foreground visible even if LayoutBuilder throws initially',
        () async {
          await testNocterm('error then success', (tester) async {
            // First, test with an error
            await tester.pumpComponent(
              Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        throw Exception('Initial error');
                      },
                    ),
                  ),
                  Center(child: Text('ERROR_OVERLAY')),
                ],
              ),
            );

            // Error component should render but overlay should still be there
            expect(tester.terminalState, containsText('Exception'));
            expect(tester.terminalState, containsText('ERROR_OVERLAY'));

            // Then replace with working component
            await tester.pumpComponent(
              Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return const Text('RECOVERED');
                      },
                    ),
                  ),
                  Center(child: Text('RECOVERED_OVERLAY')),
                ],
              ),
            );

            expect(tester.terminalState, containsText('RECOVERED'));
            expect(tester.terminalState, containsText('RECOVERED_OVERLAY'));
          });
        },
      );
    });

    group('Stack with multiple positioned children and LayoutBuilder', () {
      test('all positioned children visible with LayoutBuilder', () async {
        await testNocterm('multiple positioned children', (tester) async {
          await tester.pumpComponent(
            Stack(
              children: [
                // Background with LayoutBuilder
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        children: [for (int i = 0; i < 3; i++) Text('Row $i')],
                      );
                    },
                  ),
                ),
                // Multiple positioned overlays
                Positioned(left: 2, top: 1, child: Text('TOP_LEFT')),
                Positioned(right: 2, top: 1, child: Text('TOP_RIGHT')),
                Center(child: Text('CENTER')),
                Positioned(left: 2, bottom: 1, child: Text('BOTTOM_LEFT')),
              ],
            ),
          );

          expect(tester.terminalState, containsText('Row 0'));
          expect(tester.terminalState, containsText('TOP_LEFT'));
          expect(tester.terminalState, containsText('TOP_RIGHT'));
          expect(tester.terminalState, containsText('CENTER'));
          expect(tester.terminalState, containsText('BOTTOM_LEFT'));
        });
      });
    });
  });
}

// Helper components for testing

/// A stack with togglable grid content in LayoutBuilder
class _TogglableGridStack extends StatelessComponent {
  final bool showGrid;

  const _TogglableGridStack({required this.showGrid});

  @override
  Component build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (showGrid) {
                // Create a large widget tree (the problematic case)
                return Column(
                  children: [
                    for (int row = 0; row < 10; row++)
                      Row(
                        children: [
                          for (int col = 0; col < 5; col++)
                            Container(
                              width: 8,
                              height: 1,
                              child: Text('[$row,$col]'),
                            ),
                        ],
                      ),
                  ],
                );
              } else {
                // Simple, small widget
                return const SizedBox(width: 1, height: 1);
              }
            },
          ),
        ),
        // This is the foreground that should ALWAYS be visible
        Center(
          child: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.white),
            ),
            padding: const EdgeInsets.all(1),
            child: const Text('CENTERED_TEXT'),
          ),
        ),
      ],
    );
  }
}

/// A stateful version for testing state-triggered transitions
class _StatefulGridToggle extends StatefulComponent {
  const _StatefulGridToggle();

  @override
  State<_StatefulGridToggle> createState() => _StatefulGridToggleState();
}

class _StatefulGridToggleState extends State<_StatefulGridToggle> {
  bool _showGrid = false;

  void toggleGrid() {
    setState(() {
      _showGrid = !_showGrid;
    });
  }

  @override
  Component build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_showGrid) {
                return Column(
                  children: [
                    for (int row = 0; row < 8; row++)
                      Row(
                        children: [
                          for (int col = 0; col < 6; col++)
                            SizedBox(width: 6, child: Text('[$row]')),
                        ],
                      ),
                  ],
                );
              } else {
                return const SizedBox();
              }
            },
          ),
        ),
        Center(
          child: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.cyan),
              color: const Color.fromRGB(0, 50, 100),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: const Text('FOREGROUND_LABEL'),
          ),
        ),
      ],
    );
  }
}
