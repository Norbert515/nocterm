import 'package:nocterm/nocterm.dart';
import 'package:nocterm_riverpod/nocterm_riverpod.dart';
import 'package:test/test.dart';

// Simple provider test to verify basic functionality
void main() {
  test('Basic Riverpod integration works', () async {
    final provider = Provider<String>((ref) => 'Hello from Riverpod!');

    await testNocterm('basic provider read', (tester) async {
      await tester.pumpComponent(
        ProviderScope(
          child: StatelessBuilder(
            builder: (context) {
              // Use read for now - watch needs more complex integration
              final value = context.read(provider);
              return Text(value);
            },
          ),
        ),
      );

      expect(tester.terminalState, containsText('Hello from Riverpod!'));
    });
  });

  test('StateProvider can be modified', () async {
    final counterProvider = StateProvider<int>((ref) => 0);

    await testNocterm('state provider modification', (tester) async {
      await tester.pumpComponent(
        ProviderScope(
          child: StatefulBuilder(
            builder: (context, setState) {
              // Re-read the provider on each build
              final count = context.read(counterProvider);

              return Column(
                children: [
                  Text('Count: $count'),
                  KeyboardListener(
                    onKeyEvent: (key) {
                      if (key == LogicalKey.arrowUp) {
                        context.read(counterProvider.notifier).state++;
                        setState(() {}); // Manually trigger rebuild
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

      // Initial state
      expect(tester.terminalState, containsText('Count: 0'));

      // Increment
      await tester.sendKey(LogicalKey.arrowUp);
      await tester.pump();
      expect(tester.terminalState, containsText('Count: 1'));
    });
  });

  test('Provider overrides work', () async {
    final greetingProvider = Provider<String>((ref) => 'Default');

    await testNocterm('provider override', (tester) async {
      await tester.pumpComponent(
        ProviderScope(
          overrides: [greetingProvider.overrideWith((ref) => 'Overridden!')],
          child: StatelessBuilder(
            builder: (context) {
              final value = context.read(greetingProvider);
              return Text(value);
            },
          ),
        ),
      );

      expect(tester.terminalState, containsText('Overridden!'));
    });
  });
}

// Helper components
class StatelessBuilder extends StatelessComponent {
  const StatelessBuilder({super.key, required this.builder});

  final ComponentBuilder builder;

  @override
  Component build(BuildContext context) {
    return builder(context);
  }
}

class StatefulBuilder extends StatefulComponent {
  const StatefulBuilder({super.key, required this.builder});

  final Component Function(BuildContext, StateSetter) builder;

  @override
  State<StatefulBuilder> createState() => _StatefulBuilderState();
}

class _StatefulBuilderState extends State<StatefulBuilder> {
  @override
  Component build(BuildContext context) {
    return component.builder(context, setState);
  }
}
