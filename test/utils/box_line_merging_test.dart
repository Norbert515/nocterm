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

  group('Given two characters of the same weight', () {
    // Same weight means overlapping arms agree, so `pick` returns the same
    // arm set either way round.
    const light = [
      '─', '│', '┌', '┐', '└', '┘', '├', '┤', '┬', '┴', '┼', //
      '╴', '╵', '╶', '╷',
    ];
    const heavy = [
      '━', '┃', '┏', '┓', '┗', '┛', '┣', '┫', '┳', '┻', '╋', //
      '╸', '╹', '╺', '╻',
    ];
    const double = ['═', '║', '╔', '╗', '╚', '╝', '╠', '╣', '╦', '╩', '╬'];

    for (final (name, chars) in [
      ('light', light),
      ('heavy', heavy),
      ('double', double),
    ]) {
      test(
          'when any two $name characters are merged '
          'then the order does not matter', () {
        for (final a in chars) {
          for (final b in chars) {
            expect(
              mergeBoxCharacters(a, b),
              mergeBoxCharacters(b, a),
              reason: 'merging $a and $b is order dependent',
            );
          }
        }
      });
    }
  });

  group('Given characters of different weights', () {
    test(
        'when their arms point in different directions '
        'then the order does not matter', () {
      // The common junction case: a heavy line crossing or landing on a
      // light one. Neither character has an arm the other also has, so
      // both weights survive regardless of who is drawn first.
      for (final (a, b) in [
        ('┃', '─'),
        ('━', '│'),
        ('╻', '─'),
        ('╹', '─'),
        ('╺', '│'),
        ('╷', '━'),
        ('╶', '┃'),
        ('║', '─'),
        ('═', '│'),
      ]) {
        expect(
          mergeBoxCharacters(a, b),
          mergeBoxCharacters(b, a),
          reason: 'merging $a and $b is order dependent',
        );
      }
    });

    test(
        'when they share an arm direction '
        'then the newly drawn weight wins', () {
      // Overlapping arms are the one place drawing order is visible: the
      // new character's weight replaces the existing one on the shared
      // arm, so heavy-on-light and light-on-heavy differ.
      expect(mergeBoxCharacters('━', '─'), '━');
      expect(mergeBoxCharacters('─', '━'), '─');
      expect(mergeBoxCharacters('┃', '│'), '┃');
      expect(mergeBoxCharacters('│', '┃'), '│');
      expect(mergeBoxCharacters('═', '─'), '═');
      expect(mergeBoxCharacters('─', '═'), '─');

      // The same rule downgrades individual arms of a junction. A light
      // divider running through a heavy tee thins the arms it overlaps
      // while leaving the others heavy.
      expect(mergeBoxCharacters('┝', '─'), '┾');
      expect(mergeBoxCharacters('─', '┝'), '┼');
      expect(mergeBoxCharacters('┗', '─'), '┺');
      expect(mergeBoxCharacters('─', '┗'), '┸');
      expect(mergeBoxCharacters('┳', '│'), '╈');
      expect(mergeBoxCharacters('│', '┳'), '┿');
    });

    test(
        'when the combination has no Unicode junction '
        'then each order keeps its own new character', () {
      // Double never combines with heavy, so the fallback to `newChar`
      // makes the result depend on which was drawn last.
      expect(mergeBoxCharacters('═', '┃'), '═');
      expect(mergeBoxCharacters('┃', '═'), '┃');
    });
  });

  test(
      'Given two aliases with identical arms '
      'when merged then the existing character is kept', () {
    // Both orders leave the arms unchanged, so each keeps whichever style
    // was already on the canvas.
    expect(mergeBoxCharacters('╭', '┌'), '┌');
    expect(mergeBoxCharacters('┌', '╭'), '╭');
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
