import 'package:matcher/matcher.dart';
import '../style.dart';
import 'terminal_state.dart';

/// Matcher that checks if terminal contains specific text
class ContainsText extends Matcher {
  final String text;

  const ContainsText(this.text);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is TerminalState) {
      return item.containsText(text);
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('contains text "$text"');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is TerminalState) {
      return mismatchDescription
          .add('actual content:\n')
          .add(item.renderToString());
    }
    return mismatchDescription.add('is not a TerminalState');
  }
}

/// Matcher that checks for text at a specific position
class HasTextAt extends Matcher {
  final int x;
  final int y;
  final String text;

  const HasTextAt(this.x, this.y, this.text);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is TerminalState) {
      final actualText = item.getTextAt(x, y, length: text.length);
      return actualText == text;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('has text "$text" at position ($x, $y)');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is TerminalState) {
      final actualText = item.getTextAt(x, y, length: text.length);
      return mismatchDescription.add(
        'actual text at ($x, $y): "${actualText ?? "(out of bounds)"}"',
      );
    }
    return mismatchDescription.add('is not a TerminalState');
  }
}

/// Matcher that checks if terminal has styled text
class HasStyledText extends Matcher {
  final String text;
  final TextStyle style;

  const HasStyledText(this.text, this.style);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is TerminalState) {
      final styledTexts = item.getStyledText();
      for (final styled in styledTexts) {
        if (styled.text.contains(text) && _styleMatches(styled.style, style)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _styleMatches(TextStyle actual, TextStyle expected) {
    if (expected.color != null && actual.color != expected.color) {
      return false;
    }
    if (expected.backgroundColor != null &&
        actual.backgroundColor != expected.backgroundColor) {
      return false;
    }
    if (expected.fontWeight == FontWeight.bold &&
        actual.fontWeight != FontWeight.bold) {
      return false;
    }
    if (expected.fontStyle == FontStyle.italic &&
        actual.fontStyle != FontStyle.italic) {
      return false;
    }
    if (expected.decoration?.hasUnderline == true &&
        actual.decoration?.hasUnderline != true) {
      return false;
    }
    if (expected.fontWeight == FontWeight.dim &&
        actual.fontWeight != FontWeight.dim) {
      return false;
    }
    if (expected.reverse && !actual.reverse) return false;
    return true;
  }

  @override
  Description describe(Description description) {
    return description.add('has styled text "$text" with style $style');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is TerminalState) {
      final styledTexts = item.getStyledText();
      if (styledTexts.isEmpty) {
        return mismatchDescription.add('no styled text found');
      }
      return mismatchDescription
          .add('styled texts found: ')
          .addAll('', ', ', '', styledTexts.map((s) => '"${s.text}"'));
    }
    return mismatchDescription.add('is not a TerminalState');
  }
}

/// Matcher that compares terminal state to a snapshot
class MatchesSnapshot extends Matcher {
  final String snapshot;

  const MatchesSnapshot(this.snapshot);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is TerminalState) {
      final actual = item.toSnapshot();
      matchState['actual'] = actual;
      return actual == snapshot;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('matches snapshot');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is TerminalState) {
      final actual = matchState['actual'] ?? item.toSnapshot();
      return mismatchDescription
          .add('snapshot mismatch:\nExpected:\n')
          .add(snapshot)
          .add('\n\nActual:\n')
          .add(actual);
    }
    return mismatchDescription.add('is not a TerminalState');
  }
}

/// Matcher that checks if terminal is empty (all spaces)
class IsEmpty extends Matcher {
  const IsEmpty();

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is TerminalState) {
      final text = item.getText();
      return text.trim().isEmpty;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is empty');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is TerminalState) {
      return mismatchDescription
          .add('terminal contains:\n')
          .add(item.renderToString());
    }
    return mismatchDescription.add('is not a TerminalState');
  }
}

// Convenience functions for creating matchers

/// Matches if terminal contains the specified text
Matcher containsText(String text) => ContainsText(text);

/// Matches if terminal has text at the specified position
Matcher hasTextAt(int x, int y, String text) => HasTextAt(x, y, text);

/// Matches if terminal has styled text
Matcher hasStyledText(String text, TextStyle style) =>
    HasStyledText(text, style);

/// Matches if terminal state matches snapshot
Matcher matchesSnapshot(String snapshot) => MatchesSnapshot(snapshot);

/// Matches if terminal is empty
const Matcher isEmpty = IsEmpty();

/// Matches if terminal is not empty
Matcher get isNotEmpty => isNot(isEmpty);
