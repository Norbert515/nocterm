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
  final projHash = sha256
      .convert(utf8.encode(proj))
      .toString()
      .substring(0, 16);

  // Return path: ~/.nocterm/<hash>/
  return p.join(home, '.nocterm', projHash);
}

String getProjectDirectory() {
  var parent = Directory.current;
  while (true) {
    final newParent = parent.parent;

    if (newParent == parent) {
      throw StateError('Could not determine project directory');
    }

    final pubspec = File(p.join(parent.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      return parent.path;
    }
    if (newParent.path == '/') {
      return '/';
    }

    parent = newParent;
  }
}

/// Get the path to the log_port file for the current directory.
String getLogPortPath() {
  return p.join(getNoctermDirectory(), 'log_port');
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
