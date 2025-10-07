import 'lazy.dart';
import 'exceptions.dart';

/// Represents a scoped container for managing service lifecycles
///
/// A Scope is an isolated container that holds service instances and factories.
/// Useful for managing services tied to specific lifetimes (e.g., user session, navigation context).
class Scope {
  // The name of this scope, used for identification and debugging
  final String name;

  // Stores instantiated singletons (including lazy singletons)
  final Map<Type, dynamic> _instances = {};

  // Stores factory functions to create new instances on demand
  final Map<Type, dynamic> _factories = {};

  // Indicates whether this scope has been disposed
  bool _isDisposed = false;

  // Constructor to create a new scope with a given name
  Scope(this.name);

  /// Registers a factory method for type `T` within this scope.
  /// Throws [ServiceAlreadyRegisteredException] if a factory is already registered.
  void register<T>(T Function() factory) {
    _throwIfDisposed();  // Prevents registration if scope is already disposed

    if (_factories.containsKey(T)) {
      throw ServiceAlreadyRegisteredException(T);
    }

    _factories[T] = factory;
  }

  /// Registers a singleton instance of type `T` within this scope.
  /// Throws [ServiceAlreadyRegisteredException] if the type is already registered.
  void registerSingleton<T>(T instance) {
    _throwIfDisposed();  // Check if scope is still valid

    if (_instances.containsKey(T) || _factories.containsKey(T)) {
      throw ServiceAlreadyRegisteredException(T);
    }

    _instances[T] = instance;
  }

  /// Registers a lazy singleton of type `T` using a factory.
  /// The instance is created only when first accessed via `get<T>()`.
  /// Throws [ServiceAlreadyRegisteredException] if the type is already registered.
  void registerLazySingleton<T>(T Function() factory) {
    _throwIfDisposed();  // Ensure scope is active

    if (_instances.containsKey(T) || _factories.containsKey(T)) {
      throw ServiceAlreadyRegisteredException(T);
    }

    _instances[T] = Lazy<T>(factory);
  }

  /// Retrieves an instance of type `T` from the scope.
  /// - Returns the singleton or lazy singleton if registered.
  /// - If a factory is registered, it creates and returns a new instance.
  /// Throws [ServiceNotRegisteredException] if the type is not found.
  T get<T>() {
    _throwIfDisposed();  // Check if scope is usable

    // First check for registered singleton/lazy singleton
    if (_instances.containsKey(T)) {
      final instance = _instances[T];

      if (instance is Lazy<T>) {
        return instance.value;  // Create and return lazy instance
      }

      return instance as T;  // Return existing singleton
    }

    // Check for registered factory
    if (_factories.containsKey(T)) {
      final factory = _factories[T] as T Function();
      return factory();  // Create and return new instance from factory
    }

    // Service not found
    throw ServiceNotRegisteredException(T);
  }

  /// Returns true if the type `T` has been registered in this scope.
  /// Checks both singleton and factory registrations.
  bool isRegistered<T>() {
    return _instances.containsKey(T) || _factories.containsKey(T);
  }

  /// Disposes the scope and all services registered in it.
  /// - Calls `dispose()` on instances that implement [Disposable] or [Lazy].
  /// - Clears all internal storage and marks the scope as disposed.
  void dispose() {
    if (_isDisposed) return;

    for (final instance in _instances.values) {
      if (instance is Lazy) {
        instance.dispose();  // Dispose lazily initialized instance
      } else if (instance is Disposable) {
        instance.dispose();  // Dispose directly if Disposable
      }
    }

    _instances.clear();   // Remove all instances
    _factories.clear();   // Remove all factories
    _isDisposed = true;   // Mark scope as disposed
  }

  /// Indicates whether this scope has been disposed.
  /// Once disposed, no further registrations or retrievals are allowed.
  bool get isDisposed => _isDisposed;

  /// Throws an error if any operation is attempted on a disposed scope.
  void _throwIfDisposed() {
    if (_isDisposed) {
      throw StateError('Scope "$name" has been disposed');
    }
  }
}