import 'dart:async';
import 'dart:io';

import 'package:nocterm/src/size.dart';

import 'terminal_backend.dart';

/// Backend for shell mode - communicates via Unix socket.
/// Size updates come via OSC 9999 sequences in the input stream.
class SocketBackend implements TerminalBackend {
  final Socket _socket;
  Size _size;
  final StreamController<Size> _resizeController =
      StreamController<Size>.broadcast();
  bool _disposed = false;

  SocketBackend(this._socket, {Size? initialSize})
    : _size = initialSize ?? const Size(80, 24);

  @override
  void writeRaw(String data) {
    if (!_disposed) {
      _socket.write(data);
    }
  }

  @override
  Size getSize() => _size;

  @override
  void notifySizeChanged(Size newSize) {
    _size = newSize;
    if (!_disposed) {
      _resizeController.add(newSize);
    }
  }

  @override
  bool get supportsSize => true;

  @override
  Stream<List<int>>? get inputStream => _socket;

  @override
  Stream<Size>? get resizeStream => _resizeController.stream;

  @override
  Stream<void>? get shutdownStream => null; // Socket closure handled differently

  @override
  void enableRawMode() {
    // No-op: socket doesn't have raw mode
  }

  @override
  void disableRawMode() {
    // No-op: socket doesn't have raw mode
  }

  @override
  bool get isAvailable => !_disposed;

  @override
  void requestExit([int exitCode = 0]) {
    // In shell mode, we don't call exit() - just close the socket
    dispose();
  }

  @override
  void dispose() {
    _disposed = true;
    _resizeController.close();
    try {
      _socket.close();
    } catch (_) {}
  }
}
