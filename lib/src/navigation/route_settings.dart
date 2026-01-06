/// Settings for a route
class RouteSettings {
  /// The name of the route (e.g., '/settings')
  final String? name;

  /// Arguments passed to the route
  final Object? arguments;

  const RouteSettings({this.name, this.arguments});

  /// Create a copy with updated values
  RouteSettings copyWith({String? name, Object? arguments}) {
    return RouteSettings(
      name: name ?? this.name,
      arguments: arguments ?? this.arguments,
    );
  }

  @override
  String toString() => 'RouteSettings(name: $name, arguments: $arguments)';
}
