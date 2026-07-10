import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Given a half-arm segment end and a perpendicular full line', () {
    test('when merged then a tee junction is formed', () {
      // A divider endpoint contributes only the arm pointing into the
      // segment, so an endpoint on a border forms a tee, not a cross.
      expect(mergeBoxCharacters('╷', '─'), '┬');
      expect(mergeBoxCharacters('╵', '─'), '┴');
      expect(mergeBoxCharacters('╶', '│'), '├');
      expect(mergeBoxCharacters('╴', '│'), '┤');
    });

    test('when merged in either order then the result is the same', () {
      expect(mergeBoxCharacters('╴', '│'), mergeBoxCharacters('│', '╴'));
      expect(mergeBoxCharacters('╷', '─'), mergeBoxCharacters('─', '╷'));
    });
  });

  test(
      'Given two perpendicular full lines '
      'when merged then a cross junction is formed', () {
    expect(mergeBoxCharacters('│', '─'), '┼');
    expect(mergeBoxCharacters('─', '│'), '┼');
  });

  group('Given an existing tee junction', () {
    test('when a half-arm it already contains is merged then it is unchanged',
        () {
      expect(mergeBoxCharacters('╷', '┬'), '┬');
    });

    test('when a perpendicular full line is merged then it becomes a cross',
        () {
      expect(mergeBoxCharacters('│', '┬'), '┼');
      expect(mergeBoxCharacters('─', '├'), '┼');
    });
  });

  group('Given a rounded corner', () {
    test('when overdrawn with a subset of its arms then it stays rounded', () {
      expect(mergeBoxCharacters('╶', '╭'), '╭');
      expect(mergeBoxCharacters('╷', '╭'), '╭');
      expect(mergeBoxCharacters('╭', '╭'), '╭');
      expect(mergeBoxCharacters('╴', '╮'), '╮');
      expect(mergeBoxCharacters('╵', '╰'), '╰');
    });

    test('when a new arm is added then it becomes a square junction', () {
      expect(mergeBoxCharacters('╴', '╭'), '┬');
      expect(mergeBoxCharacters('╵', '╭'), '├');
    });
  });

  test(
      'Given a corner and a full line '
      'when merged then a tee junction is formed', () {
    // The overlaid-panel case: a panel corner landing on a border run.
    expect(mergeBoxCharacters('╭', '─'), '┬');
    expect(mergeBoxCharacters('╰', '─'), '┴');
    expect(mergeBoxCharacters('╭', '│'), '├');
    expect(mergeBoxCharacters('┐', '│'), '┤');
  });

  test(
      'Given a heavy line and a light line '
      'when merged then a mixed-weight junction is formed', () {
    expect(mergeBoxCharacters('━', '│'), '┿');
    expect(mergeBoxCharacters('┃', '─'), '╂');
    expect(mergeBoxCharacters('╺', '│'), '┝');
    expect(mergeBoxCharacters('╹', '─'), '┸');
  });

  test(
      'Given a double line and a light line '
      'when merged then a double-single junction is formed', () {
    expect(mergeBoxCharacters('═', '│'), '╪');
    expect(mergeBoxCharacters('║', '─'), '╫');
    expect(mergeBoxCharacters('│', '═'), '╪');
  });

  test(
      'Given a dashed line and a perpendicular line '
      'when merged then the junction matches the solid counterpart', () {
    expect(mergeBoxCharacters('╌', '│'), '┼');
    expect(mergeBoxCharacters('┊', '─'), '┼');
  });

  test(
      'Given a combination with no Unicode representation '
      'when merged then the new character is kept', () {
    // Double meeting heavy has no Unicode junction.
    expect(mergeBoxCharacters('═', '┃'), '═');
  });

  test(
      'Given a non box-drawing character '
      'when merged then no merge is performed', () {
    expect(mergeBoxCharacters('a', '─'), isNull);
    expect(mergeBoxCharacters('─', 'a'), isNull);
    expect(mergeBoxCharacters('─', ' '), isNull);
    expect(mergeBoxCharacters(' ', ' '), isNull);
    // Diagonals are deliberately not mergeable.
    expect(mergeBoxCharacters('╱', '─'), isNull);
  });

  test(
      'Given box-drawing line characters '
      'when checked for mergeability then they are mergeable', () {
    for (final char in ['─', '│', '━', '║', '┼', '╋', '╬', '╴', '╭']) {
      expect(isMergeableBoxCharacter(char), isTrue, reason: char);
    }
  });

  test(
      'Given non-line characters '
      'when checked for mergeability then they are not mergeable', () {
    for (final char in [' ', 'a', '╳', '█', '▸']) {
      expect(isMergeableBoxCharacter(char), isFalse, reason: char);
    }
  });
}
