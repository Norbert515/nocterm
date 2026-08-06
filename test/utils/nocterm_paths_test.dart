import 'dart:io';

import 'package:nocterm/src/utils/nocterm_paths.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('getProjectDirectory', () {
    late Directory tempRoot;

    // Each test walks up from a directory it passes in rather than from the
    // process's current one. `Directory.current` is process-wide and not
    // per-isolate, so setting it here would race with every other test
    // running concurrently in the same process - including tests in other
    // files, which would then resolve their own relative paths against
    // whichever temp directory happened to win.
    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('nocterm_paths_test_');
    });

    tearDown(() {
      if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
    });

    test('returns the closest ancestor containing pubspec.yaml', () {
      final project = Directory(p.join(tempRoot.path, 'project'))..createSync();
      File(p.join(project.path, 'pubspec.yaml')).writeAsStringSync('name: x');
      final nested = Directory(p.join(project.path, 'a', 'b'))
        ..createSync(recursive: true);

      expect(getProjectDirectory(from: nested), equals(project.path));
    });

    test('returns the starting directory when no pubspec.yaml ancestor exists',
        () {
      final dir = Directory(p.join(tempRoot.path, 'a', 'b', 'c'))
        ..createSync(recursive: true);

      expect(getProjectDirectory(from: dir), equals(dir.path));
    });

    test('terminates when walking past the filesystem root', () {
      final dir = Directory(p.join(tempRoot.path, 'deep', 'no', 'project'))
        ..createSync(recursive: true);

      expect(getProjectDirectory(from: dir), equals(dir.path));
    });

    test('defaults to the current directory', () {
      // The default path still has to work - this project has a pubspec.
      expect(getProjectDirectory(), isNotEmpty);
      expect(
        File(p.join(getProjectDirectory(), 'pubspec.yaml')).existsSync(),
        isTrue,
      );
    });
  });
}
