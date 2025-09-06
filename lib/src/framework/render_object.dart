part of 'framework.dart';

/// Visitor for render objects.
typedef RenderObjectVisitor = void Function(RenderObject renderObject);

/// Result of a hit test.
class HitTestResult {
  final List<RenderObject> path = [];

  void add(RenderObject renderObject) {
    path.add(renderObject);
  }
}

/// The pipeline owner manages the rendering pipeline.
class PipelineOwner {
  final List<RenderObject> _nodesNeedingLayout = [];
  final List<RenderObject> _nodesNeedingPaint = [];

  /// Callback to request a visual update (frame)
  VoidCallback? onNeedsVisualUpdate;

  void requestLayout(RenderObject renderObject) {
    _nodesNeedingLayout.add(renderObject);
    requestVisualUpdate();
  }

  void requestPaint(RenderObject renderObject) {
    if (!_nodesNeedingPaint.contains(renderObject)) {
      _nodesNeedingPaint.add(renderObject);
      requestVisualUpdate();
    }
  }

  /// Request that a frame be scheduled
  void requestVisualUpdate() {
    onNeedsVisualUpdate?.call();
  }

  void flushLayout() {
    // Sort by depth to process parents before children
    _nodesNeedingLayout.sort((a, b) => a.depth.compareTo(b.depth));

    while (_nodesNeedingLayout.isNotEmpty) {
      final node = _nodesNeedingLayout.removeLast();
      if (node._needsLayout && node.owner == this) {
        node._layoutWithoutResize();
      }
    }
  }

  void flushPaint() {
    // Sort by depth (deepest first) for paint order
    final List<RenderObject> dirtyNodes = List<RenderObject>.from(_nodesNeedingPaint);
    _nodesNeedingPaint.clear();

    // Sort nodes by depth - deeper nodes should be painted first
    dirtyNodes.sort((a, b) => b.depth.compareTo(a.depth));

    for (final node in dirtyNodes) {
      if (node._needsPaint && node.owner == this) {
        // In a full implementation, this would trigger actual painting
        // For now, we just mark the node as clean
        node._needsPaint = false;
      }
    }
  }
}

/// Constraints passed down the render tree
@immutable
class BoxConstraints {
  const BoxConstraints({
    this.minWidth = 0,
    this.maxWidth = double.infinity,
    this.minHeight = 0,
    this.maxHeight = double.infinity,
  });

  BoxConstraints.tight(Size size)
      : minWidth = size.width,
        maxWidth = size.width,
        minHeight = size.height,
        maxHeight = size.height;

  const BoxConstraints.expand({double? width, double? height})
      : minWidth = width ?? double.infinity,
        maxWidth = width ?? double.infinity,
        minHeight = height ?? double.infinity,
        maxHeight = height ?? double.infinity;

  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;

  Size constrain(Size size) {
    return Size(
      size.width.clamp(minWidth, maxWidth),
      size.height.clamp(minHeight, maxHeight),
    );
  }

  BoxConstraints deflate(EdgeInsets insets) {
    final horizontal = insets.left + insets.right;
    final vertical = insets.top + insets.bottom;
    final deflatedMinWidth = (minWidth - horizontal).clamp(0.0, double.infinity);
    final deflatedMaxWidth = (maxWidth - horizontal).clamp(deflatedMinWidth, double.infinity);
    final deflatedMinHeight = (minHeight - vertical).clamp(0.0, double.infinity);
    final deflatedMaxHeight = (maxHeight - vertical).clamp(deflatedMinHeight, double.infinity);
    return BoxConstraints(
      minWidth: deflatedMinWidth,
      maxWidth: deflatedMaxWidth,
      minHeight: deflatedMinHeight,
      maxHeight: deflatedMaxHeight,
    );
  }

  /// Returns new box constraints that remove the minimum width and height requirements.
  BoxConstraints loosen() {
    return BoxConstraints(
      minWidth: 0.0,
      maxWidth: maxWidth,
      minHeight: 0.0,
      maxHeight: maxHeight,
    );
  }

  bool get hasBoundedWidth => maxWidth < double.infinity;
  bool get hasBoundedHeight => maxHeight < double.infinity;
  bool get hasInfiniteWidth => minWidth >= double.infinity;
  bool get hasInfiniteHeight => minHeight >= double.infinity;

  @override
  String toString() {
    return 'BoxConstraints($minWidth..$maxWidth x $minHeight..$maxHeight)';
  }
}

/// Position offset
@immutable
class Offset {
  const Offset(this.dx, this.dy);

  final double dx;
  final double dy;

  static const Offset zero = Offset(0, 0);

  Offset operator +(Offset other) => Offset(dx + other.dx, dy + other.dy);
  Offset operator -(Offset other) => Offset(dx - other.dx, dy - other.dy);

  @override
  String toString() => 'Offset($dx, $dy)';
}

/// Edge insets for padding/margins
@immutable
class EdgeInsets {
  const EdgeInsets.only({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  const EdgeInsets.all(double value)
      : left = value,
        top = value,
        right = value,
        bottom = value;

  const EdgeInsets.symmetric({double vertical = 0, double horizontal = 0})
      : left = horizontal,
        top = vertical,
        right = horizontal,
        bottom = vertical;

  final double left;
  final double top;
  final double right;
  final double bottom;

  static const EdgeInsets zero = EdgeInsets.only();
}

/// Base class for parent data
class ParentData {
  /// Called when the RenderObject is removed from the tree.
  @mustCallSuper
  void detach() {}

  @override
  String toString() => '<none>';
}

/// Base class for render objects in the TUI framework.
///
/// RenderObjects are the building blocks of the render tree. They handle:
/// - Layout: Computing their size based on constraints from their parent
/// - Painting: Drawing themselves and their children to the terminal canvas
/// - Hit testing: Determining which render object is at a given position
///
/// The render tree is separate from the component tree and is optimized for
/// layout and painting operations.
abstract class RenderObject {
  /// The parent of this render object in the render tree.
  RenderObject? parent;

  /// Data associated with this render object by its parent.
  ///
  /// Parent data is used to store information that the parent render object
  /// needs to associate with each child, such as position offsets or flex values.
  ParentData? parentData;

  /// The owner for this render object (null if unattached).
  PipelineOwner? owner;

  BoxConstraints? _constraints;

  /// The box constraints most recently received from the parent.
  BoxConstraints get constraints => _constraints!;

  Size? _size;

  /// The size of this render object as determined during layout.
  ///
  /// This value is set by [performLayout] and should not be set directly
  /// except within [performLayout].
  Size get size => _size!;

  /// Protected setter for size that should only be used in [performLayout].
  @protected
  set size(Size value) {
    _size = value;
  }

  bool _needsLayout = true;
  bool _needsPaint = true;

  /// Whether this render object has been laid out and has a size.
  bool get hasSize => _size != null;

  /// Mark this render object as needing layout.
  ///
  /// This will cause [performLayout] to be called during the next layout pass.
  /// The layout mark is propagated up the tree to ensure ancestors also re-layout.
  void markNeedsLayout() {
    if (_needsLayout) return;
    _needsLayout = true;
    markNeedsPaint();
    parent?.markNeedsLayout();
  }

  /// Mark this render object as needing to be repainted.
  ///
  /// This will cause [paint] to be called during the next paint pass.
  /// The paint request will propagate up the tree until it reaches a
  /// repaint boundary, at which point it will be registered with the
  /// pipeline owner for processing during the next frame.
  void markNeedsPaint() {
    if (_needsPaint) return;
    _needsPaint = true;

    // Check if this is a repaint boundary
    if (parent != null) {
      // Continue propagation up the tree
      parent!.markNeedsPaint();
    } else {
      // We're the root - request visual update
      owner?.requestVisualUpdate();
    }
  }

  /// Compute the layout for this render object.
  ///
  /// This method is called by the framework with constraints from the parent.
  /// It should call [performLayout] if needed, which must set the [size].
  ///
  /// The [parentUsesSize] parameter indicates whether the parent depends on
  /// this render object's size for its own layout. This is used for optimization.
  void layout(BoxConstraints constraints, {bool parentUsesSize = false}) {
    if (!_needsLayout && constraints == _constraints) return;

    _constraints = constraints;
    // TODO remove the || true at some point
    if (_needsLayout || _size == null || true) {
      performLayout();
      assert(_size != null, 'performLayout() did not set a size');
      _needsLayout = false;
    }
  }

  /// Do the actual work of computing this render object's layout.
  ///
  /// This method must set [size] to the actual size of this render object
  /// within the given [constraints]. The constraints are accessible via
  /// the [constraints] getter.
  ///
  /// Subclasses that have children should call [layout] on each child here
  /// and position them appropriately.
  ///
  /// ## Example implementation:
  /// ```dart
  /// @override
  /// void performLayout() {
  ///   // For a leaf node, just pick a size within constraints
  ///   size = constraints.constrain(Size(desiredWidth, desiredHeight));
  ///
  ///   // For a node with children:
  ///   // 1. Layout children with appropriate constraints
  ///   // 2. Position children (set their parentData.offset)
  ///   // 3. Set this node's size based on children
  /// }
  /// ```
  @protected
  void performLayout();

  /// Paint this render object and its children.
  ///
  /// The [canvas] provides drawing operations and the [offset] is the position
  /// in the parent's coordinate system where this render object should paint itself.
  ///
  /// Subclasses should override this to paint themselves and call paint on
  /// their children with adjusted offsets.
  @mustCallSuper
  void paint(TerminalCanvas canvas, Offset offset) {
    _needsPaint = false;
    // Subclasses override this to paint
  }

  /// Attach this render object to the tree with the given owner.
  void attach(PipelineOwner owner) {
    this.owner = owner;
    // If we were already marked as needing layout or paint, notify the owner
    if (_needsLayout && parent == null) {
      owner.requestLayout(this);
    }
    if (_needsPaint && parent == null) {
      owner.requestPaint(this);
    }
  }

  /// Detach this render object from the tree.
  void detach() {
    owner = null;
    parent = null;
  }

  /// Visit each child of this render object.
  ///
  /// The [visitor] function is called for each child in order.
  /// Subclasses with children should override this method.
  void visitChildren(void Function(RenderObject child) visitor) {
    // Override in subclasses that have children
  }

  /// Setup parent data for a child render object.
  ///
  /// This is called when a child is added to ensure it has the correct
  /// parent data type for this parent.
  void setupParentData(covariant RenderObject child) {
    // Default implementation does nothing
    // Subclasses should override to initialize parentData
  }

  /// Adopt a child render object.
  void adoptChild(RenderObject child) {
    setupParentData(child);
    child.parent = this;
    markNeedsLayout();
  }

  /// Drop a child render object.
  void dropChild(RenderObject child) {
    child.detach();
    markNeedsLayout();
  }

  /// Test whether a point hits this render object.
  bool hitTest(HitTestResult result, {required Offset position}) {
    if (Rect.fromLTWH(0, 0, size.width, size.height).contains(position)) {
      result.add(this);
      return hitTestChildren(result, position: position) || hitTestSelf(position);
    }
    return false;
  }

  /// Override this to test whether your children hit at the given position.
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    return false;
  }

  /// Override this to test whether this render object hits at the given position.
  bool hitTestSelf(Offset position) {
    return false;
  }

  /// Called during layout to update internal layout state.
  void _layoutWithoutResize() {
    performLayout();
    _needsLayout = false;
    markNeedsPaint();
  }

  /// Get the depth of this node in the tree (for sorting)
  int get depth {
    int count = 0;
    RenderObject? node = parent;
    while (node != null) {
      count++;
      node = node.parent;
    }
    return count;
  }

  /// Dispose of any resources.
  void dispose() {
    // Override in subclasses to dispose resources
  }
}

/// Parent data used by RenderBox and its subclasses
class BoxParentData extends ParentData {
  /// The offset at which to paint the child in the parent's coordinate system
  Offset offset = Offset.zero;

  @override
  String toString() => 'offset=$offset';
}

/// RenderObject that can have a single child
mixin RenderObjectWithChildMixin<ChildType extends RenderObject> on RenderObject {
  ChildType? _child;
  ChildType? get child => _child;

  set child(ChildType? value) {
    if (_child != null) {
      dropChild(_child!);
    }
    _child = value;
    if (_child != null) {
      adoptChild(_child!);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _child?.attach(owner);
  }

  @override
  void detach() {
    _child?.detach();
    super.detach();
  }

  @override
  void visitChildren(void Function(RenderObject child) visitor) {
    if (_child != null) {
      visitor(_child!);
    }
  }
}

/// RenderObject that can have multiple children
mixin ContainerRenderObjectMixin<ChildType extends RenderObject> on RenderObject {
  final List<ChildType> _children = [];
  List<ChildType> get children => _children;

  void addChild(ChildType child) {
    adoptChild(child);
    _children.add(child);
  }

  void removeChild(ChildType child) {
    _children.remove(child);
    dropChild(child);
  }

  /// Insert a child at the correct position in the children list
  void insert(ChildType child, {ChildType? after}) {
    adoptChild(child);
    if (after == null) {
      // Insert at the beginning
      _children.insert(0, child);
    } else {
      final int index = _children.indexOf(after);
      if (index < 0) {
        // If 'after' is not found, add at the end as fallback
        _children.add(child);
      } else {
        // Insert after the specified child
        _children.insert(index + 1, child);
      }
    }
  }

  /// Move a child to a new position in the children list
  void move(ChildType child, {ChildType? after}) {
    assert(_children.contains(child));
    _children.remove(child);
    if (after == null) {
      // Move to the beginning
      _children.insert(0, child);
    } else {
      final int index = _children.indexOf(after);
      if (index < 0) {
        // If 'after' is not found, add at the end as fallback
        _children.add(child);
      } else {
        // Insert after the specified child
        _children.insert(index + 1, child);
      }
    }
  }

  void removeAll() {
    for (final child in _children) {
      child.detach();
    }
    _children.clear();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (final child in _children) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    for (final child in _children) {
      child.detach();
    }
    super.detach();
  }

  @override
  void visitChildren(void Function(RenderObject child) visitor) {
    for (final child in _children) {
      visitor(child);
    }
  }
}

/// Component that creates a RenderObject
abstract class RenderObjectComponent extends Component {
  const RenderObjectComponent({super.key});

  @protected
  RenderObject createRenderObject(BuildContext context);

  @protected
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {}
}

/// Element for RenderObjectComponent
abstract class RenderObjectElement extends Element {
  RenderObjectElement(RenderObjectComponent super.component);

  @override
  RenderObjectComponent get component => super.component as RenderObjectComponent;

  RenderObject? _renderObject;
  RenderObject get renderObject => _renderObject!;

  /// The ancestor [RenderObjectElement] that this element's [renderObject] is attached to.
  RenderObjectElement? _ancestorRenderObjectElement;

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _renderObject = component.createRenderObject(this);
    attachRenderObject(newSlot);
  }

  @override
  void update(Component newComponent) {
    super.update(newComponent);
    component.updateRenderObject(this, renderObject);
  }

  @override
  void updateSlot(dynamic newSlot) {
    final dynamic oldSlot = slot;
    assert(oldSlot != newSlot);
    super.updateSlot(newSlot);
    assert(slot == newSlot);
    assert(_ancestorRenderObjectElement == _findAncestorRenderObjectElement());
    _ancestorRenderObjectElement?.moveRenderObjectChild(renderObject, oldSlot, slot);
  }

  @override
  void detachRenderObject() {
    if (_ancestorRenderObjectElement != null) {
      _ancestorRenderObjectElement!.removeRenderObjectChild(renderObject, slot);
      _ancestorRenderObjectElement = null;
    }
    super.detachRenderObject();
  }

  @override
  void attachRenderObject(dynamic newSlot) {
    assert(_renderObject != null);
    assert(_ancestorRenderObjectElement == null);
    _ancestorRenderObjectElement = _findAncestorRenderObjectElement();
    _ancestorRenderObjectElement?.insertRenderObjectChild(renderObject, newSlot);
  }

  RenderObjectElement? _findAncestorRenderObjectElement() {
    Element? ancestor = parent;
    while (ancestor != null && ancestor is! RenderObjectElement) {
      ancestor = ancestor.parent;
    }
    return ancestor as RenderObjectElement?;
  }

  /// Insert the given child into [renderObject] at the given slot.
  ///
  /// The semantics of `slot` are determined by this element. For example, if
  /// this element has a single child, the slot should always be null. If this
  /// element has a list of children, the previous sibling element wrapped in an
  /// [IndexedSlot] is a convenient value for the slot.
  @protected
  void insertRenderObjectChild(RenderObject child, dynamic slot);

  /// Move the given child from the given old slot to the given new slot.
  ///
  /// The given child is guaranteed to have [renderObject] as its parent.
  ///
  /// This method is only ever called if [updateChild] can end up being called
  /// with an existing [Element] child and a `slot` that differs from the slot
  /// that element was previously given.
  @protected
  void moveRenderObjectChild(RenderObject child, dynamic oldSlot, dynamic newSlot);

  /// Remove the given child from [renderObject].
  ///
  /// The given child is guaranteed to have been inserted at the given `slot`
  /// and have [renderObject] as its parent.
  @protected
  void removeRenderObjectChild(RenderObject child, dynamic slot);
}

/// Element that has a single child
class SingleChildRenderObjectElement extends RenderObjectElement {
  SingleChildRenderObjectElement(RenderObjectComponent super.component);

  Element? _child;

  @override
  void performRebuild() {
    // Render object elements don't rebuild like buildable elements
    _dirty = false;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) {
      visitor(_child!);
    }
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    // Some single child render objects (like Text) don't have children
    try {
      final dynamic comp = component;
      final Component? childComponent = comp.child;
      _child = updateChild(_child, childComponent, null);
    } catch (e) {
      // Component doesn't have a child property
    }
  }

  @override
  void update(Component newComponent) {
    super.update(newComponent);
    // Some single child render objects (like Text) don't have children
    try {
      final dynamic comp = newComponent;
      final Component? childComponent = comp.child;
      _child = updateChild(_child, childComponent, null);
    } catch (e) {
      // Component doesn't have a child property
    }
  }

  @override
  void insertRenderObjectChild(RenderObject child, dynamic slot) {
    final RenderObjectWithChildMixin<RenderObject> renderObject =
        this.renderObject as RenderObjectWithChildMixin<RenderObject>;
    renderObject.child = child;
  }

  @override
  void moveRenderObjectChild(RenderObject child, dynamic oldSlot, dynamic newSlot) {
    // SingleChildRenderObjectElement never moves children since slot is always null
    assert(false, 'SingleChildRenderObjectElement should never move children');
  }

  @override
  void removeRenderObjectChild(RenderObject child, dynamic slot) {
    final RenderObjectWithChildMixin<RenderObject> renderObject =
        this.renderObject as RenderObjectWithChildMixin<RenderObject>;
    assert(slot == null);
    assert(renderObject.child == child);
    renderObject.child = null;
  }
}

/// Element that has multiple children
class MultiChildRenderObjectElement extends RenderObjectElement {
  MultiChildRenderObjectElement(RenderObjectComponent super.component);

  List<Element> _children = const [];

  @override
  void performRebuild() {
    // Render object elements don't rebuild like buildable elements
    _dirty = false;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final child in _children) {
      visitor(child);
    }
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    final List<Component> children = (component as dynamic).children ?? const [];
    Element? previousChild;
    _children = List<Element>.generate(children.length, (index) {
      final slot = IndexedSlot(index, previousChild);
      final child = inflateComponent(children[index], slot);
      previousChild = child;
      return child;
    });
  }

  @override
  void update(Component newComponent) {
    super.update(newComponent);
    final List<Component> newChildren = (newComponent as dynamic).children ?? const [];
    _children = updateChildren(_children, newChildren);
  }

  /// Find the last render object descendant of an element.
  /// This traverses down the tree to find render objects even when
  /// the element itself is not a RenderObjectElement (e.g., StatelessComponent).
  RenderObject? _findLastRenderObjectDescendant(Element element) {
    RenderObject? result;
    
    // If this is a RenderObjectElement, return its render object
    if (element is RenderObjectElement) {
      return element.renderObject;
    }
    
    // Otherwise, traverse children to find the last render object
    element.visitChildren((Element child) {
      final RenderObject? childRenderObject = _findLastRenderObjectDescendant(child);
      if (childRenderObject != null) {
        result = childRenderObject;
      }
    });
    
    return result;
  }

  @override
  void insertRenderObjectChild(RenderObject child, dynamic slot) {
    final ContainerRenderObjectMixin<RenderObject> renderObject =
        this.renderObject as ContainerRenderObjectMixin<RenderObject>;

    if (slot is IndexedSlot) {
      // Insert the child at the correct position based on the slot
      // The slot.value contains the previous element, we need its render object
      final Element? previousElement = slot.value as Element?;
      RenderObject? previousRenderObject;

      // Find the render object from the previous element, traversing down if needed
      if (previousElement != null) {
        previousRenderObject = _findLastRenderObjectDescendant(previousElement);
      }

      renderObject.insert(child, after: previousRenderObject);
    } else {
      // Fallback for non-indexed slots
      renderObject.addChild(child);
    }
  }

  @override
  void moveRenderObjectChild(RenderObject child, dynamic oldSlot, dynamic newSlot) {
    final ContainerRenderObjectMixin<RenderObject> renderObject =
        this.renderObject as ContainerRenderObjectMixin<RenderObject>;

    if (newSlot is IndexedSlot) {
      // Move the child to the new position based on the slot
      final Element? previousElement = newSlot.value as Element?;
      RenderObject? previousRenderObject;

      // Find the render object from the previous element, traversing down if needed
      if (previousElement != null) {
        previousRenderObject = _findLastRenderObjectDescendant(previousElement);
      }

      renderObject.move(child, after: previousRenderObject);
    }
    // If not an IndexedSlot, do nothing (child stays in place)
  }

  @override
  void removeRenderObjectChild(RenderObject child, dynamic slot) {
    final ContainerRenderObjectMixin<RenderObject> renderObject =
        this.renderObject as ContainerRenderObjectMixin<RenderObject>;
    renderObject.removeChild(child);
  }
}

/// Slot used for children of MultiChildRenderObjectElement
class IndexedSlot {
  const IndexedSlot(this.index, this.value);

  final int index;
  final dynamic value;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is IndexedSlot && index == other.index && value == other.value;
  }

  @override
  int get hashCode => Object.hash(index, value);
}
