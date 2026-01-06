import 'package:nocterm/nocterm.dart';
import 'package:nocterm_riverpod/nocterm_riverpod.dart';
import 'package:test/test.dart';

void main() {
  test('Riverpod integration - basic read and overrides', () async {
    // Define providers
    final nameProvider = Provider<String>((ref) => 'Nocterm');
    final greetingProvider = Provider<String>((ref) {
      final name = ref.watch(nameProvider);
      return 'Hello, $name!';
    });

    await testNocterm('riverpod basic functionality', (tester) async {
      // Test 1: Basic provider read
      await tester.pumpComponent(
        ProviderScope(
          child: _SimpleBuilder(
            builder: (context) {
              final greeting = context.read(greetingProvider);
              return Text(greeting);
            },
          ),
        ),
      );

      expect(tester.terminalState, containsText('Hello, Nocterm!'));

      // Test 2: Provider overrides
      await tester.pumpComponent(
        ProviderScope(
          overrides: [nameProvider.overrideWith((ref) => 'Riverpod')],
          child: _SimpleBuilder(
            builder: (context) {
              final greeting = context.read(greetingProvider);
              return Text(greeting);
            },
          ),
        ),
      );

      expect(tester.terminalState, containsText('Hello, Riverpod!'));
    });
  });

  test('Riverpod integration - nested scopes', () async {
    final colorProvider = Provider<String>((ref) => 'blue');

    await testNocterm('nested provider scopes', (tester) async {
      await tester.pumpComponent(
        ProviderScope(
          child: Column(
            children: [
              _SimpleBuilder(
                builder: (context) {
                  final color = context.read(colorProvider);
                  return Text('Outer: $color');
                },
              ),
              ProviderScope(
                overrides: [colorProvider.overrideWith((ref) => 'red')],
                child: _SimpleBuilder(
                  builder: (context) {
                    final color = context.read(colorProvider);
                    return Text('Inner: $color');
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(tester.terminalState, containsText('Outer: blue'));
      expect(tester.terminalState, containsText('Inner: red'));
    });
  });

  test('Riverpod integration - multiple providers', () async {
    final userProvider = Provider<String>((ref) => 'Alice');
    final ageProvider = Provider<int>((ref) => 30);
    final profileProvider = Provider<String>((ref) {
      final user = ref.watch(userProvider);
      final age = ref.watch(ageProvider);
      return '$user is $age years old';
    });

    await testNocterm('multiple providers', (tester) async {
      await tester.pumpComponent(
        ProviderScope(
          child: _SimpleBuilder(
            builder: (context) {
              final profile = context.read(profileProvider);
              return Text(profile);
            },
          ),
        ),
      );

      expect(tester.terminalState, containsText('Alice is 30 years old'));
    });
  });
}

// Helper component
class _SimpleBuilder extends StatelessComponent {
  const _SimpleBuilder({required this.builder});

  final ComponentBuilder builder;

  @override
  Component build(BuildContext context) {
    return builder(context);
  }
}
