import 'package:kiss_auth/kiss_authorization.dart';
import 'package:kiss_auth/kiss_login.dart';
import 'package:kiss_dependencies/kiss_dependencies.dart';
import 'package:kiss_pocketbase_auth/kiss_pocketbase_auth.dart';

/// Setup function type definition
typedef SetupFunction = void Function();

/// Setup dependencies for PocketBase providers
void setupPocketBaseProviders() {
  const baseUrl = 'http://localhost:8090'; // Default PocketBase URL

  register<LoginProvider>(
    () => PocketBaseLoginProvider(baseUrl: baseUrl),
  );

  register<AuthValidator>(
    () => PocketBaseAuthValidator(baseUrl: baseUrl),
  );

  // Register in-memory AuthorizationProvider (PocketBase doesn't have built-in RBAC)
  // In production, you'd implement a PocketBase-specific authorization provider
  register<AuthorizationProvider>(InMemoryAuthorizationProvider.new);

  register<LoginService>(
    () => LoginService(resolve<LoginProvider>()),
  );

  register<AuthorizationService>(
    () => AuthorizationService(
      resolve<AuthValidator>(),
      resolve<AuthorizationProvider>(),
    ),
  );

  _setupPocketBaseTestData();
}

/// Setup dependencies for InMemory providers (fallback for testing)
void setupInMemoryProviders() {
  const jwtSecret = 'default-test-secret';

  register<LoginProvider>(InMemoryLoginProvider.new);
  register<AuthValidator>(() => JwtAuthValidator.hmac(jwtSecret));
  register<AuthorizationProvider>(InMemoryAuthorizationProvider.new);
  register<LoginService>(() => LoginService(resolve<LoginProvider>()));
  register<AuthorizationService>(
    () => AuthorizationService(
      resolve<AuthValidator>(),
      resolve<AuthorizationProvider>(),
    ),
  );

  _setupInMemoryTestData();
}

/// Setup test authorization data for PocketBase users
/// Note: This sets up role/permission data since PocketBase doesn't have built-in RBAC
void _setupPocketBaseTestData() {
  (resolve<AuthorizationProvider>() as InMemoryAuthorizationProvider)
    // Admin user (should correspond to a PocketBase user)
    ..setUserData(
      'pb_admin_user_id', // This should match actual PocketBase user ID
      const AuthorizationData(
        userId: 'pb_admin_user_id',
        roles: ['admin', 'manager'],
        permissions: ['user:create', 'user:delete', 'user:read', 'user:update'],
        attributes: {'provider': 'pocketbase', 'level': 'admin'},
      ),
    )
    // Regular user
    ..setUserData(
      'pb_user_001_id',
      const AuthorizationData(
        userId: 'pb_user_001_id',
        roles: ['user'],
        permissions: ['user:read'],
        attributes: {'provider': 'pocketbase', 'level': 'user'},
      ),
    )
    // Editor user
    ..setUserData(
      'pb_editor_user_id',
      const AuthorizationData(
        userId: 'pb_editor_user_id',
        roles: ['user', 'editor'],
        permissions: ['user:read', 'content:edit', 'content:publish'],
        attributes: {'provider': 'pocketbase', 'level': 'editor'},
      ),
    );
}

/// Setup test data for InMemory providers (same as kiss_auth reference)
void _setupInMemoryTestData() {
  (resolve<AuthorizationProvider>() as InMemoryAuthorizationProvider)
    ..setUserData(
      'user_admin',
      const AuthorizationData(
        userId: 'user_admin',
        roles: ['admin', 'manager'],
        permissions: ['user:create', 'user:delete', 'user:read', 'user:update'],
        attributes: {'department': 'IT', 'level': 'senior'},
      ),
    )
    ..setUserData(
      'user_001',
      const AuthorizationData(
        userId: 'user_001',
        roles: ['user'],
        permissions: ['user:read'],
        attributes: {'department': 'Sales', 'level': 'junior'},
      ),
    )
    ..setUserData(
      'user_002',
      const AuthorizationData(
        userId: 'user_002',
        roles: ['user', 'editor'],
        permissions: ['user:read', 'content:edit', 'content:publish'],
        attributes: {'department': 'Marketing', 'level': 'mid'},
      ),
    );
}