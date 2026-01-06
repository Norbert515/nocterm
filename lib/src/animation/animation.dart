import 'package:nocterm/src/animation/curves.dart';
import 'package:nocterm/src/animation/ticker.dart';
import 'package:nocterm/src/framework/listenable.dart';
import 'package:nocterm/src/framework/value_listenable.dart';

/// The status of an animation.
enum AnimationStatus {
  /// The animation is stopped at the beginning.
  dismissed,

  /// The animation is running from beginning to end.
  forward,

  /// The animation is running from end to beginning.
  reverse,

  /// The animation is stopped at the end.
  completed,
}

/// Signature for callbacks that are called when an [Animation] changes status.
typedef AnimationStatusListener = void Function(AnimationStatus status);

/// An animation with a value of type [T].
///
/// An animation consists of a value (of type [T]) together with a status.
/// The value changes over time and the status indicates whether the animation
/// is conceptually running in the forward or reverse direction.
abstract class Animation<T> extends Listenable implements ValueListenable<T> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Animation();

  /// The current value of the animation.
  @override
  T get value;

  /// The current status of the animation.
  AnimationStatus get status;

  /// Registers a callback to be called when the animation changes status.
  void addStatusListener(AnimationStatusListener listener);

  /// Removes a status listener.
  void removeStatusListener(AnimationStatusListener listener);

  /// Whether the animation is stopped at the beginning.
  bool get isDismissed => status == AnimationStatus.dismissed;

  /// Whether the animation is stopped at the end.
  bool get isCompleted => status == AnimationStatus.completed;

  /// Whether the animation is currently running (forward or reverse).
  bool get isAnimating =>
      status == AnimationStatus.forward || status == AnimationStatus.reverse;

  /// Chains this animation with an [Animatable] to create a new [Animation].
  ///
  /// This is useful for applying transformations (like [Tween]s or [Curve]s)
  /// to an existing animation.
  ///
  /// This method is only valid when [T] is [double].
  Animation<U> drive<U>(Animatable<U> child) {
    assert(
      this is Animation<double>,
      'drive() may only be called on Animation<double>.',
    );
    return child.animate(this as Animation<double>);
  }

  @override
  String toString() {
    return '${describeIdentity(this)}(${toStringDetails()})';
  }

  /// Provides a string describing the status of this animation.
  String toStringDetails() {
    switch (status) {
      case AnimationStatus.forward:
        return '\u25B6'; // ▶
      case AnimationStatus.reverse:
        return '\u25C0'; // ◀
      case AnimationStatus.completed:
        return '\u23ED'; // ⏭
      case AnimationStatus.dismissed:
        return '\u23EE'; // ⏮
    }
  }
}

/// Returns a string identifying an object for debugging.
String describeIdentity(Object? object) {
  return '${object.runtimeType}#${shortHash(object)}';
}

/// Returns a short hash of an object for debugging.
String shortHash(Object? object) {
  return object.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
}

/// An abstract class for objects that transform a double value.
///
/// Typically used to transform animation values (which are doubles from
/// 0.0 to 1.0) into other values, such as colors, positions, etc.
abstract class Animatable<T> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Animatable();

  /// Transforms the given parameter value.
  ///
  /// The parameter [t] is typically the value of an [Animation] (between 0.0
  /// and 1.0), but may be outside this range.
  T transform(double t);

  /// Returns the value of this [Animatable] given the current value of the
  /// [animation].
  T evaluate(Animation<double> animation) => transform(animation.value);

  /// Returns a new [Animation] that wraps the given [Animation] with this
  /// [Animatable].
  Animation<T> animate(Animation<double> parent) {
    return _AnimatedEvaluation<T>(parent, this);
  }

  /// Returns a new [Animatable] that chains this [Animatable] with the given
  /// [parent].
  ///
  /// The resulting [Animatable] will first apply the [parent] transformation
  /// to the input value, then apply this [Animatable]'s transformation.
  Animatable<T> chain(Animatable<double> parent) {
    return _ChainedEvaluation<T>(parent, this);
  }
}

/// An [Animation] that wraps another [Animation] and applies an [Animatable]
/// transformation to its value.
class _AnimatedEvaluation<T> extends Animation<T> {
  _AnimatedEvaluation(this.parent, this._evaluatable);

  /// The parent animation.
  final Animation<double> parent;

  /// The evaluatable that transforms the parent's value.
  final Animatable<T> _evaluatable;

  @override
  T get value => _evaluatable.evaluate(parent);

  @override
  AnimationStatus get status => parent.status;

  @override
  void addListener(void Function() listener) {
    parent.addListener(listener);
  }

  @override
  void removeListener(void Function() listener) {
    parent.removeListener(listener);
  }

  @override
  void addStatusListener(AnimationStatusListener listener) {
    parent.addStatusListener(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    parent.removeStatusListener(listener);
  }

  @override
  String toStringDetails() {
    return '${parent.toStringDetails()} \u27A9 $_evaluatable'; // ➩
  }
}

/// An [Animatable] that chains two [Animatable]s together.
class _ChainedEvaluation<T> extends Animatable<T> {
  const _ChainedEvaluation(this._parent, this._evaluatable);

  final Animatable<double> _parent;
  final Animatable<T> _evaluatable;

  @override
  T transform(double t) => _evaluatable.transform(_parent.transform(t));

  @override
  String toString() {
    return '$_parent\u27A9$_evaluatable'; // ➩
  }
}

/// The direction in which an animation is running.
enum _AnimationDirection {
  /// The animation is running from beginning to end.
  forward,

  /// The animation is running from end to beginning.
  reverse,
}

/// A controller for an animation.
///
/// This class lets you perform common animation tasks:
///
///  * Play an animation [forward] or in [reverse], or [stop] an animation.
///  * Set the animation to a specific [value].
///  * Define the [lowerBound] and [upperBound] values of an animation.
///  * Create a [fling] animation using a physics simulation.
class AnimationController extends Animation<double> {
  /// Creates an animation controller.
  ///
  /// * [value] is the initial value of the animation. If omitted, the
  ///   animation starts at [lowerBound].
  /// * [duration] is the length of time this animation should take to
  ///   complete the transition from [lowerBound] to [upperBound].
  /// * [reverseDuration] is the length of time this animation should take to
  ///   reverse from [upperBound] to [lowerBound].
  /// * [lowerBound] is the smallest value this animation can have. The default
  ///   is 0.0.
  /// * [upperBound] is the largest value this animation can have. The default
  ///   is 1.0.
  /// * [vsync] is the [TickerProvider] for this controller.
  AnimationController({
    double? value,
    this.duration,
    this.reverseDuration,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    required TickerProvider vsync,
  }) : assert(lowerBound <= upperBound),
       _direction = _AnimationDirection.forward {
    _ticker = vsync.createTicker(_tick);
    _internalSetValue(value ?? lowerBound);
  }

  /// Creates an animation controller with no bounds.
  ///
  /// This is useful for animations that don't need to be bounded between 0.0
  /// and 1.0, such as scroll animations.
  AnimationController.unbounded({
    double value = 0.0,
    this.duration,
    this.reverseDuration,
    required TickerProvider vsync,
  }) : lowerBound = double.negativeInfinity,
       upperBound = double.infinity,
       _direction = _AnimationDirection.forward {
    _ticker = vsync.createTicker(_tick);
    _internalSetValue(value);
  }

  /// The value at which this animation is deemed to be dismissed.
  final double lowerBound;

  /// The value at which this animation is deemed to be completed.
  final double upperBound;

  /// The length of time this animation should last when going forward.
  Duration? duration;

  /// The length of time this animation should last when going reverse.
  ///
  /// If null, [duration] is used.
  Duration? reverseDuration;

  late Ticker _ticker;
  _AnimationDirection _direction;

  Duration? _lastElapsedDuration;
  double _value = 0.0;
  AnimationStatus _status = AnimationStatus.dismissed;

  final List<void Function()> _listeners = [];
  final List<AnimationStatusListener> _statusListeners = [];

  /// The current simulation driving the animation, if any.
  _AnimationSimulation? _simulation;

  @override
  double get value => _value;

  /// Stops the animation and sets [value] to [newValue].
  set value(double newValue) {
    stop();
    _internalSetValue(newValue);
    notifyListeners();
    _checkStatusChanged();
  }

  void _internalSetValue(double newValue) {
    _value = newValue.clamp(lowerBound, upperBound);
    if (_value == lowerBound) {
      _status = AnimationStatus.dismissed;
    } else if (_value == upperBound) {
      _status = AnimationStatus.completed;
    } else {
      _status = _direction == _AnimationDirection.forward
          ? AnimationStatus.forward
          : AnimationStatus.reverse;
    }
  }

  @override
  AnimationStatus get status => _status;

  /// Whether this animation is currently animating in any direction.
  @override
  bool get isAnimating => _ticker.isActive;

  /// The rate of change of [value] per second.
  ///
  /// If [isAnimating] is false, this returns 0.0.
  double get velocity {
    if (!isAnimating) {
      return 0.0;
    }
    return _simulation?.velocity(_lastElapsedDuration!) ?? 0.0;
  }

  /// Starts running the animation forwards (towards the end).
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  ///
  /// If [from] is given, the animation starts from that value instead of
  /// its current value.
  TickerFuture forward({double? from}) {
    _direction = _AnimationDirection.forward;
    if (from != null) {
      value = from;
    }
    return _animateToInternal(upperBound);
  }

  /// Starts running the animation backwards (towards the beginning).
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  ///
  /// If [from] is given, the animation starts from that value instead of
  /// its current value.
  TickerFuture reverse({double? from}) {
    _direction = _AnimationDirection.reverse;
    if (from != null) {
      value = from;
    }
    return _animateToInternal(lowerBound);
  }

  /// Drives the animation from its current value to [target].
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  ///
  /// The optional [duration] overrides the controller's [duration].
  /// The optional [curve] overrides the default linear interpolation.
  TickerFuture animateTo(
    double target, {
    Duration? duration,
    Curve curve = Curves.linear,
  }) {
    _direction = target >= _value
        ? _AnimationDirection.forward
        : _AnimationDirection.reverse;
    return _animateToInternal(target, duration: duration, curve: curve);
  }

  /// Drives the animation from its current value to [target] going backwards.
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  TickerFuture animateBack(
    double target, {
    Duration? duration,
    Curve curve = Curves.linear,
  }) {
    _direction = target <= _value
        ? _AnimationDirection.reverse
        : _AnimationDirection.forward;
    return _animateToInternal(target, duration: duration, curve: curve);
  }

  TickerFuture _animateToInternal(
    double target, {
    Duration? duration,
    Curve curve = Curves.linear,
  }) {
    final double range = upperBound - lowerBound;
    final double remainingFraction = range.isFinite
        ? (target - _value).abs() / range
        : 1.0;

    Duration? simulationDuration;
    if (_direction == _AnimationDirection.reverse && reverseDuration != null) {
      simulationDuration = reverseDuration! * remainingFraction;
    } else if (duration != null) {
      simulationDuration = duration * remainingFraction;
    } else if (this.duration != null) {
      simulationDuration = this.duration! * remainingFraction;
    }

    if (simulationDuration == null || simulationDuration == Duration.zero) {
      if (_value != target) {
        _value = target.clamp(lowerBound, upperBound);
        notifyListeners();
      }
      _status = _direction == _AnimationDirection.forward
          ? AnimationStatus.completed
          : AnimationStatus.dismissed;
      _checkStatusChanged();
      return TickerFuture.complete();
    }

    return _startSimulation(
      _InterpolationSimulation(_value, target, simulationDuration, curve),
    );
  }

  /// Repeats the animation indefinitely (or until stopped).
  ///
  /// The [min] and [max] values default to [lowerBound] and [upperBound]
  /// respectively.
  ///
  /// If [reverse] is true, the animation reverses direction on each iteration.
  /// If [reverse] is false, the animation jumps back to [min] after reaching
  /// [max].
  ///
  /// The optional [period] specifies the duration of one cycle.
  TickerFuture repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
  }) {
    min ??= lowerBound;
    max ??= upperBound;
    period ??= duration;
    assert(min <= max);
    assert(period != null);

    return _startSimulation(_RepeatingSimulation(min, max, reverse, period!));
  }

  /// Sets the controller's value to [lowerBound], stopping the animation if
  /// necessary.
  void reset() {
    value = lowerBound;
  }

  /// Stops running the animation.
  ///
  /// If [canceled] is true, the [TickerFuture.orCancel] future will complete
  /// with a [TickerCanceled] error.
  void stop({bool canceled = true}) {
    _simulation = null;
    _lastElapsedDuration = null;
    _ticker.stop(canceled: canceled);
  }

  TickerFuture _startSimulation(_AnimationSimulation simulation) {
    assert(!isAnimating);
    _simulation = simulation;
    _lastElapsedDuration = Duration.zero;
    _value = simulation.x(Duration.zero).clamp(lowerBound, upperBound);
    final result = _ticker.start();
    _status = _direction == _AnimationDirection.forward
        ? AnimationStatus.forward
        : AnimationStatus.reverse;
    _checkStatusChanged();
    return result;
  }

  void _tick(Duration elapsed) {
    _lastElapsedDuration = elapsed;

    assert(_simulation != null);
    _value = _simulation!.x(elapsed).clamp(lowerBound, upperBound);

    if (_simulation!.isDone(elapsed)) {
      _status = _direction == _AnimationDirection.forward
          ? AnimationStatus.completed
          : AnimationStatus.dismissed;
      stop(canceled: false);
    }

    notifyListeners();
    _checkStatusChanged();
  }

  AnimationStatus? _lastReportedStatus;

  void _checkStatusChanged() {
    if (_status != _lastReportedStatus) {
      _lastReportedStatus = _status;
      notifyStatusListeners(_status);
    }
  }

  /// Calls all registered listeners.
  void notifyListeners() {
    final localListeners = List<void Function()>.of(_listeners);
    for (final listener in localListeners) {
      try {
        listener();
      } catch (e) {
        // In production, we'd want to handle this error gracefully
        rethrow;
      }
    }
  }

  /// Calls all registered status listeners.
  void notifyStatusListeners(AnimationStatus status) {
    final localListeners = List<AnimationStatusListener>.of(_statusListeners);
    for (final listener in localListeners) {
      try {
        listener(status);
      } catch (e) {
        rethrow;
      }
    }
  }

  @override
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  @override
  void addStatusListener(AnimationStatusListener listener) {
    _statusListeners.add(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    _statusListeners.remove(listener);
  }

  /// Releases the resources used by this controller.
  void dispose() {
    stop();
    _ticker.dispose();
    _listeners.clear();
    _statusListeners.clear();
  }

  @override
  String toStringDetails() {
    final String paused = isAnimating ? '' : '; paused';
    final String direction = _direction == _AnimationDirection.forward
        ? '\u25B6' // ▶
        : '\u25C0'; // ◀
    final String label = debugLabel ?? '';
    return '${value.toStringAsFixed(3)}$paused$direction$label';
  }

  /// A label used for debugging.
  String? debugLabel;
}

/// Abstract base class for animation simulations.
abstract class _AnimationSimulation {
  /// Returns the position at the given elapsed time.
  double x(Duration time);

  /// Returns the velocity at the given elapsed time.
  double velocity(Duration time);

  /// Returns true if the simulation is done at the given elapsed time.
  bool isDone(Duration time);
}

/// A simulation that interpolates linearly from one value to another.
class _InterpolationSimulation extends _AnimationSimulation {
  _InterpolationSimulation(this._begin, this._end, this._duration, this._curve);

  final double _begin;
  final double _end;
  final Duration _duration;
  final Curve _curve;

  @override
  double x(Duration time) {
    final double t = (time.inMicroseconds / _duration.inMicroseconds).clamp(
      0.0,
      1.0,
    );
    if (t == 0.0) {
      return _begin;
    } else if (t == 1.0) {
      return _end;
    } else {
      return _begin + (_end - _begin) * _curve.transform(t);
    }
  }

  @override
  double velocity(Duration time) {
    final double t = (time.inMicroseconds / _duration.inMicroseconds).clamp(
      0.0,
      1.0,
    );
    final double epsilon = 0.01;
    final double t1 = (t - epsilon).clamp(0.0, 1.0);
    final double t2 = (t + epsilon).clamp(0.0, 1.0);
    final double x1 = _begin + (_end - _begin) * _curve.transform(t1);
    final double x2 = _begin + (_end - _begin) * _curve.transform(t2);
    return (x2 - x1) / (epsilon * 2);
  }

  @override
  bool isDone(Duration time) {
    return time >= _duration;
  }
}

/// A simulation that repeats a linear interpolation indefinitely.
class _RepeatingSimulation extends _AnimationSimulation {
  _RepeatingSimulation(this._min, this._max, this._reverse, this._period);

  final double _min;
  final double _max;
  final bool _reverse;
  final Duration _period;

  @override
  double x(Duration time) {
    final double periodInMicroseconds = _period.inMicroseconds.toDouble();
    final double t =
        (time.inMicroseconds % periodInMicroseconds) / periodInMicroseconds;

    final int iteration = (time.inMicroseconds / periodInMicroseconds).floor();
    final bool goingForward = _reverse ? iteration.isEven : true;

    if (goingForward) {
      return _min + (_max - _min) * t;
    } else {
      return _max - (_max - _min) * t;
    }
  }

  @override
  double velocity(Duration time) {
    final double periodInMicroseconds = _period.inMicroseconds.toDouble();
    final int iteration = (time.inMicroseconds / periodInMicroseconds).floor();
    final bool goingForward = _reverse ? iteration.isEven : true;
    return goingForward
        ? (_max - _min) /
              _period.inMicroseconds *
              Duration.microsecondsPerSecond
        : -(_max - _min) /
              _period.inMicroseconds *
              Duration.microsecondsPerSecond;
  }

  @override
  bool isDone(Duration time) {
    return false; // Repeating forever
  }
}
