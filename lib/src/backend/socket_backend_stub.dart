// Stub file for web platforms.
// The actual implementation is in socket_backend.dart (IO only).

import 'dart:async';

import 'package:nocterm/src/size.dart';

import 'terminal_backend.dart';

/// Stub SocketBackend for web platforms.
/// This class exists so that code can reference SocketBackend without
/// conditional imports, but it will throw if actually used on web.
class SocketBackend implements TerminalBackend {
  SocketBackend(dynamic socket, {Size? initialSize}) {
    throw UnsupportedError(
      'SocketBackend is only available on native platforms',
    );
  }

  void updateSize(Size newSize) {
    throw UnsupportedError(
      'SocketBackend is only available on native platforms',
    );
  }

  @override
  void writeRaw(String data) {
    throw UnsupportedError(
      'SocketBackend is only available on native platforms',
    );
  }

  @override
  Size getSize() {
    throw UnsupportedError(
      'SocketBackend is only available on native platforms',
    );
  }

  @override
  bool get supportsSize => throw UnsupportedError(
    'SocketBackend is only available on native platforms',
  );

  @override
  Stream<List<int>>? get inputStream => throw UnsupportedError(
    'SocketBackend is only available on native platforms',
  );

  @override
  Stream<Size>? get resizeStream => throw UnsupportedError(
    'SocketBackend is only available on native platforms',
  );

  @override
  Stream<void>? get shutdownStream => throw UnsupportedError(
    'SocketBackend is only available on native platforms',
  );

  @override
  void enableRawMode() {
    throw UnsupportedError(
      'SocketBackend is only available on native platforms',
    );
  }

  @override
  void disableRawMode() {
    throw UnsupportedError(
      'SocketBackend is only available on native platforms',
    );
  }

  @override
  bool get isAvailable => throw UnsupportedError(
    'SocketBackend is only available on native platforms',
  );

  @override
  void notifySizeChanged(Size newSize) {
    throw UnsupportedError(
      'SocketBackend is only available on native platforms',
    );
  }

  @override
  void requestExit([int exitCode = 0]) {
    throw UnsupportedError(
      'SocketBackend is only available on native platforms',
    );
  }

  @override
  void dispose() {
    throw UnsupportedError(
      'SocketBackend is only available on native platforms',
    );
  }
}
