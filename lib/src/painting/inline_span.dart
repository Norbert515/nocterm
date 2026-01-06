import 'package:nocterm/nocterm.dart';

/// Visitor pattern callback for walking [InlineSpan] trees.
typedef InlineSpanVisitor = bool Function(InlineSpan span);

/// An immutable span of inline content which forms part of a paragraph.
///
/// This is the base class for all inline span types. Unlike Flutter's version,
/// this is simplified for terminal rendering without gesture recognition or
/// complex text metrics.
abstract class InlineSpan {
  /// Creates an [InlineSpan] with the given style.
  const InlineSpan({this.style});

  /// The [TextStyle] to apply to this span.
  ///
  /// The style will be merged with the style of any parent span.
  final TextStyle? style;

  /// Returns the plain text representation of this span.
  String toPlainText({bool includePlaceholderOffsets = true}) {
    final StringBuffer buffer = StringBuffer();
    computeToPlainText(
      buffer,
      includePlaceholderOffsets: includePlaceholderOffsets,
    );
    return buffer.toString();
  }

  /// Walks this span and its descendants in pre-order and calls [visitor]
  /// for each span that has content.
  ///
  /// Returns true if the visitor function returns true for all spans, and
  /// false if the visitor function returns false for any span.
  bool visitChildren(InlineSpanVisitor visitor);

  /// Adds the plain text representation of this span to the given buffer.
  void computeToPlainText(
    StringBuffer buffer, {
    bool includePlaceholderOffsets = true,
  });

  /// Converts this span to a list of styled text segments for rendering.
  ///
  /// Each segment contains a piece of text and its associated style.
  /// The parent style is merged with the span's style.
  List<StyledTextSegment> toStyledSegments([TextStyle? parentStyle]);

  /// Merges two text styles, with child properties overriding parent properties.
  TextStyle? mergeStyle(TextStyle? parent, TextStyle? child) {
    if (parent == null) return child;
    if (child == null) return parent;

    return TextStyle(
      color: child.color ?? parent.color,
      backgroundColor: child.backgroundColor ?? parent.backgroundColor,
      fontWeight: child.fontWeight ?? parent.fontWeight,
      fontStyle: child.fontStyle ?? parent.fontStyle,
      decoration: child.decoration ?? parent.decoration,
      reverse: child.reverse || parent.reverse,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is InlineSpan && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}

/// A styled segment of text ready for rendering.
///
/// This is a simple data class that pairs a string with its style.
class StyledTextSegment {
  const StyledTextSegment(this.text, this.style);

  final String text;
  final TextStyle? style;

  @override
  String toString() => 'StyledTextSegment("$text", $style)';
}
