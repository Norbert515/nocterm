import 'package:nocterm/src/animation/ticker.dart';
import 'package:nocterm/src/framework/framework.dart';

/// Provides a single [Ticker] that is configured to only tick while the
/// current [State] is active.
///
/// To use this mixin, add it to your [State] class:
///
/// ```dart
/// class MyState extends State<MyComponent> with SingleTickerProviderStateMixin {
///   late AnimationController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = AnimationController(
///       duration: const Duration(milliseconds: 300),
///       vsync: this,
///     );
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
/// }
/// ```
///
/// This mixin can only create a single ticker. If you need multiple tickers,
/// use [TickerProviderStateMixin] instead.
mixin SingleTickerProviderStateMixin<T extends StatefulComponent> on State<T>
    implements TickerProvider {
  Ticker? _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(
      _ticker == null,
      'SingleTickerProviderStateMixin can only create a single Ticker. '
      'If you need multiple Tickers, use TickerProviderStateMixin instead.',
    );
    _ticker = Ticker(
      onTick,
      debugLabel: 'created by ${_describeIdentity(this)}',
    );
    return _ticker!;
  }

  @override
  void dispose() {
    assert(
      _ticker == null || !_ticker!.isActive,
      '${_describeIdentity(this)} was disposed with an active Ticker.\n'
      'The Ticker should be stopped before calling dispose().',
    );
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    // If we have a ticker, we might need to update its muted state
    // based on visibility or other factors. This is a placeholder for
    // future enhancement when we add visibility detection.
    super.didChangeDependencies();
  }
}

/// Provides [Ticker] objects that are configured to only tick while the
/// current [State] is active.
///
/// To use this mixin, add it to your [State] class:
///
/// ```dart
/// class MyState extends State<MyComponent> with TickerProviderStateMixin {
///   late AnimationController _controller1;
///   late AnimationController _controller2;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller1 = AnimationController(
///       duration: const Duration(milliseconds: 300),
///       vsync: this,
///     );
///     _controller2 = AnimationController(
///       duration: const Duration(milliseconds: 500),
///       vsync: this,
///     );
///   }
///
///   @override
///   void dispose() {
///     _controller1.dispose();
///     _controller2.dispose();
///     super.dispose();
///   }
/// }
/// ```
///
/// Use this mixin when you need multiple [AnimationController]s. If you only
/// need a single ticker, use [SingleTickerProviderStateMixin] instead, which
/// is slightly more efficient.
mixin TickerProviderStateMixin<T extends StatefulComponent> on State<T>
    implements TickerProvider {
  Set<Ticker>? _tickers;

  @override
  Ticker createTicker(TickerCallback onTick) {
    _tickers ??= <Ticker>{};
    final ticker = _WidgetTicker(
      onTick,
      this,
      debugLabel: 'created by ${_describeIdentity(this)}',
    );
    _tickers!.add(ticker);
    return ticker;
  }

  void _removeTicker(_WidgetTicker ticker) {
    assert(_tickers != null);
    assert(_tickers!.contains(ticker));
    _tickers!.remove(ticker);
  }

  @override
  void dispose() {
    assert(() {
      if (_tickers != null) {
        for (final ticker in _tickers!) {
          if (ticker.isActive) {
            throw StateError(
              '${_describeIdentity(this)} was disposed with an active Ticker.\n'
              'All Tickers should be stopped before calling dispose().\n'
              'Active ticker: $ticker',
            );
          }
        }
      }
      return true;
    }());
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    // If we have tickers, we might need to update their muted state
    // based on visibility or other factors. This is a placeholder for
    // future enhancement when we add visibility detection.
    super.didChangeDependencies();
  }
}

/// A [Ticker] that is associated with a [TickerProviderStateMixin].
///
/// This ticker automatically removes itself from the provider when disposed.
class _WidgetTicker extends Ticker {
  _WidgetTicker(super.onTick, this._creator, {super.debugLabel});

  final TickerProviderStateMixin _creator;

  @override
  void dispose() {
    _creator._removeTicker(this);
    super.dispose();
  }
}

/// Returns a string identifying an object for debugging.
String _describeIdentity(Object? object) {
  return '${object.runtimeType}#${object.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0')}';
}
