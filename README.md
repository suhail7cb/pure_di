# Pure DI

A lightweight, pure Dart dependency injection library with **zero external dependencies**. Perfect for Dart CLI applications, server-side apps, or any Dart-only environment where you need clean dependency management without the overhead of larger DI frameworks.

## ✨ Features

- **🔧 Service Locator Pattern** - Simple and intuitive API
- **🦥 Lazy Singletons** - Instances created only when first accessed  
- **🎯 Scoped Services** - Manage lifecycles in groups or nested contexts
- **🚀 Zero Dependencies** - Pure Dart with no external packages
- **🧹 Automatic Cleanup** - Built-in disposal management for services
- **🔒 Type Safe** - Full type safety with generic constraints
- **🪶 Lightweight** - Minimal footprint and fast performance
- **📱 Cross Platform** - Works on all Dart platforms (CLI, server, Flutter)

## 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  pure_di: <latest_version>
```

### Basic Usage

```dart
import 'package:pure_di/pure_di.dart';

// Define your services
class DatabaseService {
  void query(String sql) => print('Executing: $sql');
}

class UserRepository {
  final DatabaseService database;
  UserRepository(this.database);
  
  void findUser(String id) => database.query('SELECT * FROM users WHERE id = $id');
}

void main() {
  // Register services
  locator.registerSingleton<DatabaseService>(DatabaseService());
  locator.register<UserRepository>(() => UserRepository(locator.get<DatabaseService>()));
  
  // Use services
  final repo = locator.get<UserRepository>();
  repo.findUser('123');
  
  // Cleanup when done
  locator.dispose();
}
```

## 📚 Registration Types

### Singleton
Register an instance that will be reused every time:

```dart
locator.registerSingleton<DatabaseService>(DatabaseService('connection-string'));

final db1 = locator.get<DatabaseService>();
final db2 = locator.get<DatabaseService>();
// db1 and db2 are the same instance
```

### Factory  
Register a factory function that creates a new instance each time:

```dart
locator.register<LoggingService>(() => LoggingService());

final logger1 = locator.get<LoggingService>();
final logger2 = locator.get<LoggingService>();
// logger1 and logger2 are different instances
```

### Lazy Singleton
Register a factory that creates an instance only when first accessed:

```dart
locator.registerLazySingleton<ExpensiveService>(() {
  print('Creating expensive service...');
  return ExpensiveService();
});

// No output yet - service not created
final service = locator.get<ExpensiveService>(); 
// Now prints: "Creating expensive service..."

final service2 = locator.get<ExpensiveService>();
// service and service2 are the same instance, no recreation
```

## 🎯 Scoped Services

Create isolated service containers for different parts of your application:

```dart
// Create scopes
final webScope = locator.createScope('web-request');
final jobScope = locator.createScope('background-job');

// Register different configurations per scope
webScope.registerSingleton<DatabaseService>(DatabaseService('web-db'));
jobScope.registerSingleton<DatabaseService>(DatabaseService('job-db'));

// Each scope maintains its own instances
final webDb = webScope.get<DatabaseService>();
final jobDb = jobScope.get<DatabaseService>();

// Dispose scopes when done
locator.disposeScope('web-request');
locator.disposeScope('background-job');
```

## 🧹 Lifecycle Management

### Automatic Disposal
Services implementing `Disposable` are automatically cleaned up:

```dart
class DatabaseService implements Disposable {
  @override
  void dispose() {
    print('Closing database connection');
  }
}

locator.registerSingleton<DatabaseService>(DatabaseService());
locator.dispose(); // Automatically calls dispose() on DatabaseService
```

### Manual Service Management

```dart
// Check if registered
if (locator.isRegistered<UserService>()) {
  final service = locator.get<UserService>();
}

// Unregister single service
locator.unregister<UserService>();

// Reset entire service locator
ServiceLocator.reset();
```

## 🏗️ Architecture Examples

### Dependency Injection Chain

```dart
// Bottom layer
locator.registerSingleton<DatabaseService>(DatabaseService());

// Middle layer - depends on database
locator.register<UserRepository>(() => 
  UserRepository(locator.get<DatabaseService>()));

// Top layer - depends on repository  
locator.registerLazySingleton<UserService>(() =>
  UserService(locator.get<UserRepository>()));

// All dependencies automatically resolved
final userService = locator.get<UserService>();
```

### Request-Scoped Services (Web Server)

```dart
void handleRequest(HttpRequest request) {
  final requestScope = locator.createScope('request-${request.id}');
  
  // Register request-specific services
  requestScope.registerSingleton<RequestContext>(RequestContext(request));
  requestScope.register<UserController>(() => 
    UserController(requestScope.get<RequestContext>()));
  
  try {
    final controller = requestScope.get<UserController>();
    controller.handleRequest();
  } finally {
    // Automatic cleanup of all request-scoped services
    locator.disposeScope('request-${request.id}');
  }
}
```

## 🔧 API Reference

### ServiceLocator

| Method | Description |
|--------|-------------|
| `register<T>(factory)` | Register a factory function |
| `registerSingleton<T>(instance)` | Register a singleton instance |
| `registerLazySingleton<T>(factory)` | Register a lazy singleton |
| `get<T>()` | Resolve a service instance |
| `isRegistered<T>()` | Check if service is registered |
| `unregister<T>()` | Remove and dispose a service |
| `createScope(name)` | Create a new scope |
| `getScope(name)` | Get existing scope |
| `disposeScope(name)` | Dispose a scope |
| `dispose()` | Dispose all services and scopes |

### Scope

| Method | Description |
|--------|-------------|
| `register<T>(factory)` | Register scoped factory |
| `registerSingleton<T>(instance)` | Register scoped singleton |
| `registerLazySingleton<T>(factory)` | Register scoped lazy singleton |
| `get<T>()` | Resolve from this scope |
| `isRegistered<T>()` | Check registration in scope |
| `dispose()` | Dispose all services in scope |

## ✅ Best Practices

### 1. **Register Early, Use Late**
```dart
void main() {
  // Register all dependencies at startup
  setupDependencies();
  
  // Use throughout application
  runApplication();
  
  // Cleanup at shutdown
  locator.dispose();
}
```

### 2. **Use Factories for Stateful Services**
```dart
// Good - new instance each time
locator.register<HttpClient>(() => HttpClient());

// Avoid - shared mutable state
locator.registerSingleton<HttpClient>(HttpClient());
```

### 3. **Scope by Lifecycle**
```dart
// Application-wide services
locator.registerSingleton<ConfigService>(ConfigService());

// Request-scoped services
final scope = locator.createScope('request');
scope.register<RequestHandler>(() => RequestHandler());
```

### 4. **Implement Disposable for Resources**
```dart
class FileService implements Disposable {
  final File _file;
  
  @override
  void dispose() {
    _file.close();
  }
}
```

## 🧪 Testing

Pure DI makes testing easy with its reset functionality:

```dart
void main() {
  group('UserService Tests', () {
    setUp(() {
      ServiceLocator.reset(); // Clean slate for each test
      
      // Register test dependencies
      locator.registerSingleton<DatabaseService>(MockDatabaseService());
    });
    
    test('should find user by id', () {
      locator.register<UserRepository>(() => 
        UserRepository(locator.get<DatabaseService>()));
      
      final repo = locator.get<UserRepository>();
      // Test implementation...
    });
  });
}
```

## 🗺️ Future Roadmap

### Version 1.1.0
- **Named Instances** - Register multiple implementations of the same type
  ```dart
  locator.registerSingleton<DatabaseService>(primaryDb, instanceName: 'primary');
  locator.registerSingleton<DatabaseService>(cacheDb, instanceName: 'cache');
  ```

### Version 1.2.0  
- **Async Factories** - Support for asynchronous service creation
  ```dart
  locator.registerAsync<ApiService>(() async {
    final config = await loadConfig();
    return ApiService(config);
  });
  ```

### Version 1.3.0
- **Lifecycle Hooks** - Custom initialization and disposal logic
  ```dart
  locator.registerSingleton<Service>(
    Service(),
    onInit: (service) => service.initialize(),
    onDispose: (service) => service.cleanup(),
  );
  ```

### Version 1.4.0
- **Development Tools** - Optional diagnostics and logging
  ```dart
  // Debug mode only
  locator.enableDiagnostics();
  locator.printDependencyGraph();
  ```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/pure_di.git
cd pure_di

# Install dependencies
dart pub get

# Run tests
dart test

# Run example
dart run example/main.dart
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

- 📧 **Issues**: [GitHub Issues](https://github.com/yourusername/pure_di/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/pure_di/discussions)
- ⭐ **Star this repo** if you find it useful!

---

Made with ❤️ for the Dart community