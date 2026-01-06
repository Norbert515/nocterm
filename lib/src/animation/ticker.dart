import 'dart:async';

import 'package:nocterm/src/binding/scheduler_binding.dart';

/// Signature for callbacks passed to [Ticker].
///
/// The [elapsed] parameter is the amount of time that has passed since the
/// ticker started.
typedef TickerCallback = void Function(Duration elapsed);

/// An interface for objects that can provide a [Ticker].
///
/// This is typically implemented by [State] subclasses that want to use
/// [AnimationController].
abstract class TickerProvider {
  /// Creates a [Ticker] that will call the given [onTick] callback on each
  /// frame.
  ///
  /// The returned [Ticker] must be disposed when it is no longer needed.
  Ticker createTicker(TickerCallback onTick);
}

/// A Future that represents the result of starting a [Ticker].
///
/// The future completes with null when the ticker stops (either because
/// [Ticker.stop] was called or because the ticker was disposed).
class TickerFuture implements Future<void> {
  TickerFuture._();

  /// Creates a completed [TickerFuture].
  factory TickerFuture.complete() {
    final result = TickerFuture._();
    result._complete();
    return result;
  }

  final Completer<void> _primaryCompleter = Completer<void>();
  Completer<void>? _secondaryCompleter;
  bool _completed = false;

  void _complete() {
    assert(!_completed);
    _completed = true;
    _primaryCompleter.complete();
    _secondaryCompleter?.complete();
  }

  void _cancel(Ticker ticker) {
    assert(!_completed);
    _completed = true;
    _secondaryCompleter?.completeError(TickerCanceled(ticker));
  }

  /// Returns a Future that resolves when this [TickerFuture] completes.
  ///
  /// If the ticker is canceled (via [Ticker.stop] with `canceled: true`),
  /// the returned future completes with a [TickerCanceled] error.
  ///
  /// Use this when you want to be notified if the animation is canceled.
  Future<void> get orCancel {
    if (_secondaryCompleter == null) {
      _secondaryCompleter = Completer<void>();
      if (_completed) {
        _secondaryCompleter!.complete();
      }
    }
    return _secondaryCompleter!.future;
  }

  /// Returns a Future that resolves when this [TickerFuture] completes,
  /// ignoring any cancellation.
  ///
  /// Use this when you don't care whether the animation completed normally
  /// or was canceled.
  Future<void> get whenCompleteOrCancel {
    return _primaryCompleter.future;
  }

  @override
  Stream<void> asStream() => _primaryCompleter.future.asStream();

  @override
  Future<void> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return _primaryCompleter.future.catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(void value) onValue, {
    Function? onError,
  }) {
    return _primaryCompleter.future.then(onValue, onError: onError);
  }

  @override
  Future<void> timeout(
    Duration timeLimit, {
    FutureOr<void> Function()? onTimeout,
  }) {
    return _primaryCompleter.future.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<void> whenComplete(FutureOr<void> Function() action) {
    return _primaryCompleter.future.whenComplete(action);
  }
}

/// Exception thrown when a [Ticker] is canceled.
class TickerCanceled implements Exception {
  /// Creates a [TickerCanceled] exception with an optional reference to the
  /// [Ticker] that was canceled.
  const TickerCanceled([this.ticker]);

  /// The ticker that was canceled.
  final Ticker? ticker;

  @override
  String toString() {
    if (ticker != null) {
      return 'This ticker was canceled: $ticker';
    }
    return 'The ticker was canceled before it completed.';
  }
}

/// Calls its callback once per animation frame.
///
/// When created, a [Ticker] is initially idle. Call [start] to begin calling
/// the [onTick] callback once per animation frame.
///
/// A [Ticker] can be silenced by setting [muted] to true. While muted, the
/// ticker remains "active" but the [onTick] callback is not called.
class Ticker {
  /// Creates a [Ticker].
  ///
  /// The [onTick] callback will be called once per animation frame while the
  /// ticker is active.
  Ticker(this._onTick, {this.debugLabel});

  /// An optional label for debugging.
  final String? debugLabel;

  final TickerCallback _onTick;

  Duration? _startTime;
  int? _animationId;
  TickerFuture? _future;

  bool _muted = false;

  /// Whether this ticker is muted.
  ///
  /// When muted, the ticker remains "active" but the [onTick] callback is not
  /// called. This is useful for pausing animations while keeping them logically
  /// active.
  bool get muted => _muted;

  set muted(bool value) {
    if (value == _muted) {
      return;
    }
    _muted = value;
    if (value) {
      _unscheduleTick();
    } else if (shouldScheduleTick) {
      _scheduleTick();
    }
  }

  /// Whether the ticker is currently ticking.
  ///
  /// Returns true if [start] has been called and [stop] has not yet been
  /// called.
  bool get isTicking => _future != null;

  /// Whether the ticker is currently active.
  ///
  /// An active ticker is one that has been started but not yet stopped,
  /// regardless of whether it is muted.
  bool get isActive => _future != null;

  /// Whether a tick should be scheduled.
  bool get shouldScheduleTick => !muted && isActive;

  /// Starts the ticker.
  ///
  /// Returns a [TickerFuture] that completes when the ticker stops.
  ///
  /// Throws an assertion error if the ticker has already been started.
  TickerFuture start() {
    assert(!isActive, 'A ticker can only be started once.');
    _future = TickerFuture._();
    if (shouldScheduleTick) {
      _scheduleTick();
    }
    return _future!;
  }

  void _scheduleTick({bool rescheduling = false}) {
    assert(!muted);
    assert(shouldScheduleTick);
    _animationId = SchedulerBinding.instance.scheduleFrameCallback(
      _tick,
      rescheduling: rescheduling,
      debugLabel: debugLabel,
    );
  }

  void _unscheduleTick() {
    if (_animationId != null) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(_animationId!);
      _animationId = null;
    }
  }

  void _tick(Duration timeStamp) {
    assert(isTicking);
    assert(!muted);

    _startTime ??= timeStamp;
    _animationId = null;

    _onTick(timeStamp - _startTime!);

    if (shouldScheduleTick) {
      _scheduleTick(rescheduling: true);
    }
  }

  /// Stops the ticker.
  ///
  /// If [canceled] is true (the default), the [TickerFuture.orCancel] future
  /// will complete with a [TickerCanceled] error. If [canceled] is false,
  /// the future completes normally.
  void stop({bool canceled = true}) {
    if (!isActive) {
      return;
    }

    final future = _future!;
    _future = null;
    _startTime = null;
    _unscheduleTick();

    if (canceled) {
      future._cancel(this);
    } else {
      future._complete();
    }
  }

  /// Disposes of the ticker.
  ///
  /// Calling dispose also stops the ticker if it is currently active.
  void dispose() {
    if (isActive) {
      stop(canceled: true);
    }
  }

  /// Absorbs an existing ticker.
  ///
  /// This is used when the ticker provider changes (e.g., during hot reload).
  void absorbTicker(Ticker originalTicker) {
    assert(!isActive);
    assert(
      originalTicker._future == null || !originalTicker._future!._completed,
    );

    if (originalTicker._future != null) {
      _future = originalTicker._future;
      _startTime = originalTicker._startTime;
      if (shouldScheduleTick) {
        _scheduleTick();
      }
      originalTicker._future = null;
      originalTicker._startTime = null;
      originalTicker._unscheduleTick();
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('${objectRuntimeType(this, 'Ticker')}(');
    if (debugLabel != null) {
      buffer.write(debugLabel);
    }
    buffer.write(')');
    return buffer.toString();
  }
}

/// Returns a short description of an object for debugging.
String objectRuntimeType(Object? object, String optimizedValue) {
  assert(() {
    optimizedValue = object.runtimeType.toString();
    return true;
  }());
  return optimizedValue;
}
