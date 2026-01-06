import 'dart:math' as math;

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import '../rendering/scrollable_render_object.dart';

/// Signature for a function that creates a widget for a given index.
typedef IndexedWidgetBuilder =
    Component? Function(BuildContext context, int index);

/// Signature for a function that provides the item count.
typedef ItemCountGetter = int Function();

/// A scrollable list of widgets arranged linearly.
///
/// ListView is the most commonly used scrolling widget. It displays its
/// children one after another in the scroll direction.
class ListView extends StatefulComponent {
  /// Creates a scrollable, linear array of widgets from an explicit [List].
  ListView({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.padding,
    this.itemExtent,
    this.lazy = false,
    List<Component> children = const [],
  }) : itemCount = children.length,
       itemBuilder = ((context, index) => children[index]),
       separatorBuilder = null;

  /// Creates a scrollable, linear array of widgets that are created on demand.
  ///
  /// This constructor is appropriate for list views with a large (or infinite)
  /// number of children because the builder is called only for those children
  /// that are actually visible.
  const ListView.builder({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.padding,
    this.itemExtent,
    this.lazy = false,
    required this.itemBuilder,
    this.itemCount,
  }) : separatorBuilder = null;

  /// Creates a scrollable, linear array of widgets with a separator between each item.
  const ListView.separated({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.padding,
    this.lazy = false,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.itemCount,
  }) : itemExtent = null;

  /// The axis along which the scroll view scrolls.
  final Axis scrollDirection;

  /// Whether the scroll view scrolls in the reading direction.
  ///
  /// For example, if [scrollDirection] is [Axis.horizontal], then the scroll
  /// view scrolls from left to right when [reverse] is false and from right to
  /// left when [reverse] is true.
  ///
  /// Similarly, if [scrollDirection] is [Axis.vertical], then the scroll view
  /// scrolls from top to bottom when [reverse] is false and from bottom to top
  /// when [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverse;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  final ScrollController? controller;

  /// The amount of space by which to inset the children.
  final EdgeInsets? padding;

  /// If non-null, forces the children to have the given extent in the scroll
  /// direction.
  final double? itemExtent;

  /// Whether to use lazy building of children.
  ///
  /// When false (the default), all children are built during layout to determine
  /// the exact scroll extent, but only visible children are painted.
  /// This provides accurate scroll metrics at the cost of building all children.
  ///
  /// When true, only visible children are built, which is more efficient for
  /// large lists but may result in estimated scroll extents.
  final bool lazy;

  /// Called to build children for the list.
  final IndexedWidgetBuilder itemBuilder;

  /// Called to build separators between items (for ListView.separated).
  final IndexedWidgetBuilder? separatorBuilder;

  /// The total number of items. If null, the list is infinite.
  final int? itemCount;

  @override
  State<ListView> createState() => _ListViewState();
}

class _ListViewState extends State<ListView> {
  ScrollController? _controller;

  ScrollController get _effectiveController =>
      component.controller ?? _controller!;

  @override
  void initState() {
    super.initState();
    if (component.controller == null) {
      _controller = ScrollController();
    }
  }

  @override
  void didUpdateComponent(ListView oldWidget) {
    super.didUpdateComponent(oldWidget);
    if (component.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _controller?.dispose();
        _controller = null;
      }
      if (component.controller == null) {
        _controller = ScrollController();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return _ListViewport(
      scrollDirection: component.scrollDirection,
      reverse: component.reverse,
      controller: _effectiveController,
      padding: component.padding,
      itemExtent: component.itemExtent,
      lazy: component.lazy,
      itemBuilder: component.itemBuilder,
      separatorBuilder: component.separatorBuilder,
      itemCount: component.itemCount,
    );
  }
}

/// Internal widget that handles the viewport and rendering for ListView.
class _ListViewport extends RenderObjectComponent {
  const _ListViewport({
    required this.scrollDirection,
    this.reverse = false,
    required this.controller,
    this.padding,
    this.itemExtent,
    this.lazy = false,
    required this.itemBuilder,
    this.separatorBuilder,
    this.itemCount,
  });

  final Axis scrollDirection;
  final bool reverse;
  final ScrollController controller;
  final EdgeInsets? padding;
  final double? itemExtent;
  final bool lazy;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final int? itemCount;

  @override
  Element createElement() => _ListViewportElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderListViewport(
      scrollDirection: scrollDirection,
      reverse: reverse,
      controller: controller,
      padding: padding,
      itemExtent: itemExtent,
      lazy: lazy,
      hasSeparators: separatorBuilder != null,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderListViewport renderObject,
  ) {
    renderObject
      ..scrollDirection = scrollDirection
      ..reverse = reverse
      ..controller = controller
      ..padding = padding
      ..itemExtent = itemExtent
      ..lazy = lazy
      ..hasSeparators = separatorBuilder != null;
  }
}

/// Element for ListView that manages building children on demand.
class _ListViewportElement extends RenderObjectElement {
  _ListViewportElement(_ListViewport super.component);

  @override
  _ListViewport get component => super.component as _ListViewport;

  @override
  RenderListViewport get renderObject =>
      super.renderObject as RenderListViewport;

  /// Currently built children indexed by their item index.
  final Map<int, Element> _children = {};

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    renderObject._element = this;
  }

  @override
  void unmount() {
    renderObject._element = null;
    super.unmount();
  }

  @override
  void update(Component newComponent) {
    super.update(newComponent);
    // Force rebuild to update children
    renderObject.markNeedsLayout();
  }

  @override
  void performRebuild() {
    // Render object elements don't rebuild like buildable elements
    // _dirty is handled by the base class
  }

  @override
  void insertRenderObjectChild(RenderObject child, dynamic slot) {
    // ListView manages its own children through buildChild
    // This is not used in our implementation
  }

  @override
  void moveRenderObjectChild(
    RenderObject child,
    dynamic oldSlot,
    dynamic newSlot,
  ) {
    // ListView doesn't move render object children
  }

  @override
  void removeRenderObjectChild(RenderObject child, dynamic slot) {
    // ListView manages its own children through buildChild
    // This is not used in our implementation
  }

  /// Builds or updates a child at the given index.
  Element? buildChild(int index) {
    // Check if index is valid
    if (component.itemCount != null && index >= component.itemCount!) {
      return null;
    }

    // Build the child widget
    final child = component.itemBuilder(this, index);
    if (child == null) return null;

    // Update or create element
    final oldChild = _children[index];
    if (oldChild != null && Component.canUpdate(oldChild.component, child)) {
      oldChild.update(child);
      return oldChild;
    } else {
      oldChild?.unmount();
      // ignore: invalid_use_of_protected_member
      final newChild = child.createElement();
      _children[index] = newChild;
      newChild.mount(this, index);
      return newChild;
    }
  }

  /// Builds a separator at the given index.
  Element? buildSeparator(int index) {
    if (component.separatorBuilder == null) return null;

    final separator = component.separatorBuilder!(this, index);
    if (separator == null) return null;

    final separatorIndex = -index - 1; // Use negative indices for separators
    final oldSeparator = _children[separatorIndex];

    if (oldSeparator != null &&
        Component.canUpdate(oldSeparator.component, separator)) {
      oldSeparator.update(separator);
      return oldSeparator;
    } else {
      oldSeparator?.unmount();
      // ignore: invalid_use_of_protected_member
      final newSeparator = separator.createElement();
      _children[separatorIndex] = newSeparator;
      newSeparator.mount(this, separatorIndex);
      return newSeparator;
    }
  }

  /// Removes children that are no longer visible.
  void removeInvisibleChildren(int firstIndex, int lastIndex) {
    final keysToRemove = <int>[];
    for (final key in _children.keys) {
      if (key >= 0) {
        // Regular item
        if (key < firstIndex || key > lastIndex) {
          keysToRemove.add(key);
        }
      } else {
        // Separator
        final separatorIndex = -key - 1;
        if (separatorIndex < firstIndex || separatorIndex >= lastIndex) {
          keysToRemove.add(key);
        }
      }
    }

    for (final key in keysToRemove) {
      final child = _children[key];
      if (child != null) {
        // Properly deactivate and unmount the element
        if (child.mounted) {
          child.deactivate();
          child.unmount();
        }
      }
      _children.remove(key);
    }
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    _children.values.forEach(visitor);
  }
}

/// Render object for ListView viewport.
class RenderListViewport extends RenderObject with ScrollableRenderObjectMixin {
  RenderListViewport({
    required Axis scrollDirection,
    bool reverse = false,
    required ScrollController controller,
    EdgeInsets? padding,
    double? itemExtent,
    bool lazy = false,
    bool hasSeparators = false,
  }) : _scrollDirection = scrollDirection,
       _reverse = reverse,
       _controller = controller,
       _padding = padding,
       _itemExtent = itemExtent,
       _lazy = lazy,
       _hasSeparators = hasSeparators {
    _controller.addListener(_handleScrollUpdate);
    _controller.attach(this);
  }

  _ListViewportElement? _element;

  Axis _scrollDirection;
  Axis get scrollDirection => _scrollDirection;
  set scrollDirection(Axis value) {
    if (_scrollDirection != value) {
      _scrollDirection = value;
      markNeedsLayout();
    }
  }

  bool _reverse;
  bool get reverse => _reverse;
  set reverse(bool value) {
    if (_reverse != value) {
      _reverse = value;
      markNeedsLayout();
    }
  }

  ScrollController _controller;
  ScrollController get controller => _controller;
  set controller(ScrollController value) {
    if (_controller != value) {
      _controller.removeListener(_handleScrollUpdate);
      _controller.detach(this);
      _controller = value;
      _controller.addListener(_handleScrollUpdate);
      _controller.attach(this);
      markNeedsLayout();
    }
  }

  EdgeInsets? _padding;
  EdgeInsets? get padding => _padding;
  set padding(EdgeInsets? value) {
    if (_padding != value) {
      _padding = value;
      markNeedsLayout();
    }
  }

  double? _itemExtent;
  double? get itemExtent => _itemExtent;
  set itemExtent(double? value) {
    if (_itemExtent != value) {
      _itemExtent = value;
      markNeedsLayout();
    }
  }

  bool _lazy;
  bool get lazy => _lazy;
  set lazy(bool value) {
    if (_lazy != value) {
      _lazy = value;
      markNeedsLayout();
    }
  }

  bool _hasSeparators;
  bool get hasSeparators => _hasSeparators;
  set hasSeparators(bool value) {
    if (_hasSeparators != value) {
      _hasSeparators = value;
      markNeedsLayout();
    }
  }

  void _handleScrollUpdate() {
    markNeedsPaint();
  }

  @override
  bool handleMouseWheel(MouseEvent event) {
    // Only handle vertical scroll for vertical ScrollViews
    // and horizontal scroll for horizontal ScrollViews
    if (_scrollDirection == Axis.vertical) {
      if (event.button == MouseButton.wheelUp) {
        // In reverse mode, invert the scroll direction
        if (_reverse) {
          _controller.scrollDown(3.0); // Wheel up scrolls down in reverse mode
        } else {
          _controller.scrollUp(3.0); // Normal behavior
        }
        return true;
      } else if (event.button == MouseButton.wheelDown) {
        // In reverse mode, invert the scroll direction
        if (_reverse) {
          _controller.scrollUp(3.0); // Wheel down scrolls up in reverse mode
        } else {
          _controller.scrollDown(3.0); // Normal behavior
        }
        return true;
      }
    } else {
      // For horizontal scroll, we might want to handle horizontal wheel events
      // but for now just handle vertical wheel as horizontal scroll
      if (event.button == MouseButton.wheelUp) {
        if (_reverse) {
          _controller.scrollDown(3.0);
        } else {
          _controller.scrollUp(3.0);
        }
        return true;
      } else if (event.button == MouseButton.wheelDown) {
        if (_reverse) {
          _controller.scrollUp(3.0);
        } else {
          _controller.scrollDown(3.0);
        }
        return true;
      }
    }

    return false;
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScrollUpdate);
    _controller.detach(this);
    super.dispose();
  }

  /// Information about visible children after layout.
  final List<_ChildLayoutInfo> _visibleChildren = [];

  /// All built children when not lazy (for accurate extent calculation).
  final List<_ChildLayoutInfo> _allChildren = [];

  /// Tracks the average item extent for estimating total scroll extent
  double? _averageItemExtent;

  @override
  void performLayout() {
    _visibleChildren.clear();
    _allChildren.clear();

    if (_element == null) {
      size = constraints.constrain(Size.zero);
      return;
    }

    // Apply padding
    final effectivePadding = padding ?? EdgeInsets.zero;
    final innerConstraints = constraints.deflate(effectivePadding);

    // Our size is constrained by our parent
    size = constraints.constrain(
      Size(constraints.maxWidth, constraints.maxHeight),
    );

    // Calculate viewport dimensions
    final viewportExtent = scrollDirection == Axis.vertical
        ? innerConstraints.maxHeight
        : innerConstraints.maxWidth;
    final crossAxisExtent = scrollDirection == Axis.vertical
        ? innerConstraints.maxWidth
        : innerConstraints.maxHeight;

    // Build visible children
    final component = _element!.component;
    final itemCount = component.itemCount;

    // Child constraints
    final childConstraints = scrollDirection == Axis.vertical
        ? BoxConstraints(
            minWidth: crossAxisExtent,
            maxWidth: crossAxisExtent,
            minHeight: 0,
            maxHeight: itemExtent ?? double.infinity,
          )
        : BoxConstraints(
            minHeight: crossAxisExtent,
            maxHeight: crossAxisExtent,
            minWidth: 0,
            maxWidth: itemExtent ?? double.infinity,
          );

    double totalExtent = 0;

    if (_lazy) {
      // Lazy mode: only build visible children
      totalExtent = _performLazyLayout(
        viewportExtent: viewportExtent,
        childConstraints: childConstraints,
        itemCount: itemCount,
      );
    } else {
      // Non-lazy mode: build all children for accurate extent
      totalExtent = _performEagerLayout(
        viewportExtent: viewportExtent,
        childConstraints: childConstraints,
        itemCount: itemCount,
      );
    }

    // Update scroll metrics with axis direction
    final maxExtent = math.max(0.0, totalExtent - viewportExtent);
    final axisDirection = axisToAxisDirection(
      scrollDirection,
      reverse: _reverse,
    );
    _controller.updateMetrics(
      minScrollExtent: 0,
      maxScrollExtent: maxExtent,
      viewportDimension: viewportExtent,
      axisDirection: axisDirection,
    );

    // Clean up invisible children in lazy mode
    if (_lazy && _visibleChildren.isNotEmpty) {
      final firstIndex = _visibleChildren.first.index;
      final lastIndex = _visibleChildren.last.index;
      _element!.removeInvisibleChildren(
        firstIndex >= 0 ? firstIndex : 0,
        lastIndex >= 0 ? lastIndex : itemCount ?? lastIndex,
      );
    }
  }

  /// Performs lazy layout - only builds visible children
  double _performLazyLayout({
    required double viewportExtent,
    required BoxConstraints childConstraints,
    required int? itemCount,
  }) {
    final scrollOffset = _controller.offset;
    double currentPosition = 0;
    int itemIndex = 0;

    // Find first visible item
    if (itemExtent != null) {
      // Fast path for fixed extent
      itemIndex = (scrollOffset / itemExtent!).floor();
      currentPosition = itemIndex * itemExtent!;
    } else {
      // For variable extent, start from 0
      itemIndex = 0;
      currentPosition = 0;
    }

    // Track total extent of measured items for average calculation
    double totalMeasuredExtent = 0;
    int measuredCount = 0;

    while (currentPosition < scrollOffset + viewportExtent) {
      if (itemCount != null && itemIndex >= itemCount) break;

      // Build item
      final child = _element!.buildChild(itemIndex);
      if (child == null) break;

      // Get render object
      final renderObject = _getRenderObject(child);
      if (renderObject == null) continue;

      // Layout child
      renderObject.layout(childConstraints, parentUsesSize: true);

      // Track item extent for average calculation
      final childExtent = scrollDirection == Axis.vertical
          ? renderObject.size.height
          : renderObject.size.width;
      totalMeasuredExtent += childExtent;
      measuredCount++;

      // Store child info if visible
      if (currentPosition + childExtent > scrollOffset) {
        _visibleChildren.add(
          _ChildLayoutInfo(
            renderObject: renderObject,
            offset: currentPosition,
            index: itemIndex,
          ),
        );
      }

      currentPosition += childExtent;

      // Add separator if needed
      if (hasSeparators && (itemCount == null || itemIndex < itemCount - 1)) {
        final separator = _element!.buildSeparator(itemIndex);
        if (separator != null) {
          final separatorRenderObject = _getRenderObject(separator);
          if (separatorRenderObject != null) {
            separatorRenderObject.layout(
              childConstraints,
              parentUsesSize: true,
            );
            final separatorExtent = scrollDirection == Axis.vertical
                ? separatorRenderObject.size.height
                : separatorRenderObject.size.width;

            if (currentPosition + separatorExtent > scrollOffset) {
              _visibleChildren.add(
                _ChildLayoutInfo(
                  renderObject: separatorRenderObject,
                  offset: currentPosition,
                  index: -itemIndex - 1,
                ),
              );
            }
            currentPosition += separatorExtent;
          }
        }
      }

      itemIndex++;
    }

    // Update average item extent if we measured any items
    if (measuredCount > 0) {
      final newAverage = totalMeasuredExtent / measuredCount;
      if (_averageItemExtent == null) {
        _averageItemExtent = newAverage;
      } else {
        // Smooth the average to avoid jumps
        _averageItemExtent = (_averageItemExtent! * 0.7) + (newAverage * 0.3);
      }
    }

    // Calculate total extent
    if (itemExtent != null && itemCount != null) {
      // Fixed extent - exact calculation
      return itemExtent! * itemCount + (hasSeparators ? (itemCount - 1) : 0);
    } else if (itemCount != null && _averageItemExtent != null) {
      // Variable extent with known count - estimate based on average
      double extent = _averageItemExtent! * itemCount;
      if (hasSeparators) {
        extent += itemCount - 1;
      }
      return extent;
    } else {
      // Unknown count or no measurements yet - use what we've built
      return currentPosition;
    }
  }

  /// Performs eager layout - builds all children for accurate extent
  double _performEagerLayout({
    required double viewportExtent,
    required BoxConstraints childConstraints,
    required int? itemCount,
  }) {
    final scrollOffset = _controller.offset;
    double currentPosition = 0;

    // Build all children to get accurate total extent
    int itemIndex = 0;
    final maxItems = itemCount ?? 1000; // Reasonable limit for non-lazy mode

    while (itemIndex < maxItems) {
      // Build item
      final child = _element!.buildChild(itemIndex);
      if (child == null) break;

      // Get render object
      final renderObject = _getRenderObject(child);
      if (renderObject == null) continue;

      // Layout child
      renderObject.layout(childConstraints, parentUsesSize: true);

      final childExtent = scrollDirection == Axis.vertical
          ? renderObject.size.height
          : renderObject.size.width;

      // Store all children info
      _allChildren.add(
        _ChildLayoutInfo(
          renderObject: renderObject,
          offset: currentPosition,
          index: itemIndex,
        ),
      );

      // Check if visible
      if (currentPosition < scrollOffset + viewportExtent &&
          currentPosition + childExtent > scrollOffset) {
        _visibleChildren.add(
          _ChildLayoutInfo(
            renderObject: renderObject,
            offset: currentPosition,
            index: itemIndex,
          ),
        );
      }

      currentPosition += childExtent;

      // Add separator if needed
      if (hasSeparators && (itemCount == null || itemIndex < itemCount - 1)) {
        final separator = _element!.buildSeparator(itemIndex);
        if (separator != null) {
          final separatorRenderObject = _getRenderObject(separator);
          if (separatorRenderObject != null) {
            separatorRenderObject.layout(
              childConstraints,
              parentUsesSize: true,
            );
            final separatorExtent = scrollDirection == Axis.vertical
                ? separatorRenderObject.size.height
                : separatorRenderObject.size.width;

            _allChildren.add(
              _ChildLayoutInfo(
                renderObject: separatorRenderObject,
                offset: currentPosition,
                index: -itemIndex - 1,
              ),
            );

            if (currentPosition < scrollOffset + viewportExtent &&
                currentPosition + separatorExtent > scrollOffset) {
              _visibleChildren.add(
                _ChildLayoutInfo(
                  renderObject: separatorRenderObject,
                  offset: currentPosition,
                  index: -itemIndex - 1,
                ),
              );
            }

            currentPosition += separatorExtent;
          }
        }
      }

      itemIndex++;
    }

    return currentPosition; // Exact total extent
  }

  /// Helper to get render object from element
  RenderObject? _getRenderObject(Element element) {
    RenderObject? renderObject;
    void findRenderObject(Element el) {
      if (el is RenderObjectElement) {
        renderObject = el.renderObject;
      } else {
        el.visitChildren(findRenderObject);
      }
    }

    findRenderObject(element);
    return renderObject;
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    final effectivePadding = padding ?? EdgeInsets.zero;

    // Create clipped canvas for viewport
    final clippedCanvas = canvas.clip(
      Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
    );

    // Calculate viewport extent for reverse mode
    final viewportExtent = scrollDirection == Axis.vertical
        ? size.height - effectivePadding.top - effectivePadding.bottom
        : size.width - effectivePadding.left - effectivePadding.right;

    // Paint only visible children
    for (final child in _visibleChildren) {
      double childPosition = child.offset - _controller.offset;

      // In reverse mode, flip the position
      if (_reverse) {
        final childExtent = scrollDirection == Axis.vertical
            ? child.renderObject.size.height
            : child.renderObject.size.width;
        childPosition = viewportExtent - childPosition - childExtent;
      }

      final childOffset = scrollDirection == Axis.vertical
          ? Offset(effectivePadding.left, effectivePadding.top + childPosition)
          : Offset(effectivePadding.left + childPosition, effectivePadding.top);

      child.renderObject.paint(clippedCanvas, childOffset);
    }
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    for (final child in _visibleChildren) {
      visitor(child.renderObject);
    }
  }

  @override
  bool hitTest(HitTestResult result, {required Offset position}) {
    // Check if position is within our bounds
    if (!Rect.fromLTWH(0, 0, size.width, size.height).contains(position)) {
      return false;
    }

    // Test children (will add to result if hit)
    bool hitChild = hitTestChildren(result, position: position);

    // Add ourselves if we hit
    if (hitChild || hitTestSelf(position)) {
      result.add(this);
      return true;
    }

    return false;
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    final effectivePadding = padding ?? EdgeInsets.zero;
    final scrollOffset = _controller.offset;

    // Calculate viewport extent for reverse mode
    final viewportExtent = scrollDirection == Axis.vertical
        ? size.height - effectivePadding.top - effectivePadding.bottom
        : size.width - effectivePadding.left - effectivePadding.right;

    // Test visible children in reverse order (front to back)
    for (int i = _visibleChildren.length - 1; i >= 0; i--) {
      final child = _visibleChildren[i];
      double childPosition = child.offset - scrollOffset;

      // Get child extent (needed for reverse mode and bounds checking)
      final childExtent = scrollDirection == Axis.vertical
          ? child.renderObject.size.height
          : child.renderObject.size.width;

      // Apply reverse mode transformation
      if (_reverse) {
        childPosition = viewportExtent - childPosition - childExtent;
      }

      final childOffset = scrollDirection == Axis.vertical
          ? Offset(effectivePadding.left, effectivePadding.top + childPosition)
          : Offset(effectivePadding.left + childPosition, effectivePadding.top);

      // Check if position is within child's bounds before testing
      final childBounds = Rect.fromLTWH(
        childOffset.dx,
        childOffset.dy,
        child.renderObject.size.width,
        child.renderObject.size.height,
      );

      if (!childBounds.contains(position)) {
        continue; // Skip this child
      }

      // Transform position to child's local coordinates
      final localPosition = position - childOffset;

      // Test if this child was hit
      if (child.renderObject.hitTest(result, position: localPosition)) {
        return true;
      }
    }

    return false;
  }

  /// Gets the offset and extent of an item by its index.
  ///
  /// Returns a record with (offset, extent) if the item is found,
  /// or null if the item doesn't exist or hasn't been laid out yet.
  ///
  /// This method works in both lazy and non-lazy modes:
  /// - In non-lazy mode, queries the _allChildren list for accurate positions
  /// - In lazy mode, checks _visibleChildren or estimates based on itemExtent
  (double, double)? getItemOffsetAndExtent(int index) {
    // First check if we're in non-lazy mode and have all children
    if (!_lazy && _allChildren.isNotEmpty) {
      // Find the item in all children
      for (final child in _allChildren) {
        if (child.index == index) {
          final extent = scrollDirection == Axis.vertical
              ? child.renderObject.size.height
              : child.renderObject.size.width;
          return (child.offset, extent);
        }
      }
      return null; // Item not found
    }

    // For lazy mode, check visible children first
    for (final child in _visibleChildren) {
      if (child.index == index) {
        final extent = scrollDirection == Axis.vertical
            ? child.renderObject.size.height
            : child.renderObject.size.width;
        return (child.offset, extent);
      }
    }

    // If item is not visible in lazy mode, try to estimate if we have itemExtent
    if (_lazy && itemExtent != null) {
      // Fixed extent - we can calculate exact position
      final offset = index * itemExtent!;
      return (offset, itemExtent!);
    }

    // If item is not visible and we can't estimate, we need to build it
    // This is only safe to do during layout
    // For now, return null to indicate item position is unknown
    return null;
  }
}

/// Information about a visible child in the viewport.
class _ChildLayoutInfo {
  const _ChildLayoutInfo({
    required this.renderObject,
    required this.offset,
    required this.index,
  });

  final RenderObject renderObject;
  final double offset;
  final int index;
}
