import 'package:nocterm/nocterm.dart';

/// Theme showcase example demonstrating all built-in themes.
///
/// Run with: dart run example/theme_showcase.dart
void main() async {
  await runApp(const ThemeShowcase());
}

/// List of all built-in themes with their display names.
const _themes = <(String name, TuiThemeData theme)>[
  ('Dark (Default)', TuiThemeData.dark),
  ('Light', TuiThemeData.light),
  ('Nord', TuiThemeData.nord),
  ('Dracula', TuiThemeData.dracula),
  ('Catppuccin Mocha', TuiThemeData.catppuccinMocha),
  ('Gruvbox Dark', TuiThemeData.gruvboxDark),
];

class ThemeShowcase extends StatefulComponent {
  const ThemeShowcase({super.key});

  @override
  State<ThemeShowcase> createState() => _ThemeShowcaseState();
}

class _ThemeShowcaseState extends State<ThemeShowcase> {
  int _currentThemeIndex = 0;

  TuiThemeData get _currentTheme => _themes[_currentThemeIndex].$2;
  String get _currentThemeName => _themes[_currentThemeIndex].$1;

  void _nextTheme() {
    setState(() {
      _currentThemeIndex = (_currentThemeIndex + 1) % _themes.length;
    });
  }

  void _previousTheme() {
    setState(() {
      _currentThemeIndex =
          (_currentThemeIndex - 1 + _themes.length) % _themes.length;
    });
  }

  void _selectTheme(int index) {
    if (index >= 0 && index < _themes.length) {
      setState(() {
        _currentThemeIndex = index;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return TuiTheme(
      data: _currentTheme,
      child: Focusable(
        focused: true,
        onKeyEvent: (event) {
          if (event.logicalKey == LogicalKey.keyQ ||
              event.logicalKey == LogicalKey.escape) {
            shutdownApp();
            return true;
          } else if (event.logicalKey == LogicalKey.arrowRight ||
              event.logicalKey == LogicalKey.keyL) {
            _nextTheme();
            return true;
          } else if (event.logicalKey == LogicalKey.arrowLeft ||
              event.logicalKey == LogicalKey.keyH) {
            _previousTheme();
            return true;
          } else if (event.logicalKey == LogicalKey.digit1) {
            _selectTheme(0);
            return true;
          } else if (event.logicalKey == LogicalKey.digit2) {
            _selectTheme(1);
            return true;
          } else if (event.logicalKey == LogicalKey.digit3) {
            _selectTheme(2);
            return true;
          } else if (event.logicalKey == LogicalKey.digit4) {
            _selectTheme(3);
            return true;
          } else if (event.logicalKey == LogicalKey.digit5) {
            _selectTheme(4);
            return true;
          } else if (event.logicalKey == LogicalKey.digit6) {
            _selectTheme(5);
            return true;
          }
          return false;
        },
        child: _ThemeShowcaseContent(
          themeName: _currentThemeName,
          themeIndex: _currentThemeIndex,
        ),
      ),
    );
  }
}

class _ThemeShowcaseContent extends StatelessComponent {
  _ThemeShowcaseContent({required this.themeName, required this.themeIndex});

  final String themeName;
  final int themeIndex;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);

    return Container(
      decoration: BoxDecoration(color: theme.background),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 52, maxHeight: 22),
          decoration: BoxDecoration(
            color: theme.surface,
            border: BoxBorder.all(color: theme.outline),
          ),
          child: Column(
            children: [
              // Header with theme name
              _buildHeader(theme),

              // Divider below header
              Divider(),

              // Content area
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome text
                      Center(
                        child: Text(
                          'Welcome to nocterm TUI framework',
                          style: TextStyle(color: theme.onSurface),
                        ),
                      ),

                      SizedBox(height: 1),

                      // Progress bar demonstration
                      _buildProgressSection(theme),

                      SizedBox(height: 1),

                      // Divider
                      Divider(),

                      SizedBox(height: 1),

                      // Status indicators
                      _buildStatusSection(theme),

                      Spacer(),

                      // Theme selector hint
                      _buildThemeSelector(theme),

                      SizedBox(height: 1),

                      // Footer instructions
                      _buildFooter(theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Component _buildHeader(TuiThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(color: theme.surface),
      child: Center(
        child: Text(
          'Theme: $themeName',
          style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Component _buildProgressSection(TuiThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(height: 1, child: ProgressBar(value: 0.6)),
            ),
            SizedBox(width: 2),
            Text('60%', style: TextStyle(color: theme.secondary)),
          ],
        ),
      ],
    );
  }

  Component _buildStatusSection(TuiThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('● ', style: TextStyle(color: theme.success)),
            Text('Success message', style: TextStyle(color: theme.onSurface)),
          ],
        ),
        Row(
          children: [
            Text('● ', style: TextStyle(color: theme.warning)),
            Text('Warning message', style: TextStyle(color: theme.onSurface)),
          ],
        ),
        Row(
          children: [
            Text('● ', style: TextStyle(color: theme.error)),
            Text('Error message', style: TextStyle(color: theme.onSurface)),
          ],
        ),
      ],
    );
  }

  Component _buildThemeSelector(TuiThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < _themes.length; i++) ...[
          Text(
            i == themeIndex ? '●' : '○',
            style: TextStyle(
              color: i == themeIndex ? theme.primary : theme.outline,
            ),
          ),
          if (i < _themes.length - 1) Text(' '),
        ],
      ],
    );
  }

  Component _buildFooter(TuiThemeData theme) {
    return Column(
      children: [
        Center(
          child: Text(
            'Press 1-6 to switch themes',
            style: TextStyle(color: theme.outline),
          ),
        ),
        Center(
          child: Text(
            'Press Q to quit',
            style: TextStyle(color: theme.outline),
          ),
        ),
      ],
    );
  }
}
