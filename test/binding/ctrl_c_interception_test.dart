import 'dart:async';

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/backend/terminal.dart' as term;
import 'package:test/test.dart';

import 'fake_backend.dart';

/// A component that swallows every key it is given.
class _KeySink extends StatelessComponent {
  const _KeySink({required this.onKey});

  final bool Function(KeyboardEvent) onKey;

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: onKey,
      child: const SizedBox.shrink(),
    );
  }
}

/// The cases where Ctrl+C must *not* end the app.
///
/// These share one binding, which they can because none of them shuts down -
/// a TerminalBinding registers VM service extensions that cannot be undone,
/// so only one can exist per isolate. The shutdown case lives in
/// ctrl_c_shutdown_test.dart for the same reason.
void main() {
  late FakeBackend backend;
  late TerminalBinding binding;

  setUpAll(() {
    backend = FakeBackend();
    binding = TerminalBinding(term.Terminal(backend, size: const Size(40, 10)));
    binding.initialize();
  });

  tearDownAll(() {
    backend.dispose();
    NoctermBinding.resetInstance();
  });

  Future<void> settle() => Future.delayed(const Duration(milliseconds: 20));

  test(
      'Given a component that handles Ctrl+C '
      'when it arrives then the app keeps running', () async {
    var seen = 0;
    binding.attachRootComponent(_KeySink(onKey: (_) {
      seen++;
      return true;
    }));
    await settle();

    backend.sendBytes('\x1b[99;5u'.codeUnits);
    await settle();

    expect(seen, greaterThan(0), reason: 'the component should see the key');
    expect(backend.exitRequested, isFalse);
  });

  test(
      'Given Ctrl+Shift+C '
      'when it arrives then the app keeps running', () async {
    // Terminals bind Ctrl+Shift+C to copy. Under the kitty protocol it is
    // modifier 6 rather than 5, so the two are distinguishable.
    binding.attachRootComponent(const SizedBox.shrink());
    await settle();

    backend.sendBytes('\x1b[99;6u'.codeUnits);
    await settle();

    expect(backend.exitRequested, isFalse);
  });
}
