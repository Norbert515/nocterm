/// Benchmark to measure the performance of the rendering system.
///
/// Run with: dart run benchmark/display_list_benchmark.dart
library;

import 'package:characters/characters.dart';
import 'package:nocterm/src/buffer.dart';
import 'package:nocterm/src/framework/framework.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import 'package:nocterm/src/rectangle.dart';
import 'package:nocterm/src/style.dart';
import 'package:nocterm/src/utils/unicode_width.dart';

/// Number of iterations for each benchmark
const int iterations = 1000;

/// Terminal sizes for testing
const terminalWidth = 80;
const terminalHeight = 24;

void main() {
  print('Rendering System Benchmark');
  print('==========================');
  print('Iterations per test: $iterations');
  print('Terminal size: ${terminalWidth}x$terminalHeight');
  print('');

  _runCellWidthCachingBenchmark();
  print('');
  _runBufferDiffBenchmarks();
  print('');
  _runDirectPaintingBenchmark();
  print('');
  _runFullRenderPipelineBenchmark();
}

void _runCellWidthCachingBenchmark() {
  print('Test: Cell Width Caching');
  print('------------------------');

  // Test strings with various character types
  final testStrings = [
    'Hello World', // ASCII
    '你好世界', // Chinese (wide chars)
    '🎉🚀✨', // Emoji
    'Mixed 混合 🎯', // Mixed
  ];

  // Without caching - compute width every time
  final swUncached = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    for (final str in testStrings) {
      for (final grapheme in str.characters) {
        // Simulate what happens without caching - compute each time
        UnicodeWidth.graphemeWidth(grapheme);
      }
    }
  }
  swUncached.stop();
  final uncachedMs = swUncached.elapsedMicroseconds / iterations / 1000;

  // With caching - use Cell.width getter
  final cells = <Cell>[];
  for (final str in testStrings) {
    for (final grapheme in str.characters) {
      cells.add(Cell(char: grapheme));
    }
  }

  // Warm up the cache
  for (final cell in cells) {
    cell.width;
  }

  final swCached = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    for (final cell in cells) {
      cell.width; // Uses cached value
    }
  }
  swCached.stop();
  final cachedMs = swCached.elapsedMicroseconds / iterations / 1000;

  print('  Without caching: ${uncachedMs.toStringAsFixed(3)}ms');
  print('  With caching:    ${cachedMs.toStringAsFixed(3)}ms');
  if (cachedMs > 0) {
    print('  Speedup:         ${(uncachedMs / cachedMs).toStringAsFixed(1)}x');
  } else {
    print('  Speedup:         (cached too fast to measure)');
  }
}

void _runBufferDiffBenchmarks() {
  print('Test: Buffer Differential Rendering');
  print('------------------------------------');

  final style = TextStyle(
    color: Color.fromRGB(255, 255, 255),
    backgroundColor: Color.fromRGB(0, 0, 0),
  );

  // Test different change percentages
  for (final changePercent in [1, 10, 50, 100]) {
    final buffer = Buffer(terminalWidth, terminalHeight);
    final previousBuffer = Buffer(terminalWidth, terminalHeight);

    // Initialize both buffers with same content
    for (int y = 0; y < terminalHeight; y++) {
      for (int x = 0; x < terminalWidth; x++) {
        final char = String.fromCharCode((x + y) % 26 + 65);
        previousBuffer.setCell(x, y, Cell(char: char, style: style));
        buffer.setCell(x, y, Cell(char: char, style: style));
      }
    }

    // Modify specified percentage of cells
    final totalCells = terminalWidth * terminalHeight;
    final cellsToChange = (totalCells * changePercent / 100).toInt();
    for (int i = 0; i < cellsToChange; i++) {
      final x = i % terminalWidth;
      final y = i ~/ terminalWidth;
      buffer.setCell(x, y, Cell(char: '@', style: style));
    }

    // Measure diff time
    int changedCount = 0;
    final sw = Stopwatch()..start();
    for (int iter = 0; iter < iterations; iter++) {
      changedCount = 0;
      for (int y = 0; y < terminalHeight; y++) {
        for (int x = 0; x < terminalWidth; x++) {
          if (buffer.getCell(x, y) != previousBuffer.getCell(x, y)) {
            changedCount++;
          }
        }
      }
    }
    sw.stop();
    final avgMs = sw.elapsedMicroseconds / iterations / 1000;
    print(
      '  $changePercent% changed ($changedCount cells): ${avgMs.toStringAsFixed(3)}ms',
    );
  }
}

void _runDirectPaintingBenchmark() {
  print('Test: Direct Painting to Buffer');
  print('-------------------------------');

  final screenRect = Rect.fromLTWH(
    0,
    0,
    terminalWidth.toDouble(),
    terminalHeight.toDouble(),
  );

  for (final opCount in [10, 100, 1000]) {
    final buffer = Buffer(terminalWidth, terminalHeight);
    final canvas = TerminalCanvas(buffer, screenRect);

    final style = TextStyle(
      color: Color.fromRGB(255, 255, 255),
      backgroundColor: Color.fromRGB(0, 0, 0),
    );

    final sw = Stopwatch()..start();
    for (int iter = 0; iter < iterations; iter++) {
      for (int i = 0; i < opCount; i++) {
        final x = (i * 7) % terminalWidth;
        final y = (i * 3) % terminalHeight;

        switch (i % 3) {
          case 0:
            canvas.drawText(
              Offset(x.toDouble(), y.toDouble()),
              'Text$i',
              style: style,
            );
            break;
          case 1:
            canvas.fillRect(
              Rect.fromLTWH(x.toDouble(), y.toDouble(), 5, 1),
              '#',
              style: style,
            );
            break;
          case 2:
            canvas.drawBox(
              Rect.fromLTWH(x.toDouble(), y.toDouble(), 3, 2),
              border: BorderStyle.single,
              style: style,
            );
            break;
        }
      }
    }
    sw.stop();
    final avgMs = sw.elapsedMicroseconds / iterations / 1000;
    print('  $opCount operations: ${avgMs.toStringAsFixed(3)}ms');
  }
}

void _runFullRenderPipelineBenchmark() {
  print('Test: Full Render Pipeline (Paint + Diff)');
  print('-----------------------------------------');

  final screenRect = Rect.fromLTWH(
    0,
    0,
    terminalWidth.toDouble(),
    terminalHeight.toDouble(),
  );

  final style = TextStyle(
    color: Color.fromRGB(255, 255, 255),
    backgroundColor: Color.fromRGB(0, 0, 0),
  );

  // Simulate a typical frame with 100 paint operations
  const opCount = 100;

  // Create a "previous" buffer (simulating last frame)
  final previousBuffer = Buffer(terminalWidth, terminalHeight);
  {
    final canvas = TerminalCanvas(previousBuffer, screenRect);
    for (int i = 0; i < opCount; i++) {
      final x = (i * 7) % terminalWidth;
      final y = (i * 3) % terminalHeight;
      canvas.drawText(
        Offset(x.toDouble(), y.toDouble()),
        'Item$i',
        style: style,
      );
    }
  }

  // Measure full pipeline: paint to new buffer + diff with previous
  final sw = Stopwatch()..start();
  for (int iter = 0; iter < iterations; iter++) {
    // 1. Paint phase
    final buffer = Buffer(terminalWidth, terminalHeight);
    final canvas = TerminalCanvas(buffer, screenRect);

    for (int i = 0; i < opCount; i++) {
      final x = (i * 7) % terminalWidth;
      final y = (i * 3) % terminalHeight;
      // Simulate small changes (10% modified)
      final text = i < 10 ? 'Mod$i' : 'Item$i';
      canvas.drawText(Offset(x.toDouble(), y.toDouble()), text, style: style);
    }

    // 2. Diff phase
    int changedCells = 0;
    for (int y = 0; y < terminalHeight; y++) {
      for (int x = 0; x < terminalWidth; x++) {
        if (buffer.getCell(x, y) != previousBuffer.getCell(x, y)) {
          changedCells++;
        }
      }
    }

    // Prevent dead code elimination
    assert(changedCells >= 0);
  }
  sw.stop();
  final avgMs = sw.elapsedMicroseconds / iterations / 1000;

  print('  100 ops, 10% changed: ${avgMs.toStringAsFixed(3)}ms');
  print('');
  print('Summary: Simpler immediate-mode rendering');
  print('  - Paint directly to buffer (no DisplayList)');
  print('  - Cell-by-cell diff with previous buffer');
  print('  - Cell width cached for fast comparisons');
}
