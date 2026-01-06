import '../style.dart';
import 'brightness.dart';

/// A color that resolves differently based on theme brightness.
///
/// This is the recommended way to specify colors in nocterm apps,
/// as it ensures your UI works in both light and dark themes.
///
/// Example:
/// ```dart
/// final textColor = AdaptiveColor(
///   light: Color.fromRGB(33, 33, 33),   // dark text for light backgrounds
///   dark: Color.fromRGB(248, 248, 242),  // light text for dark backgrounds
/// );
///
/// // Resolve based on current theme
/// final resolvedColor = textColor.resolve(theme.brightness);
/// ```
class AdaptiveColor {
  /// The color to use in light theme.
  final Color light;

  /// The color to use in dark theme.
  final Color dark;

  /// Creates an adaptive color with different values for light and dark themes.
  const AdaptiveColor({required this.light, required this.dark});

  /// Creates an adaptive color with the same value for both themes.
  ///
  /// Use this when a color should remain the same regardless of theme,
  /// such as brand colors or specific accent colors.
  const AdaptiveColor.all(Color color) : light = color, dark = color;

  /// Resolves this color based on the given brightness.
  ///
  /// Returns [dark] for [Brightness.dark] and [light] for [Brightness.light].
  Color resolve(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdaptiveColor && other.light == light && other.dark == dark;
  }

  @override
  int get hashCode => Object.hash(light, dark);

  @override
  String toString() => 'AdaptiveColor(light: $light, dark: $dark)';
}
