import 'dart:async';

import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  test('differential renderer batches adjacent cells and tracks wide glyphs',
      () async {
    final backend = _CapturingBackend(const Size(12, 2));
    final binding = _TestTerminalBinding(Terminal(backend));
    late _MutableTextState state;

    binding.attachRootComponent(
      _MutableText(onStateCreated: (value) => state = value),
    );
    binding.pump();
    backend.clear();

    state.setText('BBBB');
    await Future<void>.delayed(FrameRate.fps30);

    final output = backend.output;
    expect(output, contains('BBBB'));
    expect(_cursorMoveCount(output), 1);

    backend.clear();

    state.setText('你C');
    await Future<void>.delayed(FrameRate.fps30);

    final wideOutput = backend.output;
    expect(wideOutput, contains('你C'));
    expect(_cursorMoveCount(wideOutput), 1);

    binding.shutdown();
  });
}

int _cursorMoveCount(String output) {
  return RegExp(r'\x1b\[\d+;\d+H').allMatches(output).length;
}

class _TestTerminalBinding extends TerminalBinding {
  _TestTerminalBinding(super.terminal);

  void pump() => executeFrame();
}

class _MutableText extends StatefulComponent {
  const _MutableText({required this.onStateCreated});

  final void Function(_MutableTextState) onStateCreated;

  @override
  State<_MutableText> createState() => _MutableTextState();
}

class _MutableTextState extends State<_MutableText> {
  String text = 'AAAA';

  @override
  void initState() {
    super.initState();
    component.onStateCreated(this);
  }

  void setText(String value) {
    setState(() => text = value);
  }

  @override
  Component build(BuildContext context) => Text(text);
}

class _CapturingBackend implements TerminalBackend {
  _CapturingBackend(this._size);

  final Size _size;
  final StringBuffer _output = StringBuffer();

  String get output => _output.toString();

  void clear() => _output.clear();

  @override
  void writeRaw(String data) => _output.write(data);

  @override
  Size getSize() => _size;

  @override
  bool get supportsSize => true;

  @override
  void notifySizeChanged(Size newSize) {}

  @override
  Stream<List<int>>? get inputStream => const Stream<List<int>>.empty();

  @override
  Stream<Size>? get resizeStream => null;

  @override
  Stream<void>? get shutdownStream => null;

  @override
  Stream<void>? get resumeStream => null;

  @override
  void enableRawMode() {}

  @override
  void disableRawMode() {}

  @override
  bool get isAvailable => true;

  @override
  void requestExit([int exitCode = 0]) {}

  @override
  void dispose() {}
}
