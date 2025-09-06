/// Mouse button types
enum MouseButton {
  left,
  middle,
  right,
  wheelUp,
  wheelDown,
}

/// Mouse event for terminal interactions
class MouseEvent {
  final MouseButton button;
  final int x; // Column position (0-based)
  final int y; // Row position (0-based)
  final bool pressed; // true for press, false for release
  
  const MouseEvent({
    required this.button,
    required this.x,
    required this.y,
    required this.pressed,
  });
  
  @override
  String toString() => 'MouseEvent($button at $x,$y pressed=$pressed)';
}