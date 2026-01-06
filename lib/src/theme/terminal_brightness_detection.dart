import 'dart:io';

import '../backend/terminal.dart';
import '../style.dart';
import 'brightness.dart';

/// Calculate brightness from an RGB color using the Rec. 709 luminance formula.
///
/// Returns [Brightness.dark] if the color's luminance is below 0.5,
/// [Brightness.light] otherwise.
///
/// The formula used is: luminance = 0.2126*R + 0.7152*G + 0.0722*B
/// where R, G, B are normalized to 0.0-1.0 range.
Brightness brightnessFromColor(Color color) {
  // Rec. 709 luminance formula (same as sRGB)
  // Using normalized 0-1 values
  final luminance = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;

  // luminance < 0.5 means dark background -> dark theme
  return luminance < 0.5 ? Brightness.dark : Brightness.light;
}

/// Detect terminal brightness from the COLORFGBG environment variable.
///
/// This variable is set by some terminal emulators in the format "fg;bg" or
/// "fg;extra;bg" where fg and bg are ANSI color indices.
///
/// ANSI colors 0-6 and 8 are considered dark backgrounds.
/// ANSI colors 7 and 9-15 are considered light backgrounds.
///
/// Returns null if the variable is not set or cannot be parsed.
Brightness? detectBrightnessFromColorFgBg() {
  final colorFgBg = Platform.environment['COLORFGBG'];
  if (colorFgBg == null || colorFgBg.isEmpty) {
    return null;
  }

  // Format: "fg;bg" or "fg;extra;bg"
  final parts = colorFgBg.split(';');
  if (parts.isEmpty) {
    return null;
  }

  // Background is the last element
  final bgString = parts.last;
  final bg = int.tryParse(bgString);
  if (bg == null) {
    return null;
  }

  // ANSI color interpretation:
  // 0 = black, 1 = red, 2 = green, 3 = yellow, 4 = blue, 5 = magenta, 6 = cyan
  // 7 = white (light gray), 8 = bright black (dark gray)
  // 9-15 = bright colors (generally light)
  //
  // Dark backgrounds: 0-6, 8
  // Light backgrounds: 7, 9-15
  if (bg == 7 || bg >= 9) {
    return Brightness.light;
  }
  return Brightness.dark;
}

/// Check macOS system appearance (Dark Mode setting).
///
/// Uses `defaults read -g AppleInterfaceStyle` to detect if macOS Dark Mode
/// is enabled. Returns [Brightness.dark] if the output is "Dark",
/// [Brightness.light] if the command fails (key doesn't exist in light mode).
///
/// Returns null on non-macOS platforms or if detection fails unexpectedly.
Future<Brightness?> detectMacOSDarkMode() async {
  if (!Platform.isMacOS) {
    return null;
  }

  try {
    final result = await Process.run('defaults', [
      'read',
      '-g',
      'AppleInterfaceStyle',
    ]);

    // Exit code 0 means the key exists (Dark Mode is on)
    // Exit code 1 means the key doesn't exist (Light Mode)
    if (result.exitCode == 0) {
      final output = (result.stdout as String).trim().toLowerCase();
      if (output == 'dark') {
        return Brightness.dark;
      }
    }

    // Key doesn't exist = Light Mode
    return Brightness.light;
  } catch (e) {
    // Process failed to run
    return null;
  }
}

/// Detect terminal brightness using a fallback chain of detection methods.
///
/// The detection methods are tried in order:
/// 1. **OSC 11 query** - Queries the terminal's actual background color via
///    [Terminal.getBackgroundColor]. This is the most accurate method but
///    requires terminal support.
/// 2. **COLORFGBG environment variable** - Some terminals set this variable
///    with foreground/background color indices.
/// 3. **macOS AppleInterfaceStyle** - On macOS, checks the system Dark Mode
///    setting via `defaults read`.
/// 4. **Default to dark** - If all methods fail, defaults to [Brightness.dark]
///    as most terminal users prefer dark themes.
///
/// The [timeout] parameter controls how long to wait for the OSC 11 query.
/// A shorter timeout (e.g., 50ms) is recommended to avoid UI delays.
///
/// Example:
/// ```dart
/// final brightness = await detectTerminalBrightness(terminal);
/// final theme = brightness == Brightness.light
///     ? TuiThemeData.light
///     : TuiThemeData.dark;
/// ```
Future<Brightness> detectTerminalBrightness(
  Terminal terminal, {
  Duration timeout = const Duration(milliseconds: 50),
}) async {
  // Method 1: OSC 11 query for actual background color
  try {
    final bgColor = await terminal.getBackgroundColor(timeout: timeout);
    if (bgColor != null) {
      return brightnessFromColor(bgColor);
    }
  } catch (e) {
    // OSC query failed, continue to fallback
  }

  // Method 2: COLORFGBG environment variable
  final colorFgBgBrightness = detectBrightnessFromColorFgBg();
  if (colorFgBgBrightness != null) {
    return colorFgBgBrightness;
  }

  // Method 3: macOS system appearance
  final macOSBrightness = await detectMacOSDarkMode();
  if (macOSBrightness != null) {
    return macOSBrightness;
  }

  // Method 4: Default to dark (most terminal users prefer dark themes)
  return Brightness.dark;
}
