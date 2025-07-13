# Kiss PocketBase Auth

A PocketBase authentication provider for the [kiss_auth](https://github.com/WAMF/kiss_auth) package.

## Features

- Implements the `AuthValidator` interface from kiss_auth
- Token validation using PocketBase's auth refresh endpoint
- Password authentication support
- Access to PocketBase user record data
- Proper error handling with custom exceptions

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  kiss_pocketbase_auth:
    git:
      url: https://github.com/WAMF/kiss_pocketbase_auth.git
```

## Usage

```dart
import 'package:kiss_pocketbase_auth/kiss_pocketbase_auth.dart';

// Create validator
final validator = PocketBaseAuthValidator(baseUrl: 'http://localhost:8090');

// Authenticate with password
final authData = await validator.authenticateWithPassword(
  identity: 'user@example.com',
  password: 'password',
);

// Access user data
print(authData.userId);
print(authData.email);
print(authData.username);
print(authData.verified);

// Validate existing token
final token = validator.extractToken(authData);
final validatedData = await validator.validateToken(token!);
```

## Integration Tests

This package includes integration tests that run against a real PocketBase instance using Docker Compose.

### Prerequisites

- Docker and Docker Compose installed
- Bash shell (for running scripts)

### Running Tests

```bash
# Clean up any existing containers first (recommended)
./scripts/cleanup_test_containers.sh

# Run all tests in a single container session
dart test test/all_tests.dart

# Or use the test-all script
./scripts/test-all.sh

# Or run individual test files (they'll share container if already running)
dart test test/pocketbase_auth_test.dart
dart test test/integration/pocketbase_auth_validator_test.dart
```

**Note:** The tests use a singleton pattern to manage the Docker container. If a container is already running, tests will reuse it. This prevents conflicts when running multiple test files.

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

Main authentication validator class.

#### Constructor

```dart
PocketBaseAuthValidator({required String baseUrl})
```

#### Methods

- `Future<AuthenticationData> validateToken(String token)` - Validates a token and returns auth data
- `Future<PocketBaseAuthenticationData> authenticateWithPassword({required String identity, required String password, String collection = 'users'})` - Authenticates with username/email and password
- `String? extractToken(PocketBaseAuthenticationData authData)` - Extracts token from auth data

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