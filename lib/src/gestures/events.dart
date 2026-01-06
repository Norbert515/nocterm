import '../framework/framework.dart';

/// Details for tap down events.
class TapDownDetails {
  const TapDownDetails({
    required this.globalPosition,
    required this.localPosition,
  });

  /// The global position where the tap occurred.
  final Offset globalPosition;

  /// The local position where the tap occurred.
  final Offset localPosition;
}

/// Details for tap up events.
class TapUpDetails {
  const TapUpDetails({
    required this.globalPosition,
    required this.localPosition,
  });

  /// The global position where the tap was released.
  final Offset globalPosition;

  /// The local position where the tap was released.
  final Offset localPosition;
}

/// Details for long press start events.
class LongPressStartDetails {
  const LongPressStartDetails({
    required this.globalPosition,
    required this.localPosition,
  });

  /// The global position where the long press started.
  final Offset globalPosition;

  /// The local position where the long press started.
  final Offset localPosition;
}

/// Details for long press end events.
class LongPressEndDetails {
  const LongPressEndDetails({
    required this.globalPosition,
    required this.localPosition,
  });

  /// The global position where the long press ended.
  final Offset globalPosition;

  /// The local position where the long press ended.
  final Offset localPosition;
}

/// Callback signatures for gesture events.
typedef GestureTapDownCallback = void Function(TapDownDetails details);
typedef GestureTapUpCallback = void Function(TapUpDetails details);
typedef GestureTapCallback = void Function();
typedef GestureTapCancelCallback = void Function();
typedef GestureLongPressCallback = void Function();
typedef GestureLongPressStartCallback =
    void Function(LongPressStartDetails details);
typedef GestureLongPressEndCallback =
    void Function(LongPressEndDetails details);
