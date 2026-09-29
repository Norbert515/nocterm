import 'package:nocterm/nocterm.dart';

/// A ScrollController that automatically scrolls to the bottom when new content
/// is added, but preserves scroll position when the user scrolls up.
/// Useful for chat interfaces, logs, and other auto-scrolling content.
class AutoScrollController extends ScrollController {
  AutoScrollController({
    super.initialScrollOffset,
    this.autoScrollThreshold = 1.0,
  });

  /// The distance from the bottom within which auto-scroll is enabled.
  /// If the user is within this distance from the bottom, new content
  /// will trigger auto-scroll. Default is 1.0 pixel.
  final double autoScrollThreshold;

  /// Whether auto-scroll is currently enabled based on scroll position.
  bool _isAutoScrollEnabled = true;

  /// Whether auto-scroll is currently enabled.
  bool get isAutoScrollEnabled => _isAutoScrollEnabled;

  /// Track the previous max scroll extent to detect content changes.
  double _previousMaxScrollExtent = 0.0;

  @override
  void updateMetrics({
    required double minScrollExtent,
    required double maxScrollExtent,
    required double viewportDimension,
    AxisDirection? axisDirection,
  }) {
    // Check if we should auto-scroll before updating metrics
    final wasNearBottom = _isNearBottom();
    final contentGrew = maxScrollExtent > _previousMaxScrollExtent;

    // Update metrics
    super.updateMetrics(
      minScrollExtent: minScrollExtent,
      maxScrollExtent: maxScrollExtent,
      viewportDimension: viewportDimension,
      axisDirection: axisDirection,
    );

    // Auto-scroll if we were near bottom and content grew.
    //
    // This must be a silent layout-time correction. Deferring to a post-frame
    // jump lets one frame paint with the old offset when content wraps onto a
    // new line, which shows up as a visible flicker in chat/log panels.
    if (_isAutoScrollEnabled && wasNearBottom && contentGrew) {
      correctOffset(isReversed ? minScrollExtent : maxScrollExtent);
    }

    _previousMaxScrollExtent = maxScrollExtent;
  }

  /// Check if the scroll position is near the bottom.
  bool _isNearBottom() {
    if (maxScrollExtent == 0) return true; // No scrolling needed

    if (isReversed) {
      // In reverse mode, "bottom" is at offset 0
      return offset <= autoScrollThreshold;
    } else {
      // In normal mode, "bottom" is at maxScrollExtent
      return offset >= maxScrollExtent - autoScrollThreshold;
    }
  }

  /// Update auto-scroll state based on current position.
  void _updateAutoScrollState() {
    final wasEnabled = _isAutoScrollEnabled;
    _isAutoScrollEnabled = _isNearBottom();

    if (wasEnabled != _isAutoScrollEnabled) {
      notifyListeners();
    }
  }

  @override
  void jumpTo(double value) {
    super.jumpTo(value);
    _updateAutoScrollState();
  }

  @override
  void scrollBy(double delta) {
    super.scrollBy(delta);
    _updateAutoScrollState();
  }

  /// Manually enable auto-scroll and scroll to bottom.
  void enableAutoScroll() {
    _isAutoScrollEnabled = true;
    if (isReversed) {
      scrollToStart(); // In reverse mode, "bottom" is at start
    } else {
      scrollToEnd(); // In normal mode, "bottom" is at end
    }
    notifyListeners();
  }

  /// Manually disable auto-scroll.
  void disableAutoScroll() {
    _isAutoScrollEnabled = false;
    notifyListeners();
  }

  /// Scroll to bottom with auto-scroll enabled.
  void scrollToBottom() {
    enableAutoScroll();
  }
}
