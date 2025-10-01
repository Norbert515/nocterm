import 'package:characters/characters.dart';

/// Utility class for handling Unicode character display width in terminals
///
/// This implementation handles the display width of Unicode characters,
/// including emojis and other multi-column characters.
class UnicodeWidth {
  /// Calculate the display width of a string in terminal columns
  static int stringWidth(String text) {
    if (text.isEmpty) return 0;

    // Use grapheme clusters for accurate width calculation
    int totalWidth = 0;
    for (final grapheme in text.characters) {
      totalWidth += graphemeWidth(grapheme);
    }

    return totalWidth;
  }

  /// Calculate the display width of a single grapheme cluster
  static int graphemeWidth(String grapheme) {
    if (grapheme.isEmpty) return 0;

    // Handle ZWJ sequences (emoji families, professions, etc.)
    if (grapheme.contains('\u200D')) {
      // ZWJ emoji sequences are typically 2 columns wide
      if (_containsEmoji(grapheme)) {
        return 2;
      }
    }

    // For single-rune graphemes, use existing logic
    final runes = grapheme.runes.toList();
    if (runes.length == 1) {
      return runeWidth(runes[0]);
    }

    // For multi-rune graphemes, calculate the base character width
    // and ignore combining marks
    int width = 0;
    bool foundBase = false;

    for (final rune in runes) {
      final runeW = runeWidth(rune);

      // Skip zero-width characters (combining marks, etc.)
      if (runeW == 0) continue;

      // Use the width of the first non-zero-width character as the base
      if (!foundBase && runeW > 0) {
        width = runeW;
        foundBase = true;
      }
    }

    return width;
  }

  /// Check if a string contains emoji characters
  static bool _containsEmoji(String text) {
    for (final rune in text.runes) {
      if (_isEmoji(rune)) return true;
    }
    return false;
  }
  
  /// Calculate the display width of a single rune/codepoint
  static int runeWidth(int rune) {
    // Tab character has special handling - it takes up 1 column minimum
    if (rune == 0x09) {
      return 1;
    }
    
    // Control characters (0x00-0x1F, 0x7F-0x9F) except tab
    if ((rune >= 0x00 && rune <= 0x1F) || (rune >= 0x7F && rune <= 0x9F)) {
      return 0;
    }
    
    // Combining marks (0x0300-0x036F, and others)
    if ((rune >= 0x0300 && rune <= 0x036F) ||
        (rune >= 0x1AB0 && rune <= 0x1AFF) ||
        (rune >= 0x1DC0 && rune <= 0x1DFF) ||
        (rune >= 0x20D0 && rune <= 0x20FF) ||
        (rune >= 0xFE20 && rune <= 0xFE2F)) {
      return 0;
    }
    
    // Zero-width joiner and non-joiner
    if (rune == 0x200D || rune == 0x200C) {
      return 0;
    }
    
    // Variation selectors
    if ((rune >= 0xFE00 && rune <= 0xFE0F) || 
        (rune >= 0xE0100 && rune <= 0xE01EF)) {
      return 0;
    }
    
    // Wide characters - CJK ideographs, Hiragana, Katakana
    if (_isWideCharacter(rune)) {
      return 2;
    }
    
    // Emoji detection
    if (_isEmoji(rune)) {
      return 2;
    }
    
    // Default to 1 column width for regular characters
    return 1;
  }
  
  /// Check if a rune represents a wide character (CJK, etc.)
  static bool _isWideCharacter(int rune) {
    // CJK Unified Ideographs
    if ((rune >= 0x4E00 && rune <= 0x9FFF) ||
        (rune >= 0x3400 && rune <= 0x4DBF) ||
        (rune >= 0x20000 && rune <= 0x2A6DF) ||
        (rune >= 0x2A700 && rune <= 0x2B73F) ||
        (rune >= 0x2B740 && rune <= 0x2B81F) ||
        (rune >= 0x2B820 && rune <= 0x2CEAF)) {
      return true;
    }
    
    // Hiragana and Katakana
    if ((rune >= 0x3040 && rune <= 0x309F) ||
        (rune >= 0x30A0 && rune <= 0x30FF)) {
      return true;
    }
    
    // Full-width Latin characters
    if (rune >= 0xFF01 && rune <= 0xFF60) {
      return true;
    }
    
    // Hangul
    if ((rune >= 0xAC00 && rune <= 0xD7AF) ||
        (rune >= 0x1100 && rune <= 0x11FF) ||
        (rune >= 0x3130 && rune <= 0x318F) ||
        (rune >= 0xA960 && rune <= 0xA97F) ||
        (rune >= 0xD7B0 && rune <= 0xD7FF)) {
      return true;
    }
    
    return false;
  }
  
  /// Check if a rune represents an emoji
  static bool _isEmoji(int rune) {
    // Basic emoji blocks
    if ((rune >= 0x1F300 && rune <= 0x1F5FF) || // Misc Symbols and Pictographs
        (rune >= 0x1F600 && rune <= 0x1F64F) || // Emoticons
        (rune >= 0x1F680 && rune <= 0x1F6FF) || // Transport and Map Symbols
        (rune >= 0x1F900 && rune <= 0x1F9FF) || // Supplemental Symbols and Pictographs
        (rune >= 0x1FA70 && rune <= 0x1FAFF)) { // Symbols and Pictographs Extended-A
      return true;
    }
    
    // Miscellaneous Symbols
    if (rune >= 0x2600 && rune <= 0x26FF) {
      return true;
    }
    
    // Dingbats with emoji presentation
    if (rune >= 0x2700 && rune <= 0x27BF) {
      return true;
    }
    
    // Regional indicator symbols (flags)
    if (rune >= 0x1F1E6 && rune <= 0x1F1FF) {
      return true;
    }
    
    // Some specific emojis in other ranges
    if (rune == 0x231A || rune == 0x231B || // Watch, hourglass
        rune == 0x23E9 || rune == 0x23EA || // Fast forward, rewind
        rune == 0x23EB || rune == 0x23EC || // Up/down arrows
        rune == 0x23F0 || rune == 0x23F3 || // Alarm clock, hourglass flowing
        (rune >= 0x25FB && rune <= 0x25FE) || // Squares
        (rune >= 0x2614 && rune <= 0x2615) || // Umbrella, coffee
        (rune >= 0x2648 && rune <= 0x2653) || // Zodiac signs
        rune == 0x267F || // Wheelchair
        rune == 0x2693 || // Anchor
        rune == 0x26A1 || // High voltage
        (rune >= 0x26AA && rune <= 0x26AB) || // White/black circles
        (rune >= 0x26BD && rune <= 0x26BE) || // Soccer, baseball
        (rune >= 0x26C4 && rune <= 0x26C5) || // Snowman
        rune == 0x26CE || // Ophiuchus
        rune == 0x26D4 || // No entry
        rune == 0x26EA || // Church
        (rune >= 0x26F2 && rune <= 0x26F3) || // Fountain, flag
        rune == 0x26F5 || // Sailboat
        rune == 0x26FA || // Tent
        rune == 0x26FD || // Fuel pump
        rune == 0x2705 || // Check mark
        (rune >= 0x270A && rune <= 0x270B) || // Raised fist/hand
        rune == 0x2728 || // Sparkles
        rune == 0x274C || // Cross mark
        rune == 0x274E || // Cross mark negative
        (rune >= 0x2753 && rune <= 0x2755) || // Question marks
        rune == 0x2757 || // Exclamation
        (rune >= 0x2795 && rune <= 0x2797) || // Plus/minus/divide
        rune == 0x27B0 || // Curly loop
        rune == 0x27BF || // Double curly loop
        (rune >= 0x2B1B && rune <= 0x2B1C) || // Black/white squares
        rune == 0x2B50 || // Star
        rune == 0x2B55) { // Heavy circle
      return true;
    }
    
    return false;
  }
  
  /// Split a string into grapheme clusters with their positions and widths
  static List<GraphemeInfo> analyzeString(String text) {
    final result = <GraphemeInfo>[];
    final runes = text.runes.toList();
    int columnPosition = 0;
    
    for (int i = 0; i < runes.length; i++) {
      final rune = runes[i];
      final width = runeWidth(rune);
      
      // Skip zero-width characters for positioning
      if (width > 0) {
        result.add(GraphemeInfo(
          character: String.fromCharCode(rune),
          runeIndex: i,
          columnPosition: columnPosition,
          displayWidth: width,
        ));
        columnPosition += width;
      }
    }
    
    return result;
  }
}

/// Information about a grapheme cluster in a string
class GraphemeInfo {
  final String character;
  final int runeIndex;
  final int columnPosition;
  final int displayWidth;
  
  const GraphemeInfo({
    required this.character,
    required this.runeIndex,
    required this.columnPosition,
    required this.displayWidth,
  });
}