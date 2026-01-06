import 'package:nocterm/nocterm.dart';
import 'package:riverpod/riverpod.dart';

/// Manages provider subscriptions for a single element.
///
/// This class tracks all provider subscriptions for an element and ensures
/// proper cleanup during rebuilds and disposal.
class ProviderDependencies {
  ProviderDependencies(this.dependent);

  /// The element that owns these dependencies
  final Element dependent;

  /// The current provider container
  ProviderContainer? _container;

  /// Active subscriptions from the current build
  final Map<ProviderListenable, ProviderSubscription> _watchers = {};
  final Map<ProviderListenable, ProviderSubscription> _listeners = {};

  /// Previous subscriptions from the last build (for cleanup)
  final Map<ProviderListenable, ProviderSubscription> _oldWatchers = {};
  final Map<ProviderListenable, ProviderSubscription> _oldListeners = {};

  /// Watch a provider and rebuild when it changes.
  ///
  /// This method:
  /// 1. Reuses existing subscriptions when possible
  /// 2. Creates new subscriptions only when needed
  /// 3. Automatically triggers rebuilds when the provider changes
  T watch<T>(ProviderListenable<T> provider, ProviderContainer container) {
    // Check if container changed (e.g., nested scope)
    if (_container != null && _container != container) {
      // Container changed, clean up all subscriptions
      _deactivateAll();
    }
    _container = container;

    // Check if we already have an active subscription
    if (!_watchers.containsKey(provider)) {
      // Check if we had a subscription from the previous build
      if (_oldWatchers.containsKey(provider)) {
        // Reuse the existing subscription
        _watchers[provider] = _oldWatchers.remove(provider)!;
      } else {
        // Create a new subscription
        final subscription = container.listen<T>(provider, (previous, next) {
          // Only trigger rebuild if this subscription is still active
          if (_watchers.containsKey(provider) ||
              _oldWatchers.containsKey(provider)) {
            if (dependent.mounted) {
              dependent.markNeedsBuild();
            }
          }
        }, fireImmediately: false);
        _watchers[provider] = subscription;
      }
    }

    // Read and return the current value
    return (_watchers[provider] as ProviderSubscription<T>).read();
  }

  /// Listen to a provider with a callback.
  ///
  /// Unlike watch, this doesn't trigger rebuilds but calls the provided callback.
  void listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener,
    ProviderContainer container, {
    bool fireImmediately = false,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    // Check if container changed
    if (_container != null && _container != container) {
      _deactivateAll();
    }
    _container = container;

    // Close existing listener if any
    if (_listeners.containsKey(provider)) {
      _listeners[provider]!.close();
    }
    if (_oldListeners.containsKey(provider)) {
      _oldListeners[provider]!.close();
    }

    // Create new listener subscription
    final subscription = container.listen<T>(
      provider,
      listener,
      fireImmediately: fireImmediately,
      onError: onError,
    );

    _listeners[provider] = subscription;
  }

  /// Called when the element rebuilds.
  ///
  /// This method:
  /// 1. Moves current subscriptions to "old" maps
  /// 2. Cleans up any unused old subscriptions
  void didRebuildDependent() {
    // Clean up old subscriptions that weren't reused
    for (final subscription in _oldWatchers.values) {
      subscription.close();
    }
    for (final subscription in _oldListeners.values) {
      subscription.close();
    }

    // Move current subscriptions to old for the next build
    _oldWatchers
      ..clear()
      ..addAll(_watchers);
    _watchers.clear();

    _oldListeners
      ..clear()
      ..addAll(_listeners);
    _listeners.clear();
  }

  /// Called when the element is deactivated.
  ///
  /// This method cleans up ALL subscriptions.
  void deactivateDependent() {
    _deactivateAll();
  }

  /// Clean up all subscriptions
  void _deactivateAll() {
    // Close all active subscriptions
    for (final subscription in _watchers.values) {
      subscription.close();
    }
    for (final subscription in _oldWatchers.values) {
      subscription.close();
    }
    for (final subscription in _listeners.values) {
      subscription.close();
    }
    for (final subscription in _oldListeners.values) {
      subscription.close();
    }

    // Clear all maps
    _watchers.clear();
    _oldWatchers.clear();
    _listeners.clear();
    _oldListeners.clear();

    _container = null;
  }
}
