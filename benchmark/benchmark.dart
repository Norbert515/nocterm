/// Nocterm benchmark suite.
///
/// Run with: dart run benchmark/benchmark.dart [filter]
/// Examples:
///   dart run benchmark/benchmark.dart              # Run all, compare to baseline
///   dart run benchmark/benchmark.dart --save        # Run all, save as new baseline
///   dart run benchmark/benchmark.dart buffer        # Only Buffer & Cell suite
///   dart run benchmark/benchmark.dart --save buffer # Save baseline for Buffer only
///   dart run benchmark/benchmark.dart --ci          # Markdown output for CI comments
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/utils/unicode_width.dart';

// ---------------------------------------------------------------------------
// Benchmark infrastructure
// ---------------------------------------------------------------------------

class BenchmarkResult {
  final String name;
  final int iterations;
  final List<double> samplesUs; // microseconds per iteration

  BenchmarkResult(this.name, this.iterations, this.samplesUs);

  double get medianUs {
    final sorted = List<double>.from(samplesUs)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isEven) {
      return (sorted[mid - 1] + sorted[mid]) / 2;
    }
    return sorted[mid];
  }

  double get minUs => samplesUs.reduce(math.min);
  double get maxUs => samplesUs.reduce(math.max);

  String _fmtMs(double us) {
    final ms = us / 1000;
    if (ms >= 100) return '${ms.toStringAsFixed(0)}ms';
    if (ms >= 10) return '${ms.toStringAsFixed(1)}ms';
    return '${ms.toStringAsFixed(3)}ms';
  }

  String get medianStr => _fmtMs(medianUs);
  String get minStr => _fmtMs(minUs);
  String get maxStr => _fmtMs(maxUs);
}

typedef SyncBenchmarkFn = void Function();
typedef AsyncBenchmarkFn = Future<void> Function();

class Benchmark {
  final String name;
  final int warmup;
  final int iterations;
  final int samples;
  final SyncBenchmarkFn? syncFn;
  final AsyncBenchmarkFn? asyncFn;
  final AsyncBenchmarkFn? setup;
  final AsyncBenchmarkFn? teardown;

  Benchmark.sync(
    this.name,
    this.syncFn, {
    this.warmup = 100,
    this.iterations = 1000,
    this.samples = 10,
    this.setup,
    this.teardown,
  }) : asyncFn = null;

  Benchmark.async(
    this.name,
    this.asyncFn, {
    this.warmup = 10,
    this.iterations = 100,
    this.samples = 10,
    this.setup,
    this.teardown,
  }) : syncFn = null;

  Future<BenchmarkResult> run() async {
    if (setup != null) await setup!();

    // Warmup
    if (syncFn != null) {
      for (int i = 0; i < warmup; i++) {
        syncFn!();
      }
    } else {
      for (int i = 0; i < warmup; i++) {
        await asyncFn!();
      }
    }

    // Collect samples
    final sampleResults = <double>[];
    for (int s = 0; s < samples; s++) {
      final sw = Stopwatch()..start();
      if (syncFn != null) {
        for (int i = 0; i < iterations; i++) {
          syncFn!();
        }
      } else {
        for (int i = 0; i < iterations; i++) {
          await asyncFn!();
        }
      }
      sw.stop();
      sampleResults.add(sw.elapsedMicroseconds / iterations);
    }

    if (teardown != null) await teardown!();

    return BenchmarkResult(name, iterations, sampleResults);
  }
}

class BenchmarkSuite {
  final String name;
  final List<Benchmark> benchmarks;

  BenchmarkSuite(this.name, this.benchmarks);

  Future<List<BenchmarkResult>> run() async {
    final results = <BenchmarkResult>[];
    for (final bench in benchmarks) {
      results.add(await bench.run());
    }
    return results;
  }
}

// ---------------------------------------------------------------------------
// Baseline support
// ---------------------------------------------------------------------------

const _baselinePath = 'benchmark/baseline.json';

/// Key for a benchmark result in the baseline file: "suite/name"
String _baselineKey(String suite, String name) => '$suite/$name';

Map<String, double> loadBaseline() {
  final file = File(_baselinePath);
  if (!file.existsSync()) return {};
  try {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return json.map((k, v) => MapEntry(k, (v as num).toDouble()));
  } catch (_) {
    return {};
  }
}

void saveBaseline(Map<String, double> baseline) {
  final file = File(_baselinePath);
  final encoder = JsonEncoder.withIndent('  ');
  // Sort keys for stable output
  final sorted = Map.fromEntries(
    baseline.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  file.writeAsStringSync('${encoder.convert(sorted)}\n');
}

String _deltaStr(double currentUs, double? baselineUs) {
  if (baselineUs == null) return '';
  if (baselineUs == 0) return '';
  final pct = ((currentUs - baselineUs) / baselineUs * 100);
  final sign = pct >= 0 ? '+' : '';
  final pctStr = '$sign${pct.toStringAsFixed(0)}%';
  // Color: green for faster (negative), red for slower (positive), dim for noise
  if (pct.abs() < 5) return '\x1b[2m$pctStr\x1b[0m'; // dim = noise
  if (pct < 0) return '\x1b[32m$pctStr\x1b[0m'; // green = faster
  return '\x1b[31m$pctStr\x1b[0m'; // red = slower
}

void printSuiteResults(
  String suiteName,
  List<BenchmarkResult> results,
  Map<String, double> baseline,
) {
  final hasBaseline = baseline.isNotEmpty;
  const nameWidth = 48;
  const colWidth = 10;
  const deltaWidth = 10;

  // Header
  var header = '${suiteName.padRight(nameWidth)}'
      '${'median'.padLeft(colWidth)}'
      '${'min'.padLeft(colWidth)}'
      '${'max'.padLeft(colWidth)}'
      '  iters';
  if (hasBaseline) header += 'vs base'.padLeft(deltaWidth);
  print(header);
  print('─' * (nameWidth + colWidth * 3 + 8 + (hasBaseline ? deltaWidth : 0)));

  // Results
  for (final r in results) {
    final key = _baselineKey(suiteName, r.name);
    final baseMedian = baseline[key];
    var line = '${r.name.padRight(nameWidth)}'
        '${r.medianStr.padLeft(colWidth)}'
        '${r.minStr.padLeft(colWidth)}'
        '${r.maxStr.padLeft(colWidth)}'
        '  x${r.iterations}';
    if (hasBaseline) {
      final delta = _deltaStr(r.medianUs, baseMedian);
      // Pad accounting for ANSI codes (they take space in the string but not on screen)
      final visibleLen = delta.replaceAll(RegExp(r'\x1b\[[0-9;]*m'), '').length;
      line += delta.padLeft(deltaWidth + (delta.length - visibleLen));
    }
    print(line);
  }
}

// ---------------------------------------------------------------------------
// CI markdown output
// ---------------------------------------------------------------------------

String _deltaIcon(double currentUs, double? baselineUs) {
  if (baselineUs == null || baselineUs == 0) return '';
  final pct = ((currentUs - baselineUs) / baselineUs * 100);
  final sign = pct >= 0 ? '+' : '';
  final pctStr = '$sign${pct.toStringAsFixed(0)}%';
  if (pct.abs() < 5) return pctStr;
  if (pct < 0) return '$pctStr :arrow_down:';
  return '$pctStr :arrow_up:';
}

String markdownSuiteResults(
  String suiteName,
  List<BenchmarkResult> results,
  Map<String, double> baseline,
) {
  final hasBaseline = baseline.isNotEmpty;
  final buf = StringBuffer();

  buf.writeln('#### $suiteName');
  buf.writeln();

  if (hasBaseline) {
    buf.writeln('| Benchmark | Median | Min | Max | vs main |');
    buf.writeln('|-----------|-------:|----:|----:|--------:|');
  } else {
    buf.writeln('| Benchmark | Median | Min | Max |');
    buf.writeln('|-----------|-------:|----:|----:|');
  }

  for (final r in results) {
    final key = _baselineKey(suiteName, r.name);
    final baseMedian = baseline[key];
    if (hasBaseline) {
      final delta = _deltaIcon(r.medianUs, baseMedian);
      buf.writeln(
          '| ${r.name} | ${r.medianStr} | ${r.minStr} | ${r.maxStr} | $delta |');
    } else {
      buf.writeln('| ${r.name} | ${r.medianStr} | ${r.minStr} | ${r.maxStr} |');
    }
  }

  return buf.toString();
}

// ---------------------------------------------------------------------------
// Suite 1: Buffer & Cell
// ---------------------------------------------------------------------------

BenchmarkSuite bufferSuite() {
  final style = TextStyle(
    color: Color.fromRGB(255, 255, 255),
    backgroundColor: Color.fromRGB(0, 0, 0),
  );
  final style2 = TextStyle(
    color: Color.fromRGB(200, 100, 50),
    backgroundColor: Color.fromRGB(10, 20, 30),
  );

  return BenchmarkSuite('Buffer & Cell', [
    // Buffer allocation
    Benchmark.sync('Buffer allocation (80x24)', () {
      Buffer(80, 24);
    }),
    Benchmark.sync('Buffer allocation (200x50)', () {
      Buffer(200, 50);
    }),

    // Cell equality
    () {
      final cell1 = Cell(char: 'A', style: style);
      final cell2 = Cell(char: 'A', style: style);
      return Benchmark.sync('Cell equality (same)', () {
        cell1 == cell2;
      });
    }(),
    () {
      final cell1 = Cell(char: 'A', style: style);
      final cell3 = Cell(char: 'B', style: style2);
      return Benchmark.sync('Cell equality (different)', () {
        cell1 == cell3;
      });
    }(),

    // Cell width caching
    () {
      final testStrings = ['Hello World', '你好世界', '🎉🚀✨', 'Mixed 混合 🎯'];
      return Benchmark.sync(
        'Cell width (uncached)',
        () {
          for (final str in testStrings) {
            for (final grapheme in str.characters) {
              UnicodeWidth.graphemeWidth(grapheme);
            }
          }
        },
      );
    }(),
    () {
      final testStrings = ['Hello World', '你好世界', '🎉🚀✨', 'Mixed 混合 🎯'];
      final cells = <Cell>[];
      for (final str in testStrings) {
        for (final grapheme in str.characters) {
          cells.add(Cell(char: grapheme));
        }
      }
      // Prime the cache
      for (final cell in cells) {
        cell.width;
      }
      return Benchmark.sync(
        'Cell width (cached)',
        () {
          for (final cell in cells) {
            cell.width;
          }
        },
      );
    }(),

    // Buffer diff at various change rates
    for (final changePercent in [1, 10, 50, 100])
      () {
        final buffer = Buffer(80, 24);
        final previousBuffer = Buffer(80, 24);

        // Initialize both with same content
        for (int y = 0; y < 24; y++) {
          for (int x = 0; x < 80; x++) {
            final char = String.fromCharCode((x + y) % 26 + 65);
            previousBuffer.setCell(x, y, Cell(char: char, style: style));
            buffer.setCell(x, y, Cell(char: char, style: style));
          }
        }

        // Modify specified percentage
        final cellsToChange = (80 * 24 * changePercent / 100).toInt();
        for (int i = 0; i < cellsToChange; i++) {
          buffer.setCell(i % 80, i ~/ 80, Cell(char: '@', style: style));
        }

        return Benchmark.sync(
          'Buffer diff ($changePercent% changed, 80x24)',
          () {
            int count = 0;
            for (int y = 0; y < 24; y++) {
              for (int x = 0; x < 80; x++) {
                if (buffer.getCell(x, y) != previousBuffer.getCell(x, y)) {
                  count++;
                }
              }
            }
            // Prevent dead-code elimination
            assert(count >= 0);
          },
        );
      }(),
  ]);
}

// ---------------------------------------------------------------------------
// Suite 2: Canvas & Painting
// ---------------------------------------------------------------------------

BenchmarkSuite canvasSuite() {
  final style = TextStyle(
    color: Color.fromRGB(255, 255, 255),
    backgroundColor: Color.fromRGB(0, 0, 0),
  );

  final screenRect = Rect.fromLTWH(0, 0, 80, 24);

  return BenchmarkSuite('Canvas & Painting', [
    // drawText throughput
    Benchmark.sync('drawText (100 calls, 80x24)', () {
      final buffer = Buffer(80, 24);
      final canvas = TerminalCanvas(buffer, screenRect);
      for (int i = 0; i < 100; i++) {
        final x = (i * 7) % 80;
        final y = (i * 3) % 24;
        canvas.drawText(Offset(x.toDouble(), y.toDouble()), 'Text$i',
            style: style);
      }
    }),

    // fillRect throughput
    Benchmark.sync('fillRect (100 calls, 80x24)', () {
      final buffer = Buffer(80, 24);
      final canvas = TerminalCanvas(buffer, screenRect);
      for (int i = 0; i < 100; i++) {
        final x = (i * 7) % 75;
        final y = (i * 3) % 22;
        canvas.fillRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 5, 2),
          '#',
          style: style,
        );
      }
    }),

    // drawBox throughput
    Benchmark.sync('drawBox (50 calls, 80x24)', () {
      final buffer = Buffer(80, 24);
      final canvas = TerminalCanvas(buffer, screenRect);
      for (int i = 0; i < 50; i++) {
        final x = (i * 7) % 75;
        final y = (i * 3) % 20;
        canvas.drawBox(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 5, 3),
          border: BorderStyle.single,
          style: style,
        );
      }
    }),

    // Full paint + diff pipeline
    () {
      final previousBuffer = Buffer(80, 24);
      {
        final canvas = TerminalCanvas(previousBuffer, screenRect);
        for (int i = 0; i < 100; i++) {
          final x = (i * 7) % 80;
          final y = (i * 3) % 24;
          canvas.drawText(Offset(x.toDouble(), y.toDouble()), 'Item$i',
              style: style);
        }
      }

      return Benchmark.sync(
        'Full paint + diff (100 ops, 10% changed)',
        () {
          final buffer = Buffer(80, 24);
          final canvas = TerminalCanvas(buffer, screenRect);

          for (int i = 0; i < 100; i++) {
            final x = (i * 7) % 80;
            final y = (i * 3) % 24;
            final text = i < 10 ? 'Mod$i' : 'Item$i';
            canvas.drawText(Offset(x.toDouble(), y.toDouble()), text,
                style: style);
          }

          int count = 0;
          for (int y = 0; y < 24; y++) {
            for (int x = 0; x < 80; x++) {
              if (buffer.getCell(x, y) != previousBuffer.getCell(x, y)) {
                count++;
              }
            }
          }
          assert(count >= 0);
        },
      );
    }(),
  ]);
}

// ---------------------------------------------------------------------------
// Suite 3: Widget Pipeline
// ---------------------------------------------------------------------------

BenchmarkSuite widgetPipelineSuite(String label, Size size) {
  NoctermTestBinding? binding;

  Benchmark widgetBench(
    String name,
    Component Function() buildWidget, {
    int warmup = 20,
    int iterations = 200,
    int samples = 10,
  }) {
    return Benchmark.async(
      name,
      () async {
        binding!.attachRootComponent(buildWidget());
        await binding!.pump();
      },
      warmup: warmup,
      iterations: iterations,
      samples: samples,
      setup: () async {
        binding = NoctermTestBinding(size: size);
      },
      teardown: () async {
        binding?.shutdown();
        binding = null;
      },
    );
  }

  return BenchmarkSuite('Widget Pipeline ($label)', [
    // Single Text widget
    widgetBench(
      'Text widget',
      () => Text('Hello, benchmark world!'),
    ),

    // Column with 10 Text children
    widgetBench(
      'Column with 10 Text children',
      () => Column(
        children: List.generate(10, (i) => Text('Row $i: some content')),
      ),
    ),

    // Nested Containers (5 deep)
    widgetBench(
      'Nested Containers (5 deep)',
      () {
        Component child = Text('inner');
        for (int i = 0; i < 5; i++) {
          child = Container(
            padding: EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.solid),
            ),
            child: child,
          );
        }
        return child;
      },
    ),

    // Row with 8 children
    widgetBench(
      'Row with 8 children',
      () => Row(
        children: List.generate(
          8,
          (i) => Expanded(child: Text('C$i')),
        ),
      ),
    ),

    // ListView with 100 items
    widgetBench(
      'ListView.builder (100 items)',
      () => ListView.builder(
        itemCount: 100,
        itemBuilder: (context, index) => Text('Item $index: description'),
      ),
      iterations: 100,
    ),

    // Stack with overlapping children
    widgetBench(
      'Stack with 5 positioned children',
      () => Stack(
        children: List.generate(
          5,
          (i) => Positioned(
            top: i * 2,
            left: i * 4,
            child: Text('Layer $i'),
          ),
        ),
      ),
    ),

    // setState rebuild
    () {
      NoctermTestBinding? stateBinding;
      _RebuildCounter? counter;

      return Benchmark.async(
        'setState rebuild cycle',
        () async {
          counter!.trigger();
          await stateBinding!.pump();
        },
        warmup: 20,
        iterations: 200,
        samples: 10,
        setup: () async {
          stateBinding = NoctermTestBinding(size: size);
          final widget = _RebuildCounterWidget();
          stateBinding!.attachRootComponent(widget);
          await stateBinding!.pump();
          // Find the state
          counter = _findState<_RebuildCounter>(stateBinding!.rootElement!);
        },
        teardown: () async {
          stateBinding?.shutdown();
          stateBinding = null;
          counter = null;
        },
      );
    }(),
  ]);
}

// Helper widget for setState benchmark
class _RebuildCounterWidget extends StatefulComponent {
  @override
  State<_RebuildCounterWidget> createState() => _RebuildCounter();
}

class _RebuildCounter extends State<_RebuildCounterWidget> {
  int _count = 0;

  void trigger() {
    setState(() {
      _count++;
    });
  }

  @override
  Component build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (i) => Text('Item $i count=$_count'),
      ),
    );
  }
}

T? _findState<T extends State>(Element element) {
  if (element is StatefulElement && element.state is T) {
    return element.state as T;
  }
  T? result;
  element.visitChildren((child) {
    result ??= _findState<T>(child);
  });
  return result;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main(List<String> args) async {
  final mutableArgs = List<String>.from(args);
  final save = mutableArgs.remove('--save');
  final ci = mutableArgs.remove('--ci');
  final filter =
      mutableArgs.isNotEmpty ? mutableArgs.first.toLowerCase() : null;

  final suites = <BenchmarkSuite>[
    bufferSuite(),
    canvasSuite(),
    widgetPipelineSuite('80x24', const Size(80, 24)),
    widgetPipelineSuite('200x50', const Size(200, 50)),
  ];

  final baseline = loadBaseline();

  if (!ci) {
    print('');
    print('nocterm benchmark suite');
    print('========================');
    if (baseline.isNotEmpty && !save) {
      print('Comparing against baseline (${baseline.length} benchmarks)');
    }
    if (save) {
      print('Will save results as new baseline');
    }
    print('');
  }

  final totalSw = Stopwatch()..start();
  int suitesRun = 0;
  final newBaseline = Map<String, double>.from(baseline);
  final markdownParts = <String>[];

  for (final suite in suites) {
    if (filter != null && !suite.name.toLowerCase().contains(filter)) {
      continue;
    }

    final results = await suite.run();

    if (ci) {
      markdownParts.add(markdownSuiteResults(suite.name, results, baseline));
    } else {
      printSuiteResults(suite.name, results, save ? {} : baseline);
      print('');
    }
    suitesRun++;

    // Collect results for baseline
    for (final r in results) {
      newBaseline[_baselineKey(suite.name, r.name)] = r.medianUs;
    }
  }

  totalSw.stop();

  if (suitesRun == 0) {
    print('No suites matched filter "$filter".');
    print('Available suites:');
    for (final s in suites) {
      print('  - ${s.name}');
    }
  } else {
    if (save) {
      saveBaseline(newBaseline);
      if (!ci) {
        print(
            'Baseline saved to $_baselinePath (${newBaseline.length} benchmarks)');
      }
    }
    if (ci) {
      // Write markdown to file for CI to pick up
      final md = StringBuffer();
      md.writeln('### Benchmark Results');
      md.writeln();
      if (baseline.isNotEmpty) {
        md.writeln('Comparing against `main` baseline.');
        md.writeln();
      }
      for (final part in markdownParts) {
        md.writeln(part);
      }
      final totalSec = totalSw.elapsedMilliseconds / 1000;
      md.writeln('*Completed in ${totalSec.toStringAsFixed(1)}s*');
      final mdFile = File('benchmark/results.md');
      mdFile.writeAsStringSync(md.toString());
      print('Markdown results written to benchmark/results.md');
    } else {
      final totalSec = totalSw.elapsedMilliseconds / 1000;
      print('Done in ${totalSec.toStringAsFixed(1)}s ($suitesRun suites)');
    }
  }
}
