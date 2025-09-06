import '../keyboard/mouse_event.dart';

/// Mixin for RenderObjects that can handle scroll events
mixin ScrollableRenderObjectMixin {
  /// Handle a mouse wheel event
  /// Returns true if the event was handled
  bool handleMouseWheel(MouseEvent event);
}