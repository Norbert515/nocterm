import 'package:nocterm/nocterm.dart';

/// Auto Theme Detection Demo
///
/// This demo showcases nocterm's automatic terminal brightness detection.
/// The app automatically selects a light or dark theme based on your terminal's
/// background color.
///
/// Run with: dart run example/auto_theme_demo.dart
///
/// Try running this in different terminals:
/// - iTerm2, Terminal.app, VS Code with dark/light themes
/// - Switch your terminal theme and re-run to see the difference
void main() async {
  await runApp(
    NoctermApp(
      title: 'Auto Theme Demo',
      // No theme specified - will auto-detect!
      child: const AutoThemeDemo(),
    ),
  );
}

class AutoThemeDemo extends StatelessComponent {
  const AutoThemeDemo({super.key});

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.keyQ ||
            event.logicalKey == LogicalKey.escape) {
          shutdownApp();
          return true;
        }
        return false;
      },
      child: Container(
        decoration: BoxDecoration(color: theme.background),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 60, maxHeight: 20),
            decoration: BoxDecoration(
              color: theme.surface,
              border: BoxBorder.all(color: theme.outline),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(vertical: 1),
                  child: Center(
                    child: Text(
                      'Auto Theme Detection',
                      style: TextStyle(
                        color: theme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Divider(),

                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Detection result
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isDark ? 'Moon' : 'Sun',
                              style: TextStyle(color: theme.primary),
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Detected: ',
                              style: TextStyle(color: theme.onSurface),
                            ),
                            Text(
                              isDark ? 'DARK' : 'LIGHT',
                              style: TextStyle(
                                color: theme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' terminal',
                              style: TextStyle(color: theme.onSurface),
                            ),
                          ],
                        ),

                        SizedBox(height: 2),

                        // Explanation
                        Text(
                          'nocterm automatically detected your terminal',
                          style: TextStyle(color: theme.onSurface),
                        ),
                        Text(
                          'background color and selected the appropriate',
                          style: TextStyle(color: theme.onSurface),
                        ),
                        Text(
                          'theme for optimal readability.',
                          style: TextStyle(color: theme.onSurface),
                        ),

                        SizedBox(height: 2),

                        // Color samples
                        Divider(),
                        SizedBox(height: 1),
                        _buildColorSamples(theme),

                        Spacer(),

                        // Detection methods info
                        Text(
                          'Detection: OSC 11 > COLORFGBG > macOS',
                          style: TextStyle(color: theme.outline),
                        ),

                        SizedBox(height: 1),

                        // Footer
                        Text(
                          'Press Q to quit',
                          style: TextStyle(color: theme.outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Component _buildColorSamples(TuiThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _colorDot(theme.primary, 'Pri'),
        SizedBox(width: 2),
        _colorDot(theme.secondary, 'Sec'),
        SizedBox(width: 2),
        _colorDot(theme.success, 'OK'),
        SizedBox(width: 2),
        _colorDot(theme.warning, 'Wrn'),
        SizedBox(width: 2),
        _colorDot(theme.error, 'Err'),
      ],
    );
  }

  Component _colorDot(Color color, String label) {
    return Column(
      children: [
        Text('*', style: TextStyle(color: color)),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
