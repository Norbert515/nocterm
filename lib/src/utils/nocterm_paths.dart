import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Get the global nocterm directory for the current working directory.
///
/// Returns a path like: `~/.nocterm/<hash-of-cwd>/`
///
/// This ensures each project gets its own isolated directory in the global
/// nocterm storage, avoiding pollution of the user's project directory.
String getNoctermDirectory() {
  // Get home directory
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null) {
    throw StateError('Could not determine home directory');
  }

  // Get current working directory and create a hash
  final proj = getProjectDirectory();
  final projHash =
      sha256.convert(utf8.encode(proj)).toString().substring(0, 16);

  // Return path: ~/.nocterm/<hash>/
  return p.join(home, '.nocterm', projHash);
}

/// The closest ancestor of [from] holding a `pubspec.yaml`, or [from]
/// itself when no ancestor has one.
///
/// [from] defaults to the process's current directory. Pass it explicitly
/// to avoid depending on that: `Directory.current` is process-wide rather
/// than per-isolate, so a caller that sets it races with every other
/// isolate in the process.
String getProjectDirectory({Directory? from}) {
  final origin = from ?? Directory.current;
  final start = origin.path;
  var parent = origin;
  while (true) {
    final pubspec = File(p.join(parent.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) return parent.path;

    final newParent = parent.parent;
    // Compare paths, not Directory identity — terminates at Windows drive
    // roots where parent.parent returns the same path.
    if (newParent.path == parent.path) return start;
    parent = newParent;
  }
}

/// Get the path to the log_port file for a specific PID.
String getLogPortPathForPid(int pid) {
  return p.join(getNoctermDirectory(), 'log_port.$pid');
}

/// Get the path to the log_port file for the current process.
String getLogPortPath() {
  return getLogPortPathForPid(pid);
}

/// List all log_port files in the nocterm directory.
/// Returns list of (pid, path) records.
Future<List<({int pid, String path})>> listLogPortFiles() async {
  final dir = Directory(getNoctermDirectory());
  if (!await dir.exists()) return [];

  final files = <({int pid, String path})>[];
  await for (final entity in dir.list()) {
    if (entity is File) {
      final name = p.basename(entity.path);
      if (name.startsWith('log_port.')) {
        final pidStr = name.substring('log_port.'.length);
        final parsedPid = int.tryParse(pidStr);
        if (parsedPid != null) {
          files.add((pid: parsedPid, path: entity.path));
        }
      }
    }
  }
  return files;
}

/// Get the path to the shell_handle file for the current directory.
String getShellHandlePath() {
  return p.join(getNoctermDirectory(), 'shell_handle');
}

/// Get the path to the shell socket file for the current directory.
String getShellSocketPath() {
  return p.join(getNoctermDirectory(), 'shell.sock');
}

/// Ensure the nocterm directory exists for the current working directory.
Future<void> ensureNoctermDirectoryExists() async {
  final dir = Directory(getNoctermDirectory());
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}
