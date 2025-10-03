import 'lazy.dart';
import 'exceptions.dart';

/// Represents a scoped container for managing service lifecycles
class Scope {
  final String name;
  final Map<Type, dynamic> _instances = {};
  final Map<Type, dynamic> _factories = {};
  bool _isDisposed = false;

  Scope(this.name);

  /// Registers a factory function for a service type within this scope
  void register<T>(T Function() factory) {
    _throwIfDisposed();
    if (_factories.containsKey(T)) {
      throw ServiceAlreadyRegisteredException(T);
    }
    _factories[T] = factory;
  }

  /// Registers a singleton instance within this scope
  void registerSingleton<T>(T instance) {
    _throwIfDisposed();
    if (_instances.containsKey(T) || _factories.containsKey(T)) {
      throw ServiceAlreadyRegisteredException(T);
    }
    _instances[T] = instance;
  }

  /// Registers a lazy singleton within this scope
  void registerLazySingleton<T>(T Function() factory) {
    _throwIfDisposed();
    if (_instances.containsKey(T) || _factories.containsKey(T)) {
      throw ServiceAlreadyRegisteredException(T);
    }
    _instances[T] = Lazy<T>(factory);
  }

  /// Resolves a service from this scope
  T get<T>() {
    _throwIfDisposed();

    // Check if we have a direct instance
    if (_instances.containsKey(T)) {
      final instance = _instances[T];
      if (instance is Lazy<T>) {
        return instance.value;
      }
      return instance as T;
    }

    // Check if we have a factory
    if (_factories.containsKey(T)) {
      final factory = _factories[T] as T Function();
      return factory();
    }

    throw ServiceNotRegisteredException(T);
  }

  /// Checks if a service is registered in this scope
  bool isRegistered<T>() {
    return _instances.containsKey(T) || _factories.containsKey(T);
  }

  /// Disposes all services in this scope
  void dispose() {
    if (_isDisposed) return;

    // Dispose lazy singletons and disposable instances
    for (final instance in _instances.values) {
      if (instance is Lazy) {
        instance.dispose();
      } else if (instance is Disposable) {
        instance.dispose();
      }
    }

    _instances.clear();
    _factories.clear();
    _isDisposed = true;
  }

  /// Checks if this scope has been disposed
  bool get isDisposed => _isDisposed;

  void _throwIfDisposed() {
    if (_isDisposed) {
      throw StateError('Scope "$name" has been disposed');
    }
  }
}
