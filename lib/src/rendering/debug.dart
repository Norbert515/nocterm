/// Debug flags for the nocterm rendering system.
library;

import '../style.dart';

// Default repaint color: less saturated (0.5), semi-transparent (0.3 alpha)
// Starting hue at 60 (yellow) like Flutter
const HSVColor _kDebugDefaultRepaintColor = HSVColor.fromAHSV(
  0.3,
  60.0,
  0.5,
  1.0,
);

/// Overlay a rotating set of colors when repainting render objects in debug mode.
///
/// When enabled, every render object that repaints will have its background
/// tinted with a color from the rainbow spectrum. The color rotates each frame,
/// making it easy to see which objects are being repainted frequently.
bool debugRepaintRainbowEnabled = false;

/// The current color to overlay when repainting a render object.
///
/// This value is incremented by the frame drawing callback when
/// [debugRepaintRainbowEnabled] is true.
HSVColor debugCurrentRepaintColor = _kDebugDefaultRepaintColor;

/// Reset debug state to defaults (useful for testing).
void debugResetRepaintRainbow() {
  debugRepaintRainbowEnabled = false;
  debugCurrentRepaintColor = _kDebugDefaultRepaintColor;
}
