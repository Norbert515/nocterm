import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

class _Base {
  int baseValue = 0;
}

/// Uses [ChangeNotifier] as a mixin, like Flutter allows.
class _MixedInNotifier extends _Base with ChangeNotifier {
  void increment() {
    baseValue++;
    notifyListeners();
  }
}

class _ExtendedNotifier extends ChangeNotifier {
  void fire() => notifyListeners();
}

void main() {
  group('ChangeNotifier', () {
    test('can be mixed in', () {
      final notifier = _MixedInNotifier();
      var calls = 0;
      void listener() => calls++;

      notifier.addListener(listener);
      notifier.increment();
      expect(calls, 1);
      expect(notifier.baseValue, 1);

      notifier.removeListener(listener);
      notifier.increment();
      expect(calls, 1);
    });

    test('can still be extended', () {
      final notifier = _ExtendedNotifier();
      var calls = 0;
      notifier.addListener(() => calls++);

      notifier.fire();
      expect(calls, 1);

      notifier.dispose();
      notifier.fire();
      expect(calls, 1);
    });
  });
}
