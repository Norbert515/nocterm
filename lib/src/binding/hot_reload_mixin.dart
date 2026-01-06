import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:hotreloader/hotreloader.dart';

import '../foundation/nocterm_error.dart';
import '../framework/framework.dart';

/// Mixin that adds hot reload support to TUI bindings
mixin HotReloadBinding on NoctermBinding {
  HotReloader? _reloader;

  /// Initialize hot reload support
  ///
  /// This should only be called in development mode
  Future<void> initializeHotReload() async {
    if (_reloader != null) return;
    print('executableArguments: ${Platform.executableArguments}');

    // Only enable hot reload if we're running with --enable-vm-service
    // This is automatically set when running with `dart run --enable-vm-service`
    final bool vmServiceEnabled = Platform.executableArguments.any(
      (arg) =>
          arg.contains('--enable-vm-service') ||
          arg.contains('--observe') ||
          arg.contains('--enable-asserts'),
    );

    if (!vmServiceEnabled) {
      print(
        '[HotReload] VM service not enabled. Run with --enable-vm-service to enable hot reload.',
      );
      return;
    }

    try {
      // Get and print VM service info
      try {
        final info = await Service.getInfo();
        if (info.serverUri != null) {
          if (info.serverWebSocketUri != null) {
            print(
              '[HotReload] DevTools URL: ${info.serverUri}devtools/?uri=${info.serverWebSocketUri}',
            );
          }
        }
      } catch (e) {
        // Service.getInfo might not be available in all environments
        print('[HotReload] Could not retrieve VM service URL: $e');
      }

      _reloader = await HotReloader.create(
        automaticReload: true,
        debounceInterval: Duration(milliseconds: 100),
        onBeforeReload: (ctx) {
          // Log the file that triggered the reload
          if (ctx.event case final event?) {
            print('[HotReload] Change detected: ${event.path}');
          }
          return true;
        },
        onAfterReload: (ctx) {
          switch (ctx.result) {
            case HotReloadResult.Failed:
              NoctermError.reportError(
                NoctermErrorDetails(
                  exception: Exception('Compilation error during hot reload'),
                  library: 'nocterm hot reload',
                  context: 'during hot reload compilation',
                ),
              );
            case HotReloadResult.Succeeded:
              // Trigger reassemble after successful reload
              _performReassembleAfterReload();
            case HotReloadResult.PartiallySucceeded:
              print('[HotReload] Hot reload partially succeeded');
            case HotReloadResult.Skipped:
              print('[HotReload] Hot reload skipped');
          }
        },
      );
    } catch (e, stack) {
      print('[HotReload] Failed to initialize hot reload: $e');
      print('[HotReload] Stack trace: $stack');
    }
  }

  /// Perform reassemble after a successful hot reload
  void _performReassembleAfterReload() {
    // Use a microtask to ensure the VM has finished updating
    scheduleMicrotask(() async {
      try {
        print('[HotReload] Reassembling application...');
        await performReassemble();
        print('[HotReload] Application reassembled successfully');
      } catch (e, stack) {
        NoctermError.reportError(
          NoctermErrorDetails(
            exception: e,
            stack: stack,
            library: 'nocterm hot reload',
            context: 'during reassemble',
          ),
        );
      }
    });
  }

  /// Stop hot reload support
  void stopHotReload() {
    _reloader?.stop();
    _reloader = null;
  }

  /// Override shutdown to cleanup hot reload
  void shutdownWithHotReload() {
    stopHotReload();
  }
}
