// Importing required dependencies.
// 'lazy.dart' defines lazy singletons,
// 'scope.dart' defines scoped service instances,
// 'exceptions.dart' contains custom exception classes.
import 'lazy.dart';
import 'scope.dart';
import 'exceptions.dart';

/// A simple Service Locator for Dependency Injection (DI).
///
/// It allows registering services as:
/// - Singleton (one instance)
/// - Lazy Singleton (created on first use)
/// - Factory (new instance on every request)
///
/// It also supports scoping for contextual service management.
class PureDI {
  // Singleton instance of PureDI (global access point).
  static PureDI? _instance;

  // Holds all singleton instances (including lazy singletons).
  final Map<Type, dynamic> _singletons = {};

  // Holds factory functions for services.
  final Map<Type, dynamic> _factories = {};

  // Holds all named scopes created via `createScope()`.
  final Map<String, Scope> _scopes = {};

  // Private constructor to prevent external instantiation.
  PureDI._();

  /// Accessor for the global instance (Singleton pattern).
  /// Initializes the instance if not already created.
  static PureDI get instance {
    _instance ??= PureDI._();
    return _instance!;
  }

  /// Resets the global instance (useful for testing).
  /// Clears all services and scopes, and removes the singleton.
  static void reset() {
    if (_instance != null) {
      _instance!._reset();
      _instance = null;
    }
  }

  /// Registers a factory method that creates a **new instance** each time `get<T>()` is called.
  /// Throws [ServiceAlreadyRegisteredException] if a factory for `T` is already registered.
  void register<T>(T Function() factory) {
    if (_factories.containsKey(T)) {
      throw ServiceAlreadyRegisteredException(T);
    }
    _factories[T] = factory;
  }

  /// Registers a **singleton** instance. The same instance will be returned every time.
  /// Throws [ServiceAlreadyRegisteredException] if a singleton of `T` is already registered.
  void registerSingleton<T>(T instance) {
    if (_singletons.containsKey(T)) {
      throw ServiceAlreadyRegisteredException(T);
    }
    _singletons[T] = instance;
  }

  /// Registers a **lazy singleton**: a service that is instantiated on the first access.
  /// Internally wraps the factory in a [Lazy<T>] object.
  /// Throws [ServiceAlreadyRegisteredException] if a singleton of `T` is already registered.
  void registerLazySingleton<T>(T Function() factory) {
    if (_singletons.containsKey(T)) {
      throw ServiceAlreadyRegisteredException(T);
    }
    _singletons[T] = Lazy<T>(factory);
  }

  /// Retrieves an instance of type `T`.
  /// - Returns the singleton if available.
  /// - If it's a [Lazy] singleton, calls `.value` to instantiate and return.
  /// - If registered as a factory, invokes the factory to create a new instance.
  /// Throws [ServiceNotRegisteredException] if the service is not found.
  T get<T>() {
    // Check if a singleton or lazy singleton exists
    if (_singletons.containsKey(T)) {
      final instance = _singletons[T];
      if (instance is Lazy<T>) {
        return instance.value; // Instantiate and return
      }
      return instance as T;
    }

    // Check if a factory is registered
    if (_factories.containsKey(T)) {
      final factory = _factories[T] as T Function();
      return factory(); // Create a new instance
    }

    // Service not registered
    throw ServiceNotRegisteredException(T);
  }

  /// Checks whether a service of type `T` is registered
  /// (as a singleton, lazy singleton, or factory).
  bool isRegistered<T>() {
    return _singletons.containsKey(T) || _factories.containsKey(T);
  }

  /// Unregisters a service of type `T` from both singleton and factory registries.
  /// If the service is disposable, calls its `dispose()` method.
  void unregister<T>() {
    final singleton = _singletons.remove(T); // Remove singleton
    _factories.remove(T); // Remove factory

    // Clean up resources if the service supports disposal
    if (singleton is Lazy) {
      singleton.dispose();
    } else if (singleton is Disposable) {
      singleton.dispose();
    }
  }

  /// Creates and registers a new named [Scope].
  /// A scope is a container for context-specific services (e.g., user session).
  /// Throws [StateError] if a scope with the same name already exists.
  Scope createScope(String name) {
    if (_scopes.containsKey(name)) {
      throw StateError('Scope "$name" already exists');
    }
    final scope = Scope(name);
    _scopes[name] = scope;
    return scope;
  }

  /// Retrieves an existing scope by name.
  /// Throws [ScopeNotFoundException] if the scope doesn't exist.
  Scope getScope(String name) {
    final scope = _scopes[name];
    if (scope == null) {
      throw ScopeNotFoundException(name);
    }
    return scope;
  }

  /// Disposes and removes a scope by name.
  /// Calls the scope's `dispose()` method.
  void disposeScope(String name) {
    final scope = _scopes.remove(name);
    scope?.dispose();
  }

  /// Checks whether a scope with the given name exists.
  bool hasScope(String name) {
    return _scopes.containsKey(name);
  }

  /// Returns a list of all currently active scope names.
  List<String> get scopeNames => _scopes.keys.toList();

  /// Disposes all services and scopes managed by this instance.
  /// Used for cleanup before application shutdown or during testing.
  void dispose() {
    // Dispose all registered scopes
    for (final scope in _scopes.values) {
      scope.dispose();
    }
    _scopes.clear();

    // Dispose all singletons/lazy singletons if needed
    for (final instance in _singletons.values) {
      if (instance is Lazy) {
        instance.dispose();
      } else if (instance is Disposable) {
        instance.dispose();
      }
    }

    // Clear all internal registries
    _reset();
  }

  /// Internal helper to clear all registries without disposing.
  void _reset() {
    _singletons.clear();
    _factories.clear();
    _scopes.clear();
  }
}
