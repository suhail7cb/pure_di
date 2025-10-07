// Lazy singleton wrapper that creates instances only when first accessed

class Lazy<T> {
  // Holds the actual instance of type T (nullable until initialized)
  T? _instance;

  // Factory function to create the instance of type T
  final T Function() _factory;

  // Indicates whether the instance has been created
  bool _isInitialized = false;

  // Constructor takes a factory method to lazily instantiate the object
  Lazy(this._factory);

  /// Returns the lazily created instance.
  /// If it hasn't been created yet, calls the factory to create it,
  /// marks it as initialized, and stores the instance internally.
  T get value {
    if (!_isInitialized) {
      _instance = _factory(); // Create the instance on first access
      _isInitialized = true; // Mark as initialized
    }
    return _instance!; // Return the cached instance
  }

  /// Returns `true` if the instance has already been created,
  /// otherwise `false`.
  bool get isInitialized => _isInitialized;

  /// Disposes of the instance if:
  /// - It has already been created (`_isInitialized` is true), and
  /// - It implements the [Disposable] interface.
  ///
  /// After disposing, it clears the instance and resets the initialized flag.
  void dispose() {
    if (_isInitialized && _instance is Disposable) {
      (_instance as Disposable).dispose(); // Call dispose if supported
    }
    _instance = null; // Remove reference
    _isInitialized = false; // Mark as not initialized
  }

  /// Resets the lazy instance.
  /// This is an alias for `dispose()` and ensures the instance
  /// will be re-created the next time `value` is accessed.
  void reset() {
    dispose();
  }
}

/// Interface for disposable services.
///
/// Implement this on any service class that needs to release
/// resources when it is no longer needed (e.g., close streams, connections).
abstract class Disposable {
  void dispose();
}
