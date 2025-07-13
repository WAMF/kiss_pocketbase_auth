import 'login_credentials.dart';
import 'login_result.dart';

/// Abstract interface for login providers
/// 
/// Handles credential-based authentication and token generation.
abstract class LoginProvider {
  /// Authenticate a user with credentials and return tokens
  Future<LoginResult> authenticate(LoginCredentials credentials);
  
  /// Refresh an access token using a refresh token
  Future<LoginResult> refreshToken(String refreshToken);
  
  /// Revoke/logout a user session
  Future<bool> logout(String token);
  
  /// Check if a token is valid and not expired
  Future<bool> isTokenValid(String token);
  
  /// Get user ID from a token without full validation
  Future<String?> getUserIdFromToken(String token);
  
  /// Get provider information
  Map<String, dynamic> getProviderInfo();
  
  // Convenience methods for common authentication patterns
  
  /// Login with email and password
  Future<LoginResult> loginWithPassword(String email, String password);
  
  /// Login with username and password
  Future<LoginResult> loginWithUsername(String username, String password);
  
  /// Login with API key
  Future<LoginResult> loginWithApiKey(String apiKey, {String? keyId});
  
  /// Login with OAuth credentials
  Future<LoginResult> loginWithOAuth({
    required String provider,
    required String accessToken,
    String? refreshToken,
    String? idToken,
    List<String>? scope,
  });
  
  /// Login anonymously
  Future<LoginResult> loginAnonymously({
    String? userId,
    Map<String, dynamic>? metadata,
  });
}