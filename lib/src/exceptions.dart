// Custom exceptions for Pure DI
//
// These exceptions provide descriptive error handling for common
// dependency injection issues like missing registrations, duplicates,
// and unknown scopes.

/// Thrown when trying to retrieve a service that hasn't been registered.
///
/// For example, calling `get<MyService>()` without having previously
/// registered `MyService` using `register`, `registerSingleton`, or `registerLazySingleton`.
class ServiceNotRegisteredException implements Exception {
  // The type of service that was attempted to be retrieved
  final Type serviceType;

  // Constructor to initialize with the missing service type
  const ServiceNotRegisteredException(this.serviceType);

  @override
  String toString() => 'Service of type $serviceType is not registered';
}

/// Thrown when attempting to register a service that is already registered.
///
/// This helps prevent accidental overwriting of service registrations,
/// which can lead to unexpected behavior or bugs.
class ServiceAlreadyRegisteredException implements Exception {
  // The type of service that was attempted to be re-registered
  final Type serviceType;

  // Constructor to initialize with the conflicting service type
  const ServiceAlreadyRegisteredException(this.serviceType);

  @override
  String toString() => 'Service of type $serviceType is already registered';
}

/// Thrown when trying to access a scope that doesn't exist.
///
/// Useful when calling `getScope(name)` or `disposeScope(name)`
/// with an invalid or unregistered scope name.
class ScopeNotFoundException implements Exception {
  // The name of the scope that was not found
  final String scopeName;

  // Constructor to initialize with the missing scope name
  const ScopeNotFoundException(this.scopeName);

  @override
  String toString() => 'Scope "$scopeName" not found';
}
