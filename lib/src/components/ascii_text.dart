import 'package:nocterm/nocterm.dart' hide TextAlign;

import 'render_ascii_text.dart';
import 'render_text.dart' show TextAlign;

// Re-export for convenience
export 'ascii_font.dart' show AsciiFont, AsciiGlyph;
export 'render_ascii_text.dart' show AsciiLayoutConfig, AsciiLayoutResult;

/// A component that displays text as ASCII art using customizable fonts.
///
/// Similar to [Text], but renders the text in a large ASCII art format.
/// Multiple built-in fonts are available, and custom fonts can be created
/// by extending [AsciiFont].
///
/// Example usage:
/// ```dart
/// AsciiText('HELLO')
///
/// AsciiText(
///   'WORLD',
///   font: AsciiFont.banner,
///   style: TextStyle(color: Colors.cyan),
/// )
///
/// AsciiText(
///   'Welcome',
///   font: AsciiFont.block,
///   textAlign: TextAlign.center,
/// )
/// ```
///
/// ## Available Fonts
///
/// - [AsciiFont.standard] - Default block-style font (5 lines high)
/// - [AsciiFont.banner] - Large banner font (7 lines high)
/// - [AsciiFont.block] - Bold block font (6 lines high)
/// - [AsciiFont.slim] - Minimalist thin font (5 lines high)
///
/// ## Creating Custom Fonts
///
/// To create a custom font, extend [AsciiFont] and provide glyph definitions:
///
/// ```dart
/// class MyFont extends AsciiFont {
///   const MyFont();
///
///   @override
///   int get height => 4;
///
///   @override
///   Map<String, AsciiGlyph> get glyphs => {
///     'A': AsciiGlyph([' /\\ ', '/__\\', '|  |', '|  |']),
///     // ... more characters
///   };
/// }
/// ```
class AsciiText extends SingleChildRenderObjectComponent {
  /// Creates an ASCII art text component.
  ///
  /// The [data] argument must not be null.
  ///
  /// The [font] defaults to [AsciiFont.standard].
  ///
  /// The [textAlign] defaults to [TextAlign.left].
  const AsciiText(
    this.data, {
    super.key,
    this.style,
    this.font = AsciiFont.standard,
    this.textAlign = TextAlign.left,
  });

  /// The text to display as ASCII art.
  final String data;

  /// The style to use when painting the text.
  ///
  /// This affects the color, weight, and other text decorations.
  final TextStyle? style;

  /// The ASCII font to use for rendering.
  ///
  /// Defaults to [AsciiFont.standard]. See [AsciiFont] for available fonts.
  final AsciiFont font;

  /// How the text should be aligned horizontally.
  ///
  /// Defaults to [TextAlign.left].
  final TextAlign textAlign;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderAsciiText(
      text: data,
      style: style,
      font: font,
      textAlign: textAlign,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderAsciiText renderObject) {
    renderObject
      ..text = data
      ..style = style
      ..font = font
      ..textAlign = textAlign;
  }
}

/// A pre-styled variant of [AsciiText] with gradient coloring support.
///
/// This is a convenience component that applies a style transformation
/// to create visually striking ASCII text effects.
///
/// Note: This component renders each line with the given style.
/// For true gradient effects, consider using multiple overlapping
/// AsciiText components or custom rendering.
class StyledAsciiText extends StatelessComponent {
  const StyledAsciiText(
    this.data, {
    super.key,
    this.font = AsciiFont.standard,
    this.textAlign = TextAlign.left,
    this.style,
  });

  final String data;
  final AsciiFont font;
  final TextAlign textAlign;
  final TextStyle? style;

  @override
  Component build(BuildContext context) {
    return AsciiText(data, font: font, textAlign: textAlign, style: style);
  }
}
