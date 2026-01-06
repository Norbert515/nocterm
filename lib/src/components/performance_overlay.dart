import 'dart:collection';

import 'package:nocterm/nocterm.dart';

/// A visual overlay that displays real-time performance metrics.
///
/// Shows frame timing data in the terminal, similar to Flutter's PerformanceOverlay.
///
/// Example:
/// ```dart
/// NoctermApp(
///   child: Stack(
///     children: [
///       MyApp(),
///       PerformanceOverlay(), // Shows performance stats
///     ],
///   ),
/// )
/// ```
class PerformanceOverlay extends StatefulComponent {
  const PerformanceOverlay({
    super.key,
    this.maxSamples = 60,
    this.position = OverlayPosition.topRight,
  });

  /// Maximum number of frame samples to keep for averaging.
  final int maxSamples;

  /// Where to position the overlay.
  final OverlayPosition position;

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

enum OverlayPosition { topLeft, topRight, bottomLeft, bottomRight }

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  final Queue<FrameTiming> _recentFrames = Queue<FrameTiming>();
  FrameTiming? _lastFrame;
  int _slowFrameCount = 0;
  FrameTimingCallback? _callback;

  @override
  void initState() {
    super.initState();
    _callback = _onFrameTiming;
    SchedulerBinding.instance.addFrameTimingCallback(_callback!);
  }

  @override
  void dispose() {
    if (_callback != null) {
      SchedulerBinding.instance.removeFrameTimingCallback(_callback!);
    }
    super.dispose();
  }

  void _onFrameTiming(FrameTiming timing) {
    setState(() {
      _lastFrame = timing;
      _recentFrames.add(timing);
      if (timing.isSlowFrame) {
        _slowFrameCount++;
      }
      while (_recentFrames.length > component.maxSamples) {
        _recentFrames.removeFirst();
      }
    });
  }

  double get _averageFrameTime {
    if (_recentFrames.isEmpty) return 0.0;
    final total = _recentFrames.fold<int>(
      0,
      (sum, frame) => sum + frame.totalDuration.inMicroseconds,
    );
    return total / _recentFrames.length / 1000.0; // Convert to ms
  }

  double get _fps {
    if (_averageFrameTime == 0) return 0.0;
    return 1000.0 / _averageFrameTime;
  }

  @override
  Component build(BuildContext context) {
    if (_lastFrame == null) {
      return const SizedBox();
    }

    final stats = _buildStatsText();
    final lines = stats.split('\n');
    final maxWidth =
        lines.map((l) => l.length).reduce((a, b) => a > b ? a : b) + 2;
    final totalHeight = lines.length + 2;

    return Positioned(
      top:
          component.position == OverlayPosition.topLeft ||
              component.position == OverlayPosition.topRight
          ? 0.0
          : null,
      bottom:
          component.position == OverlayPosition.bottomLeft ||
              component.position == OverlayPosition.bottomRight
          ? 0.0
          : null,
      left:
          component.position == OverlayPosition.topLeft ||
              component.position == OverlayPosition.bottomLeft
          ? 0.0
          : null,
      right:
          component.position == OverlayPosition.topRight ||
              component.position == OverlayPosition.bottomRight
          ? 0.0
          : null,
      child: Container(
        width: maxWidth.toDouble(),
        height: totalHeight.toDouble(),
        decoration: const BoxDecoration(color: Color(0xFF000000)),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: Text(stats, style: const TextStyle(color: Color(0xFFFFFFFF))),
        ),
      ),
    );
  }

  String _buildStatsText() {
    final buffer = StringBuffer();

    // Current frame
    final lastFrameMs = _lastFrame!.totalDuration.inMicroseconds / 1000.0;
    final frameColor = _lastFrame!.isSlowFrame ? '🔴' : '🟢';
    buffer.writeln(
      '$frameColor Frame #${_lastFrame!.frameNumber}: ${lastFrameMs.toStringAsFixed(2)}ms',
    );

    // FPS and average
    buffer.writeln(
      'FPS: ${_fps.toStringAsFixed(1)} (avg: ${_averageFrameTime.toStringAsFixed(2)}ms)',
    );

    // Slow frame count
    if (_slowFrameCount > 0) {
      buffer.writeln('⚠️  Slow frames: $_slowFrameCount');
    }

    // Build time breakdown
    final buildMs = _lastFrame!.buildDuration.inMicroseconds / 1000.0;
    buffer.writeln('Build: ${buildMs.toStringAsFixed(2)}ms');

    // Frame rate limiting status
    final limiting = SchedulerBinding.instance.enableFrameRateLimiting;
    buffer.write('Rate limit: ${limiting ? "ON" : "OFF"}');

    return buffer.toString();
  }
}
