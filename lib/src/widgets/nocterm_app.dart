import 'package:nocterm/nocterm.dart';

/// A widget that describes this app to the terminal emulator and provides navigation.
///
/// [NoctermApp] provides:
/// - Declarative terminal window title and icon name setting (via OSC escape sequences)
/// - Built-in navigation support via [Navigator]
/// - Routing configuration similar to Flutter's [MaterialApp]
///
/// Similar to Flutter's [MaterialApp] and [WidgetsApp], this widget should
/// typically be the root of your TUI application.
///
/// ## Simple Usage (No Navigation):
/// ```dart
/// void main() async {
///   await runApp(
///     NoctermApp(
///       title: 'My TUI App',
///       iconName: 'MyApp',
///       child: MyHomeScreen(),
///     ),
///   );
/// }
/// ```
///
/// ## With Navigation:
/// ```dart
/// void main() async {
///   await runApp(
///     NoctermApp(
///       title: 'My TUI App',
///       home: HomeScreen(),
///       routes: {
///         '/settings': (context) => SettingsScreen(),
///         '/about': (context) => AboutScreen(),
///       },
///     ),
///   );
/// }
/// ```
///
/// The [title] parameter sets the terminal window title (OSC 2), and [iconName]
/// sets the terminal icon name (OSC 1). If only [title] is provided, both the
/// window title and icon name will be set to the same value (OSC 0).
///
/// These escape sequences are supported by most modern terminal emulators
/// including xterm, iTerm2, GNOME Terminal, Windows Terminal, and others.
///
/// ## Auto Theme Detection
///
/// When no explicit [theme] is provided, the terminal's background color is
/// automatically detected and the appropriate light or dark theme is applied:
///
/// ```dart
/// NoctermApp(
///   child: MyApp(),  // Auto-detects light/dark theme
/// )
/// ```
///
/// To use a specific theme, provide it explicitly:
///
/// ```dart
/// NoctermApp(
///   theme: TuiThemeData.nord,  // Use Nord theme
///   child: MyApp(),
/// )
/// ```
///
/// Auto-detection uses multiple fallback methods:
/// 1. OSC 11 query for actual terminal background color
/// 2. COLORFGBG environment variable
/// 3. macOS system appearance (Dark Mode setting)
/// 4. Defaults to dark theme if all methods fail
class NoctermApp extends StatefulComponent {
  /// Creates a widget that describes this app to the terminal emulator.
  ///
  /// Either [child], [home], or [routes] must be provided.
  ///
  /// If [child] is provided without navigation parameters, no Navigator will be created.
  /// If [home] or [routes] are provided, a Navigator will be created automatically.
  ///
  /// The [title] parameter sets the terminal window title. If [iconName] is not
  /// provided, the title will also be used as the icon name.
  ///
  /// The [iconName] parameter optionally sets a separate icon name. This is
  /// typically used in X11 window managers to display a short name when the
  /// window is minimized or iconified.
  const NoctermApp({
    this.title,
    this.iconName,
    this.child,
    this.home,
    this.routes,
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorObservers = const [],
    this.navigatorKey,
    this.theme,
    super.key,
  }) : assert(
         child != null ||
             home != null ||
             routes != null ||
             onGenerateRoute != null,
         'Either child, home, routes, or onGenerateRoute must be provided',
       ),
       assert(
         child == null ||
             (home == null &&
                 routes == null &&
                 initialRoute == null &&
                 onGenerateRoute == null &&
                 onUnknownRoute == null),
         'If child is provided, navigation parameters (home, routes, initialRoute, onGenerateRoute, onUnknownRoute) cannot be used',
       );

  /// A one-line description of this app for use in the terminal window title.
  ///
  /// This is displayed in the terminal emulator's window title bar.
  /// Uses OSC 2 escape sequence to set the window title.
  ///
  /// If [iconName] is not provided, this value will also be used for the icon name.
  final String? title;

  /// A short name for this app used when the terminal window is iconified.
  ///
  /// This is primarily used by X11 window managers to show a short name when
  /// the window is minimized. Uses OSC 1 escape sequence.
  ///
  /// If not provided, [title] will be used for both window title and icon name.
  final String? iconName;

  /// The widget below this widget in the tree.
  ///
  /// If this is provided, no Navigator will be created. Use this for simple apps
  /// that don't need navigation.
  ///
  /// Cannot be used with [home], [routes], [initialRoute], or [onGenerateRoute].
  final Component? child;

  /// The widget for the default route of the app (Navigator.defaultRouteName, `/`).
  ///
  /// This is the route that is displayed first when the application starts normally.
  ///
  /// If [home] is specified, a Navigator will be created automatically.
  final Component? home;

  /// The application's top-level routing table.
  ///
  /// When a named route is pushed with [Navigator.pushNamed], the route name is
  /// looked up in this map.
  ///
  /// If [routes] are provided, a Navigator will be created automatically.
  final Map<String, Component Function(BuildContext)>? routes;

  /// The name of the first route to show, if a Navigator is created.
  ///
  /// Defaults to [Navigator.defaultRouteName] (`/`).
  ///
  /// The value is passed to [Navigator.initialRoute].
  final String? initialRoute;

  /// The route generator callback used when the app is navigated to a named route.
  ///
  /// This is used if [routes] does not contain the requested route.
  final RouteFactory? onGenerateRoute;

  /// Called when [onGenerateRoute] fails to generate a route.
  ///
  /// This callback is typically used for error handling. For example, this
  /// callback might always generate a "not found" page that describes the route
  /// that wasn't found.
  final RouteFactory? onUnknownRoute;

  /// A list of observers for the Navigator created for this app.
  ///
  /// This list is empty by default. To observe navigation events, provide
  /// a list of NavigatorObserver instances.
  final List<NavigatorObserver> navigatorObservers;

  /// A key to use for the Navigator created for this app.
  ///
  /// This can be used to access the NavigatorState directly via
  /// [GlobalKey.currentState].
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The theme to use for this application.
  ///
  /// If provided, this theme will be applied to all descendant components
  /// via [TuiTheme]. Components can access it using `TuiTheme.of(context)`.
  ///
  /// If null, the theme will be auto-detected based on terminal brightness.
  /// See the class documentation for details on the detection methods.
  final TuiThemeData? theme;

  @override
  State<NoctermApp> createState() => _NoctermAppState();
}

class _NoctermAppState extends State<NoctermApp> {
  /// The detected theme when autoDetectTheme is enabled.
  /// Null until detection completes or if autoDetectTheme is false.
  TuiThemeData? _detectedTheme;

  /// Whether theme detection is in progress.
  bool _detectingTheme = false;

  @override
  void initState() {
    super.initState();
    _updateTitle();
    _detectThemeIfNeeded();
  }

  @override
  void didUpdateComponent(NoctermApp oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.title != component.title ||
        oldComponent.iconName != component.iconName) {
      _updateTitle();
    }
    // Re-detect theme if explicit theme was removed
    if (oldComponent.theme != null && component.theme == null) {
      _detectThemeIfNeeded();
    }
  }

  void _detectThemeIfNeeded() {
    // Don't detect if:
    // - a theme is explicitly provided
    // - detection is already in progress
    if (component.theme != null || _detectingTheme) {
      return;
    }

    _detectingTheme = true;

    // Try to get the terminal
    Terminal? terminal;
    try {
      final binding = NoctermBinding.instance;
      if (binding is TerminalBinding) {
        terminal = binding.terminal;
      } else if (binding is NoctermTestBinding) {
        terminal = binding.terminal;
      }
    } catch (e) {
      // Binding not available
    }

    if (terminal == null) {
      // No terminal available, use default dark theme
      _detectingTheme = false;
      setState(() {
        _detectedTheme = TuiThemeData.dark;
      });
      return;
    }

    // Detect brightness asynchronously
    detectTerminalBrightness(terminal)
        .then((brightness) {
          if (mounted) {
            setState(() {
              _detectedTheme = brightness == Brightness.light
                  ? TuiThemeData.light
                  : TuiThemeData.dark;
              _detectingTheme = false;
            });
          }
        })
        .catchError((_) {
          // On error, default to dark theme
          if (mounted) {
            setState(() {
              _detectedTheme = TuiThemeData.dark;
              _detectingTheme = false;
            });
          }
        });
  }

  void _updateTitle() {
    final title = component.title;
    final iconName = component.iconName;

    // In test mode, there's no TerminalBinding, so we skip setting the title
    // We use a try-catch to handle both test and production environments
    try {
      // Try to get the terminal from the current binding
      final binding = NoctermBinding.instance;

      // Check if this is a TerminalBinding (production) or NoctermTestBinding (test)
      if (binding is TerminalBinding) {
        final terminal = binding.terminal;

        if (title != null && iconName != null) {
          // Set both separately
          terminal.setWindowTitle(title);
          terminal.setIconName(iconName);
          terminal.flush();
        } else if (title != null) {
          // Set both to the same value using OSC 0
          terminal.setTitleAndIcon(title);
          terminal.flush();
        }
      } else if (binding is NoctermTestBinding) {
        // In test mode, also set the title on the mock terminal
        final terminal = binding.terminal;

        if (title != null && iconName != null) {
          terminal.setWindowTitle(title);
          terminal.setIconName(iconName);
          terminal.flush();
        } else if (title != null) {
          terminal.setTitleAndIcon(title);
          terminal.flush();
        }
      }
      // If both are null, do nothing (keep existing terminal title)
    } catch (e) {
      // In case binding is not available, silently ignore
      // This can happen during early initialization or in certain test scenarios
    }
  }

  @override
  Component build(BuildContext context) {
    Component content;

    // If child is provided, use it directly without Navigator
    if (component.child != null) {
      content = component.child!;
    } else {
      // Otherwise, create a Navigator with the provided configuration
      content = Navigator(
        key: component.navigatorKey,
        home: component.home,
        routes: component.routes,
        initialRoute: component.initialRoute,
        onGenerateRoute: component.onGenerateRoute,
        onUnknownRoute: component.onUnknownRoute,
        observers: component.navigatorObservers,
      );
    }

    // Wrap in TuiTheme if a theme is provided or auto-detected
    final effectiveTheme = component.theme ?? _detectedTheme;
    if (effectiveTheme != null) {
      content = TuiTheme(data: effectiveTheme, child: content);
    }

    return content;
  }
}
