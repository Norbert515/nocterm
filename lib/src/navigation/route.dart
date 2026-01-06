import '../framework/framework.dart';
import '../components/basic.dart';
import '../components/stack.dart' show Alignment, Positioned;
import 'route_settings.dart';
import 'overlay.dart';

/// Base class for routes in the navigation system
abstract class Route<T> {
  /// The settings for this route (name, arguments)
  final RouteSettings settings;

  Route({required this.settings});

  /// The overlay entries for this route.
  List<OverlayEntry> get overlayEntries => _overlayEntries;
  final List<OverlayEntry> _overlayEntries = <OverlayEntry>[];

  /// Navigator that this route is in.
  dynamic get navigator => _navigator;
  dynamic _navigator;

  set navigatorState(dynamic navigator) {
    _navigator = navigator;
  }

  /// Called when the route is inserted into the navigator.
  void install() {
    assert(_overlayEntries.isEmpty);
    _overlayEntries.addAll(createOverlayEntries());
  }

  /// Create the overlay entries for this route.
  Iterable<OverlayEntry> createOverlayEntries();

  /// Called when the route is removed from the navigator.
  void dispose() {
    for (final OverlayEntry entry in _overlayEntries) {
      entry.remove();
    }
    _overlayEntries.clear();
  }

  /// Check if this route can be popped.
  /// Override to prevent popping in certain conditions.
  bool canPop() => true;
}

/// A standard page route
class PageRoute<T> extends Route<T> {
  final ComponentBuilder builder;

  PageRoute({required this.builder, required super.settings});

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    return <OverlayEntry>[
      OverlayEntry(builder: builder, maintainState: true, opaque: true),
    ];
  }
}

/// A modal overlay route (like a dialog)
class ModalRoute<T> extends Route<T> {
  /// Builder for the modal content
  final ComponentBuilder builder;

  /// Whether tapping outside the modal dismisses it
  final bool barrierDismissible;

  /// Decoration for the modal container
  final BoxDecoration? decoration;

  /// Alignment of the modal on screen
  final Alignment alignment;

  /// Width constraint for the modal
  final double? width;

  /// Height constraint for the modal
  final double? height;

  ModalRoute({
    required this.builder,
    required super.settings,
    this.barrierDismissible = true,
    this.decoration,
    this.alignment = Alignment.center,
    this.width,
    this.height,
  });

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    return <OverlayEntry>[
      // Barrier entry
      OverlayEntry(builder: (context) => Container(), opaque: false),
      // Modal content entry
      OverlayEntry(
        builder: (context) {
          Component modalContent = builder(context);

          // Apply decoration if provided
          if (decoration != null) {
            modalContent = DecoratedBox(
              decoration: decoration!,
              child: modalContent,
            );
          }

          // Apply size constraints if provided
          if (width != null || height != null) {
            modalContent = SizedBox(
              width: width,
              height: height,
              child: modalContent,
            );
          }

          // Apply alignment
          return Positioned.fill(
            child: Align(alignment: alignment, child: modalContent),
          );
        },
        maintainState: true,
      ),
    ];
  }
}

/// Factory for creating routes from settings
typedef RouteFactory = Route<dynamic>? Function(RouteSettings settings);
