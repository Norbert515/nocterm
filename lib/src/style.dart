/// Color constants which align with terminal colors.
///
/// This follows Flutter's pattern of having a separate Colors class
/// to avoid conflicts with Color instance members.
abstract class Colors {
  // Prevent instantiation
  Colors._();

  /// Completely opaque black.
  static const Color black = Color.fromRGB(0, 0, 0);

  /// Completely opaque red.
  static const Color red = Color.fromRGB(255, 0, 0);

  /// Completely opaque green.
  static const Color green = Color.fromRGB(0, 255, 0);

  /// Completely opaque yellow.
  static const Color yellow = Color.fromRGB(255, 255, 0);

  /// Completely opaque blue.
  static const Color blue = Color.fromRGB(0, 0, 255);

  /// Completely opaque magenta.
  static const Color magenta = Color.fromRGB(255, 0, 255);

  /// Completely opaque cyan.
  static const Color cyan = Color.fromRGB(0, 255, 255);

  /// Completely opaque white.
  static const Color white = Color.fromRGB(255, 255, 255);

  /// Completely opaque grey.
  static const Color grey = Color.fromRGB(128, 128, 128);

  /// Completely opaque gray (American spelling).
  static const Color gray = grey;

  // Bright/bold terminal colors

  /// Bright black (dark grey).
  static const Color brightBlack = Color.fromRGB(85, 85, 85);

  /// Bright red.
  static const Color brightRed = Color.fromRGB(255, 85, 85);

  /// Bright green.
  static const Color brightGreen = Color.fromRGB(85, 255, 85);

  /// Bright yellow.
  static const Color brightYellow = Color.fromRGB(255, 255, 85);

  /// Bright blue.
  static const Color brightBlue = Color.fromRGB(85, 85, 255);

  /// Bright magenta.
  static const Color brightMagenta = Color.fromRGB(255, 85, 255);

  /// Bright cyan.
  static const Color brightCyan = Color.fromRGB(85, 255, 255);

  /// Bright white.
  static const Color brightWhite = Color.fromRGB(255, 255, 255);
}

/// An immutable 32 bit color value in ARGB format.
///
/// This is a simplified version of Flutter's Color class for terminal use.
/// We only use RGB values since terminals don't support true alpha blending.
class Color {
  /// The red component of this color, 0 to 255.
  final int red;

  /// The green component of this color, 0 to 255.
  final int green;

  /// The blue component of this color, 0 to 255.
  final int blue;

  /// Creates a color from an integer value.
  ///
  /// The value should be in 0xRRGGBB format where:
  /// - RR is the red component (0-255)
  /// - GG is the green component (0-255)
  /// - BB is the blue component (0-255)
  const Color(int value)
      : red = (value >> 16) & 0xFF,
        green = (value >> 8) & 0xFF,
        blue = value & 0xFF;

  /// Creates a color from red, green, and blue components.
  ///
  /// The values must be between 0 and 255 inclusive.
  const Color.fromRGB(this.red, this.green, this.blue)
      : assert(red >= 0 && red <= 255),
        assert(green >= 0 && green <= 255),
        assert(blue >= 0 && blue <= 255);

  /// Converts this color to an ANSI escape code.
  ///
  /// If [background] is true, returns a background color code.
  /// Otherwise returns a foreground color code.
  String toAnsi({bool background = false}) {
    if (background) {
      return '\x1b[48;2;$red;$green;${blue}m';
    }
    return '\x1b[38;2;$red;$green;${blue}m';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is Color && other.red == red && other.green == green && other.blue == blue;
  }

  @override
  int get hashCode => Object.hash(red, green, blue);

  @override
  String toString() => 'Color(r: $red, g: $green, b: $blue)';
}

/// The thickness of the glyphs used to draw the text.
///
/// Simplified version of Flutter's FontWeight for terminal use.
enum FontWeight {
  /// Normal font weight (W400).
  normal,

  /// Bold font weight (W700).
  bold,

  /// Dim/light font weight (W300).
  dim,
}

/// Whether to use italics.
enum FontStyle {
  /// Use upright glyphs.
  normal,

  /// Use italic glyphs.
  italic,
}

/// A linear decoration to draw near the text.
class TextDecoration {
  const TextDecoration._(this._mask);

  final int _mask;

  /// No decoration.
  static const TextDecoration none = TextDecoration._(0x0);

  /// Draw a line underneath the text.
  static const TextDecoration underline = TextDecoration._(0x1);

  /// Draw a line through the text (strikethrough).
  static const TextDecoration lineThrough = TextDecoration._(0x2);

  /// Draw a line above the text (overline).
  static const TextDecoration overline = TextDecoration._(0x4);

  /// Combines multiple decorations.
  factory TextDecoration.combine(List<TextDecoration> decorations) {
    int mask = 0;
    for (final decoration in decorations) {
      mask |= decoration._mask;
    }
    return TextDecoration._(mask);
  }

  /// Whether this decoration contains underline.
  bool get contains => _mask != 0;

  /// Whether this decoration contains underline.
  bool get hasUnderline => (_mask & underline._mask) != 0;

  /// Whether this decoration contains line through.
  bool get hasLineThrough => (_mask & lineThrough._mask) != 0;

  /// Whether this decoration contains overline.
  bool get hasOverline => (_mask & overline._mask) != 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is TextDecoration && other._mask == _mask;
  }

  @override
  int get hashCode => _mask.hashCode;
}

/// An immutable style describing how to format and paint text.
///
/// This is a simplified version of Flutter's TextStyle for terminal use.
/// It follows Flutter's naming conventions to make it familiar for Flutter developers.
class TextStyle {
  /// The color to use when painting the text.
  ///
  /// In Flutter terminology, this is the foreground color.
  final Color? color;

  /// The color to use as the background for the text.
  final Color? backgroundColor;

  /// The typeface thickness to use when painting the text.
  final FontWeight? fontWeight;

  /// The typeface variant to use when drawing the letters.
  final FontStyle? fontStyle;

  /// The decorations to paint near the text (e.g., underline).
  final TextDecoration? decoration;

  /// Whether to reverse the foreground and background colors.
  ///
  /// This is a terminal-specific feature not present in Flutter's TextStyle.
  final bool reverse;

  /// Creates a text style.
  const TextStyle({
    this.color,
    this.backgroundColor,
    this.fontWeight,
    this.fontStyle,
    this.decoration,
    this.reverse = false,
  });

  /// Creates a copy of this text style but with the given fields replaced.
  TextStyle copyWith({
    Color? color,
    Color? backgroundColor,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    bool? reverse,
  }) {
    return TextStyle(
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      decoration: decoration ?? this.decoration,
      reverse: reverse ?? this.reverse,
    );
  }

  /// Merge this style with another, with the other style taking precedence.
  TextStyle merge(TextStyle? other) {
    if (other == null) return this;
    return copyWith(
      color: other.color,
      backgroundColor: other.backgroundColor,
      fontWeight: other.fontWeight,
      fontStyle: other.fontStyle,
      decoration: other.decoration,
      reverse: other.reverse,
    );
  }

  /// Converts this text style to ANSI escape codes.
  String toAnsi() {
    final codes = <String>[];

    if (color != null) {
      codes.add(color!.toAnsi());
    }
    if (backgroundColor != null) {
      codes.add(backgroundColor!.toAnsi(background: true));
    }

    // Handle font weight
    if (fontWeight == FontWeight.bold) {
      codes.add('\x1b[1m');
    } else if (fontWeight == FontWeight.dim) {
      codes.add('\x1b[2m');
    }

    // Handle font style
    if (fontStyle == FontStyle.italic) {
      codes.add('\x1b[3m');
    }

    // Handle decorations
    if (decoration != null) {
      if (decoration!.hasUnderline) {
        codes.add('\x1b[4m');
      }
      if (decoration!.hasLineThrough) {
        codes.add('\x1b[9m');
      }
      if (decoration!.hasOverline) {
        codes.add('\x1b[53m');
      }
    }

    if (reverse) {
      codes.add('\x1b[7m');
    }

    return codes.join();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is TextStyle &&
        other.color == color &&
        other.backgroundColor == backgroundColor &&
        other.fontWeight == fontWeight &&
        other.fontStyle == fontStyle &&
        other.decoration == decoration &&
        other.reverse == reverse;
  }

  @override
  int get hashCode => Object.hash(
        color,
        backgroundColor,
        fontWeight,
        fontStyle,
        decoration,
        reverse,
      );

  @override
  String toString() => 'TextStyle('
      '${color != null ? 'color: $color, ' : ''}'
      '${backgroundColor != null ? 'backgroundColor: $backgroundColor, ' : ''}'
      '${fontWeight != null ? 'fontWeight: $fontWeight, ' : ''}'
      '${fontStyle != null ? 'fontStyle: $fontStyle, ' : ''}'
      '${decoration != null ? 'decoration: $decoration, ' : ''}'
      '${reverse ? 'reverse: true' : ''}'
      ')';

  /// ANSI reset code to clear all formatting.
  static const String reset = '\x1b[0m';
}
