import 'dart:async';
import '../keyboard/mouse_event.dart';
import '../framework/framework.dart';
import 'recognizer.dart';
import 'events.dart';

/// Recognizes tap gestures.
///
/// A tap is recognized when a pointer down and up occur in the same location
/// within a short time period.
class TapGestureRecognizer extends GestureRecognizer {
  TapGestureRecognizer({
    this.onTapDown,
    this.onTapUp,
    this.onTap,
    this.onTapCancel,
  });

  /// Called when a tap down has been detected.
  GestureTapDownCallback? onTapDown;

  /// Called when a tap up has been detected.
  GestureTapUpCallback? onTapUp;

  /// Called when a tap has been completed.
  GestureTapCallback? onTap;

  /// Called when a tap has been cancelled.
  GestureTapCancelCallback? onTapCancel;

  Offset? _downPosition;
  Timer? _doubleTapTimer;
  bool _sentTapDown = false;
  bool _wonArena = false;

  static const double _kTouchSlop = 2.0; // cells

  @override
  void handlePointerDown(MouseEvent event, Offset localPosition) {
    _downPosition = localPosition;
    _sentTapDown = false;
    _wonArena = false;

    if (onTapDown != null) {
      final details = TapDownDetails(
        globalPosition: Offset(event.x.toDouble(), event.y.toDouble()),
        localPosition: localPosition,
      );
      onTapDown?.call(details);
      _sentTapDown = true;
    }
  }

  @override
  void handlePointerUp(MouseEvent event, Offset localPosition) {
    if (_downPosition == null) {
      return;
    }

    // Check if the pointer moved too far
    final dx = (localPosition.dx - _downPosition!.dx).abs();
    final dy = (localPosition.dy - _downPosition!.dy).abs();

    if (dx > _kTouchSlop || dy > _kTouchSlop) {
      // Moved too far, cancel the tap
      _reset();
      return;
    }

    // Call onTapUp
    if (onTapUp != null) {
      final details = TapUpDetails(
        globalPosition: Offset(event.x.toDouble(), event.y.toDouble()),
        localPosition: localPosition,
      );
      onTapUp?.call(details);
    }

    // Auto-accept the gesture if we haven't won the arena yet
    // This allows taps to work without explicit arena management
    if (!_wonArena) {
      acceptGesture();
    } else {
      _checkTap();
    }
  }

  @override
  void handlePointerMove(MouseEvent event, Offset localPosition) {
    if (_downPosition == null) {
      return;
    }

    // Check if moved too far from initial position
    final dx = (localPosition.dx - _downPosition!.dx).abs();
    final dy = (localPosition.dy - _downPosition!.dy).abs();

    if (dx > _kTouchSlop || dy > _kTouchSlop) {
      // Moved too far, cancel
      rejectGesture();
    }
  }

  @override
  void acceptGesture() {
    _wonArena = true;
    // Check tap BEFORE calling super, which will reset state
    if (_downPosition != null) {
      _checkTap();
    }
    super.acceptGesture();
  }

  @override
  void rejectGesture() {
    super.rejectGesture();
    if (_sentTapDown && onTapCancel != null) {
      onTapCancel?.call();
    }
    _reset();
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (disposition == GestureDisposition.rejected) {
      if (_sentTapDown && onTapCancel != null) {
        onTapCancel?.call();
      }
    }
    _reset();
  }

  void _checkTap() {
    if (onTap != null && _downPosition != null) {
      onTap?.call();
    }
  }

  void _reset() {
    _downPosition = null;
    _sentTapDown = false;
    _wonArena = false;
    _doubleTapTimer?.cancel();
    _doubleTapTimer = null;
    reset();
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    super.dispose();
  }
}

/// Recognizes double tap gestures.
class DoubleTapGestureRecognizer extends GestureRecognizer {
  DoubleTapGestureRecognizer({this.onDoubleTap});

  /// Called when a double tap has been detected.
  GestureTapCallback? onDoubleTap;

  Offset? _firstTapPosition;
  Timer? _doubleTapTimer;
  int _tapCount = 0;

  static const Duration _doubleTapTimeout = Duration(milliseconds: 300);
  static const double _kDoubleTapSlop = 2.0; // cells

  @override
  void handlePointerDown(MouseEvent event, Offset localPosition) {
    if (_tapCount == 0) {
      // First tap
      _firstTapPosition = localPosition;
      _tapCount = 1;

      // Start timer for double tap window
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(_doubleTapTimeout, () {
        _reset();
      });
    } else if (_tapCount == 1) {
      // Second tap - check if it's close enough to first tap
      if (_firstTapPosition != null) {
        final dx = (localPosition.dx - _firstTapPosition!.dx).abs();
        final dy = (localPosition.dy - _firstTapPosition!.dy).abs();

        if (dx <= _kDoubleTapSlop && dy <= _kDoubleTapSlop) {
          // Valid double tap!
          _doubleTapTimer?.cancel();
          onDoubleTap?.call();
          _reset();
        } else {
          // Too far apart, start over
          _firstTapPosition = localPosition;
          _tapCount = 1;
          _doubleTapTimer?.cancel();
          _doubleTapTimer = Timer(_doubleTapTimeout, () {
            _reset();
          });
        }
      }
    }
  }

  @override
  void handlePointerUp(MouseEvent event, Offset localPosition) {
    // Nothing to do on pointer up for double tap
  }

  @override
  void handlePointerMove(MouseEvent event, Offset localPosition) {
    // Movement doesn't affect double tap
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (disposition == GestureDisposition.rejected) {
      _reset();
    }
  }

  void _reset() {
    _firstTapPosition = null;
    _tapCount = 0;
    _doubleTapTimer?.cancel();
    _doubleTapTimer = null;
    reset();
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    super.dispose();
  }
}
