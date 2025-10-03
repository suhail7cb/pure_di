/// Pure DI - A lightweight dependency injection library for Dart
///
/// This library provides a service locator pattern implementation with support for:
/// - Lazy singletons (created only when first accessed)
/// - Scoped instances (for managing lifecycles in groups)
/// - Simple and intuitive API
/// - Zero external dependencies
library pure_di;

export 'src/pure_di_locator.dart';
export 'src/scope.dart';
export 'src/lazy.dart';
export 'src/exceptions.dart';
