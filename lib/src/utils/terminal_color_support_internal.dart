import 'package:nocterm/src/utils/truthiness.dart';

bool detectTruecolorFromEnv(Map<String, String> env) {
  final override = env['NOCTERM_TRUECOLOR']?.toLowerCase();
  if (override != null && override.isNotEmpty) {
    if (truthy(override)) return true;
    if (falsey(override)) return false;
  }

  final colorterm = env['COLORTERM']?.toLowerCase() ?? '';
  if (colorterm.contains('truecolor') || colorterm.contains('24bit')) {
    return true;
  }

  // Windows Terminal exports WT_SESSION but (as of this writing) does not set
  // COLORTERM, even though it supports 24-bit truecolor natively. Detect it
  // explicitly so #RRGGBB themes render correctly without requiring the user
  // to export COLORTERM=truecolor manually.
  final wtSession = env['WT_SESSION'];
  if (wtSession != null && wtSession.isNotEmpty) {
    return true;
  }

  final term = env['TERM']?.toLowerCase() ?? '';
  if (term.contains('truecolor') || term.contains('24bit')) {
    return true;
  }

  return false;
}
