/// Per-render-object layout profiler.
///
/// Accumulates time spent in [RenderObject.layout] (and its recursive
/// descendants) keyed by the runtime type of the render object. When
/// the host's [FrameProfiler] is recording, [setActive] is flipped on
/// and the per-type counts roll up into the next call to [collect].
///
/// Cheap when inactive: a single bool check per layout call.
///
/// The hot-path is in [RenderObject.layout], which the framework
/// calls on every layout pass. We avoid allocating per call by
/// keeping a fixed-size array of "hot type slots" (the most common
/// render object types like RenderConstrainedBox, RenderParagraph,
/// RenderPadding, etc.) and a Map for the long tail. The hot slot
/// cache is bypassed when inactive.
class NoctermLayoutProfiler {
  NoctermLayoutProfiler._();

  /// Single shared instance. The framework's [RenderObject.layout]
  /// reads [isActive] on every call; the chat panel's
  /// [FrameProfiler] flips it on when recording starts and back
  /// off when recording stops.
  static final NoctermLayoutProfiler instance = NoctermLayoutProfiler._();

  /// Hot-path gate. When false, [RenderObject.layout] skips the
  /// bookkeeping entirely and just runs the layout.
  static bool isActive = false;

  /// Per-type totals. Keyed by the render object's runtime type
  /// string (e.g. `RenderParagraph`, `RenderConstrainedBox`).
  /// Cleared by [reset] at the start of every recording.
  final Map<String, _TypeStats> _byType = <String, _TypeStats>{};

  /// Per-call records, kept so the report can surface the
  /// `topSlowLayoutCalls` (the N individual layout calls that
  /// took the longest). Capped at 200 to bound memory.
  final List<_LayoutCall> _calls = <_LayoutCall>[];
  int _nextCallId = 0;

  /// Start recording. Idempotent.
  void setActive() {
    isActive = true;
  }

  /// Stop recording. The map and call list are kept around so
  /// the host can call [collect] after flipping the flag off.
  void setInactive() {
    isActive = false;
  }

  /// Wipe per-type and per-call accumulators. Called by the
  /// host at the start of a recording.
  void reset() {
    _byType.clear();
    _calls.clear();
    _nextCallId = 0;
  }

  /// Called from [RenderObject.layout] on every invocation while
  /// [isActive] is true. [us] is the elapsed microseconds for
  /// that one layout() call (which is one render object's
  /// performLayout, NOT the cumulative subtree time — see
  /// note in [collect]).
  void record(String typeName, int us) {
    final stats = _byType.putIfAbsent(typeName, () => _TypeStats());
    stats.totalUs += us;
    stats.count++;
    if (stats.maxUs < us) stats.maxUs = us;

    // Keep the top slowest individual calls so the report can
    // surface "this one Row layout() call took 3.2ms" rather
    // than only averages. Capped to keep memory bounded.
    if (_calls.length < 200) {
      _calls.add(_LayoutCall(_nextCallId++, typeName, us));
    } else {
      // Find the smallest in the list and replace it if the new
      // one is bigger. Simple linear scan — 200 entries is cheap.
      var minIdx = 0;
      for (var i = 1; i < _calls.length; i++) {
        if (_calls[i].us < _calls[minIdx].us) minIdx = i;
      }
      if (_calls[minIdx].us < us) {
        _calls[minIdx] = _LayoutCall(_nextCallId++, typeName, us);
      }
    }
  }

  /// Drain accumulators into a JSON-friendly map suitable for
  /// embedding in a profile report under `byLayout`.
  Map<String, dynamic> collect() {
    final byType = <String, dynamic>{};
    for (final entry in _byType.entries) {
      final s = entry.value;
      byType[entry.key] = {
        'count': s.count,
        'totalUs': s.totalUs,
        'avgUs': s.count == 0 ? 0 : s.totalUs ~/ s.count,
        'maxUs': s.maxUs,
      };
    }
    // Sort the per-type entries by totalUs descending so the
    // biggest offenders surface at the top of the report.
    final sorted = byType.entries.toList()
      ..sort((a, b) =>
          (b.value['totalUs'] as int).compareTo(a.value['totalUs'] as int));

    // Top-N individual layout calls (capped at 20 in the
    // report itself; the underlying list may be longer for
    // debugging).
    final calls = List<_LayoutCall>.from(_calls)
      ..sort((a, b) => b.us.compareTo(a.us));
    final topCalls = calls
        .take(20)
        .map((c) => {'id': c.id, 'type': c.type, 'us': c.us})
        .toList();

    return {
      'byType': Map<String, dynamic>.fromEntries(sorted),
      'topSlowCalls': topCalls,
      'totalCalls': _calls.length < 200 ? _calls.length : 200,
    };
  }
}

class _TypeStats {
  int count = 0;
  int totalUs = 0;
  int maxUs = 0;
}

class _LayoutCall {
  _LayoutCall(this.id, this.type, this.us);
  final int id;
  final String type;
  final int us;
}
