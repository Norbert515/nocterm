import 'package:nocterm/nocterm.dart';
import 'package:nocterm_riverpod/nocterm_riverpod.dart';
import 'package:test/test.dart';

void main() {
  test('Watch triggers rebuild on provider change', () async {
    final counterProvider = StateProvider<int>((ref) => 0);

    await testNocterm('watch rebuild test', (tester) async {
      await tester.pumpComponent(
        ProviderScope(child: _TestWidget(counterProvider: counterProvider)),
      );

      // Initial state
      expect(tester.terminalState, containsText('Count: 0'));
      print('[TEST] Initial render complete');

      // Trigger provider change
      print('[TEST] Incrementing counter...');
      await tester.sendKey(LogicalKey.arrowUp);

      // Give time for async operations
      await Future.delayed(Duration(milliseconds: 100));
      await tester.pump();

      print('[TEST] After pump, checking state...');
      // Check if rebuild happened
      expect(tester.terminalState, containsText('Count: 1'));
    });
  });
}

class _TestWidget extends StatelessComponent {
  const _TestWidget({required this.counterProvider});

  final StateProvider<int> counterProvider;

  @override
  Component build(BuildContext context) {
    print('[WIDGET] Building widget...');
    final count = context.watch(counterProvider);
    print('[WIDGET] Watch returned: $count');

    return Column(
      children: [
        Text('Count: $count'),
        KeyboardListener(
          onKeyEvent: (key) {
            if (key == LogicalKey.arrowUp) {
              print('[WIDGET] Incrementing provider state...');
              context.read(counterProvider.notifier).state++;
            }
            return false;
          },
          child: const Text('Press up to increment'),
        ),
      ],
    );
  }
}
