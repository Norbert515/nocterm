import 'package:nocterm/nocterm.dart';
import 'inline_span.dart';

/// An immutable span of text with optional children.
///
/// A [TextSpan] object can be styled using its [style] property. The style will
/// be applied to the [text] and the [children].
///
/// A [TextSpan] object can just have plain text, or it can have children
/// [TextSpan] objects with their own styles that (possibly only partially)
/// override the [style] of this object. If a [TextSpan] has both [text] and
/// [children], then the [text] is treated as if it was an un-styled [TextSpan]
/// at the start of the [children] list.
class TextSpan extends InlineSpan {
  /// Creates a [TextSpan] with the given values.
  ///
  /// For the object to be useful, at least one of [text] or
  /// [children] should be set.
  const TextSpan({this.text, this.children, super.style});

  /// The text contained in this span.
  ///
  /// If both [text] and [children] are non-null, the text will precede the
  /// children.
  final String? text;

  /// Additional spans to include as children.
  ///
  /// If both [text] and [children] are non-null, the text will precede the
  /// children.
  ///
  /// The list must not contain any nulls.
  final List<InlineSpan>? children;

  @override
  bool visitChildren(InlineSpanVisitor visitor) {
    if (text != null) {
      if (!visitor(this)) {
        return false;
      }
    }
    if (children != null) {
      for (final InlineSpan child in children!) {
        if (!child.visitChildren(visitor)) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  void computeToPlainText(
    StringBuffer buffer, {
    bool includePlaceholderOffsets = true,
  }) {
    if (text != null) {
      buffer.write(text);
    }
    if (children != null) {
      for (final InlineSpan child in children!) {
        child.computeToPlainText(
          buffer,
          includePlaceholderOffsets: includePlaceholderOffsets,
        );
      }
    }
  }

  @override
  List<StyledTextSegment> toStyledSegments([TextStyle? parentStyle]) {
    final List<StyledTextSegment> segments = [];
    final TextStyle? mergedStyle = mergeStyle(parentStyle, style);

    if (text != null && text!.isNotEmpty) {
      segments.add(StyledTextSegment(text!, mergedStyle));
    }

    if (children != null) {
      for (final InlineSpan child in children!) {
        segments.addAll(child.toStyledSegments(mergedStyle));
      }
    }

    return segments;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    if (!(super == other)) return false;
    return other is TextSpan &&
        other.text == text &&
        _listEquals(other.children, children);
  }

  @override
  int get hashCode => Object.hash(super.hashCode, text, children);

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
