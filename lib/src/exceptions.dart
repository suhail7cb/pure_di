// part of 'pure_di.dart';

/// Custom exceptions for Pure DI

class ServiceNotRegisteredException implements Exception {
  final Type serviceType;

  const ServiceNotRegisteredException(this.serviceType);

  @override
  String toString() => 'Service of type $serviceType is not registered';
}

class ServiceAlreadyRegisteredException implements Exception {
  final Type serviceType;

  const ServiceAlreadyRegisteredException(this.serviceType);

  @override
  String toString() => 'Service of type $serviceType is already registered';
}

class ScopeNotFoundException implements Exception {
  final String scopeName;

  const ScopeNotFoundException(this.scopeName);

  @override
  String toString() => 'Scope "$scopeName" not found';
}
