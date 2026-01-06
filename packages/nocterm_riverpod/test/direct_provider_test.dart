import 'package:nocterm/nocterm.dart';
import 'package:nocterm_riverpod/nocterm_riverpod.dart';
import 'package:test/test.dart';

void main() {
  test('Direct provider modification triggers watch', () async {
    final counterProvider = StateProvider<int>((ref) => 0);
    int buildCount = 0;

    await testNocterm('direct provider test', (tester) async {
      late ProviderContainer container;

      await tester.pumpComponent(
        ProviderScope(
          child: Builder(
            builder: (context) {
              // Store the container for later use
              container = ProviderScope.containerOf(context, listen: false);

              buildCount++;
              print('[BUILD] Build #$buildCount');
              final count = context.watch(counterProvider);
              print('[BUILD] Count value: $count');

              return Text('Count: $count, Builds: $buildCount');
            },
          ),
        ),
      );

      // Initial state
      print('[TEST] Initial state check');
      expect(buildCount, 1);
      expect(tester.terminalState, containsText('Count: 0, Builds: 1'));

      // Directly modify the provider through the container
      print('[TEST] Modifying provider directly...');
      container.read(counterProvider.notifier).state = 1;

      // Give time for the subscription callback to fire
      await Future.delayed(Duration(milliseconds: 100));

      // Force a frame
      print('[TEST] Pumping frame...');
      await tester.pump();

      // Check if rebuild happened
      print('[TEST] Final build count: $buildCount');
      expect(buildCount, 2, reason: 'Widget should have rebuilt');
      expect(tester.terminalState, containsText('Count: 1, Builds: 2'));
    });
  });
}

// Simple Builder widget for testing
class Builder extends StatelessComponent {
  const Builder({super.key, required this.builder});

  final ComponentBuilder builder;

  @override
  Component build(BuildContext context) => builder(context);
}
