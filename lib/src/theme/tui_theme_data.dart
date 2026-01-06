import '../backend/terminal.dart';
import '../style.dart';
import 'brightness.dart';
import 'terminal_brightness_detection.dart';

/// Defines the colors for a TUI theme.
///
/// A theme consists of colors for various UI elements, designed to work
/// together harmoniously. Use the built-in themes like [TuiThemeData.dark],
/// [TuiThemeData.light], [TuiThemeData.nord], etc., or create custom themes.
///
/// Example:
/// ```dart
/// TuiTheme(
///   data: TuiThemeData.catppuccinMocha,
///   child: MyApp(),
/// )
/// ```
class TuiThemeData {
  /// The brightness of this theme (dark or light).
  final Brightness brightness;

  /// The main background color for the application.
  final Color background;

  /// Text/icon color on top of [background].
  final Color onBackground;

  /// Surface colors for widgets like cards, dialogs, menus.
  final Color surface;

  /// Text/icon color on top of [surface].
  final Color onSurface;

  /// The primary accent color for branding and emphasis.
  final Color primary;

  /// Text/icon color on top of [primary].
  final Color onPrimary;

  /// Alternative accent color for secondary emphasis.
  final Color secondary;

  /// Text/icon color on top of [secondary].
  final Color onSecondary;

  /// Color for error states and destructive actions.
  final Color error;

  /// Text/icon color on top of [error].
  final Color onError;

  /// Color for success states.
  final Color success;

  /// Text/icon color on top of [success].
  final Color onSuccess;

  /// Color for warning states.
  final Color warning;

  /// Text/icon color on top of [warning].
  final Color onWarning;

  /// Color for borders and dividers.
  final Color outline;

  /// Lighter variant of outline for subtle borders.
  final Color outlineVariant;

  /// Creates a custom theme with the specified colors.
  const TuiThemeData({
    required this.brightness,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.error,
    required this.onError,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.outline,
    required this.outlineVariant,
  });

  /// Creates a copy of this theme with the given fields replaced.
  TuiThemeData copyWith({
    Brightness? brightness,
    Color? background,
    Color? onBackground,
    Color? surface,
    Color? onSurface,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? error,
    Color? onError,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? outline,
    Color? outlineVariant,
  }) {
    return TuiThemeData(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
    );
  }

  // ===== Factory Methods =====

  /// Create a theme based on detected terminal brightness.
  ///
  /// Uses [detectTerminalBrightness] to query the terminal's background color
  /// and returns [TuiThemeData.light] or [TuiThemeData.dark] accordingly.
  ///
  /// The [timeout] parameter controls how long to wait for the OSC 11 query.
  /// A shorter timeout (default 50ms) is recommended to avoid UI delays.
  ///
  /// Example:
  /// ```dart
  /// final theme = await TuiThemeData.fromTerminal(terminal);
  /// ```
  static Future<TuiThemeData> fromTerminal(
    Terminal terminal, {
    Duration timeout = const Duration(milliseconds: 50),
  }) async {
    final brightness = await detectTerminalBrightness(
      terminal,
      timeout: timeout,
    );
    return brightness == Brightness.light
        ? TuiThemeData.light
        : TuiThemeData.dark;
  }

  // ===== Built-in Themes =====

  /// The default dark theme.
  ///
  /// Features a dark background with light text and a blue primary color.
  static const TuiThemeData dark = TuiThemeData(
    brightness: Brightness.dark,
    background: Color(0x18181C),
    onBackground: Color(0xF8F8F2),
    surface: Color(0x24242A),
    onSurface: Color(0xF8F8F2),
    primary: Color(0x8BB3F4),
    onPrimary: Color(0x18181C),
    secondary: Color(0x9CA3AF),
    onSecondary: Color(0x18181C),
    error: Color(0xE76170),
    onError: Color(0x18181C),
    success: Color(0x8BD598),
    onSuccess: Color(0x18181C),
    warning: Color(0xF1D589),
    onWarning: Color(0x18181C),
    outline: Color(0x9299A6),
    outlineVariant: Color(0x4B5563),
  );

  /// A light theme with dark text on light backgrounds.
  static const TuiThemeData light = TuiThemeData(
    brightness: Brightness.light,
    background: Color(0xFAFAFA),
    onBackground: Color(0x18181C),
    surface: Color(0xFFFFFF),
    onSurface: Color(0x18181C),
    primary: Color(0x4F77B8),
    onPrimary: Color(0xFFFFFF),
    secondary: Color(0x6B7280),
    onSecondary: Color(0xFFFFFF),
    error: Color(0xBF3948),
    onError: Color(0xFFFFFF),
    success: Color(0x3B995C),
    onSuccess: Color(0xFFFFFF),
    warning: Color(0xB5994D),
    onWarning: Color(0x18181C),
    outline: Color(0x6A717E),
    outlineVariant: Color(0xD1D5DB),
  );

  /// Nord theme - an arctic, north-bluish color palette.
  ///
  /// Based on the popular Nord color scheme.
  static const TuiThemeData nord = TuiThemeData(
    brightness: Brightness.dark,
    background: Color(0x2E3440),
    onBackground: Color(0xECEFF4),
    surface: Color(0x3B4252),
    onSurface: Color(0xECEFF4),
    primary: Color(0x88C0D0),
    onPrimary: Color(0x2E3440),
    secondary: Color(0x81A1C1),
    onSecondary: Color(0x2E3440),
    error: Color(0xBF616A),
    onError: Color(0xECEFF4),
    success: Color(0xA3BE8C),
    onSuccess: Color(0x2E3440),
    warning: Color(0xEBCB8B),
    onWarning: Color(0x2E3440),
    outline: Color(0x4C566A),
    outlineVariant: Color(0x434C5E),
  );

  /// Dracula theme - a dark theme with vibrant colors.
  ///
  /// Based on the popular Dracula color scheme.
  static const TuiThemeData dracula = TuiThemeData(
    brightness: Brightness.dark,
    background: Color(0x282A36),
    onBackground: Color(0xF8F8F2),
    surface: Color(0x44475A),
    onSurface: Color(0xF8F8F2),
    primary: Color(0xBD93F9),
    onPrimary: Color(0x282A36),
    secondary: Color(0xFF79C6),
    onSecondary: Color(0x282A36),
    error: Color(0xFF5555),
    onError: Color(0xF8F8F2),
    success: Color(0x50FA7B),
    onSuccess: Color(0x282A36),
    warning: Color(0xF1FA8C),
    onWarning: Color(0x282A36),
    outline: Color(0x6272A4),
    outlineVariant: Color(0x44475A),
  );

  /// Catppuccin Mocha theme - a warm, cozy dark theme.
  ///
  /// Based on the Catppuccin color scheme (Mocha variant).
  static const TuiThemeData catppuccinMocha = TuiThemeData(
    brightness: Brightness.dark,
    background: Color(0x1E1E2E),
    onBackground: Color(0xCDD6F4),
    surface: Color(0x313244),
    onSurface: Color(0xCDD6F4),
    primary: Color(0x89B4FA),
    onPrimary: Color(0x1E1E2E),
    secondary: Color(0xF5C2E7),
    onSecondary: Color(0x1E1E2E),
    error: Color(0xF38BA8),
    onError: Color(0x1E1E2E),
    success: Color(0xA6E3A1),
    onSuccess: Color(0x1E1E2E),
    warning: Color(0xF9E2AF),
    onWarning: Color(0x1E1E2E),
    outline: Color(0x6C7086),
    outlineVariant: Color(0x45475A),
  );

  /// Gruvbox Dark theme - a retro groove theme.
  ///
  /// Based on the Gruvbox color scheme (dark variant).
  static const TuiThemeData gruvboxDark = TuiThemeData(
    brightness: Brightness.dark,
    background: Color(0x282828),
    onBackground: Color(0xEBDBB2),
    surface: Color(0x3C3836),
    onSurface: Color(0xEBDBB2),
    primary: Color(0x83A598),
    onPrimary: Color(0x282828),
    secondary: Color(0xD3869B),
    onSecondary: Color(0x282828),
    error: Color(0xFB4934),
    onError: Color(0xEBDBB2),
    success: Color(0xB8BB26),
    onSuccess: Color(0x282828),
    warning: Color(0xFABD2F),
    onWarning: Color(0x282828),
    outline: Color(0x665C54),
    outlineVariant: Color(0x504945),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TuiThemeData &&
        other.brightness == brightness &&
        other.background == background &&
        other.onBackground == onBackground &&
        other.surface == surface &&
        other.onSurface == onSurface &&
        other.primary == primary &&
        other.onPrimary == onPrimary &&
        other.secondary == secondary &&
        other.onSecondary == onSecondary &&
        other.error == error &&
        other.onError == onError &&
        other.success == success &&
        other.onSuccess == onSuccess &&
        other.warning == warning &&
        other.onWarning == onWarning &&
        other.outline == outline &&
        other.outlineVariant == outlineVariant;
  }

  @override
  int get hashCode => Object.hash(
    brightness,
    background,
    onBackground,
    surface,
    onSurface,
    primary,
    onPrimary,
    secondary,
    onSecondary,
    error,
    onError,
    success,
    onSuccess,
    warning,
    onWarning,
    outline,
    outlineVariant,
  );

  @override
  String toString() => 'TuiThemeData(brightness: $brightness)';
}
