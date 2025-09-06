import 'dart:math' as math;

import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import 'package:nocterm/src/rectangle.dart';
import '../keyboard/mouse_event.dart';
import '../rendering/scrollable_render_object.dart';

/// Signature for a function that creates a widget for a given index.
typedef IndexedWidgetBuilder = Component? Function(BuildContext context, int index);

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
    this.controller,
    this.padding,
    this.itemExtent,
    List<Component> children = const [],
  })  : itemCount = children.length,
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
    this.controller,
    this.padding,
    this.itemExtent,
    required this.itemBuilder,
    this.itemCount,
  }) : separatorBuilder = null;

  /// Creates a scrollable, linear array of widgets with a separator between each item.
  const ListView.separated({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.padding,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.itemCount,
  }) : itemExtent = null;

  /// The axis along which the scroll view scrolls.
  final Axis scrollDirection;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  final ScrollController? controller;

  /// The amount of space by which to inset the children.
  final EdgeInsets? padding;

  /// If non-null, forces the children to have the given extent in the scroll
  /// direction.
  final double? itemExtent;

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

  ScrollController get _effectiveController => component.controller ?? _controller!;

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

  bool _handleKeyEvent(KeyboardEvent event) {
    final controller = _effectiveController;
    final key = event.logicalKey;

    if (component.scrollDirection == Axis.vertical) {
      if (key == LogicalKey.arrowUp) {
        controller.scrollUp();
        return true;
      } else if (key == LogicalKey.arrowDown) {
        controller.scrollDown();
        return true;
      } else if (key == LogicalKey.pageUp) {
        controller.pageUp();
        return true;
      } else if (key == LogicalKey.pageDown) {
        controller.pageDown();
        return true;
      } else if (key == LogicalKey.home) {
        controller.scrollToStart();
        return true;
      } else if (key == LogicalKey.end) {
        controller.scrollToEnd();
        return true;
      }
    } else {
      if (key == LogicalKey.arrowLeft) {
        controller.scrollUp();
        return true;
      } else if (key == LogicalKey.arrowRight) {
        controller.scrollDown();
        return true;
      } else if (key == LogicalKey.home) {
        controller.scrollToStart();
        return true;
      } else if (key == LogicalKey.end) {
        controller.scrollToEnd();
        return true;
      }
    }
    return false;
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: _handleKeyEvent,
      child: _ListViewport(
        scrollDirection: component.scrollDirection,
        controller: _effectiveController,
        padding: component.padding,
        itemExtent: component.itemExtent,
        itemBuilder: component.itemBuilder,
        separatorBuilder: component.separatorBuilder,
        itemCount: component.itemCount,
      ),
    );
  }
}

/// Internal widget that handles the viewport and rendering for ListView.
class _ListViewport extends RenderObjectComponent {
  const _ListViewport({
    required this.scrollDirection,
    required this.controller,
    this.padding,
    this.itemExtent,
    required this.itemBuilder,
    this.separatorBuilder,
    this.itemCount,
  });

  final Axis scrollDirection;
  final ScrollController controller;
  final EdgeInsets? padding;
  final double? itemExtent;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final int? itemCount;

  @override
  Element createElement() => _ListViewportElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderListViewport(
      scrollDirection: scrollDirection,
      controller: controller,
      padding: padding,
      itemExtent: itemExtent,
      hasSeparators: separatorBuilder != null,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderListViewport renderObject) {
    renderObject
      ..scrollDirection = scrollDirection
      ..controller = controller
      ..padding = padding
      ..itemExtent = itemExtent
      ..hasSeparators = separatorBuilder != null;
  }
}

/// Element for ListView that manages building children on demand.
class _ListViewportElement extends RenderObjectElement {
  _ListViewportElement(_ListViewport super.component);

  @override
  _ListViewport get component => super.component as _ListViewport;

  @override
  RenderListViewport get renderObject => super.renderObject as RenderListViewport;

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
  void moveRenderObjectChild(RenderObject child, dynamic oldSlot, dynamic newSlot) {
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

    if (oldSeparator != null && Component.canUpdate(oldSeparator.component, separator)) {
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
      _children[key]?.unmount();
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
    required ScrollController controller,
    EdgeInsets? padding,
    double? itemExtent,
    bool hasSeparators = false,
  })  : _scrollDirection = scrollDirection,
        _controller = controller,
        _padding = padding,
        _itemExtent = itemExtent,
        _hasSeparators = hasSeparators {
    _controller.addListener(_handleScrollUpdate);
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

  ScrollController _controller;
  ScrollController get controller => _controller;
  set controller(ScrollController value) {
    if (_controller != value) {
      _controller.removeListener(_handleScrollUpdate);
      _controller = value;
      _controller.addListener(_handleScrollUpdate);
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
        _controller.scrollUp(3.0); // Scroll 3 lines
        return true;
      } else if (event.button == MouseButton.wheelDown) {
        _controller.scrollDown(3.0); // Scroll 3 lines
        return true;
      }
    } else {
      // For horizontal scroll, we might want to handle horizontal wheel events
      // but for now just handle vertical wheel as horizontal scroll
      if (event.button == MouseButton.wheelUp) {
        _controller.scrollUp(3.0);
        return true;
      } else if (event.button == MouseButton.wheelDown) {
        _controller.scrollDown(3.0);
        return true;
      }
    }
    
    return false;
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScrollUpdate);
    super.dispose();
  }

  /// Information about visible children after layout.
  final List<_ChildLayoutInfo> _visibleChildren = [];

  @override
  void performLayout() {
    _visibleChildren.clear();

    if (_element == null) {
      size = constraints.constrain(Size.zero);
      return;
    }

    // Apply padding
    final effectivePadding = padding ?? EdgeInsets.zero;
    final innerConstraints = constraints.deflate(effectivePadding);

    // Our size is constrained by our parent
    size = constraints.constrain(Size(
      constraints.maxWidth,
      constraints.maxHeight,
    ));

    // Calculate viewport dimensions
    final viewportExtent = scrollDirection == Axis.vertical ? innerConstraints.maxHeight : innerConstraints.maxWidth;

    final crossAxisExtent = scrollDirection == Axis.vertical ? innerConstraints.maxWidth : innerConstraints.maxHeight;

    // Determine visible range based on scroll offset
    final scrollOffset = _controller.offset;
    double currentPosition = 0;
    int itemIndex = 0;

    // Find first visible item
    if (itemExtent != null) {
      // Fast path for fixed extent
      itemIndex = (scrollOffset / itemExtent!).floor();
      currentPosition = itemIndex * itemExtent!;
    } else {
      // For variable extent, we need to measure items
      // For simplicity, start from 0 (could optimize with caching)
      itemIndex = 0;
      currentPosition = 0;
    }

    // Build visible children
    final component = _element!.component;
    final itemCount = component.itemCount;

    while (currentPosition < scrollOffset + viewportExtent) {
      if (itemCount != null && itemIndex >= itemCount) break;

      // Build item
      final child = _element!.buildChild(itemIndex);
      if (child == null) break;

      // Get render object - traverse down to find the first RenderObjectElement
      RenderObject? renderObject;
      void findRenderObject(Element element) {
        if (element is RenderObjectElement) {
          renderObject = element.renderObject;
        } else {
          element.visitChildren(findRenderObject);
        }
      }

      findRenderObject(child);

      if (renderObject == null) continue;

      // Layout child
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

      renderObject!.layout(childConstraints, parentUsesSize: true);

      // Store child info if visible
      if (currentPosition + (scrollDirection == Axis.vertical ? renderObject!.size.height : renderObject!.size.width) >
          scrollOffset) {
        _visibleChildren.add(_ChildLayoutInfo(
          renderObject: renderObject!,
          offset: currentPosition,
          index: itemIndex,
        ));
      }

      currentPosition += scrollDirection == Axis.vertical ? renderObject!.size.height : renderObject!.size.width;

      // Add separator if needed
      if (hasSeparators && (itemCount == null || itemIndex < itemCount - 1)) {
        final separator = _element!.buildSeparator(itemIndex);
        if (separator != null) {
          // Get render object for separator
          RenderObject? separatorRenderObject;
          void findSeparatorRenderObject(Element element) {
            if (element is RenderObjectElement) {
              separatorRenderObject = element.renderObject;
            } else {
              element.visitChildren(findSeparatorRenderObject);
            }
          }

          findSeparatorRenderObject(separator);

          if (separatorRenderObject == null) continue;
          separatorRenderObject!.layout(childConstraints, parentUsesSize: true);

          if (currentPosition +
                  (scrollDirection == Axis.vertical
                      ? separatorRenderObject!.size.height
                      : separatorRenderObject!.size.width) >
              scrollOffset) {
            _visibleChildren.add(_ChildLayoutInfo(
              renderObject: separatorRenderObject!,
              offset: currentPosition,
              index: -itemIndex - 1,
            ));
          }

          currentPosition +=
              scrollDirection == Axis.vertical ? separatorRenderObject!.size.height : separatorRenderObject!.size.width;
        }
      }

      itemIndex++;
    }

    // Update scroll metrics
    final totalExtent = itemExtent != null && itemCount != null
        ? itemExtent! * itemCount + (hasSeparators ? (itemCount - 1) : 0)
        : currentPosition; // Approximate for now

    _controller.updateMetrics(
      minScrollExtent: 0,
      maxScrollExtent: math.max(0, totalExtent - viewportExtent),
      viewportDimension: viewportExtent,
    );

    // Clean up invisible children
    if (_visibleChildren.isNotEmpty) {
      final firstIndex = _visibleChildren.first.index;
      final lastIndex = _visibleChildren.last.index;
      _element!.removeInvisibleChildren(
        firstIndex >= 0 ? firstIndex : 0,
        lastIndex >= 0 ? lastIndex : itemCount ?? lastIndex,
      );
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    final effectivePadding = padding ?? EdgeInsets.zero;

    // Create clipped canvas for viewport
    final clippedCanvas = canvas.clip(
      Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
    );

    // Paint visible children
    for (final child in _visibleChildren) {
      final childOffset = scrollDirection == Axis.vertical
          ? Offset(effectivePadding.left, effectivePadding.top + child.offset - _controller.offset)
          : Offset(effectivePadding.left + child.offset - _controller.offset, effectivePadding.top);

      child.renderObject.paint(clippedCanvas, childOffset);
    }
  }

  // Hit testing removed for now
  // @override
  // bool hitTestChildren(HitTestResult result, {required Offset position}) {
  //   final effectivePadding = padding ?? EdgeInsets.zero;
  //
  //   for (final child in _visibleChildren) {
  //     final childOffset = scrollDirection == Axis.vertical
  //         ? Offset(effectivePadding.left,
  //                 effectivePadding.top + child.offset - _controller.offset)
  //         : Offset(effectivePadding.left + child.offset - _controller.offset,
  //                 effectivePadding.top);
  //
  //     if (child.renderObject.hitTest(result, position: position - childOffset)) {
  //       return true;
  //     }
  //   }
  //   return false;
  // }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    for (final child in _visibleChildren) {
      visitor(child.renderObject);
    }
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
