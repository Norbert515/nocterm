import '../framework/framework.dart';
import '../keyboard/mouse_event.dart';
import '../gestures/events.dart';
import '../gestures/hit_test.dart';
import '../gestures/tap.dart';
import '../gestures/long_press.dart';
import '../rendering/mouse_tracker.dart';
import 'package:nocterm/src/rendering/mouse_region.dart';

/// A widget that detects gestures.
///
/// Attempts to recognize gestures that correspond to its non-null callbacks.
///
/// If this widget has a child, it defers to that child for sizing behavior.
/// If it does not have a child, it grows to fit the parent instead.
///
/// By default, [GestureDetector] uses [HitTestBehavior.deferToChild] for
/// determining hit test behavior.
///
/// Example:
/// ```dart
/// GestureDetector(
///   onTap: () => print('Tapped!'),
///   onDoubleTap: () => print('Double tapped!'),
///   onLongPress: () => print('Long pressed!'),
///   child: Container(
///     width: 20,
///     height: 5,
///     child: Text('Click me'),
///   ),
/// )
/// ```
class GestureDetector extends StatefulComponent {
  const GestureDetector({
    super.key,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onDoubleTap,
    this.onLongPress,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.behavior = HitTestBehavior.deferToChild,
    this.child,
  });

  /// Called when a tap occurs.
  final GestureTapCallback? onTap;

  /// Called when a tap down has been detected.
  final GestureTapDownCallback? onTapDown;

  /// Called when a tap up has been detected.
  final GestureTapUpCallback? onTapUp;

  /// Called when a tap has been cancelled.
  final GestureTapCancelCallback? onTapCancel;

  /// Called when a double tap occurs.
  final GestureTapCallback? onDoubleTap;

  /// Called when a long press is detected.
  final GestureLongPressCallback? onLongPress;

  /// Called when a long press starts.
  final GestureLongPressStartCallback? onLongPressStart;

  /// Called when a long press ends.
  final GestureLongPressEndCallback? onLongPressEnd;

  /// How to behave during hit testing.
  final HitTestBehavior behavior;

  /// The child widget.
  final Component? child;

  @override
  State<GestureDetector> createState() => _GestureDetectorState();
}

class _GestureDetectorState extends State<GestureDetector> {
  TapGestureRecognizer? _tapRecognizer;
  DoubleTapGestureRecognizer? _doubleTapRecognizer;
  LongPressGestureRecognizer? _longPressRecognizer;

  @override
  void initState() {
    super.initState();
    _syncRecognizers();
  }

  @override
  void didUpdateComponent(GestureDetector oldComponent) {
    super.didUpdateComponent(oldComponent);
    _syncRecognizers();
  }

  @override
  void dispose() {
    _tapRecognizer?.dispose();
    _doubleTapRecognizer?.dispose();
    _longPressRecognizer?.dispose();
    super.dispose();
  }

  void _syncRecognizers() {
    // Tap recognizer
    if (component.onTap != null ||
        component.onTapDown != null ||
        component.onTapUp != null ||
        component.onTapCancel != null) {
      _tapRecognizer ??= TapGestureRecognizer();
      _tapRecognizer!
        ..onTap = component.onTap
        ..onTapDown = component.onTapDown
        ..onTapUp = component.onTapUp
        ..onTapCancel = component.onTapCancel;
    } else {
      _tapRecognizer?.dispose();
      _tapRecognizer = null;
    }

    // Double tap recognizer
    if (component.onDoubleTap != null) {
      _doubleTapRecognizer ??= DoubleTapGestureRecognizer();
      _doubleTapRecognizer!.onDoubleTap = component.onDoubleTap;
    } else {
      _doubleTapRecognizer?.dispose();
      _doubleTapRecognizer = null;
    }

    // Long press recognizer
    if (component.onLongPress != null ||
        component.onLongPressStart != null ||
        component.onLongPressEnd != null) {
      _longPressRecognizer ??= LongPressGestureRecognizer();
      _longPressRecognizer!
        ..onLongPress = component.onLongPress
        ..onLongPressStart = component.onLongPressStart
        ..onLongPressEnd = component.onLongPressEnd;
    } else {
      _longPressRecognizer?.dispose();
      _longPressRecognizer = null;
    }
  }

  void _handlePointerDown(MouseEvent event) {
    // Convert global position to local
    final localPosition = Offset(event.x.toDouble(), event.y.toDouble());

    // Add pointer to recognizers
    _tapRecognizer?.addPointer(event, localPosition);
    _doubleTapRecognizer?.addPointer(event, localPosition);
    _longPressRecognizer?.addPointer(event, localPosition);
  }

  void _handlePointerUp(MouseEvent event) {
    final localPosition = Offset(event.x.toDouble(), event.y.toDouble());

    // Notify recognizers
    _tapRecognizer?.handlePointerUp(event, localPosition);
    _doubleTapRecognizer?.handlePointerUp(event, localPosition);
    _longPressRecognizer?.handlePointerUp(event, localPosition);
  }

  void _handlePointerMove(MouseEvent event) {
    final localPosition = Offset(event.x.toDouble(), event.y.toDouble());

    // Notify recognizers
    _tapRecognizer?.handlePointerMove(event, localPosition);
    _doubleTapRecognizer?.handlePointerMove(event, localPosition);
    _longPressRecognizer?.handlePointerMove(event, localPosition);
  }

  @override
  Component build(BuildContext context) {
    // Use MouseRegion to capture mouse events
    return _GestureDetectorMouseRegion(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerMove: _handlePointerMove,
      behavior: component.behavior,
      child: component.child,
    );
  }
}

/// Internal widget that wraps the child and handles mouse events.
class _GestureDetectorMouseRegion extends SingleChildRenderObjectComponent {
  const _GestureDetectorMouseRegion({
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onPointerMove,
    required this.behavior,
    super.child,
  });

  final void Function(MouseEvent) onPointerDown;
  final void Function(MouseEvent) onPointerUp;
  final void Function(MouseEvent) onPointerMove;
  final HitTestBehavior behavior;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderGestureDetector(
      onPointerDown: onPointerDown,
      onPointerUp: onPointerUp,
      onPointerMove: onPointerMove,
      behavior: behavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderGestureDetector renderObject,
  ) {
    renderObject
      ..onPointerDown = onPointerDown
      ..onPointerUp = onPointerUp
      ..onPointerMove = onPointerMove
      ..behavior = behavior;
  }
}

/// Render object for GestureDetector that tracks mouse events.
class _RenderGestureDetector extends RenderMouseRegion {
  _RenderGestureDetector({
    required void Function(MouseEvent) onPointerDown,
    required void Function(MouseEvent) onPointerUp,
    required void Function(MouseEvent) onPointerMove,
    required HitTestBehavior behavior,
  }) : _onPointerDown = onPointerDown,
       _onPointerUp = onPointerUp,
       _onPointerMove = onPointerMove,
       _behavior = behavior,
       super(
         onEnter: null,
         onExit: null,
         onHover: null,
         opaque: behavior == HitTestBehavior.opaque,
       );

  void Function(MouseEvent) _onPointerDown;
  void Function(MouseEvent) get onPointerDown => _onPointerDown;
  set onPointerDown(void Function(MouseEvent) value) {
    if (_onPointerDown == value) return;
    _onPointerDown = value;
    _updateGestureAnnotation();
  }

  void Function(MouseEvent) _onPointerUp;
  void Function(MouseEvent) get onPointerUp => _onPointerUp;
  set onPointerUp(void Function(MouseEvent) value) {
    if (_onPointerUp == value) return;
    _onPointerUp = value;
    _updateGestureAnnotation();
  }

  void Function(MouseEvent) _onPointerMove;
  void Function(MouseEvent) get onPointerMove => _onPointerMove;
  set onPointerMove(void Function(MouseEvent) value) {
    if (_onPointerMove == value) return;
    _onPointerMove = value;
    _updateGestureAnnotation();
  }

  HitTestBehavior _behavior;
  HitTestBehavior get behavior => _behavior;
  set behavior(HitTestBehavior value) {
    if (_behavior == value) return;
    _behavior = value;
    // Update opaque based on behavior
    opaque = value == HitTestBehavior.opaque;
  }

  // Store gesture detector annotation separately from mouse region annotation
  MouseTrackerAnnotation? _gestureAnnotation;

  // Track button press state to detect state transitions
  // This is more reliable than using isMotion flag
  bool _isLeftButtonPressed = false;

  @override
  MouseTrackerAnnotation? get annotation =>
      _gestureAnnotation ?? super.annotation;

  void _updateGestureAnnotation() {
    _gestureAnnotation = MouseTrackerAnnotation(
      onEnter: (event) {
        // When entering, sync our state with the current button state
        // but don't trigger pointer down unless button is pressed during entry
        if (event.button == MouseButton.left) {
          if (event.pressed && !_isLeftButtonPressed) {
            // Button is pressed as we enter - treat as new press
            _isLeftButtonPressed = true;
            _onPointerDown(event);
          } else if (!event.pressed) {
            // Button not pressed, ensure state is clean
            _isLeftButtonPressed = false;
          }
        }
      },
      onExit: (event) {
        // When exiting, if button was pressed inside and is now released,
        // we should complete the gesture
        if (!event.pressed &&
            _isLeftButtonPressed &&
            event.button == MouseButton.left) {
          _isLeftButtonPressed = false;
          _onPointerUp(event);
        }
        // Reset state when leaving region to prevent stuck buttons
        // This handles the case where button is still pressed when we exit
        _isLeftButtonPressed = false;
      },
      onHover: (event) {
        // Handle move events for gesture recognizers
        if (event.button != MouseButton.wheelUp &&
            event.button != MouseButton.wheelDown) {
          _onPointerMove(event);
        }

        // Detect button state transitions (pressed -> not pressed, or vice versa)
        // This works regardless of the isMotion flag
        if (event.button == MouseButton.left) {
          if (event.pressed && !_isLeftButtonPressed) {
            // Button was just pressed while hovering
            _isLeftButtonPressed = true;
            _onPointerDown(event);
          } else if (!event.pressed && _isLeftButtonPressed) {
            // Button was just released while hovering
            _isLeftButtonPressed = false;
            _onPointerUp(event);
          }
        }
      },
      renderObject: this,
    );
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _updateGestureAnnotation();
  }

  @override
  bool hitTestSelf(Offset position) {
    switch (_behavior) {
      case HitTestBehavior.deferToChild:
        return false;
      case HitTestBehavior.opaque:
      case HitTestBehavior.translucent:
        return true;
    }
  }
}
