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
}