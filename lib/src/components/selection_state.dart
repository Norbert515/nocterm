/// Global selection drag state used to coordinate behavior across widgets.
///
/// Render objects that depend on this (fx. [RenderListViewport])
/// register callbacks via [addListener] and mark themselves dirty.
class SelectionDragState {
  static int _activeCount = 0;
  static final Map<Object, SelectionRange> _ranges = {};
  static final Set<void Function()> _listeners = {};

  /// Whether a selection drag is currently active.
  static bool get isActive => _activeCount > 0;

  static void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  static void _notify() {
    if (_listeners.isEmpty) return;
    // Snapshot so listeners can safely detach themselves mid-iteration.
    for (final listener in _listeners.toList(growable: false)) {
      listener();
    }
  }

  /// Mark selection drag as active.
  static void begin() {
    _activeCount++;
    _notify();
  }

  /// Mark selection drag as inactive.
  static void end() {
    if (_activeCount > 0) {
      _activeCount--;
    }
    if (_activeCount == 0) {
      _ranges.clear();
    }
    _notify();
  }

  static void updateRange(Object context, int minIndex, int maxIndex) {
    if (minIndex > maxIndex) return;
    final newRange = SelectionRange(minIndex, maxIndex);
    final existing = _ranges[context];
    if (existing == newRange) return;
    _ranges[context] = newRange;
    _notify();
  }

  static SelectionRange? rangeFor(Object context) {
    return _ranges[context];
  }
}

class SelectionRange {
  const SelectionRange(this.minIndex, this.maxIndex);

  final int minIndex;
  final int maxIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SelectionRange &&
          other.minIndex == minIndex &&
          other.maxIndex == maxIndex);

  @override
  int get hashCode => Object.hash(minIndex, maxIndex);
}
