
// part of 'pure_di.dart';


/// Lazy singleton wrapper that creates instances only when first accessed

class Lazy<T> {
  T? _instance;
  final T Function() _factory;
  bool _isInitialized = false;

  Lazy(this._factory);

  /// Gets the instance, creating it if necessary
  T get value {
    if (!_isInitialized) {
      _instance = _factory();
      _isInitialized = true;
    }
    return _instance!;
  }

  /// Checks if the instance has been created
  bool get isInitialized => _isInitialized;

  /// Disposes the instance if it implements Disposable
  void dispose() {
    if (_isInitialized && _instance is Disposable) {
      (_instance as Disposable).dispose();
    }
    _instance = null;
    _isInitialized = false;
  }

  /// Resets the lazy instance, forcing recreation on next access
  void reset() {
    dispose();
  }
}

/// Interface for disposable services
abstract class Disposable {
  void dispose();
}
