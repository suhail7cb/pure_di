import 'lazy.dart';
import 'scope.dart';
import 'exceptions.dart';

/// Service locator for dependency injection
class PureDI {
  static PureDI? _instance;

  final Map<Type, dynamic> _singletons = {};
  final Map<Type, dynamic> _factories = {};
  final Map<String, Scope> _scopes = {};

  PureDI._();

  /// Gets the global instance of the service locator
  static PureDI get instance {
    _instance ??= PureDI._();
    return _instance!;
  }

  /// Resets the service locator (useful for testing)
  static void reset() {
    if (_instance != null) {
      _instance!._reset();
      _instance = null;
    }
  }

  /// Registers a factory function for creating instances
  void register<T>(T Function() factory) {
    // if (_singletons.containsKey(T) || _factories.containsKey(T)) {
    if ( _factories.containsKey(T)) {
      throw ServiceAlreadyRegisteredException(T);
    }
    _factories[T] = factory;
  }

  /// Registers a singleton instance
  void registerSingleton<T>(T instance) {
    // if (_singletons.containsKey(T) || _factories.containsKey(T)) {
    if (_singletons.containsKey(T)) {
      throw ServiceAlreadyRegisteredException(T);
    }
    _singletons[T] = instance;
  }

  /// Registers a lazy singleton that will be created only when first accessed
  void registerLazySingleton<T>(T Function() factory) {
    // if (_singletons.containsKey(T) || _factories.containsKey(T)) {
    if (_singletons.containsKey(T)) {
      throw ServiceAlreadyRegisteredException(T);
    }
    _singletons[T] = Lazy<T>(factory);
  }

  /// Gets an instance of the specified type
  T get<T>() {
    // Check singletons first
    if (_singletons.containsKey(T)) {
      final instance = _singletons[T];
      if (instance is Lazy<T>) {
        return instance.value;
      }
      return instance as T;
    }

    // Check factories
    if (_factories.containsKey(T)) {
      final factory = _factories[T] as T Function();
      return factory();
    }

    throw ServiceNotRegisteredException(T);
  }

  /// Checks if a service is registered
  bool isRegistered<T>() {
    return _singletons.containsKey(T) || _factories.containsKey(T);
  }

  /// Unregisters a service
  void unregister<T>() {
    final singleton = _singletons.remove(T);
    _factories.remove(T);

    // Dispose if necessary
    if (singleton is Lazy) {
      singleton.dispose();
    } else if (singleton is Disposable) {
      singleton.dispose();
    }
  }

  /// Creates a new scope
  Scope createScope(String name) {
    if (_scopes.containsKey(name)) {
      throw StateError('Scope "$name" already exists');
    }
    final scope = Scope(name);
    _scopes[name] = scope;
    return scope;
  }

  /// Gets an existing scope
  Scope getScope(String name) {
    final scope = _scopes[name];
    if (scope == null) {
      throw ScopeNotFoundException(name);
    }
    return scope;
  }

  /// Removes and disposes a scope
  void disposeScope(String name) {
    final scope = _scopes.remove(name);
    scope?.dispose();
  }

  /// Checks if a scope exists
  bool hasScope(String name) {
    return _scopes.containsKey(name);
  }

  /// Gets all active scope names
  List<String> get scopeNames => _scopes.keys.toList();

  /// Disposes all services and scopes
  void dispose() {
    // Dispose all scopes
    for (final scope in _scopes.values) {
      scope.dispose();
    }
    _scopes.clear();

    // Dispose singletons
    for (final instance in _singletons.values) {
      if (instance is Lazy) {
        instance.dispose();
      } else if (instance is Disposable) {
        instance.dispose();
      }
    }

    _reset();
  }

  void _reset() {
    _singletons.clear();
    _factories.clear();
    _scopes.clear();
  }
}
