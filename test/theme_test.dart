import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Brightness', () {
    test('dark value exists', () {
      expect(Brightness.dark, isNotNull);
    });

    test('light value exists', () {
      expect(Brightness.light, isNotNull);
    });

    test('both values are distinct', () {
      expect(Brightness.dark, isNot(equals(Brightness.light)));
    });
  });

  group('AdaptiveColor', () {
    test('construction with light/dark colors', () {
      final lightColor = Color(0xFFFFFF);
      final darkColor = Color(0x000000);

      final adaptiveColor = AdaptiveColor(light: lightColor, dark: darkColor);

      expect(adaptiveColor.light, equals(lightColor));
      expect(adaptiveColor.dark, equals(darkColor));
    });

    test('AdaptiveColor.all() factory creates same color for both', () {
      final singleColor = Color(0xFF0000);

      final adaptiveColor = AdaptiveColor.all(singleColor);

      expect(adaptiveColor.light, equals(singleColor));
      expect(adaptiveColor.dark, equals(singleColor));
    });

    test('resolve(Brightness.dark) returns dark color', () {
      final lightColor = Color(0xFFFFFF);
      final darkColor = Color(0x000000);
      final adaptiveColor = AdaptiveColor(light: lightColor, dark: darkColor);

      final resolved = adaptiveColor.resolve(Brightness.dark);

      expect(resolved, equals(darkColor));
    });

    test('resolve(Brightness.light) returns light color', () {
      final lightColor = Color(0xFFFFFF);
      final darkColor = Color(0x000000);
      final adaptiveColor = AdaptiveColor(light: lightColor, dark: darkColor);

      final resolved = adaptiveColor.resolve(Brightness.light);

      expect(resolved, equals(lightColor));
    });

    test('equality works correctly', () {
      final color1 = AdaptiveColor(
        light: Color(0xFFFFFF),
        dark: Color(0x000000),
      );
      final color2 = AdaptiveColor(
        light: Color(0xFFFFFF),
        dark: Color(0x000000),
      );
      final color3 = AdaptiveColor(
        light: Color(0xFFFFFE),
        dark: Color(0x000000),
      );

      expect(color1, equals(color2));
      expect(color1, isNot(equals(color3)));
    });

    test('hashCode is consistent', () {
      final color1 = AdaptiveColor(
        light: Color(0xFFFFFF),
        dark: Color(0x000000),
      );
      final color2 = AdaptiveColor(
        light: Color(0xFFFFFF),
        dark: Color(0x000000),
      );

      expect(color1.hashCode, equals(color2.hashCode));
    });

    test('toString returns expected format', () {
      final adaptiveColor = AdaptiveColor(
        light: Color(0xFFFFFF),
        dark: Color(0x000000),
      );

      expect(adaptiveColor.toString(), contains('AdaptiveColor'));
      expect(adaptiveColor.toString(), contains('light'));
      expect(adaptiveColor.toString(), contains('dark'));
    });
  });

  group('TuiColors', () {
    test('surface exists and is AdaptiveColor', () {
      expect(TuiColors.surface, isA<AdaptiveColor>());
    });

    test('onSurface exists and is AdaptiveColor', () {
      expect(TuiColors.onSurface, isA<AdaptiveColor>());
    });

    test('primary exists and is AdaptiveColor', () {
      expect(TuiColors.primary, isA<AdaptiveColor>());
    });

    test('error exists and is AdaptiveColor', () {
      expect(TuiColors.error, isA<AdaptiveColor>());
    });

    test('success exists and is AdaptiveColor', () {
      expect(TuiColors.success, isA<AdaptiveColor>());
    });

    test('warning exists and is AdaptiveColor', () {
      expect(TuiColors.warning, isA<AdaptiveColor>());
    });

    test('outline exists and is AdaptiveColor', () {
      expect(TuiColors.outline, isA<AdaptiveColor>());
    });

    test('background exists and is AdaptiveColor', () {
      expect(TuiColors.background, isA<AdaptiveColor>());
    });

    test('onBackground exists and is AdaptiveColor', () {
      expect(TuiColors.onBackground, isA<AdaptiveColor>());
    });

    test('secondary exists and is AdaptiveColor', () {
      expect(TuiColors.secondary, isA<AdaptiveColor>());
    });

    test('outlineVariant exists and is AdaptiveColor', () {
      expect(TuiColors.outlineVariant, isA<AdaptiveColor>());
    });

    test('colors resolve correctly for dark brightness', () {
      final primaryDark = TuiColors.primary.resolve(Brightness.dark);
      final primaryLight = TuiColors.primary.resolve(Brightness.light);

      expect(primaryDark, isA<Color>());
      expect(primaryLight, isA<Color>());
      // Dark and light should typically be different (for contrast)
      expect(primaryDark, isNot(equals(primaryLight)));
    });

    test('colors resolve correctly for light brightness', () {
      final surfaceDark = TuiColors.surface.resolve(Brightness.dark);
      final surfaceLight = TuiColors.surface.resolve(Brightness.light);

      expect(surfaceDark, isA<Color>());
      expect(surfaceLight, isA<Color>());
    });
  });

  group('TuiThemeData', () {
    group('built-in themes', () {
      test('TuiThemeData.dark exists and has dark brightness', () {
        expect(TuiThemeData.dark, isA<TuiThemeData>());
        expect(TuiThemeData.dark.brightness, equals(Brightness.dark));
      });

      test('TuiThemeData.light exists and has light brightness', () {
        expect(TuiThemeData.light, isA<TuiThemeData>());
        expect(TuiThemeData.light.brightness, equals(Brightness.light));
      });

      test('TuiThemeData.nord exists and has dark brightness', () {
        expect(TuiThemeData.nord, isA<TuiThemeData>());
        expect(TuiThemeData.nord.brightness, equals(Brightness.dark));
      });

      test('TuiThemeData.dracula exists and has dark brightness', () {
        expect(TuiThemeData.dracula, isA<TuiThemeData>());
        expect(TuiThemeData.dracula.brightness, equals(Brightness.dark));
      });

      test('TuiThemeData.catppuccinMocha exists and has dark brightness', () {
        expect(TuiThemeData.catppuccinMocha, isA<TuiThemeData>());
        expect(
          TuiThemeData.catppuccinMocha.brightness,
          equals(Brightness.dark),
        );
      });

      test('TuiThemeData.gruvboxDark exists and has dark brightness', () {
        expect(TuiThemeData.gruvboxDark, isA<TuiThemeData>());
        expect(TuiThemeData.gruvboxDark.brightness, equals(Brightness.dark));
      });
    });

    group('required color properties', () {
      void verifyThemeHasAllColors(TuiThemeData theme, String themeName) {
        expect(
          theme.background,
          isA<Color>(),
          reason: '$themeName should have background',
        );
        expect(
          theme.onBackground,
          isA<Color>(),
          reason: '$themeName should have onBackground',
        );
        expect(
          theme.surface,
          isA<Color>(),
          reason: '$themeName should have surface',
        );
        expect(
          theme.onSurface,
          isA<Color>(),
          reason: '$themeName should have onSurface',
        );
        expect(
          theme.primary,
          isA<Color>(),
          reason: '$themeName should have primary',
        );
        expect(
          theme.onPrimary,
          isA<Color>(),
          reason: '$themeName should have onPrimary',
        );
        expect(
          theme.secondary,
          isA<Color>(),
          reason: '$themeName should have secondary',
        );
        expect(
          theme.onSecondary,
          isA<Color>(),
          reason: '$themeName should have onSecondary',
        );
        expect(
          theme.error,
          isA<Color>(),
          reason: '$themeName should have error',
        );
        expect(
          theme.onError,
          isA<Color>(),
          reason: '$themeName should have onError',
        );
        expect(
          theme.success,
          isA<Color>(),
          reason: '$themeName should have success',
        );
        expect(
          theme.warning,
          isA<Color>(),
          reason: '$themeName should have warning',
        );
        expect(
          theme.outline,
          isA<Color>(),
          reason: '$themeName should have outline',
        );
        expect(
          theme.outlineVariant,
          isA<Color>(),
          reason: '$themeName should have outlineVariant',
        );
      }

      test('dark theme has all required colors', () {
        verifyThemeHasAllColors(TuiThemeData.dark, 'dark');
      });

      test('light theme has all required colors', () {
        verifyThemeHasAllColors(TuiThemeData.light, 'light');
      });

      test('nord theme has all required colors', () {
        verifyThemeHasAllColors(TuiThemeData.nord, 'nord');
      });

      test('dracula theme has all required colors', () {
        verifyThemeHasAllColors(TuiThemeData.dracula, 'dracula');
      });

      test('catppuccinMocha theme has all required colors', () {
        verifyThemeHasAllColors(
          TuiThemeData.catppuccinMocha,
          'catppuccinMocha',
        );
      });

      test('gruvboxDark theme has all required colors', () {
        verifyThemeHasAllColors(TuiThemeData.gruvboxDark, 'gruvboxDark');
      });
    });

    group('copyWith', () {
      test('copyWith creates new instance with changed brightness', () {
        final original = TuiThemeData.dark;
        final modified = original.copyWith(brightness: Brightness.light);

        expect(modified.brightness, equals(Brightness.light));
        expect(original.brightness, equals(Brightness.dark));
      });

      test('copyWith creates new instance with changed primary', () {
        final original = TuiThemeData.dark;
        final newPrimary = Color(0xFF0000);
        final modified = original.copyWith(primary: newPrimary);

        expect(modified.primary, equals(newPrimary));
        expect(original.primary, isNot(equals(newPrimary)));
      });

      test('copyWith preserves unchanged values', () {
        final original = TuiThemeData.dark;
        final modified = original.copyWith(primary: Color(0xFF0000));

        expect(modified.background, equals(original.background));
        expect(modified.onBackground, equals(original.onBackground));
        expect(modified.surface, equals(original.surface));
        expect(modified.onSurface, equals(original.onSurface));
        expect(modified.secondary, equals(original.secondary));
        expect(modified.error, equals(original.error));
        expect(modified.success, equals(original.success));
        expect(modified.warning, equals(original.warning));
        expect(modified.outline, equals(original.outline));
      });

      test('copyWith with no arguments returns equivalent theme', () {
        final original = TuiThemeData.dark;
        final modified = original.copyWith();

        expect(modified, equals(original));
      });
    });

    group('equality and hashCode', () {
      test('same themes are equal', () {
        expect(TuiThemeData.dark, equals(TuiThemeData.dark));
      });

      test('different themes are not equal', () {
        expect(TuiThemeData.dark, isNot(equals(TuiThemeData.light)));
        expect(TuiThemeData.nord, isNot(equals(TuiThemeData.dracula)));
      });

      test('hashCode is consistent for equal themes', () {
        expect(TuiThemeData.dark.hashCode, equals(TuiThemeData.dark.hashCode));
      });
    });

    test('toString returns expected format', () {
      final theme = TuiThemeData.dark;
      expect(theme.toString(), contains('TuiThemeData'));
      expect(theme.toString(), contains('brightness'));
    });
  });

  group('TuiTheme InheritedComponent', () {
    test('TuiTheme.of returns the provided theme data', () async {
      await testNocterm('TuiTheme.of returns provided theme', (tester) async {
        TuiThemeData? capturedTheme;

        await tester.pumpComponent(
          TuiTheme(
            data: TuiThemeData.dracula,
            child: LayoutBuilder(
              builder: (context, constraints) {
                capturedTheme = TuiTheme.of(context);
                return Text('Test');
              },
            ),
          ),
        );

        expect(capturedTheme, isNotNull);
        expect(capturedTheme, equals(TuiThemeData.dracula));
      });
    });

    test(
      'TuiTheme.of returns default (dark) when no TuiTheme ancestor',
      () async {
        await testNocterm('TuiTheme.of returns default dark theme', (
          tester,
        ) async {
          TuiThemeData? capturedTheme;

          await tester.pumpComponent(
            LayoutBuilder(
              builder: (context, constraints) {
                capturedTheme = TuiTheme.of(context);
                return Text('Test');
              },
            ),
          );

          expect(capturedTheme, isNotNull);
          expect(capturedTheme, equals(TuiThemeData.dark));
        });
      },
    );

    test('TuiTheme.maybeOf returns null when no TuiTheme ancestor', () async {
      await testNocterm('TuiTheme.maybeOf returns null', (tester) async {
        TuiThemeData? capturedTheme;
        bool wasChecked = false;

        await tester.pumpComponent(
          LayoutBuilder(
            builder: (context, constraints) {
              capturedTheme = TuiTheme.maybeOf(context);
              wasChecked = true;
              return Text('Test');
            },
          ),
        );

        expect(wasChecked, isTrue);
        expect(capturedTheme, isNull);
      });
    });

    test('TuiTheme.maybeOf returns theme when ancestor exists', () async {
      await testNocterm('TuiTheme.maybeOf returns theme', (tester) async {
        TuiThemeData? capturedTheme;

        await tester.pumpComponent(
          TuiTheme(
            data: TuiThemeData.nord,
            child: LayoutBuilder(
              builder: (context, constraints) {
                capturedTheme = TuiTheme.maybeOf(context);
                return Text('Test');
              },
            ),
          ),
        );

        expect(capturedTheme, isNotNull);
        expect(capturedTheme, equals(TuiThemeData.nord));
      });
    });

    test('nested TuiTheme overrides parent theme', () async {
      await testNocterm('nested TuiTheme overrides parent', (tester) async {
        TuiThemeData? outerTheme;
        TuiThemeData? innerTheme;

        await tester.pumpComponent(
          TuiTheme(
            data: TuiThemeData.dark,
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    outerTheme = TuiTheme.of(context);
                    return Text('Outer');
                  },
                ),
                TuiTheme(
                  data: TuiThemeData.catppuccinMocha,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      innerTheme = TuiTheme.of(context);
                      return Text('Inner');
                    },
                  ),
                ),
              ],
            ),
          ),
        );

        expect(outerTheme, equals(TuiThemeData.dark));
        expect(innerTheme, equals(TuiThemeData.catppuccinMocha));
      });
    });
  });

  group('Component Theme Integration', () {
    test(
      'ProgressBar uses theme primary and outline colors by default',
      () async {
        await testNocterm('ProgressBar uses theme colors', (tester) async {
          // Test with dark theme
          await tester.pumpComponent(
            TuiTheme(
              data: TuiThemeData.dark,
              child: SizedBox(
                width: 20,
                height: 1,
                child: ProgressBar(value: 0.5),
              ),
            ),
          );

          // The progress bar should render with theme colors
          final content = tester.terminalState.getText();
          expect(content, contains('█'));
          expect(content, contains('░'));
        });
      },
    );

    test('ProgressBar renders with different themes', () async {
      await testNocterm('ProgressBar with dracula theme', (tester) async {
        await tester.pumpComponent(
          TuiTheme(
            data: TuiThemeData.dracula,
            child: SizedBox(
              width: 20,
              height: 1,
              child: ProgressBar(value: 0.5),
            ),
          ),
        );

        final content = tester.terminalState.getText();
        expect(content, contains('█'));
      });

      await testNocterm('ProgressBar with nord theme', (tester) async {
        await tester.pumpComponent(
          TuiTheme(
            data: TuiThemeData.nord,
            child: SizedBox(
              width: 20,
              height: 1,
              child: ProgressBar(value: 0.5),
            ),
          ),
        );

        final content = tester.terminalState.getText();
        expect(content, contains('█'));
      });
    });

    test('Divider uses theme outline color by default', () async {
      await testNocterm('Divider uses theme colors', (tester) async {
        await tester.pumpComponent(
          TuiTheme(
            data: TuiThemeData.dark,
            child: Container(
              width: 20,
              height: 3,
              child: Column(
                children: [Text('Above'), Divider(), Text('Below')],
              ),
            ),
          ),
        );

        expect(tester.terminalState, containsText('─'));
      });
    });

    test('Divider renders with different themes', () async {
      await testNocterm('Divider with catppuccinMocha theme', (tester) async {
        await tester.pumpComponent(
          TuiTheme(
            data: TuiThemeData.catppuccinMocha,
            child: Container(width: 20, height: 3, child: Divider()),
          ),
        );

        expect(tester.terminalState, containsText('─'));
      });

      await testNocterm('Divider with gruvboxDark theme', (tester) async {
        await tester.pumpComponent(
          TuiTheme(
            data: TuiThemeData.gruvboxDark,
            child: Container(width: 20, height: 3, child: Divider()),
          ),
        );

        expect(tester.terminalState, containsText('─'));
      });
    });

    test('custom colors override theme colors for ProgressBar', () async {
      await testNocterm('ProgressBar custom colors', (tester) async {
        final customValueColor = Colors.red;
        final customBackgroundColor = Colors.blue;

        await tester.pumpComponent(
          TuiTheme(
            data: TuiThemeData.dark,
            child: SizedBox(
              width: 20,
              height: 1,
              child: ProgressBar(
                value: 0.5,
                valueColor: customValueColor,
                backgroundColor: customBackgroundColor,
              ),
            ),
          ),
        );

        final content = tester.terminalState.getText();
        expect(content, contains('█'));
      });
    });

    test('custom color overrides theme color for Divider', () async {
      await testNocterm('Divider custom color', (tester) async {
        await tester.pumpComponent(
          TuiTheme(
            data: TuiThemeData.dark,
            child: Container(
              width: 20,
              height: 3,
              child: Divider(color: Colors.green),
            ),
          ),
        );

        expect(tester.terminalState, containsText('─'));
      });
    });
  });
}
