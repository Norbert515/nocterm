import 'package:nocterm/nocterm.dart';
import 'package:nocterm_riverpod/nocterm_riverpod.dart';

// Define providers
final counterProvider = StateProvider<int>((ref) => 0);

final doubledProvider = Provider<int>((ref) {
  // This provider watches counterProvider and recomputes when it changes
  final count = ref.watch(counterProvider);
  return count * 2;
});

final messageProvider = Provider<String>((ref) {
  final count = ref.watch(counterProvider);
  if (count == 0) return 'Start counting!';
  if (count < 5) return 'Keep going!';
  if (count < 10) return 'Nice progress!';
  return 'Wow, you\'re on fire! 🔥';
});

void main() {
  runApp(ProviderScope(child: const CounterApp()));
}

class CounterApp extends StatelessComponent {
  const CounterApp({super.key});

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Text(
            'nocterm_riverpod Counter Demo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2),
          CounterDisplay(),
          SizedBox(height: 1),
          DoubledDisplay(),
          SizedBox(height: 1),
          MessageDisplay(),
          SizedBox(height: 2),
          CounterControls(),
          SizedBox(height: 2),
          Instructions(),
        ],
      ),
    );
  }
}

/// Displays the current counter value using context.watch
class CounterDisplay extends StatelessComponent {
  const CounterDisplay({super.key});

  @override
  Component build(BuildContext context) {
    // This will automatically rebuild when counterProvider changes
    final count = context.watch(counterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(border: BoxBorder.all(color: Colors.cyan)),
      child: Text(
        'Counter: $count',
        style: const TextStyle(color: Colors.cyan),
      ),
    );
  }
}

/// Displays the doubled value using a computed provider
class DoubledDisplay extends StatelessComponent {
  const DoubledDisplay({super.key});

  @override
  Component build(BuildContext context) {
    // Watches the computed provider which depends on counterProvider
    final doubled = context.watch(doubledProvider);

    return Text(
      'Doubled: $doubled',
      style: const TextStyle(color: Colors.green),
    );
  }
}

/// Displays a message based on the counter value
class MessageDisplay extends StatelessComponent {
  const MessageDisplay({super.key});

  @override
  Component build(BuildContext context) {
    final message = context.watch(messageProvider);

    return Text(message, style: const TextStyle(color: Colors.yellow));
  }
}

/// Controls for modifying the counter
class CounterControls extends StatelessComponent {
  const CounterControls({super.key});

  @override
  Component build(BuildContext context) {
    return KeyboardListener(
      onKeyEvent: (key) {
        if (key == LogicalKey.add) {
          context.read(counterProvider.notifier).state++;
        } else if (key == LogicalKey.minus) {
          context.read(counterProvider.notifier).state--;
        } else if (key == LogicalKey.keyR) {
          context.read(counterProvider.notifier).state = 0;
        }
        return false;
      },
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(border: BoxBorder.all(color: Colors.blue)),
        child: const Text('Controls: [+] Increment, [-] Decrement, [R] Reset'),
      ),
    );
  }
}

class Instructions extends StatelessComponent {
  const Instructions({super.key});

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(border: BoxBorder.all(color: Colors.grey)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('• Use keyboard shortcuts to control the counter'),
          Text('• Press + to increment'),
          Text('• Press - to decrement'),
          Text('• Press r to reset'),
          Text(''),
          Text('Notice how all displays update automatically!'),
        ],
      ),
    );
  }
}
