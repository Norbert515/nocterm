import 'logical_key.dart';

/// Represents the state of modifier keys during a keyboard event.
class ModifierKeys {
  const ModifierKeys({
    this.ctrl = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
  });

  /// Whether any Ctrl key is pressed.
  final bool ctrl;

  /// Whether any Shift key is pressed.
  final bool shift;

  /// Whether any Alt/Option key is pressed.
  final bool alt;

  /// Whether any Meta/Command/Windows key is pressed.
  final bool meta;

  /// Returns true if any modifier key is pressed.
  bool get hasAnyModifier => ctrl || shift || alt || meta;

  /// Creates a copy with specified fields overridden.
  ModifierKeys copyWith({bool? ctrl, bool? shift, bool? alt, bool? meta}) {
    return ModifierKeys(
      ctrl: ctrl ?? this.ctrl,
      shift: shift ?? this.shift,
      alt: alt ?? this.alt,
      meta: meta ?? this.meta,
    );
  }

  @override
  String toString() {
    final modifiers = <String>[];
    if (ctrl) modifiers.add('Ctrl');
    if (shift) modifiers.add('Shift');
    if (alt) modifiers.add('Alt');
    if (meta) modifiers.add('Meta');
    return modifiers.isEmpty ? 'none' : modifiers.join('+');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModifierKeys &&
          ctrl == other.ctrl &&
          shift == other.shift &&
          alt == other.alt &&
          meta == other.meta;

  @override
  int get hashCode => Object.hash(ctrl, shift, alt, meta);
}

/// Represents a keyboard event.
class KeyboardEvent {
  const KeyboardEvent({
    required this.logicalKey,
    this.character,
    this.modifiers = const ModifierKeys(),
  });

  /// The logical key that was pressed.
  final LogicalKey logicalKey;

  /// The character representation of the key, if applicable.
  /// This will be null for non-character keys like arrows or function keys.
  final String? character;

  /// The state of modifier keys during this event.
  final ModifierKeys modifiers;

  /// Convenience getters for modifier states.
  bool get isControlPressed => modifiers.ctrl;
  bool get isShiftPressed => modifiers.shift;
  bool get isAltPressed => modifiers.alt;
  bool get isMetaPressed => modifiers.meta;

  /// Check if this event matches a specific key with optional modifiers.
  bool matches(
    LogicalKey key, {
    bool? ctrl,
    bool? shift,
    bool? alt,
    bool? meta,
  }) {
    if (logicalKey != key) return false;
    if (ctrl != null && modifiers.ctrl != ctrl) return false;
    if (shift != null && modifiers.shift != shift) return false;
    if (alt != null && modifiers.alt != alt) return false;
    if (meta != null && modifiers.meta != meta) return false;
    return true;
  }

  @override
  String toString() {
    final parts = <String>[];
    if (modifiers.hasAnyModifier) {
      parts.add('modifiers: $modifiers');
    }
    parts.add('key: $logicalKey');
    if (character != null) {
      parts.add('character: "$character"');
    }
    return 'KeyboardEvent(${parts.join(', ')})';
  }
}
