import 'package:nocterm/nocterm.dart';

import '../components/stack.dart' as stack_lib;
import 'render_theater.dart';

/// A single entry in an [Overlay].
class OverlayEntry {
  /// Creates an overlay entry.
  OverlayEntry({
    required this.builder,
    bool opaque = false,
    bool maintainState = false,
  }) : _opaque = opaque,
       _maintainState = maintainState;

  /// The builder for the widget to display in the overlay.
  final ComponentBuilder builder;

  /// Whether this entry occludes the entire overlay.
  bool get opaque => _opaque;
  bool _opaque;
  set opaque(bool value) {
    if (_opaque == value) {
      return;
    }
    _opaque = value;
    _overlay?._didChangeEntryOpacity();
  }

  /// Whether this entry must be included in the tree even if there is a fully
  /// opaque entry above it.
  bool get maintainState => _maintainState;
  bool _maintainState;
  set maintainState(bool value) {
    if (_maintainState == value) {
      return;
    }
    _maintainState = value;
    _overlay?._didChangeEntryOpacity();
  }

  OverlayState? _overlay;
  final GlobalKey<_OverlayEntryWidgetState> _key =
      GlobalKey<_OverlayEntryWidgetState>();

  /// Remove this entry from the overlay.
  void remove() {
    _overlay?._remove(this);
  }

  /// Mark this entry as needing to rebuild.
  void markNeedsBuild() {
    _key.currentState?._markNeedsBuild();
  }
}

/// A stack of entries that can be managed independently.
class Overlay extends StatefulComponent {
  /// Creates an overlay.
  const Overlay({super.key, this.initialEntries = const <OverlayEntry>[]});

  /// The entries to include in the overlay initially.
  final List<OverlayEntry> initialEntries;

  /// The state from the closest instance of this class that encloses the given context.
  static OverlayState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<OverlayState>();
  }

  /// The state from the closest instance of this class that encloses the given context.
  static OverlayState of(BuildContext context) {
    final OverlayState? result = maybeOf(context);
    assert(result != null, 'No Overlay found in context');
    return result!;
  }

  @override
  State<Overlay> createState() => OverlayState();
}

/// The current state of an [Overlay].
class OverlayState extends State<Overlay> {
  final List<OverlayEntry> _entries = <OverlayEntry>[];

  @override
  void initState() {
    super.initState();
    // Add initial entries directly without calling setState
    for (final OverlayEntry entry in component.initialEntries) {
      assert(entry._overlay == null);
      entry._overlay = this;
      _entries.add(entry);
    }
  }

  /// Insert the given entry into the overlay.
  void insert(OverlayEntry entry, {OverlayEntry? below, OverlayEntry? above}) {
    assert(entry._overlay == null);
    assert(above == null || below == null);
    entry._overlay = this;
    setState(() {
      final int index = _insertionIndex(below, above);
      _entries.insert(index, entry);
    });
  }

  /// Insert all the entries in the given iterable.
  void insertAll(
    Iterable<OverlayEntry> entries, {
    OverlayEntry? below,
    OverlayEntry? above,
  }) {
    assert(above == null || below == null);
    if (entries.isEmpty) {
      return;
    }
    for (final OverlayEntry entry in entries) {
      assert(entry._overlay == null);
      entry._overlay = this;
    }
    setState(() {
      _entries.insertAll(_insertionIndex(below, above), entries);
    });
  }

  int _insertionIndex(OverlayEntry? below, OverlayEntry? above) {
    if (below != null) {
      return _entries.indexOf(below);
    }
    if (above != null) {
      return _entries.indexOf(above) + 1;
    }
    return _entries.length;
  }

  /// Remove the given entry from the overlay.
  void _remove(OverlayEntry entry) {
    if (entry._overlay != this) {
      return;
    }
    _entries.remove(entry);
    entry._overlay = null;
    if (mounted) {
      setState(() {});
    }
  }

  /// Rearrange the entries to match the given order.
  void rearrange(Iterable<OverlayEntry> newEntries) {
    final List<OverlayEntry> newEntriesList = newEntries.toList();
    setState(() {
      _entries.clear();
      _entries.addAll(newEntriesList);
    });
  }

  void _didChangeEntryOpacity() {
    setState(() {
      // Rebuild when opacity changes
    });
  }

  @override
  Component build(BuildContext context) {
    // Build only the entries that need to be visible
    final List<Component> children = <Component>[];
    bool onstage = true;
    int onstageCount = 0;

    // Build from top to bottom, but respect maintainState and opacity
    for (int i = _entries.length - 1; i >= 0; i -= 1) {
      final OverlayEntry entry = _entries[i];

      if (onstage) {
        onstageCount += 1;
        children.insert(
          0,
          _OverlayEntryWidget(
            key: entry._key,
            entry: entry,
            overlayState: this,
          ),
        );
        if (entry.opaque) {
          onstage = false;
        }
      } else if (entry.maintainState) {
        children.insert(
          0,
          _OverlayEntryWidget(
            key: entry._key,
            entry: entry,
            overlayState: this,
            tickerEnabled: false,
          ),
        );
      }
    }

    return _Theater(
      skipCount: children.length - onstageCount,
      clipBehavior: stack_lib.Clip.hardEdge,
      children: children,
    );
  }
}

/// A widget that builds and maintains the state for an [OverlayEntry].
class _OverlayEntryWidget extends StatefulComponent {
  const _OverlayEntryWidget({
    required super.key,
    required this.entry,
    required this.overlayState,
    this.tickerEnabled = true,
  });

  final OverlayEntry entry;
  final OverlayState overlayState;
  final bool tickerEnabled;

  @override
  State<_OverlayEntryWidget> createState() => _OverlayEntryWidgetState();
}

class _OverlayEntryWidgetState extends State<_OverlayEntryWidget> {
  void _markNeedsBuild() {
    setState(() {
      // Trigger rebuild
    });
  }

  @override
  Component build(BuildContext context) {
    // For now, ignore tickerEnabled since we don't have TickerMode yet
    return Container(
      color: Color.defaultColor, // Always use terminal default background
      child: component.entry.builder(context),
    );
  }
}

/// The Theater widget manages overlay entries with optimized rendering.
class _Theater extends MultiChildRenderObjectComponent {
  const _Theater({
    this.skipCount = 0,
    this.clipBehavior = stack_lib.Clip.hardEdge,
    required super.children,
  });

  final int skipCount;
  final stack_lib.Clip clipBehavior;

  @override
  RenderTheater createRenderObject(BuildContext context) {
    return RenderTheater(
      skipCount: skipCount,
      textDirection: TextDirection.ltr,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderTheater renderObject) {
    renderObject
      ..skipCount = skipCount
      ..textDirection = TextDirection.ltr
      ..clipBehavior = clipBehavior;
  }
}
