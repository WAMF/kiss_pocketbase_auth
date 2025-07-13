import 'package:kiss_pocketbase_auth/kiss_pocketbase_auth.dart';

void main() async {
  // Setup the login provider
  final loginProvider = PocketBaseLoginProvider(
    baseUrl: 'http://localhost:8090',
  );
  
  final loginService = LoginService(loginProvider);
  
  // Example 1: Login with email and password
  print('=== Login with Email/Password ===');
  final emailResult = await loginService.loginWithPassword(
    'test@example.com',
    'testpassword123',
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
  final usernameResult = await loginService.loginWithUsername(
    'testuser',
    'testpassword123',
  );
  
  if (usernameResult.isSuccess) {
    print('✅ Login successful!');
    print('User ID: ${usernameResult.user?.userId}');
    print('Username: ${usernameResult.user?.username}');
  } else {
    print('❌ Login failed: ${usernameResult.error}');
  }
  
  // Example 3: Create a new user
  print('\n=== Create New User ===');
  final createResult = await loginProvider.createUser(
    email: 'newuser@example.com',
    password: 'newpassword123',
    username: 'newuser',
    name: 'New User',
  );
  
  if (createResult.isSuccess) {
    print('✅ User created and logged in!');
    print('User ID: ${createResult.user?.userId}');
    print('Email: ${createResult.user?.email}');
    
    // Example 4: Logout
    print('\n=== Logout ===');
    final loggedOut = await loginService.logout(createResult.accessToken!);
    print(loggedOut ? '✅ Logged out successfully' : '❌ Logout failed');
  } else {
    print('❌ User creation failed: ${createResult.error}');
  }
  
  // Example 5: Token validation
  if (emailResult.isSuccess && emailResult.accessToken != null) {
    print('\n=== Token Validation ===');
    final isValid = await loginService.isTokenValid(emailResult.accessToken!);
    print('Token valid: ${isValid ? '✅ Yes' : '❌ No'}');
    
    final userId = await loginService.getUserIdFromToken(emailResult.accessToken!);
    print('User ID from token: $userId');
  }
  
  // Example 6: Provider info
  print('\n=== Provider Info ===');
  final providerInfo = loginService.getProviderInfo();
  print('Provider: ${providerInfo['name']}');
  print('Service: ${providerInfo['service']}');
  print('Capabilities: ${providerInfo['capabilities']}');
  print('Base URL: ${providerInfo['baseUrl']}');
}