import 'dart:async';
import 'dart:io';

import 'package:nocterm/nocterm.dart'
    hide StdioBackend, SocketBackend, WebBackend;
import 'package:nocterm/src/backend/socket_backend.dart';
import 'package:nocterm/src/backend/stdio_backend.dart';
import 'package:nocterm/src/backend/terminal.dart' as term;

(File?, bool) _useShellMode() {
  // Check for shell mode
  final shellHandleFile = File(getShellHandlePath());
  if (shellHandleFile.existsSync() case false) {
    return (null, false);
  }

  final socketPath = shellHandleFile.readAsStringSync().trim();
  if (socketPath.isEmpty) {
    return (null, false);
  }

  if (File(socketPath).existsSync()) {
    return (shellHandleFile, true);
  }

  return (null, false);
}

/// Run a TUI application on native platforms (Linux, macOS, Windows).
Future<void> runAppImpl(Component app, {bool enableHotReload = true}) async {
  if (_useShellMode() case (final file?, true)) {
    await _runAppInShellMode(app, file, enableHotReload);
  } else {
    await _runAppNormalMode(app, enableHotReload);
  }
}

Future<void> _runAppNormalMode(Component app, bool enableHotReload) async {
  TerminalBinding? binding;
  LogServer? logServer;
  Logger? logger;

  try {
    // Start log server
    logServer = LogServer();
    try {
      await logServer.start();
      logger = Logger(logServer: logServer);
    } catch (e) {
      stderr.writeln('Failed to start log server: $e');
    }

    await runZoned(
      () async {
        final backend = StdioBackend();
        final terminal = term.Terminal(backend);
        binding = TerminalBinding(terminal);

        binding!.initialize();
        binding!.attachRootComponent(app);

        if (enableHotReload && !bool.fromEnvironment('dart.vm.product')) {
          await binding!.initializeHotReload();
        }

        await binding!.runEventLoop();
      },
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String message) {
          logger?.log(message);
        },
        handleUncaughtError:
            (
              Zone self,
              ZoneDelegate parent,
              Zone zone,
              Object error,
              StackTrace stackTrace,
            ) {
              logger?.log('ERROR: $error\n$stackTrace');
            },
      ),
    );
  } catch (e) {
    // Handle signal-based exit
  } finally {
    if (binding != null && !binding!.shouldExit) {
      binding!.shutdown();
    }
    try {
      await logger?.close();
      await logServer?.close();
    } catch (_) {}
  }
}

Future<void> _runAppInShellMode(
  Component app,
  File shellHandleFile,
  bool enableHotReload,
) async {
  TerminalBinding? binding;
  LogServer? logServer;
  Logger? logger;

  try {
    logServer = LogServer();
    try {
      await logServer.start();
      logger = Logger(logServer: logServer);
    } catch (e) {
      stderr.writeln('Failed to start log server: $e');
    }

    final socketPath = await shellHandleFile.readAsString();
    final socket = await Socket.connect(
      InternetAddress(socketPath.trim(), type: InternetAddressType.unix),
      0,
    );

    await runZoned(
      () async {
        final backend = SocketBackend(socket);
        final terminal = term.Terminal(backend);
        binding = TerminalBinding(terminal);

        binding!.initialize();
        binding!.attachRootComponent(app);

        if (enableHotReload && !bool.fromEnvironment('dart.vm.product')) {
          await binding!.initializeHotReload();
        }

        await binding!.runEventLoop();
      },
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String message) {
          logger?.log(message);
          parent.print(zone, message);
        },
        handleUncaughtError:
            (
              Zone self,
              ZoneDelegate parent,
              Zone zone,
              Object error,
              StackTrace stackTrace,
            ) {
              final errorMessage = 'ERROR: $error\n$stackTrace';
              logger?.log(errorMessage);
              stderr.writeln(errorMessage);
            },
      ),
    );
  } catch (e) {
    stderr.writeln('Shell mode error: $e');
  } finally {
    if (binding != null && !binding!.shouldExit) {
      binding!.shutdown();
    }
    try {
      await logger?.close();
      await logServer?.close();
    } catch (_) {}
  }
}
