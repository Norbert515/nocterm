import 'package:nocterm/nocterm.dart';

/// Controls a scrollable widget.
///
/// Manages the scroll position and provides methods to programmatically
/// control scrolling.
class ScrollController extends ChangeNotifier {
  ScrollController({double initialScrollOffset = 0.0})
    : _offset = initialScrollOffset;

  double _offset;
  double _minScrollExtent = 0.0;
  double _maxScrollExtent = 0.0;
  double _viewportDimension = 0.0;
  AxisDirection _axisDirection = AxisDirection.down;

  /// The attached render object (used for index-based scrolling)
  Object? _attachedRenderObject;

  /// The current scroll offset.
  double get offset => _offset;

  /// The minimum in-range value for [offset].
  double get minScrollExtent => _minScrollExtent;

  /// The maximum in-range value for [offset].
  double get maxScrollExtent => _maxScrollExtent;

  /// The extent of the viewport in the scrolling direction.
  double get viewportDimension => _viewportDimension;

  /// The axis direction of scrolling.
  AxisDirection get axisDirection => _axisDirection;

  /// Whether scrolling is reversed (up for vertical, left for horizontal).
  bool get isReversed =>
      _axisDirection == AxisDirection.up ||
      _axisDirection == AxisDirection.left;

  /// Whether the [offset] is at the minimum value.
  bool get atStart => offset <= minScrollExtent;

  /// Whether the [offset] is at the maximum value.
  bool get atEnd => offset >= maxScrollExtent;

  /// The total scrollable extent.
  double get scrollExtent => maxScrollExtent - minScrollExtent;

  /// Updates the scroll metrics.
  void updateMetrics({
    required double minScrollExtent,
    required double maxScrollExtent,
    required double viewportDimension,
    AxisDirection? axisDirection,
  }) {
    final oldMin = _minScrollExtent;
    final oldMax = _maxScrollExtent;
    final oldViewport = _viewportDimension;
    final oldOffset = _offset;
    final oldAxisDirection = _axisDirection;

    _minScrollExtent = minScrollExtent;
    _maxScrollExtent = maxScrollExtent;
    _viewportDimension = viewportDimension;
    if (axisDirection != null) {
      _axisDirection = axisDirection;
    }

    // Clamp the current offset to valid range
    _offset = _offset.clamp(minScrollExtent, maxScrollExtent);

    // Only notify listeners if something actually changed
    if (oldMin != _minScrollExtent ||
        oldMax != _maxScrollExtent ||
        oldViewport != _viewportDimension ||
        oldOffset != _offset ||
        oldAxisDirection != _axisDirection) {
      notifyListeners();
    }
  }

  /// Jumps the scroll position to the given value.
  void jumpTo(double value) {
    _offset = value.clamp(minScrollExtent, maxScrollExtent);
    notifyListeners();
  }

  /// Scrolls by the given delta.
  void scrollBy(double delta) {
    jumpTo(offset + delta);
  }

  /// Scrolls up by one line (for TUI).
  void scrollUp([double lines = 1.0]) {
    scrollBy(-lines);
  }

  /// Scrolls down by one line (for TUI).
  void scrollDown([double lines = 1.0]) {
    scrollBy(lines);
  }

  /// Scrolls up by one page.
  void pageUp() {
    scrollBy(-viewportDimension);
  }

  /// Scrolls down by one page.
  void pageDown() {
    scrollBy(viewportDimension);
  }

  /// Scrolls to the start.
  void scrollToStart() {
    jumpTo(minScrollExtent);
  }

  /// Scrolls to the end.
  void scrollToEnd() {
    jumpTo(maxScrollExtent);
  }

  /// Ensures that an item at the given position is visible in the viewport.
  ///
  /// This method scrolls the viewport only if necessary to make the item
  /// visible. If the item is already fully visible, no scrolling occurs.
  ///
  /// Parameters:
  /// - [itemOffset]: The offset of the item from the start of the scrollable content.
  /// - [itemExtent]: The extent (height for vertical, width for horizontal) of the item.
  ///
  /// The method performs minimal scrolling:
  /// - If the item is below the viewport, scrolls down to show it at the bottom.
  /// - If the item is above the viewport, scrolls up to show it at the top.
  /// - If the item is already fully visible, does not scroll.
  /// - If the item is larger than the viewport, scrolls to show the start of the item.
  void ensureVisible({required double itemOffset, required double itemExtent}) {
    final itemStart = itemOffset;
    final itemEnd = itemOffset + itemExtent;
    final viewportStart = offset;
    final viewportEnd = offset + viewportDimension;

    // Item is fully visible - no need to scroll
    if (itemStart >= viewportStart && itemEnd <= viewportEnd) {
      return;
    }

    // Item is larger than viewport - show the start
    if (itemExtent > viewportDimension) {
      jumpTo(itemStart);
      return;
    }

    // Item is below viewport - scroll down to show it at the bottom
    if (itemEnd > viewportEnd) {
      final targetOffset = itemEnd - viewportDimension;
      jumpTo(targetOffset);
      return;
    }

    // Item is above viewport - scroll up to show it at the top
    if (itemStart < viewportStart) {
      jumpTo(itemStart);
      return;
    }
  }

  /// Attaches a render object to this controller.
  ///
  /// This is called by render objects (like RenderListViewport) when they
  /// are created with this controller. It allows the controller to query
  /// the render object for operations like [ensureIndexVisible].
  void attach(Object renderObject) {
    _attachedRenderObject = renderObject;
  }

  /// Detaches a render object from this controller.
  ///
  /// This is called by render objects when they are disposed.
  void detach(Object renderObject) {
    if (_attachedRenderObject == renderObject) {
      _attachedRenderObject = null;
    }
  }

  /// Ensures that an item at the given index is visible in the viewport.
  ///
  /// This method queries the attached [RenderListViewport] to get the item's
  /// position and then scrolls the viewport to make it visible using [ensureVisible].
  ///
  /// Parameters:
  /// - [index]: The index of the item to make visible.
  ///
  /// If the item's position cannot be determined (e.g., the item hasn't been
  /// laid out yet in lazy mode, or there's no attached RenderListViewport),
  /// this method does nothing.
  ///
  /// Example:
  /// ```dart
  /// scrollController.ensureIndexVisible(index: selectedIndex);
  /// ```
  void ensureIndexVisible({required int index}) {
    // Import is needed at the top of the file
    final renderViewport = _attachedRenderObject;

    if (renderViewport is! RenderListViewport) {
      // No ListView attached or wrong type
      return;
    }

    // Query the render object for the item's position
    final itemInfo = renderViewport.getItemOffsetAndExtent(index);

    if (itemInfo == null) {
      // Item position unknown (not laid out yet, or doesn't exist)
      return;
    }

    final (itemOffset, itemExtent) = itemInfo;

    // Use the existing ensureVisible logic
    ensureVisible(itemOffset: itemOffset, itemExtent: itemExtent);
  }
}

/// Base class for change notification.
abstract class ChangeNotifier implements Listenable {
  final List<VoidCallback> _listeners = [];

  /// Register a closure to be called when the object notifies its listeners.
  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove a previously registered listener.
  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Call all registered listeners.
  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Discards any resources used by the object.
  void dispose() {
    _listeners.clear();
  }
}
