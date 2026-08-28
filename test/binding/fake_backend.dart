import 'dart:async';

import 'package:nocterm/src/backend/terminal_backend.dart';
import 'package:nocterm/src/size.dart';

/// A backend whose input we drive and whose exit we can observe.
///
/// Deliberately has no [shutdownStream]: these tests are about the path
/// taken when no SIGINT ever arrives.
class FakeBackend implements TerminalBackend {
  final _input = StreamController<List<int>>.broadcast();
  final output = StringBuffer();

  int? exitCode;
  bool get exitRequested => exitCode != null;

  void sendBytes(List<int> bytes) => _input.add(bytes);

  @override
  Stream<List<int>>? get inputStream => _input.stream;

  @override
  void requestExit([int exitCode = 0]) => this.exitCode = exitCode;

  @override
  void writeRaw(String data) => output.write(data);

  @override
  Size getSize() => const Size(40, 10);

  @override
  bool get supportsSize => true;

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
  void dispose() => _input.close();
}
