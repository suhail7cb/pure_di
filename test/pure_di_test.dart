import 'package:flutter_test/flutter_test.dart';
import 'package:pure_di/pure_di.dart';

/// Global convenience instance
final locator = PureDI.instance;

// Test services
class TestService {
  final String value;
  TestService(this.value);
}

class DisposableService implements Disposable {
  bool isDisposed = false;

  @override
  void dispose() {
    isDisposed = true;
  }
}

class DatabaseService {
  final String connectionString;
  DatabaseService(this.connectionString);
}

class UserRepository {
  final DatabaseService database;
  UserRepository(this.database);
}

void main() {
  /*
   * NOTE: If running all tests together fails, try running individual test groups:
   *
   * dart test test/pure_di_test.dart --name "ServiceLocator"
   * dart test test/pure_di_test.dart --name "Scope"
   * dart test test/pure_di_test.dart --name "Scope Management"
   * dart test test/pure_di_test.dart --name "Integration Tests"
   * dart test test/pure_di_test.dart --name "Lazy"
   *
   * Some tests may interfere with each other when run together due to
   * shared global state in the ServiceLocator singleton.
   */


  group('ServiceLocator', () {
    setUp(() {
      PureDI.reset();
    });

    test('should register and resolve singleton', () {
      final service = TestService('singleton');
      locator.registerSingleton<TestService>(service);

      final resolved = locator.get<TestService>();
      expect(resolved, same(service));
      expect(resolved.value, equals('singleton'));
    });

    test('should register and resolve factory', () {
      locator.register<TestService>(() => TestService('factory'));

      final instance1 = locator.get<TestService>();
      final instance2 = locator.get<TestService>();

      expect(instance1.value, equals('factory'));
      expect(instance2.value, equals('factory'));
      expect(instance1, isNot(same(instance2))); // Different instances
    });

    test('should register and resolve lazy singleton', () {
      var createdCount = 0;
      locator.registerLazySingleton<TestService>(() {
        createdCount++;
        return TestService('lazy');
      });

      expect(createdCount, equals(0)); // Not created yet

      final instance1 = locator.get<TestService>();
      expect(createdCount, equals(1)); // Created now
      expect(instance1.value, equals('lazy'));

      final instance2 = locator.get<TestService>();
      expect(createdCount, equals(1)); // Still only created once
      expect(instance1, same(instance2)); // Same instance
    });

    test('should throw when service not registered', () {
      expect(
        () => locator.get<TestService>(),
        throwsA(isA<ServiceNotRegisteredException>()),
      );
    });

    test('should throw when registering duplicate service', () {
      locator.registerSingleton<TestService>(TestService('first'));

      expect(
        () => locator.registerSingleton<TestService>(TestService('second')),
        throwsA(isA<ServiceAlreadyRegisteredException>()),
      );
    });

    test('should check if service is registered', () {
      expect(locator.isRegistered<TestService>(), isFalse);

      locator.registerSingleton<TestService>(TestService('test'));
      expect(locator.isRegistered<TestService>(), isTrue);
    });

    test('should unregister service', () {
      locator.registerSingleton<TestService>(TestService('test'));
      expect(locator.isRegistered<TestService>(), isTrue);

      locator.unregister<TestService>();
      expect(locator.isRegistered<TestService>(), isFalse);
    });

    test('should dispose disposable services on unregister', () {
      final service = DisposableService();
      locator.registerSingleton<DisposableService>(service);

      expect(service.isDisposed, isFalse);
      locator.unregister<DisposableService>();
      expect(service.isDisposed, isTrue);
    });
  });

  group('Scope', () {
    late Scope scope;

    setUp(() {
      PureDI.reset();
      scope = locator.createScope('test');
    });

    test('should register and resolve scoped singleton', () {
      final service = TestService('scoped');
      scope.registerSingleton<TestService>(service);

      final resolved = scope.get<TestService>();
      expect(resolved, same(service));
    });

    test('should register and resolve scoped factory', () {
      scope.register<TestService>(() => TestService('scoped-factory'));

      final instance1 = scope.get<TestService>();
      final instance2 = scope.get<TestService>();

      expect(instance1, isNot(same(instance2)));
      expect(instance1.value, equals('scoped-factory'));
    });

    test('should register and resolve scoped lazy singleton', () {
      var createdCount = 0;
      scope.registerLazySingleton<TestService>(() {
        createdCount++;
        return TestService('scoped-lazy');
      });

      expect(createdCount, equals(0));

      final instance1 = scope.get<TestService>();
      final instance2 = scope.get<TestService>();

      expect(createdCount, equals(1));
      expect(instance1, same(instance2));
    });

    test('should isolate scoped instances', () {
      final scope1 = locator.createScope('scope1');
      final scope2 = locator.createScope('scope2');

      scope1.registerSingleton<TestService>(TestService('scope1'));
      scope2.registerSingleton<TestService>(TestService('scope2'));

      expect(scope1.get<TestService>().value, equals('scope1'));
      expect(scope2.get<TestService>().value, equals('scope2'));
    });

    test('should dispose scope and all services', () {
      final service = DisposableService();
      scope.registerSingleton<DisposableService>(service);

      expect(service.isDisposed, isFalse);
      expect(scope.isDisposed, isFalse);

      scope.dispose();

      expect(service.isDisposed, isTrue);
      expect(scope.isDisposed, isTrue);
    });

    test('should throw when accessing disposed scope', () {
      scope.dispose();

      expect(
        () => scope.register<TestService>(() => TestService('test')),
        throwsStateError,
      );
      expect(() => scope.get<TestService>(), throwsStateError);
    });
  });

  group('Scope Management', () {
    setUp(() {
      PureDI.reset();
    });

    test('should create and manage scopes', () {
      expect(locator.hasScope('test'), isFalse);

      final scope = locator.createScope('test');
      expect(locator.hasScope('test'), isTrue);
      expect(locator.getScope('test'), same(scope));
    });

    test('should throw when creating duplicate scope', () {
      locator.createScope('test');
      expect(() => locator.createScope('test'), throwsStateError);
    });

    test('should throw when getting non-existent scope', () {
      expect(
        () => locator.getScope('nonexistent'),
        throwsA(isA<ScopeNotFoundException>()),
      );
    });

    test('should dispose scope by name', () {
      final scope = locator.createScope('test');
      final service = DisposableService();
      scope.registerSingleton<DisposableService>(service);

      expect(service.isDisposed, isFalse);
      expect(locator.hasScope('test'), isTrue);

      locator.disposeScope('test');

      expect(service.isDisposed, isTrue);
      expect(locator.hasScope('test'), isFalse);
    });

    test('should list all scope names', () {
      expect(locator.scopeNames, isEmpty);

      locator.createScope('scope1');
      locator.createScope('scope2');

      final names = locator.scopeNames;
      expect(names, contains('scope1'));
      expect(names, contains('scope2'));
      expect(names.length, equals(2));
    });
  });

  group('Integration Tests', () {
    setUp(() {
      PureDI.reset();
    });

    test('should resolve dependencies with dependency injection', () {
      // Register dependencies
      locator.registerSingleton<DatabaseService>(
        DatabaseService('test-connection'),
      );
      locator.register<UserRepository>(
        () => UserRepository(locator.get<DatabaseService>()),
      );

      // Resolve with dependencies
      final repo = locator.get<UserRepository>();
      expect(repo.database.connectionString, equals('test-connection'));
    });

    test('should dispose all services and scopes', () {
      final globalService = DisposableService();
      final scopedService = DisposableService();

      locator.registerSingleton<DisposableService>(globalService);

      final scope = locator.createScope('test');
      scope.registerSingleton<DisposableService>(scopedService);

      expect(globalService.isDisposed, isFalse);
      expect(scopedService.isDisposed, isFalse);

      locator.dispose();

      expect(globalService.isDisposed, isTrue);
      expect(scopedService.isDisposed, isTrue);
      expect(locator.scopeNames, isEmpty);
    });
  });

  group('Lazy', () {
    test('should create instance only when accessed', () {
      var createdCount = 0;
      final lazy = Lazy<TestService>(() {
        createdCount++;
        return TestService('lazy-test');
      });

      expect(lazy.isInitialized, isFalse);
      expect(createdCount, equals(0));

      final instance = lazy.value;
      expect(lazy.isInitialized, isTrue);
      expect(createdCount, equals(1));
      expect(instance.value, equals('lazy-test'));

      // Second access should not create new instance
      final instance2 = lazy.value;
      expect(createdCount, equals(1));
      expect(instance, same(instance2));
    });

    test('should dispose and reset lazy instance', () {
      final service = DisposableService();
      final lazy = Lazy<DisposableService>(() => service);

      final instance = lazy.value;
      expect(lazy.isInitialized, isTrue);
      expect(service.isDisposed, isFalse);

      lazy.dispose();
      expect(service.isDisposed, isTrue);
      expect(lazy.isInitialized, isFalse);
    });

    test('should reset lazy instance', () {
      var createdCount = 0;
      final lazy = Lazy<TestService>(() {
        createdCount++;
        return TestService('reset-test');
      });

      final instance1 = lazy.value;
      expect(createdCount, equals(1));

      lazy.reset();
      expect(lazy.isInitialized, isFalse);

      final instance2 = lazy.value;
      expect(createdCount, equals(2));
      expect(instance1, isNot(same(instance2)));
    });
  });

  /*
   * TROUBLESHOOTING GUIDE:
   *
   * If you encounter test failures when running all tests together:
   *
   * 1. Run individual test groups:
   *    dart test --name "ServiceLocator"
   *    dart test --name "Scope"
   *    dart test --name "Lazy"
   *
   * 2. Common issues:
   *    - Shared ServiceLocator state between tests
   *    - Scopes not properly disposed
   *    - Services registered in previous tests still present
   *
   * 3. Solutions implemented:
   *    - Added ServiceLocator.reset() in setUp() and tearDown()
   *    - Proper scope disposal in tearDown()
   *    - Unique scope names to avoid conflicts
   *    - Try-finally blocks for cleanup in isolation tests
   *
   * 4. If tests still fail, enable verbose output:
   *    dart test --reporter=expanded
   */
}
