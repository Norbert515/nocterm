import 'package:meta/meta.dart';
import 'package:nocterm/src/animation/animation.dart';
import 'package:nocterm/src/animation/curves.dart';
import 'package:nocterm/src/style.dart';

// Note: Animatable is defined in animation.dart and re-exported here for convenience.
export 'package:nocterm/src/animation/animation.dart' show Animatable;

/// A linear interpolation between two values.
///
/// The [lerp] method is the core of this class. It must return the value
/// that is at position [t] between [begin] and [end].
///
/// By default, [lerp] assumes that the values are numeric and can be
/// interpolated using simple arithmetic. Subclasses can override [lerp] to
/// provide custom interpolation for other types.
class Tween<T extends dynamic> extends Animatable<T> {
  /// Creates a tween.
  ///
  /// The [begin] and [end] properties must be non-null before the tween is
  /// first used, but can be null when the tween is created.
  Tween({this.begin, this.end});

  /// The value this tween has at the beginning of the animation.
  T? begin;

  /// The value this tween has at the end of the animation.
  T? end;

  /// Returns the interpolated value for the current animation value.
  ///
  /// This is called by [transform] to obtain the actual value.
  ///
  /// The default implementation assumes that the begin and end values are
  /// numeric types that support arithmetic operations.
  @protected
  T lerp(double t) {
    assert(begin != null);
    assert(end != null);
    // This works for numeric types like int, double.
    // Subclasses should override for other types.
    return (begin as dynamic) + ((end as dynamic) - (begin as dynamic)) * t
        as T;
  }

  /// Returns the interpolated value at the given animation value [t].
  ///
  /// Subclasses typically don't override this method. Instead, they override
  /// [lerp].
  @override
  T transform(double t) {
    if (t == 0.0) {
      return begin as T;
    }
    if (t == 1.0) {
      return end as T;
    }
    return lerp(t);
  }

  @override
  String toString() =>
      '${objectRuntimeType(this, 'Tween')}<$T>($begin \u2192 $end)'; // →
}

/// Helper function to get the runtime type name of an object.
String objectRuntimeType(Object? object, String optimizedValue) {
  assert(() {
    optimizedValue = object.runtimeType.toString();
    return true;
  }());
  return optimizedValue;
}

/// A tween that interpolates between two integers.
///
/// This tween rounds the interpolated value to the nearest integer.
class IntTween extends Tween<int> {
  /// Creates an [IntTween].
  IntTween({super.begin, super.end});

  @override
  int lerp(double t) {
    return (begin! + (end! - begin!) * t).round();
  }
}

/// A tween that interpolates between two doubles.
class DoubleTween extends Tween<double> {
  /// Creates a [DoubleTween].
  DoubleTween({super.begin, super.end});

  @override
  double lerp(double t) {
    return begin! + (end! - begin!) * t;
  }
}

/// A tween that interpolates between two colors.
///
/// This uses [Color.lerp] to interpolate the ARGB channels separately,
/// which produces smooth color transitions.
class ColorTween extends Tween<Color?> {
  /// Creates a [ColorTween].
  ColorTween({super.begin, super.end});

  @override
  Color? lerp(double t) {
    return Color.lerp(begin, end, t);
  }
}

/// A tween that applies a [Curve] to a double value.
///
/// Use this to apply a curve to an animation. For example:
///
/// ```dart
/// final Animation<double> animation = CurveTween(
///   curve: Curves.easeIn,
/// ).animate(controller);
/// ```
class CurveTween extends Animatable<double> {
  /// Creates a curve tween.
  CurveTween({required this.curve});

  /// The curve to apply.
  final Curve curve;

  @override
  double transform(double t) => curve.transform(t);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'CurveTween')}(curve: $curve)';
}

/// A tween that goes from 0.0 to 1.0.
///
/// This can be used in place of a [Tween<double>] with begin: 0.0 and end: 1.0.
class ConstantTween<T> extends Tween<T> {
  /// Creates a constant tween.
  ConstantTween(T value) : super(begin: value, end: value);

  @override
  T lerp(double t) => begin as T;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'ConstantTween')}<$T>(value: $begin)';
}

/// A tween that reverses another tween.
///
/// The reversed tween evaluates to `parent.transform(1.0 - t)`.
class ReverseTween<T> extends Tween<T> {
  /// Creates a reverse tween.
  ReverseTween(this.parent) : super(begin: parent.end, end: parent.begin);

  /// The tween to reverse.
  final Tween<T> parent;

  @override
  T lerp(double t) => parent.lerp(1.0 - t);
}

/// A tween that interpolates a value only when it changes.
///
/// If [begin] equals [end], this tween returns [begin] for all values of [t].
class StepTween extends Tween<int> {
  /// Creates a step tween.
  StepTween({super.begin, super.end});

  @override
  int lerp(double t) => (begin! + (end! - begin!) * t).floor();
}

/// A tween sequence that combines multiple tweens into one.
///
/// Each tween is associated with a weight that determines what fraction of
/// the total duration it covers.
class TweenSequence<T> extends Animatable<T> {
  /// Creates a tween sequence.
  TweenSequence(List<TweenSequenceItem<T>> items) : _items = items {
    // Calculate total weight
    double totalWeight = 0.0;
    for (final item in items) {
      totalWeight += item.weight;
    }

    // Normalize weights
    double previousWeight = 0.0;
    _intervals = <_Interval>[];
    for (final item in items) {
      final double normalizedWeight = item.weight / totalWeight;
      _intervals.add(
        _Interval(previousWeight, previousWeight + normalizedWeight),
      );
      previousWeight += normalizedWeight;
    }
  }

  final List<TweenSequenceItem<T>> _items;
  late final List<_Interval> _intervals;

  @override
  T transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    if (t == 1.0) {
      return _items.last.tween.transform(1.0);
    }

    for (int i = 0; i < _items.length; i++) {
      if (t >= _intervals[i].start && t < _intervals[i].end) {
        final double localT =
            (t - _intervals[i].start) /
            (_intervals[i].end - _intervals[i].start);
        return _items[i].tween.transform(localT);
      }
    }

    // Should never reach here
    return _items.last.tween.transform(1.0);
  }
}

/// An item in a [TweenSequence].
class TweenSequenceItem<T> {
  /// Creates a tween sequence item.
  const TweenSequenceItem({required this.tween, required this.weight})
    : assert(weight > 0.0);

  /// The tween to use for this item.
  final Animatable<T> tween;

  /// The weight of this item relative to other items in the sequence.
  final double weight;
}

class _Interval {
  const _Interval(this.start, this.end);
  final double start;
  final double end;
}

/// A tween that applies only between a specific interval.
///
/// Use this to make a tween only active during part of an animation.
class Interval extends Curve {
  /// Creates an interval curve.
  ///
  /// The [begin] and [end] values must be between 0.0 and 1.0, and
  /// [begin] must be less than or equal to [end].
  const Interval(this.begin, this.end, {this.curve = Curves.linear})
    : assert(begin >= 0.0),
      assert(begin <= 1.0),
      assert(end >= 0.0),
      assert(end <= 1.0),
      assert(end >= begin);

  /// The start of the interval.
  final double begin;

  /// The end of the interval.
  final double end;

  /// The curve to apply within the interval.
  final Curve curve;

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    if (t == 0.0 || t == 1.0) {
      return t;
    }
    t = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
    if (t == 0.0 || t == 1.0) {
      return t;
    }
    return curve.transform(t);
  }

  @override
  String toString() {
    if (curve != Curves.linear) {
      return '${objectRuntimeType(this, 'Interval')}($begin\u2026$end)\u27A9$curve'; // …➩
    }
    return '${objectRuntimeType(this, 'Interval')}($begin\u2026$end)'; // …
  }
}

/// A curve that combines a threshold with a regular curve.
///
/// If the input is below the [threshold], the output is 0.0.
/// If the input is at or above the [threshold], the output is the result of
/// applying the [curve] to the input.
class Threshold extends Curve {
  /// Creates a threshold curve.
  const Threshold(this.threshold)
    : assert(threshold >= 0.0 && threshold <= 1.0);

  /// The threshold value.
  final double threshold;

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    if (t < threshold) {
      return 0.0;
    }
    return 1.0;
  }
}
