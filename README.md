# Kiss PocketBase Auth

A PocketBase authentication provider for the [kiss_auth](https://github.com/WAMF/kiss_auth) package.

## Features

- Implements the `AuthValidator` interface from kiss_auth
- Token validation using PocketBase's auth refresh endpoint
- Password authentication support
- Access to PocketBase user record data
- Proper error handling with custom exceptions

## Usage

### LoginProvider (Recommended)

```dart
import 'package:kiss_pocketbase_auth/kiss_pocketbase_auth.dart';
import 'package:kiss_auth/kiss_login.dart';

// Create a login provider
final loginProvider = PocketBaseLoginProvider(
  baseUrl: 'http://localhost:8090',
);

// Login with email and password
final result = await loginProvider.authenticate(
  EmailPasswordCredentials(
    email: 'user@example.com',
    password: 'password123',
  ),
);

if (result.isSuccess) {
  print('User ID: ${result.user?.userId}');
  print('Email: ${result.user?.email}');
  print('Token: ${result.accessToken}');
} else {
  print('Login failed: ${result.error}');
}

// Username/password authentication
final usernameResult = await loginProvider.authenticate(
  UsernamePasswordCredentials(
    username: 'johndoe',
    password: 'password123',
  ),
);

// OAuth authentication
final oauthResult = await loginProvider.authenticate(
  OAuthCredentials(
    provider: 'google',
    accessToken: 'auth_code_from_google', // OAuth2 authorization code
  ),
);

// API key authentication  
final apiResult = await loginProvider.authenticate(
  ApiKeyCredentials(
    apiKey: 'your_jwt_token',
    keyId: 'optional_key_id',
  ),
);

// Token validation
final isValid = await loginProvider.isTokenValid(result.accessToken!);

// Refresh token
final refreshResult = await loginProvider.refreshToken(result.accessToken!);

// Logout
await loginProvider.logout(result.accessToken!);
```

### Authentication Validator (Token validation only)

```dart
import 'package:kiss_pocketbase_auth/kiss_pocketbase_auth.dart';

// Create validator for token validation
final validator = PocketBaseAuthValidator(baseUrl: 'http://localhost:8090');

// Validate existing token
final authData = await validator.validateToken(token);
print('User ID: ${authData.userId}');
print('Email: ${(authData as PocketBaseAuthenticationData).email}');
print('Verified: ${(authData as PocketBaseAuthenticationData).verified}');
```

## Example App

A complete Flutter example app demonstrating login/signup flow and claims inspection is available in the `example/` directory.

```bash
cd example/kiss_pocketbase_example
flutter run
```

See [example/README.md](example/README.md) for more details.

## Integration Tests

This package includes integration tests that run against a real PocketBase instance using Docker Compose.

### Prerequisites

- Docker and Docker Compose installed
- Bash shell (for running scripts)

### Running Tests

```bash
# Clean up any existing containers first (recommended)
./scripts/cleanup_test_containers.sh

# Run tests with Docker
./scripts/test-all.sh

# Or run tests manually
dart test
```

**Note:** Integration tests require a running PocketBase instance. The test scripts will automatically start and manage Docker containers.

### Available Scripts

All scripts are located in the `scripts/` directory and are executable:

```bash
./scripts/install.sh          # Install dependencies
./scripts/analyze.sh          # Run static analysis
./scripts/fix.sh              # Apply automatic fixes
./scripts/format.sh           # Format code
./scripts/test.sh             # Run unit tests only
./scripts/test-integration.sh # Run integration tests only
./scripts/test-all.sh         # Run all tests with Docker
./scripts/docker-up.sh        # Start PocketBase container
./scripts/docker-down.sh      # Stop PocketBase container
./scripts/clean.sh            # Clean up Docker volumes and containers
./scripts/cleanup_test_containers.sh # Clean up test containers specifically
./scripts/check.sh            # Run all checks and tests
```

### Quick Start for Development

```bash
# Setup and run all checks
./scripts/check.sh

# Or step by step:
./scripts/install.sh    # Install dependencies
./scripts/analyze.sh    # Check for issues
./scripts/test-all.sh   # Run tests with PocketBase
```

## API Reference

### PocketBaseAuthValidator

Authentication validator class for token validation.

#### Constructor

```dart
PocketBaseAuthValidator({
  required String baseUrl,
  String collection = 'users',
})
```

#### Methods

- `Future<AuthenticationData> validateToken(String token)` - Validates a token and returns auth data

### PocketBaseLoginProvider

Login provider implementation supporting multiple authentication methods.

#### Constructor

```dart
PocketBaseLoginProvider({
  required String baseUrl,
  String collection = 'users',
  void Function(String type, LoginCredentials credentials)? onUnsupportedCredentialType,
})
```

#### Methods

- `Future<LoginResult> authenticate(LoginCredentials credentials)` - Authenticates with various credential types
- `Future<LoginResult> refreshToken(String refreshToken)` - Refreshes an authentication token
- `Future<bool> logout(String token)` - Logs out and clears the auth store
- `Future<bool> isTokenValid(String token)` - Validates if a token is still valid
- `Future<String?> getUserIdFromToken(String token)` - Extracts user ID from a JWT token
- `Map<String, dynamic> getProviderInfo()` - Returns provider capabilities and configuration
- `Future<LoginResult> createUser({required String email, required String password, Map<String, dynamic>? additionalData})` - Creates a new user account

#### Supported Credential Types

- `EmailPasswordCredentials` - Email and password authentication
- `UsernamePasswordCredentials` - Username and password authentication
- `OAuthCredentials` - OAuth2 authentication (Google, Facebook, GitHub, etc.)
- `ApiKeyCredentials` - API key authentication (requires JWT format)
- `AnonymousCredentials` - Not supported by PocketBase

### PocketBaseAuthenticationData

Extended authentication data with PocketBase-specific fields.

#### Properties

- `String userId` - User ID
- `Map<String, dynamic> claims` - Authentication claims
- `Map<String, dynamic> record` - User record data
- `String? collectionId` - Collection ID
- `String? collectionName` - Collection name
- `String? email` - User email
- `String? username` - Username
- `bool verified` - Email verification status
- `DateTime? created` - Record creation date
- `DateTime? updated` - Record update date

#### Methods

- `T? getRecordField<T>(String fieldName)` - Get custom field from user record

## License

MIT License - see LICENSE file for details.
