# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2024-10-02

### Added
- Initial release of Pure DI
- Service locator pattern implementation
- Singleton service registration with `registerSingleton<T>()`
- Factory service registration with `register<T>()`
- Lazy singleton registration with `registerLazySingleton<T>()`
- Service resolution with `get<T>()`
- Scoped service containers with `createScope()` and `getScope()`
- Automatic disposal of services implementing `Disposable` interface
- Type-safe service registration and resolution
- Manual service unregistration with `unregister<T>()`
- Scope lifecycle management with `disposeScope()`
- Global service locator cleanup with `dispose()`
- Zero external dependencies - pure Dart implementation
- Comprehensive test suite covering all features
- Complete documentation and examples
- Support for Dart SDK >=2.17.0 <4.0.0

### Features
- **Service Locator Pattern**: Simple and intuitive API for dependency injection
- **Lazy Singletons**: Instances created only when first accessed for performance
- **Scoped Services**: Manage service lifecycles in isolated containers
- **Automatic Cleanup**: Built-in disposal management for resource cleanup
- **Type Safety**: Full type safety with generic constraints
- **Cross Platform**: Works on CLI, server-side, and Flutter applications
- **Lightweight**: Minimal footprint with fast performance

### Documentation
- Comprehensive README with installation guide
- API reference documentation
- Usage examples and best practices
- Architecture examples for different use cases
- Testing guidelines and examples
- Future roadmap with planned features

[0.0.1]: https://github.com/suhail7cb/pure_di/releases/tag/v1.0.0