/// Merging of Unicode box-drawing characters (U+2500–U+257F).
///
/// Models every line character as four arms (up, right, down, left), each
/// with a weight. Drawing one line character on top of another can then
/// combine their arms and produce the proper junction glyph: a vertical line
/// meeting a horizontal border becomes `┬`, a divider hitting a box's left
/// edge becomes `├`, two crossing dividers become `┼`.
///
/// Used by [TerminalCanvas.drawText] when `blendBoxLines` is enabled.
library;

/// The weight of one arm of a box-drawing character.
enum LineArm {
  /// No line in this direction.
  none,

  /// A light (thin) line, e.g. `─`.
  light,

  /// A heavy (bold) line, e.g. `━`.
  heavy,

  /// A double line, e.g. `═`.
  double,
}

/// The four arms of a box-drawing character: (up, right, down, left).
typedef BoxCharArms = (LineArm, LineArm, LineArm, LineArm);

const _n = LineArm.none;
const _l = LineArm.light;
const _h = LineArm.heavy;
const _d = LineArm.double;

/// Arms for every mergeable character in the box-drawing block.
///
/// Excluded on purpose: the diagonals `╱ ╲ ╳` (not axis-aligned lines).
/// Dashed and dotted variants map to the same arms as their solid
/// counterparts so a dashed divider still forms solid junctions.
///
/// Entry order matters for [_armsToChar]: the canonical (solid, square)
/// character for a given arm set must appear before any alias sharing those
/// arms (dashed variants, rounded corners), because the reverse lookup keeps
/// the first entry.
const Map<String, BoxCharArms> _charToArms = {
  // Straight lines.
  '─': (_n, _l, _n, _l),
  '━': (_n, _h, _n, _h),
  '│': (_l, _n, _l, _n),
  '┃': (_h, _n, _h, _n),
  // Dashed/dotted variants (aliases of the straight lines above).
  '┄': (_n, _l, _n, _l),
  '┅': (_n, _h, _n, _h),
  '┆': (_l, _n, _l, _n),
  '┇': (_h, _n, _h, _n),
  '┈': (_n, _l, _n, _l),
  '┉': (_n, _h, _n, _h),
  '┊': (_l, _n, _l, _n),
  '┋': (_h, _n, _h, _n),
  '╌': (_n, _l, _n, _l),
  '╍': (_n, _h, _n, _h),
  '╎': (_l, _n, _l, _n),
  '╏': (_h, _n, _h, _n),
  // Corners.
  '┌': (_n, _l, _l, _n),
  '┍': (_n, _h, _l, _n),
  '┎': (_n, _l, _h, _n),
  '┏': (_n, _h, _h, _n),
  '┐': (_n, _n, _l, _l),
  '┑': (_n, _n, _l, _h),
  '┒': (_n, _n, _h, _l),
  '┓': (_n, _n, _h, _h),
  '└': (_l, _l, _n, _n),
  '┕': (_l, _h, _n, _n),
  '┖': (_h, _l, _n, _n),
  '┗': (_h, _h, _n, _n),
  '┘': (_l, _n, _n, _l),
  '┙': (_l, _n, _n, _h),
  '┚': (_h, _n, _n, _l),
  '┛': (_h, _n, _n, _h),
  // Rounded corners (aliases of the square corners above).
  '╭': (_n, _l, _l, _n),
  '╮': (_n, _n, _l, _l),
  '╯': (_l, _n, _n, _l),
  '╰': (_l, _l, _n, _n),
  // Tees: vertical with right arm.
  '├': (_l, _l, _l, _n),
  '┝': (_l, _h, _l, _n),
  '┞': (_h, _l, _l, _n),
  '┟': (_l, _l, _h, _n),
  '┠': (_h, _l, _h, _n),
  '┡': (_h, _h, _l, _n),
  '┢': (_l, _h, _h, _n),
  '┣': (_h, _h, _h, _n),
  // Tees: vertical with left arm.
  '┤': (_l, _n, _l, _l),
  '┥': (_l, _n, _l, _h),
  '┦': (_h, _n, _l, _l),
  '┧': (_l, _n, _h, _l),
  '┨': (_h, _n, _h, _l),
  '┩': (_h, _n, _l, _h),
  '┪': (_l, _n, _h, _h),
  '┫': (_h, _n, _h, _h),
  // Tees: horizontal with down arm.
  '┬': (_n, _l, _l, _l),
  '┭': (_n, _l, _l, _h),
  '┮': (_n, _h, _l, _l),
  '┯': (_n, _h, _l, _h),
  '┰': (_n, _l, _h, _l),
  '┱': (_n, _l, _h, _h),
  '┲': (_n, _h, _h, _l),
  '┳': (_n, _h, _h, _h),
  // Tees: horizontal with up arm.
  '┴': (_l, _l, _n, _l),
  '┵': (_l, _l, _n, _h),
  '┶': (_l, _h, _n, _l),
  '┷': (_l, _h, _n, _h),
  '┸': (_h, _l, _n, _l),
  '┹': (_h, _l, _n, _h),
  '┺': (_h, _h, _n, _l),
  '┻': (_h, _h, _n, _h),
  // Crosses.
  '┼': (_l, _l, _l, _l),
  '┽': (_l, _l, _l, _h),
  '┾': (_l, _h, _l, _l),
  '┿': (_l, _h, _l, _h),
  '╀': (_h, _l, _l, _l),
  '╁': (_l, _l, _h, _l),
  '╂': (_h, _l, _h, _l),
  '╃': (_h, _l, _l, _h),
  '╄': (_h, _h, _l, _l),
  '╅': (_l, _l, _h, _h),
  '╆': (_l, _h, _h, _l),
  '╇': (_h, _h, _l, _h),
  '╈': (_l, _h, _h, _h),
  '╉': (_h, _l, _h, _h),
  '╊': (_h, _h, _h, _l),
  '╋': (_h, _h, _h, _h),
  // Double lines.
  '═': (_n, _d, _n, _d),
  '║': (_d, _n, _d, _n),
  // Double/single corners.
  '╒': (_n, _d, _l, _n),
  '╓': (_n, _l, _d, _n),
  '╔': (_n, _d, _d, _n),
  '╕': (_n, _n, _l, _d),
  '╖': (_n, _n, _d, _l),
  '╗': (_n, _n, _d, _d),
  '╘': (_l, _d, _n, _n),
  '╙': (_d, _l, _n, _n),
  '╚': (_d, _d, _n, _n),
  '╛': (_l, _n, _n, _d),
  '╜': (_d, _n, _n, _l),
  '╝': (_d, _n, _n, _d),
  // Double/single tees and crosses.
  '╞': (_l, _d, _l, _n),
  '╟': (_d, _l, _d, _n),
  '╠': (_d, _d, _d, _n),
  '╡': (_l, _n, _l, _d),
  '╢': (_d, _n, _d, _l),
  '╣': (_d, _n, _d, _d),
  '╤': (_n, _d, _l, _d),
  '╥': (_n, _l, _d, _l),
  '╦': (_n, _d, _d, _d),
  '╧': (_l, _d, _n, _d),
  '╨': (_d, _l, _n, _l),
  '╩': (_d, _d, _n, _d),
  '╪': (_l, _d, _l, _d),
  '╫': (_d, _l, _d, _l),
  '╬': (_d, _d, _d, _d),
  // Half lines (segment ends). These are what blended divider endpoints
  // paint, so an endpoint only contributes the arm pointing into the
  // segment: `╷` on a top border `─` merges to `┬`, never `┼`.
  '╴': (_n, _n, _n, _l),
  '╵': (_l, _n, _n, _n),
  '╶': (_n, _l, _n, _n),
  '╷': (_n, _n, _l, _n),
  '╸': (_n, _n, _n, _h),
  '╹': (_h, _n, _n, _n),
  '╺': (_n, _h, _n, _n),
  '╻': (_n, _n, _h, _n),
  // Mixed-weight lines.
  '╼': (_n, _h, _n, _l),
  '╽': (_l, _n, _h, _n),
  '╾': (_n, _l, _n, _h),
  '╿': (_h, _n, _l, _n),
};

/// Reverse lookup from arms to the canonical character.
///
/// First entry in [_charToArms] wins, so aliases (dashed lines, rounded
/// corners) resolve to their solid, square counterpart.
final Map<BoxCharArms, String> _armsToChar = () {
  final map = <BoxCharArms, String>{};
  for (final entry in _charToArms.entries) {
    map.putIfAbsent(entry.value, () => entry.key);
  }
  return map;
}();

/// Merges [newChar] drawn on top of [existingChar].
///
/// Returns the junction character whose arms combine both, or null when
/// either character is not a mergeable box-drawing character (the caller
/// should fall back to a plain overwrite).
///
/// Per arm, the new character wins where it has a line and the existing
/// character's arm is kept where it doesn't. This makes segment-versus-line
/// merges order independent: `╴` onto `│` and `│` onto `╴` both give `┤`.
///
/// When the combined arms equal the existing character's arms, the existing
/// character is returned unchanged so aliases keep their identity - drawing
/// over a rounded corner `╭` with a subset of its arms does not square it
/// off to `┌`.
///
/// Combinations with no Unicode representation (e.g. a double arm meeting a
/// heavy arm) fall back to [newChar].
String? mergeBoxCharacters(String newChar, String existingChar) {
  final newArms = _charToArms[newChar];
  final existingArms = _charToArms[existingChar];
  if (newArms == null || existingArms == null) return null;

  final merged = _combine(newArms, existingArms);
  // Keep the existing character only when the new one adds nothing: a stub
  // must not square a rounded corner. Equal arms are a style choice, and
  // the character being drawn is on top.
  if (merged == existingArms && newArms != existingArms) return existingChar;
  if (merged == newArms) return newChar;
  return _armsToChar[merged] ?? newChar;
}

/// Merges the arms [newArms] drawn on top of [existingChar].
///
/// The arms-level counterpart of [mergeBoxCharacters], for arm sets Unicode
/// cannot name: half lines exist at light (`╴╵╶╷`) and heavy (`╸╹╺╻`) weight
/// only, so a lone double arm has no character - though every junction it
/// forms does.
///
/// Merges per arm as [mergeBoxCharacters] does. Returns null when
/// [existingChar] is not mergeable, or the combination has no Unicode
/// representation.
String? mergeArmsIntoCharacter(BoxCharArms newArms, String existingChar) {
  final existingArms = _charToArms[existingChar];
  if (existingArms == null) return null;

  final merged = _combine(newArms, existingArms);
  if (merged == existingArms) return existingChar;
  return _armsToChar[merged];
}

/// Combines two arm sets, the new character winning wherever it has a line.
BoxCharArms _combine(BoxCharArms newArms, BoxCharArms existingArms) {
  LineArm pick(LineArm a, LineArm b) => a == LineArm.none ? b : a;
  return (
    pick(newArms.$1, existingArms.$1),
    pick(newArms.$2, existingArms.$2),
    pick(newArms.$3, existingArms.$3),
    pick(newArms.$4, existingArms.$4),
  );
}
