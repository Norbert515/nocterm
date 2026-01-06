import 'dart:async';
import '../framework/framework.dart';
import '../components/basic.dart';
import '../components/stack.dart' show Alignment;
import '../keyboard/logical_key.dart';
import '../style.dart';
import 'route.dart';
import 'route_settings.dart';
import 'pop_behavior.dart';
import 'navigator_observer.dart';
import 'overlay.dart';

/// A widget that manages a stack of routes using an overlay
class Navigator extends StatefulComponent {
  /// The initial home route
  final Component? home;

  /// Map of named routes
  final Map<String, Component Function(BuildContext)>? routes;

  /// Initial route path for deep linking
  final String? initialRoute;

  /// Factory for generating routes
  final RouteFactory? onGenerateRoute;

  /// Factory for unknown routes
  final RouteFactory? onUnknownRoute;

  /// Configuration for pop behavior
  final PopBehavior popBehavior;

  /// Observers for navigation events
  final List<NavigatorObserver> observers;

  const Navigator({
    super.key,
    this.home,
    this.routes,
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.popBehavior = const PopBehavior(),
    this.observers = const [],
  }) : assert(
         home != null || routes != null || onGenerateRoute != null,
         'Either home, routes, or onGenerateRoute must be provided',
       );

  @override
  State<Navigator> createState() => NavigatorState();

  /// Get the navigator state from the context
  static NavigatorState? maybeOf(BuildContext context) {
    final state = context.findAncestorStateOfType<NavigatorState>();
    return state;
  }

  /// Get the navigator state from the context (throws if not found)
  static NavigatorState of(BuildContext context) {
    final NavigatorState? navigator = maybeOf(context);
    assert(navigator != null, 'No Navigator found in context');
    return navigator!;
  }
}

/// State for the Navigator
class NavigatorState extends State<Navigator> {
  final List<Route> _routes = [];
  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();
  final Map<Route, Completer<dynamic>> _routeCompleters = {};

  OverlayState? get _overlay => _overlayKey.currentState;

  @override
  void initState() {
    super.initState();
    _initializeRoutes();
  }

  @override
  void dispose() {
    for (final route in _routes) {
      route.dispose();
    }
    super.dispose();
  }

  void _initializeRoutes() {
    if (component.initialRoute != null) {
      _buildInitialRouteStack(component.initialRoute!);
    } else if (component.home != null) {
      final route = PageRoute(
        builder: (context) => component.home!,
        settings: const RouteSettings(name: '/'),
      );
      _installRoute(route);
    } else if (component.routes != null && component.routes!.containsKey('/')) {
      final route = PageRoute(
        builder: component.routes!['/']!,
        settings: const RouteSettings(name: '/'),
      );
      _installRoute(route);
    }

    // Notify observers
    for (final route in _routes) {
      for (final observer in component.observers) {
        observer.didPush(route, null);
      }
    }
  }

  void _buildInitialRouteStack(String initialRoute) {
    final segments = initialRoute
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();

    // Always start with home route if available
    if (component.home != null ||
        (component.routes?.containsKey('/') ?? false)) {
      final homeRoute = PageRoute(
        builder: component.home != null
            ? (context) => component.home!
            : component.routes!['/']!,
        settings: const RouteSettings(name: '/'),
      );
      _installRoute(homeRoute);
    }

    // Build up the route stack
    String currentPath = '';
    for (final segment in segments) {
      currentPath += '/$segment';
      final route = _createRoute(RouteSettings(name: currentPath));
      if (route != null) {
        _installRoute(route);
      }
    }
  }

  Route? _createRoute(RouteSettings settings) {
    // Try named routes first
    if (settings.name != null && component.routes != null) {
      final builder = component.routes![settings.name];
      if (builder != null) {
        return PageRoute(builder: builder, settings: settings);
      }
    }

    // Try onGenerateRoute
    if (component.onGenerateRoute != null) {
      final route = component.onGenerateRoute!(settings);
      if (route != null) return route;
    }

    // Fall back to onUnknownRoute
    if (component.onUnknownRoute != null) {
      return component.onUnknownRoute!(settings);
    }

    return null;
  }

  void _installRoute(Route route) {
    route.navigatorState = this;
    route.install();
    _routes.add(route);
  }

  /// Push a new route onto the stack
  Future<T?> push<T>(Route<T> route) {
    _installRoute(route);

    // Add overlay entries to the overlay
    if (_overlay != null) {
      _overlay!.insertAll(route.overlayEntries);
    }

    // Notify observers
    for (final observer in component.observers) {
      observer.didPush(
        route,
        _routes.length > 1 ? _routes[_routes.length - 2] : null,
      );
    }

    final completer = Completer<T?>();
    _routeCompleters[route] = completer;
    return completer.future;
  }

  /// Push a component directly onto the navigation stack.
  Future<T?> pushComponent<T>(Component component, {String? name}) {
    final route = PageRoute<T>(
      builder: (context) => component,
      settings: RouteSettings(name: name),
    );
    return push(route);
  }

  /// Push a named route
  Future<T?> pushNamed<T>(String name, {Object? arguments}) {
    final settings = RouteSettings(name: name, arguments: arguments);
    final route = _createRoute(settings);

    if (route == null) {
      throw FlutterError('Could not find a route named "$name"');
    }

    return push(route as Route<T>);
  }

  /// Push a route and replace the current top route
  Future<T?> pushReplacement<T, TO>(Route<T> newRoute, {TO? result}) {
    if (_routes.isEmpty) {
      return push(newRoute);
    }

    final oldRoute = _routes.last;

    // Install the new route
    _installRoute(newRoute);

    // Remove the old route from the stack (but keep it for disposal later)
    _routes.removeAt(_routes.length - 2);

    // Update overlay entries - remove old, add new
    if (_overlay != null) {
      // Remove old route's overlay entries
      for (final entry in oldRoute.overlayEntries) {
        entry.remove();
      }
      // Add new route's overlay entries
      _overlay!.insertAll(newRoute.overlayEntries);
    }

    // Notify observers
    for (final observer in component.observers) {
      observer.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    }

    // Complete the old route's future if it exists
    if (_routeCompleters.containsKey(oldRoute)) {
      final completer = _routeCompleters[oldRoute]!;
      _routeCompleters.remove(oldRoute);
      Future.microtask(() => completer.complete(result));
    }

    // Dispose the old route
    oldRoute.dispose();

    // Create completer for new route
    final completer = Completer<T?>();
    _routeCompleters[newRoute] = completer;
    return completer.future;
  }

  /// Push a named route and replace the current top route
  Future<T?> pushReplacementNamed<T, TO>(
    String name, {
    Object? arguments,
    TO? result,
  }) {
    final settings = RouteSettings(name: name, arguments: arguments);
    final route = _createRoute(settings);

    if (route == null) {
      throw FlutterError('Could not find a route named "$name"');
    }

    return pushReplacement<T, TO>(route as Route<T>, result: result);
  }

  /// Push a component and replace the current top route
  Future<T?> pushReplacementComponent<T, TO>(
    Component component, {
    String? name,
    TO? result,
  }) {
    final route = PageRoute<T>(
      builder: (context) => component,
      settings: RouteSettings(name: name),
    );
    return pushReplacement<T, TO>(route, result: result);
  }

  /// Pop the current route off the navigation stack.
  void pop<T>([T? result]) {
    if (!canPop()) return;

    final route = _routes.last;

    // Remove the route
    _routes.removeLast();

    // Remove overlay entries
    for (final entry in route.overlayEntries) {
      entry.remove();
    }

    // Dispose the route
    route.dispose();

    // Notify observers
    for (final observer in component.observers) {
      observer.didPop(route, _routes.isNotEmpty ? _routes.last : null);
    }

    // Complete the route's future after the current frame
    if (_routeCompleters.containsKey(route)) {
      final completer = _routeCompleters[route]!;
      _routeCompleters.remove(route);
      // Use scheduleMicrotask to defer completion
      Future.microtask(() => completer.complete(result));
    }
  }

  /// Check if the current route can be popped.
  bool canPop() {
    if (_routes.length <= 1) return false;

    final currentRoute = _routes.last;

    // Check route's own canPop
    if (!currentRoute.canPop()) return false;

    // Check PopBehavior's canPop
    if (component.popBehavior.canPop != null) {
      return component.popBehavior.canPop!(currentRoute);
    }

    return true;
  }

  /// Show a modal dialog
  Future<T?> showDialog<T>({
    required Component Function(BuildContext) builder,
    bool barrierDismissible = true,
    BoxDecoration? decoration,
    Alignment alignment = Alignment.center,
    double? width,
    double? height,
  }) {
    final route = ModalRoute<T>(
      builder: builder,
      settings: const RouteSettings(name: '<dialog>'),
      barrierDismissible: barrierDismissible,
      decoration:
          decoration ??
          BoxDecoration(
            border: BoxBorder.all(style: BoxBorderStyle.double),
            color: const Color.fromRGB(0, 0, 0),
          ),
      alignment: alignment,
      width: width,
      height: height,
    );

    return push(route);
  }

  bool _handleKeyPress(LogicalKey key) {
    if (component.popBehavior.shouldPop(key)) {
      // Check if current route is modal with barrierDismissible
      final currentRoute = _routes.last;
      if (currentRoute is ModalRoute && !currentRoute.barrierDismissible) {
        return false; // Don't pop if barrier is not dismissible
      }

      // Handle async pop confirmation
      if (component.popBehavior.onPopInvoked != null) {
        component.popBehavior.onPopInvoked!(currentRoute).then((shouldPop) {
          if (shouldPop && canPop()) {
            pop();
          }
        });
        return true; // Event was handled (async)
      } else if (canPop()) {
        pop();
        return true; // Event was handled
      }
    }

    return false; // Event was not handled
  }

  @override
  Component build(BuildContext context) {
    // Get all overlay entries from all routes
    final List<OverlayEntry> allEntries = [];
    for (final route in _routes) {
      allEntries.addAll(route.overlayEntries);
    }

    return KeyboardListener(
      onKeyEvent: _handleKeyPress,
      autofocus: true,
      child: Overlay(key: _overlayKey, initialEntries: allEntries),
    );
  }
}
