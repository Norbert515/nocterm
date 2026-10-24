import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// POSIX helper that disables ICRNL in termios [c_iflag] so that Enter
/// (CR, 0x0D) and Ctrl+J (LF, 0x0A) remain distinct bytes in raw mode.
///
/// This does NOT use cfmakeraw (which would also clear OPOST and break output).
/// It only touches the ICRNL bit in c_iflag.
///
/// On non-POSIX platforms or when no tty is attached, operations are no-ops.
class PosixRawInput {
  static const int _icrnl = 0x100;
  static const int _tcsanow = 0;
  static DynamicLibrary? _lib;
  static int? _savedCIfLag;
  static bool _disabled = false;

  static DynamicLibrary _resolveLib() {
    if (_lib != null) return _lib!;
    try {
      _lib = DynamicLibrary.process();
    } on Exception {
      if (Platform.isLinux) {
        _lib = DynamicLibrary.open('libc.so.6');
      } else {
        rethrow;
      }
    }
    return _lib!;
  }

  static int _cIfLagSize() {
    if (Platform.isMacOS) return 8; // unsigned long
    if (Platform.isLinux) return 4; // unsigned int
    return 0;
  }

  /// Disables ICRNL in c_iflag for stdin (fd 0).
  ///
  /// Returns true if the flag was successfully cleared.
  /// Returns false if the platform is not POSIX, stdin has no terminal,
  /// or any system call fails.
  static bool disableIcrnl() {
    if (_disabled) return false;
    if (!Platform.isLinux && !Platform.isMacOS) return false;
    if (!stdin.hasTerminal) return false;

    try {
      final lib = _resolveLib();
      final tcgetattr = lib.lookupFunction<
          Int32 Function(Int32 fd, Pointer<Void> termios_p),
          int Function(int fd, Pointer<Void> termios_p)>('tcgetattr');
      final tcsetattr = lib.lookupFunction<
          Int32 Function(
              Int32 fd, Int32 optional_actions, Pointer<Void> termios_p),
          int Function(int fd, int optional_actions,
              Pointer<Void> termios_p)>('tcsetattr');

      final buf = calloc<Uint8>(256);
      try {
        if (tcgetattr(0, buf.cast()) != 0) return false;

        final size = _cIfLagSize();
        if (size == 0) return false;

        final cIfLag =
            size == 8 ? buf.cast<Uint64>().value : buf.cast<Uint32>().value;

        _savedCIfLag = cIfLag;

        final newCIfLag = cIfLag & ~_icrnl;
        if (size == 8) {
          buf.cast<Uint64>().value = newCIfLag;
        } else {
          buf.cast<Uint32>().value = newCIfLag;
        }

        if (tcsetattr(0, _tcsanow, buf.cast()) != 0) {
          _savedCIfLag = null;
          return false;
        }

        _disabled = true;
        return true;
      } finally {
        calloc.free(buf);
      }
    } on Exception {
      return false;
    }
  }

  /// Restores the previously saved [c_iflag] value for stdin (fd 0).
  ///
  /// Safe to call multiple times or without a prior successful [disableIcrnl].
  static void restoreIcrnl() {
    if (!_disabled || _savedCIfLag == null) return;

    try {
      final lib = _resolveLib();
      final tcgetattr = lib.lookupFunction<
          Int32 Function(Int32 fd, Pointer<Void> termios_p),
          int Function(int fd, Pointer<Void> termios_p)>('tcgetattr');
      final tcsetattr = lib.lookupFunction<
          Int32 Function(
              Int32 fd, Int32 optional_actions, Pointer<Void> termios_p),
          int Function(int fd, int optional_actions,
              Pointer<Void> termios_p)>('tcsetattr');

      final buf = calloc<Uint8>(256);
      try {
        if (tcgetattr(0, buf.cast()) != 0) return;

        final size = _cIfLagSize();
        if (size == 0) return;

        if (size == 8) {
          buf.cast<Uint64>().value = _savedCIfLag!;
        } else {
          buf.cast<Uint32>().value = _savedCIfLag!;
        }

        tcsetattr(0, _tcsanow, buf.cast());
      } finally {
        calloc.free(buf);
      }
    } on Exception {
      // ignore
    } finally {
      _disabled = false;
      _savedCIfLag = null;
    }
  }
}
