import 'dart:developer' as developer;

/// Performance tracking utilities inspired by Flutter's FlutterTimeline.
///
/// Provides low-overhead performance measurement that integrates with
/// Dart DevTools while also allowing programmatic access to metrics.
///
/// Example:
/// ```dart
/// NoctermTimeline.startSync('renderFrame');
/// try {
///   // ... rendering work ...
/// } finally {
///   NoctermTimeline.finishSync();
/// }
/// ```
abstract final class NoctermTimeline {
  static final _BlockBuffer _buffer = _BlockBuffer();

  /// Whether to emit events to dart:developer Timeline (DevTools).
  ///
  /// When false (default), no Timeline events are emitted, reducing overhead.
  /// Set to true when using DevTools Timeline view for frame analysis.
  ///
  /// This is separate from [metricsEnabled] which controls internal metric
  /// collection for programmatic access.
  static bool debugTimelineEnabled = false;

  /// Whether metric collection is enabled.
  ///
  /// When enabled, timing data is collected and can be retrieved via
  /// [collectMetrics].
  static bool get metricsEnabled => _metricsEnabled;
  static bool _metricsEnabled = false;

  /// Enable or disable metric collection.
  ///
  /// When enabled, collects metrics for programmatic access via [collectMetrics].
  /// This is independent of [debugTimelineEnabled] which controls DevTools events.
  static set metricsEnabled(bool value) {
    if (value == _metricsEnabled) return;
    _metricsEnabled = value;
    if (!value) {
      resetMetrics();
    }
  }

  /// Start a synchronous operation labeled [name].
  ///
  /// This operation must be finished by calling [finishSync] before
  /// returning to the event queue.
  ///
  /// If [debugTimelineEnabled] is true, events are sent to DevTools Timeline.
  /// If [metricsEnabled] is true, timing data is collected for programmatic access.
  static void startSync(String name, {Map<String, Object?>? arguments}) {
    if (debugTimelineEnabled) {
      developer.Timeline.startSync(name, arguments: arguments);
    }
    if (_metricsEnabled) {
      _buffer.startSync(name);
    }
  }

  /// Finish the last synchronous operation that was started.
  static void finishSync() {
    if (debugTimelineEnabled) {
      developer.Timeline.finishSync();
    }
    if (_metricsEnabled) {
      _buffer.finishSync();
    }
  }

  /// Emit an instant event.
  static void instantSync(String name, {Map<String, Object?>? arguments}) {
    if (debugTimelineEnabled) {
      developer.Timeline.instantSync(name, arguments: arguments);
    }
  }

  /// Time a synchronous function.
  ///
  /// Convenience method that calls [startSync] and [finishSync] around
  /// the function execution.
  static T timeSync<T>(String name, T Function() function) {
    startSync(name);
    try {
      return function();
    } finally {
      finishSync();
    }
  }

  /// The current timestamp in microseconds.
  static int get now => DateTime.now().microsecondsSinceEpoch;

  /// Collect all metrics since the last [collectMetrics] or [resetMetrics].
  ///
  /// Returns aggregated timing data and resets the internal buffer.
  /// Throws if [metricsEnabled] is false.
  static PerformanceMetrics collectMetrics() {
    if (!_metricsEnabled) {
      throw StateError(
        'Metrics collection not enabled. Set metricsEnabled = true first.',
      );
    }
    final metrics = PerformanceMetrics._(_buffer.computeTimings());
    resetMetrics();
    return metrics;
  }

  /// Reset all collected metrics.
  static void resetMetrics() {
    _buffer.clear();
  }
}

/// A single timed block of code.
class TimedBlock {
  const TimedBlock({required this.name, required this.start, required this.end})
    : assert(end >= start);

  final String name;
  final int start; // microseconds
  final int end; // microseconds

  int get duration => end - start;

  @override
  String toString() => 'TimedBlock($name, $duration µs)';
}

/// Aggregated performance metrics.
class PerformanceMetrics {
  PerformanceMetrics._(this.timedBlocks);

  final List<TimedBlock> timedBlocks;

  /// Aggregate multiple blocks with the same name.
  late final Map<String, AggregatedBlock> aggregated = _computeAggregated();

  Map<String, AggregatedBlock> _computeAggregated() {
    final Map<String, (int totalDuration, int count)> aggregate = {};
    for (final block in timedBlocks) {
      final previous = aggregate[block.name] ?? (0, 0);
      aggregate[block.name] = (previous.$1 + block.duration, previous.$2 + 1);
    }
    return aggregate.map(
      (name, value) => MapEntry(
        name,
        AggregatedBlock(name: name, totalDuration: value.$1, count: value.$2),
      ),
    );
  }

  /// Get aggregated metrics for a named block.
  ///
  /// Returns zero metrics if the block never executed.
  AggregatedBlock getAggregated(String name) {
    return aggregated[name] ??
        AggregatedBlock(name: name, totalDuration: 0, count: 0);
  }

  @override
  String toString() {
    final buffer = StringBuffer('PerformanceMetrics:\n');
    for (final entry in aggregated.entries) {
      final avg = entry.value.averageDuration.toStringAsFixed(1);
      buffer.writeln(
        '  ${entry.key}: ${entry.value.totalDuration}µs (${entry.value.count}x, avg: $avgµs)',
      );
    }
    return buffer.toString();
  }
}

/// Aggregated timing data for blocks with the same name.
class AggregatedBlock {
  const AggregatedBlock({
    required this.name,
    required this.totalDuration,
    required this.count,
  });

  final String name;
  final int totalDuration; // microseconds
  final int count;

  double get averageDuration => count > 0 ? totalDuration / count : 0.0;

  @override
  String toString() =>
      'AggregatedBlock($name, $totalDuration µs, ${count}x, avg: ${averageDuration.toStringAsFixed(1)}µs)';
}

/// Internal buffer for tracking timed blocks.
class _BlockBuffer {
  final List<int> _starts = [];
  final List<int> _ends = [];
  final List<String> _names = [];
  final List<int> _startStack = [];
  final List<String> _nameStack = [];

  void startSync(String name) {
    _startStack.add(DateTime.now().microsecondsSinceEpoch);
    _nameStack.add(name);
  }

  void finishSync() {
    if (_startStack.isEmpty) {
      throw StateError(
        'Invalid sequence of startSync/finishSync. '
        'Attempted to finish timing but no pending startSync calls.',
      );
    }

    final end = DateTime.now().microsecondsSinceEpoch;
    final start = _startStack.removeLast();
    final name = _nameStack.removeLast();

    _starts.add(start);
    _ends.add(end);
    _names.add(name);
  }

  List<TimedBlock> computeTimings() {
    if (_startStack.isNotEmpty) {
      throw StateError(
        'Invalid sequence of startSync/finishSync. '
        'The following operations are still waiting to be finished: ${_nameStack.join(", ")}',
      );
    }

    final result = <TimedBlock>[];
    for (int i = 0; i < _starts.length; i++) {
      result.add(TimedBlock(name: _names[i], start: _starts[i], end: _ends[i]));
    }
    return result;
  }

  void clear() {
    _starts.clear();
    _ends.clear();
    _names.clear();
    _startStack.clear();
    _nameStack.clear();
  }
}

/// Frame timing data similar to Flutter's FrameTiming.
class FrameTiming {
  FrameTiming({
    required this.frameNumber,
    required this.buildDuration,
    required this.layoutDuration,
    required this.paintDuration,
    required this.compositingDuration,
    required this.totalDuration,
    required this.timestamp,
  });

  final int frameNumber;
  final Duration buildDuration;
  final Duration layoutDuration;
  final Duration paintDuration;
  final Duration compositingDuration;
  final Duration totalDuration;
  final DateTime timestamp;

  /// Whether this frame exceeded the target frame budget (16.67ms for 60fps).
  bool get isSlowFrame => totalDuration.inMicroseconds > 16667;

  /// Duration spent in rendering (layout + paint + compositing).
  Duration get renderDuration =>
      layoutDuration + paintDuration + compositingDuration;

  @override
  String toString() {
    return 'FrameTiming(#$frameNumber, total: ${totalDuration.inMilliseconds}ms, '
        'build: ${buildDuration.inMilliseconds}ms, '
        'layout: ${layoutDuration.inMilliseconds}ms, '
        'paint: ${paintDuration.inMilliseconds}ms, '
        'composite: ${compositingDuration.inMilliseconds}ms)';
  }
}

/// Signature for frame timing callbacks.
typedef FrameTimingCallback = void Function(FrameTiming timing);
