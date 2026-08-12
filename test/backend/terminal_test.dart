import 'dart:async';

import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  test('restoreColors terminates each OSC sequence', () {
    final backend = _RecordingBackend();
    final terminal = Terminal(backend);

    terminal.restoreColors();

    expect(
      backend.output.toString(),
      '\x1b]110\x1b\x5c\x1b]111\x1b\x5c',
    );
  });
}

class _RecordingBackend implements TerminalBackend {
  final output = StringBuffer();

  @override
  void writeRaw(String data) => output.write(data);

  @override
  Size getSize() => const Size(80, 24);

  @override
  bool get supportsSize => true;

  @override
  Stream<List<int>>? get inputStream => null;

  @override
  Stream<Size>? get resizeStream => null;

  @override
  Stream<void>? get shutdownStream => null;

  @override
  void enableRawMode() {}

  @override
  void disableRawMode() {}

  @override
  bool get isAvailable => true;

  @override
  void notifySizeChanged(Size newSize) {}

  @override
  void requestExit([int exitCode = 0]) {}

  @override
  void dispose() {}
}
