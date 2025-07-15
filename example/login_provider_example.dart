import 'package:kiss_auth/kiss_login.dart';
import 'package:kiss_pocketbase_auth/kiss_pocketbase_auth.dart';

void main() async {
  // Setup the login provider
  final loginProvider = PocketBaseLoginProvider(
    baseUrl: 'http://localhost:8090',
  );

  // Example 1: Login with email and password
  print('=== Login with Email/Password ===');
  final emailResult = await loginProvider.authenticate(
    const EmailPasswordCredentials(
      email: 'test@example.com',
      password: 'testpassword123',
    ),
  );

  if (emailResult.isSuccess) {
    print('✅ Login successful!');
    print('User ID: ${emailResult.user?.userId}');
    print('Email: ${emailResult.user?.email}');
    print('Token: ${emailResult.accessToken?.substring(0, 20)}...');
  } else {
    print('❌ Login failed: ${emailResult.error}');
    print('Error code: ${emailResult.errorCode}');
  }

  // Example 2: Login with username and password
  print('\n=== Login with Username/Password ===');
  final usernameResult = await loginProvider.authenticate(
    const UsernamePasswordCredentials(
      username: 'testuser',
      password: 'testpassword123',
    ),
  );

  if (usernameResult.isSuccess) {
    print('✅ Login successful!');
    print('User ID: ${usernameResult.user?.userId}');
    print('Username: ${usernameResult.user?.username}');
  } else {
    print('❌ Login failed: ${usernameResult.error}');
  }

  // Example 3: Create a new user (not supported via interface, so just show a message)
  print('\n=== Create New User ===');
  print('User creation is not supported via the LoginProvider interface.');

  // Example 4: Logout
  if (emailResult.isSuccess && emailResult.accessToken != null) {
    print('\n=== Logout ===');
    final loggedOut = await loginProvider.logout(emailResult.accessToken!);
    print(loggedOut ? '✅ Logged out successfully' : '❌ Logout failed');
  }

  // Example 5: Token validation
  if (emailResult.isSuccess && emailResult.accessToken != null) {
    print('\n=== Token Validation ===');
    final isValid = await loginProvider.isTokenValid(emailResult.accessToken!);
    print('Token valid: ${isValid ? '✅ Yes' : '❌ No'}');

    final userId =
        await loginProvider.getUserIdFromToken(emailResult.accessToken!);
    print('User ID from token: $userId');
  }

  // Example 6: OAuth Authentication
  print('\n=== OAuth Authentication ===');
  try {
    final oauthResult = await loginProvider.authenticate(
      const OAuthCredentials(
        provider: 'google',
        accessToken: 'mock_auth_code_from_google_oauth',
        idToken: 'mock_id_token',
        // scope: ['openid', 'email', 'profile'], // Not used in interface
      ),
    );

    if (oauthResult.isSuccess) {
      print('✅ OAuth login successful!');
      print('User ID: ${oauthResult.user?.userId}');
      print('Provider: google');
    } else {
      print('❌ OAuth login failed: ${oauthResult.error}');
    }
  } on Exception catch (e) {
    print('❌ OAuth example failed (expected with mock data): $e');
  }

  // Example 7: API Key Authentication
  print('\n=== API Key Authentication ===');
  try {
    // Note: This requires a valid JWT token as API key or custom implementation
    final apiKeyResult = await loginProvider.authenticate(
      const ApiKeyCredentials(
        apiKey: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.mock_jwt_token.signature',
        keyId: 'api_key_123',
      ),
    );

    if (apiKeyResult.isSuccess) {
      print('✅ API key authentication successful!');
      print('User ID: ${apiKeyResult.user?.userId}');
      print('Key ID: api_key_123');
    } else {
      print('❌ API key authentication failed: ${apiKeyResult.error}');
    }
  } on Exception catch (e) {
    print('❌ API key example failed (expected with mock data): $e');
  }

  // Example 8: Anonymous authentication (should fail)
  print('\n=== Anonymous Authentication ===');
  try {
    final anonymousResult = await loginProvider.authenticate(
      const AnonymousCredentials(),
    );
    if (anonymousResult.isSuccess) {
      print('✅ Anonymous login successful!');
    } else {
      print('❌ Anonymous login failed (expected): ${anonymousResult.error}');
    }
  } on Exception catch (e) {
    print('❌ Anonymous authentication failed (expected): $e');
  }

  // Example 9: Password reset (not supported via interface)
  print('\n=== Password Reset Demo ===');
  print('Password reset is not supported via the LoginProvider interface.');

  // Example 10: Provider info
  print('\n=== Provider Info ===');
  final providerInfo = loginProvider.getProviderInfo();
  print('Provider: ${providerInfo['name']}');
  print('Service: ${providerInfo['service']}');
  print('Capabilities: ${providerInfo['capabilities']}');
  print('Unsupported: ${providerInfo['unsupported']}');
  print(
      'OAuth Providers: ${(providerInfo['oauth_providers'] as List?)?.take(5).join(', ')}...');
  print('Base URL: ${providerInfo['baseUrl']}');
}
