import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

/// Regression test for ProxyElement slot passing bug.
///
/// Bug description: ProxyElement (parent of ParentDataElement, used by Positioned)
/// was not passing the parent slot to child elements when updating children.
/// This caused render objects to be inserted at the wrong position in multi-child
/// containers like Stack when the child of a Positioned changed.
///
/// Root cause: ProxyElement.mount() and update() were passing `null` as the slot
/// to updateChild() instead of passing through `this.slot`.
///
/// Fix: Changed to pass `slot` instead of `null`:
///   _child = updateChild(_child, component.child, slot);
void main() {
  group('ProxyElement slot passing regression tests', () {
    group('Positioned child replacement in Stack', () {
      test('foreground stays on top when Positioned child changes', () async {
        await testNocterm('positioned child replacement', (tester) async {
          // Initial state with SizedBox as background
          await tester.pumpComponent(_PositionedChildSwap(useAlternate: false));

          // Foreground should be visible
          expect(tester.terminalState, containsText('FOREGROUND'));

          // Switch to alternate child (Container with text)
          await tester.pumpComponent(_PositionedChildSwap(useAlternate: true));

          // CRITICAL: Foreground MUST still be on top (visible over background)
          expect(tester.terminalState, containsText('FOREGROUND'));
          expect(tester.terminalState, containsText('BACKGROUND_ALT'));
        });
      });

      test('multiple Positioned children maintain correct order', () async {
        await testNocterm('multiple positioned order', (tester) async {
          await tester.pumpComponent(const _MultiPositionedStack());

          final state = tester.findState<_MultiPositionedStackState>();

          // Initial: all three visible
          expect(tester.terminalState, containsText('BOTTOM'));
          expect(tester.terminalState, containsText('MIDDLE'));
          expect(tester.terminalState, containsText('TOP'));

          // Toggle bottom - should not affect order of others
          state.toggleBottom();
          await tester.pump();

          expect(tester.terminalState, containsText('BOTTOM_ALT'));
          expect(tester.terminalState, containsText('MIDDLE'));
          expect(tester.terminalState, containsText('TOP'));

          // Toggle middle
          state.toggleMiddle();
          await tester.pump();

          expect(tester.terminalState, containsText('BOTTOM_ALT'));
          expect(tester.terminalState, containsText('MIDDLE_ALT'));
          expect(tester.terminalState, containsText('TOP'));
        });
      });

      test('stateful toggle preserves child order', () async {
        await testNocterm('stateful positioned toggle', (tester) async {
          await tester.pumpComponent(const _StatefulPositionedToggle());

          final state = tester.findState<_StatefulPositionedToggleState>();

          // Toggle multiple times
          for (int i = 0; i < 5; i++) {
            state.toggle();
            await tester.pump();

            // TOP must always be visible (on top)
            expect(
              tester.terminalState,
              containsText('TOP_LABEL'),
              reason: 'TOP_LABEL must be visible after toggle $i',
            );
          }
        });
      });
    });

    group('Nested ProxyElements', () {
      test('deeply nested Positioned maintains order', () async {
        await testNocterm('nested positioned', (tester) async {
          // Test with nested InheritedComponent -> Positioned -> child
          await tester.pumpComponent(
            Stack(
              children: [
                Positioned.fill(
                  child: _ThemeWrapper(child: const Text('NESTED_BG')),
                ),
                Center(child: Text('NESTED_FG')),
              ],
            ),
          );

          expect(tester.terminalState, containsText('NESTED_BG'));
          expect(tester.terminalState, containsText('NESTED_FG'));
        });
      });
    });

    group('ParentData preservation', () {
      test('Positioned parent data survives child replacement', () async {
        await testNocterm('parent data preservation', (tester) async {
          // Initial positioned at specific location
          await tester.pumpComponent(
            SizedBox(
              width: 80,
              height: 24,
              child: Stack(
                children: [
                  Positioned(left: 5, top: 2, child: Text('POSITIONED_A')),
                  Center(child: Text('CENTER')),
                ],
              ),
            ),
          );

          expect(tester.terminalState, containsText('POSITIONED_A'));
          expect(tester.terminalState, containsText('CENTER'));

          // Replace the positioned child
          await tester.pumpComponent(
            SizedBox(
              width: 80,
              height: 24,
              child: Stack(
                children: [
                  Positioned(left: 5, top: 2, child: Text('POSITIONED_B')),
                  Center(child: Text('CENTER')),
                ],
              ),
            ),
          );

          // Both should still be visible with correct positioning
          expect(tester.terminalState, containsText('POSITIONED_B'));
          expect(tester.terminalState, containsText('CENTER'));
        });
      });
    });
  });
}

// Test helper components

class _PositionedChildSwap extends StatelessComponent {
  final bool useAlternate;

  const _PositionedChildSwap({required this.useAlternate});

  @override
  Component build(BuildContext context) {
    return Stack(
      children: [
        // Background - this changes
        Positioned.fill(
          child: useAlternate
              ? Container(
                  color: const Color.fromRGB(50, 50, 50),
                  child: const Text('BACKGROUND_ALT'),
                )
              : const SizedBox(),
        ),
        // Foreground - must always be on top
        Center(
          child: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.white),
            ),
            child: const Text('FOREGROUND'),
          ),
        ),
      ],
    );
  }
}

class _MultiPositionedStack extends StatefulComponent {
  const _MultiPositionedStack();

  @override
  State<_MultiPositionedStack> createState() => _MultiPositionedStackState();
}

class _MultiPositionedStackState extends State<_MultiPositionedStack> {
  bool _bottomAlt = false;
  bool _middleAlt = false;

  void toggleBottom() => setState(() => _bottomAlt = !_bottomAlt);
  void toggleMiddle() => setState(() => _middleAlt = !_middleAlt);

  @override
  Component build(BuildContext context) {
    return Stack(
      children: [
        // Bottom layer - positioned at top-left
        Positioned(
          left: 0,
          top: 0,
          child: _bottomAlt ? const Text('BOTTOM_ALT') : const Text('BOTTOM'),
        ),
        // Middle layer - positioned at top-left line 1
        Positioned(
          left: 0,
          top: 1,
          child: _middleAlt ? const Text('MIDDLE_ALT') : const Text('MIDDLE'),
        ),
        // Top layer - never changes, centered
        Center(child: Text('TOP')),
      ],
    );
  }
}

class _StatefulPositionedToggle extends StatefulComponent {
  const _StatefulPositionedToggle();

  @override
  State<_StatefulPositionedToggle> createState() =>
      _StatefulPositionedToggleState();
}

class _StatefulPositionedToggleState extends State<_StatefulPositionedToggle> {
  bool _showLarge = false;

  void toggle() => setState(() => _showLarge = !_showLarge);

  @override
  Component build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _showLarge
              ? Column(children: [for (int i = 0; i < 5; i++) Text('Row $i')])
              : const SizedBox(),
        ),
        Center(
          child: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.cyan),
            ),
            child: const Text('TOP_LABEL'),
          ),
        ),
      ],
    );
  }
}

/// Simple wrapper to test nested ProxyElements
class _ThemeWrapper extends StatelessComponent {
  final Component child;

  const _ThemeWrapper({required this.child});

  @override
  Component build(BuildContext context) {
    return child;
  }
}
