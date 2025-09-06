import '../keyboard/mouse_event.dart';

/// Interface for elements that can handle scroll events
abstract class ScrollableElement {
  /// Handle a mouse wheel event
  /// Returns true if the event was handled
  bool handleMouseWheel(MouseEvent event);
}