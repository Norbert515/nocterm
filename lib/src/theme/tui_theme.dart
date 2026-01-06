import '../framework/framework.dart';
import 'tui_theme_data.dart';

/// Provides a theme to its descendants.
///
/// Wrap your app in a [TuiTheme] to provide theme colors to all
/// descendant components. Components can then access the theme using
/// [TuiTheme.of].
///
/// Example:
/// ```dart
/// TuiTheme(
///   data: TuiThemeData.catppuccinMocha,
///   child: MyApp(),
/// )
///
/// // In a component's build method:
/// final theme = TuiTheme.of(context);
/// final textColor = theme.onSurface;
/// ```
class TuiTheme extends InheritedComponent {
  /// The theme data for this subtree.
  final TuiThemeData data;

  /// Creates a theme provider.
  const TuiTheme({super.key, required this.data, required super.child});

  /// Returns the [TuiThemeData] from the closest [TuiTheme] ancestor.
  ///
  /// If no [TuiTheme] ancestor exists, returns [TuiThemeData.dark] as
  /// the default theme.
  ///
  /// This method registers the calling component as a dependent of the
  /// [TuiTheme], so the component will rebuild when the theme changes.
  ///
  /// Example:
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   final theme = TuiTheme.of(context);
  ///   return Text(
  ///     'Hello',
  ///     style: TextStyle(color: theme.primary),
  ///   );
  /// }
  /// ```
  static TuiThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedComponentOfExactType<TuiTheme>();
    return theme?.data ?? TuiThemeData.dark;
  }

  /// Returns the [TuiThemeData] from the closest [TuiTheme] ancestor
  /// without registering a dependency.
  ///
  /// This method does NOT register the calling component as a dependent,
  /// so the component will NOT rebuild when the theme changes. Use this
  /// for one-time reads where you don't want to rebuild on theme changes.
  ///
  /// Returns `null` if no [TuiTheme] ancestor exists.
  static TuiThemeData? maybeOf(BuildContext context) {
    final element = context
        .getElementForInheritedComponentOfExactType<TuiTheme>();
    return (element?.component as TuiTheme?)?.data;
  }

  @override
  bool updateShouldNotify(TuiTheme oldComponent) {
    return data != oldComponent.data;
  }
}
