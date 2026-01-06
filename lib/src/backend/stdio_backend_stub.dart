// Stub file for web platforms.
// The actual implementation is in stdio_backend.dart (IO only).

import 'dart:async';

import 'package:nocterm/src/size.dart';

import 'terminal_backend.dart';

/// Stub StdioBackend for web platforms.
/// This class exists so that code can reference StdioBackend without
/// conditional imports, but it will throw if actually used on web.
class StdioBackend implements TerminalBackend {
  StdioBackend() {
    throw UnsupportedError(
      'StdioBackend is only available on native platforms',
    );
  }

  @override
  void writeRaw(String data) {
    throw UnsupportedError(
      'StdioBackend is only available on native platforms',
    );
  }

  @override
  Size getSize() {
    throw UnsupportedError(
      'StdioBackend is only available on native platforms',
    );
  }

  @override
  bool get supportsSize => throw UnsupportedError(
    'StdioBackend is only available on native platforms',
  );

  @override
  Stream<List<int>>? get inputStream => throw UnsupportedError(
    'StdioBackend is only available on native platforms',
  );

  @override
  Stream<Size>? get resizeStream => throw UnsupportedError(
    'StdioBackend is only available on native platforms',
  );

  @override
  Stream<void>? get shutdownStream => throw UnsupportedError(
    'StdioBackend is only available on native platforms',
  );

  @override
  void enableRawMode() {
    throw UnsupportedError(
      'StdioBackend is only available on native platforms',
    );
  }

  @override
  void disableRawMode() {
    throw UnsupportedError(
      'StdioBackend is only available on native platforms',
    );
  }

  @override
  bool get isAvailable => throw UnsupportedError(
    'StdioBackend is only available on native platforms',
  );

  @override
  void notifySizeChanged(Size newSize) {
    throw UnsupportedError(
      'StdioBackend is only available on native platforms',
    );
  }

  @override
  void requestExit([int exitCode = 0]) {
    throw UnsupportedError(
      'StdioBackend is only available on native platforms',
    );
  }

  @override
  void dispose() {
    throw UnsupportedError(
      'StdioBackend is only available on native platforms',
    );
  }
}
