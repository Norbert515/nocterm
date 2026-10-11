import 'dart:async';

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/backend/terminal.dart' as term;
import 'package:test/test.dart';

import 'fake_backend.dart';

/// The binding pushes the kitty keyboard protocol at startup, so a terminal
/// that supports it reports Ctrl+C as `ESC[99;5u` rather than the raw 0x03
/// byte. The tty raises SIGINT only for the byte, so there is no signal to
/// fall back on: this path is the app's only notice that the user asked to
/// quit, and it has to shut down on its own.
///
/// Only one test here: a TerminalBinding registers VM service extensions,
/// which cannot be unregistered, so a second binding in the same isolate
/// throws - and shutting down cancels the input subscription, so a binding
/// cannot serve two shutdown tests either. The cases that must *not* shut
/// down share one binding in ctrl_c_interception_test.dart.
void main() {
  test(
      'Given a terminal reporting Ctrl+C as an escape sequence '
      'when nothing handles it then the app exits', () async {
    final backend = FakeBackend();
    final binding =
        TerminalBinding(term.Terminal(backend, size: const Size(40, 10)));
    addTearDown(() {
      backend.dispose();
      NoctermBinding.resetInstance();
    });

    binding.initialize();
    binding.attachRootComponent(const SizedBox.shrink());

    backend.sendBytes('\x1b[99;5u'.codeUnits);
    await Future.delayed(const Duration(milliseconds: 20));

    expect(backend.exitRequested, isTrue);
    expect(backend.exitCode, equals(0));
  });
}
