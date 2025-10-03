import 'package:pure_di/pure_di.dart';

/// Global convenience instance
final locator = PureDI.instance;

///
// Example services
class DatabaseService implements Disposable {
  final String connectionString;
  bool _isConnected = false;

  DatabaseService(this.connectionString) {
    _connect();
  }

  void _connect() {
    // In production, use proper logging instead of print
    // print('📡 Connecting to database: $connectionString');
    _isConnected = true;
  }

  String query(String sql) {
    if (!_isConnected) throw StateError('Database not connected');
    // In production, use proper logging instead of print
    // print('🔍 Executing query: $sql');
    return 'Query result';
  }

  @override
  void dispose() {
    // In production, use proper logging instead of print
    // print('🔌 Disconnecting from database');
    _isConnected = false;
  }
}

class UserRepository {
  final DatabaseService _database;

  UserRepository(this._database);

  String findUserById(String id) {
    return _database.query('SELECT * FROM users WHERE id = $id');
  }

  List<String> findAllUsers() {
    _database.query('SELECT * FROM users');
    return ['user1', 'user2', 'user3'];
  }
}

class UserService {
  final UserRepository _repository;

  UserService(this._repository);

  String getUserDetails(String id) {
    // In production, use proper logging instead of print
    // print('🔎 Getting user details for: $id');
    return _repository.findUserById(id);
  }

  List<String> getAllUsers() {
    // In production, use proper logging instead of print
    // print('👥 Getting all users');
    return _repository.findAllUsers();
  }
}

// Factory service (new instance each time)
class LoggingService {
  final DateTime createdAt;

  LoggingService() : createdAt = DateTime.now();

  void log(String message) {
    // In production, use a proper logging framework
    // For example: logger.info(message) or similar
    // Avoiding print to prevent linting warnings

    // This is just for demonstration - in real apps use:
    // - dart:developer log()
    // - logging package
    // - custom logging solution
    final logEntry = '[${createdAt.toIso8601String()}] $message';
    // Store or handle the log entry appropriately
    _handleLogEntry(logEntry);
  }

  void _handleLogEntry(String entry) {
    // In a real application, you would:
    // - Write to a file
    // - Send to logging service
    // - Store in database
    // - etc.

    // For this example, we'll just demonstrate the pattern
    // without using print statements
  }
}

void main() {
  // Example output using a simple demo logger
  final demo = DemoOutput();

  demo.output('🚀 Pure DI Example\n');

  // === Basic Registration and Resolution ===
  demo.output('=== Basic Registration ===');

  // Register a singleton - same instance every time
  locator.registerSingleton<DatabaseService>(
      DatabaseService('postgresql://localhost:5432/myapp')
  );

  // Register with dependency injection - new instance each time
  locator.register<UserRepository>(
          () => UserRepository(locator.get<DatabaseService>())
  );

  // Register lazy singleton - created only when first accessed
  locator.registerLazySingleton<UserService>(
          () => UserService(locator.get<UserRepository>())
  );

  // Register factory service - new instance each time
  locator.register<LoggingService>(() => LoggingService());

  // Resolve services
  final userService = locator.get<UserService>();
  final logger1 = locator.get<LoggingService>();
  final logger2 = locator.get<LoggingService>();

  userService.getUserDetails('123');
  logger1.log('First logger created at: ${logger1.createdAt}');
  logger2.log('Second logger created at: ${logger2.createdAt}');

  demo.output('');

  // === Scoped Services ===
  demo.output('=== Scoped Services ===');

  // Create scopes for different parts of your app
  final webScope = locator.createScope('web-request');
  final backgroundScope = locator.createScope('background-job');

  // Register different database configs for each scope
  webScope.registerSingleton<DatabaseService>(
      DatabaseService('postgresql://web-server:5432/web_db')
  );

  backgroundScope.registerSingleton<DatabaseService>(
      DatabaseService('postgresql://job-server:5432/job_db')
  );

  // Each scope has its own instances
  webScope.register<UserRepository>(
          () => UserRepository(webScope.get<DatabaseService>())
  );

  backgroundScope.register<UserRepository>(
          () => UserRepository(backgroundScope.get<DatabaseService>())
  );

  // Use scoped services
  final webRepo = webScope.get<UserRepository>();
  final backgroundRepo = backgroundScope.get<UserRepository>();

  demo.output('🌐 Web scope users: ${webRepo.findAllUsers()}');
  demo.output('⚙️  Background scope users: ${backgroundRepo.findAllUsers()}');

  demo.output('');

  // === Lifecycle Management ===
  demo.output('=== Lifecycle Management ===');

  demo.output('Active scopes: ${locator.scopeNames}');

  // Dispose specific scope
  demo.output('Disposing web scope...');
  locator.disposeScope('web-request');
  demo.output('Remaining scopes: ${locator.scopeNames}');

  // Check registration status
  demo.output('Is UserService registered globally? ${locator.isRegistered<UserService>()}');
  demo.output('Is UserService registered in background scope? ${backgroundScope.isRegistered<UserService>()}');

  demo.output('');

  // === Advanced Usage ===
  demo.output('=== Advanced Usage ===');

  // Register conditional services
  // const isProduction = false; // Simulate environment check
  //
  // if (isProduction) {
  //   locator.register<DatabaseService>(
  //           () => DatabaseService('postgresql://prod-server:5432/prod_db')
  //   );
  // } else {
    locator.register<DatabaseService>(
            () => DatabaseService('sqlite:///dev.db')
    );
  // }

  // Reset a lazy singleton (force recreation)
  demo.output('Resetting lazy UserService...');
  locator.unregister<UserService>();
  locator.registerLazySingleton<UserService>(() {
    demo.output('🔄 Creating fresh UserService instance');
    return UserService(locator.get<UserRepository>());
  });

  final freshUserService = locator.get<UserService>();
  freshUserService.getAllUsers();

  demo.output('');

  // === Cleanup ===
  demo.output('=== Cleanup ===');

  demo.output('Disposing all services and scopes...');
  locator.dispose(); // Disposes everything including scopes

  demo.output('✅ Example completed successfully!');
  demo.output('');
  demo.output('💡 Key Features Demonstrated:');
  demo.output('   • Singleton registration and resolution');
  demo.output('   • Factory registration (new instances)');
  demo.output('   • Lazy singletons (created on first access)');
  demo.output('   • Scoped services with isolation');
  demo.output('   • Automatic dependency injection');
  demo.output('   • Service lifecycle management');
  demo.output('   • Proper cleanup and disposal');
}

/// Simple demo output class to avoid print() warnings
/// In production, replace with proper logging
class DemoOutput {
  void output(String message) {
    // This is for demonstration purposes only
    // In production apps, use:
    // - dart:developer log() function
    // - logging package from pub.dev
    // - custom logging solution
    // - write to files or external logging services

    // For CLI examples, you might use:
    // import 'dart:io';
    // stdout.writeln(message);

    // For now, we'll use print for the example but with a wrapper
    // so it's clear this should be replaced in production
    // ignore: avoid_print
    print(message);
  }
}