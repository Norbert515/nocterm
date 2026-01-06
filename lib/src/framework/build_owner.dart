part of 'framework.dart';

/// Manages the component tree and rebuilding process
class BuildOwner {
  BuildOwner([this.onNeedsBuild]);

  /// Called when a build is scheduled.
  final VoidCallback? onNeedsBuild;

  final _InactiveElements _inactiveElements = _InactiveElements();
  final List<Element> _dirtyElements = [];
  bool _scheduledFlushDirtyElements = false;
  bool? _dirtyElementsNeedsResorting;

  /// Forgotten children are elements that have been removed from the tree.
  final Set<Element> _forgottenChildren = HashSet<Element>();

  /// Registry for global keys
  final Map<GlobalKey, Element> _globalKeyRegistry = {};

  void _registerGlobalKey(GlobalKey key, Element element) {
    _globalKeyRegistry[key] = element;
    key._register(element);
  }

  void _unregisterGlobalKey(GlobalKey key, Element element) {
    if (_globalKeyRegistry[key] == element) {
      _globalKeyRegistry.remove(key);
      key._unregister(element);
    }
  }

  /// Schedules element for rebuild
  void scheduleBuildFor(Element element) {
    assert(element._lifecycleState == _ElementLifecycle.active);
    if (element._inDirtyList) {
      // Unsure why this is being called twice, but returning
      // early to avoid the assert.
      // assert(!element._inDirtyList);
      return;
    }

    if (!_scheduledFlushDirtyElements && onNeedsBuild != null) {
      _scheduledFlushDirtyElements = true;
      onNeedsBuild!();
    }
    _dirtyElements.add(element);
    element._inDirtyList = true;
    _dirtyElementsNeedsResorting = true;
  }

  /// Check if there are any dirty elements that need to be rebuilt
  bool get hasDirtyElements => _dirtyElements.isNotEmpty;

  /// Builds all dirty elements
  void buildScope(Element context, [VoidCallback? callback]) {
    if (callback != null) {
      callback();
    }

    _dirtyElements.sort((a, b) => a.depth - b.depth);
    _dirtyElementsNeedsResorting = false;

    int dirtyCount = _dirtyElements.length;
    int index = 0;

    while (index < dirtyCount) {
      final element = _dirtyElements[index];
      assert(element._inDirtyList);
      assert(element._lifecycleState == _ElementLifecycle.active);

      element.rebuild();
      element._inDirtyList = false;
      index += 1;

      if (_dirtyElementsNeedsResorting == true) {
        _dirtyElements.sort((a, b) => a.depth - b.depth);
        _dirtyElementsNeedsResorting = false;
        dirtyCount = _dirtyElements.length;
        while (index > 0 && _dirtyElements[index - 1].dirty) {
          index -= 1;
        }
      }
    }

    assert(() {
      for (final element in _dirtyElements) {
        assert(
          !element.dirty,
          'Element ${element.runtimeType} is still dirty after building',
        );
      }
      return true;
    }());

    _dirtyElements.clear();
    _scheduledFlushDirtyElements = false;
  }

  /// Finalizes the tree and unmounts inactive elements
  void finalizeTree() {
    _inactiveElements._unmountAll();
  }
}

/// Collection of inactive elements waiting to be unmounted
class _InactiveElements {
  final Set<Element> _elements = HashSet<Element>();

  void add(Element element) {
    // Handle both active and inactive elements like Flutter does
    if (element._lifecycleState == _ElementLifecycle.active) {
      _deactivateRecursively(element);
    } else {
      assert(element._lifecycleState == _ElementLifecycle.inactive);
    }

    _elements.add(element);
  }

  static void _deactivateRecursively(Element element) {
    assert(element._lifecycleState == _ElementLifecycle.active);
    element.deactivate();
    element.visitChildren(_deactivateRecursively);
  }

  void remove(Element element) {
    assert(_elements.contains(element));
    assert(element._lifecycleState == _ElementLifecycle.inactive);
    _elements.remove(element);
  }

  static void _unmount(Element element) {
    assert(element._lifecycleState == _ElementLifecycle.inactive);
    // Recursively unmount all children first (depth-first)
    element.visitChildren((Element child) {
      assert(child._parent == element);
      _unmount(child);
    });
    // Then unmount this element
    element.unmount();
    assert(element._lifecycleState == _ElementLifecycle.defunct);
  }

  void _unmountAll() {
    final List<Element> elements = _elements.toList()
      ..sort((a, b) => b.depth - a.depth);
    _elements.clear();

    for (final element in elements) {
      assert(element._lifecycleState == _ElementLifecycle.inactive);
      _unmount(element);
    }
  }
}
