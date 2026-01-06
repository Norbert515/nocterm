import 'route.dart';

/// An observer for navigation events
abstract class NavigatorObserver {
  /// The navigator that this observer is observing, if any
  dynamic navigator;

  /// Called when a route is pushed
  void didPush(Route route, Route? previousRoute) {}

  /// Called when a route is popped
  void didPop(Route route, Route? previousRoute) {}

  /// Called when a route is removed
  void didRemove(Route route, Route? previousRoute) {}

  /// Called when a route is replaced
  void didReplace({Route? newRoute, Route? oldRoute}) {}

  /// Called when routes are re-ordered or when the initial routes are set
  void didStartUserGesture(Route route, Route? previousRoute) {}

  /// Called when a user gesture is no longer controlling the navigator
  void didStopUserGesture() {}
}

/// A simple logging observer for debugging
class LoggingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    print('Navigator: Pushed ${route.settings.name ?? 'unnamed route'}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    print('Navigator: Popped ${route.settings.name ?? 'unnamed route'}');
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    print('Navigator: Removed ${route.settings.name ?? 'unnamed route'}');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    print(
      'Navigator: Replaced ${oldRoute?.settings.name ?? 'unnamed route'} with ${newRoute?.settings.name ?? 'unnamed route'}',
    );
  }
}
