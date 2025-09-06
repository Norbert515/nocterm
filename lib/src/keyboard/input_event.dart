import 'keyboard_event.dart';
import 'mouse_event.dart';

/// Base class for all input events (keyboard and mouse)
abstract class InputEvent {
  const InputEvent();
}

/// Keyboard input event
class KeyboardInputEvent extends InputEvent {
  final KeyboardEvent event;
  
  const KeyboardInputEvent(this.event);
}

/// Mouse input event  
class MouseInputEvent extends InputEvent {
  final MouseEvent event;
  
  const MouseInputEvent(this.event);
}