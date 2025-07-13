import 'login_provider.dart';
import 'login_credentials.dart';
import 'login_result.dart';

/// Service for handling login operations with different providers
class LoginService {
  const LoginService(this._provider);
  
  final LoginProvider _provider;
  
  /// Login with email and password
  Future<LoginResult> loginWithPassword(String email, String password) {
    final credentials = EmailPasswordCredentials(
      email: email,
      password: password,
    );
    return _provider.authenticate(credentials);
  }
  
  /// Login with username and password
  Future<LoginResult> loginWithUsername(String username, String password) {
    final credentials = UsernamePasswordCredentials(
      username: username,
      password: password,
    );
    return _provider.authenticate(credentials);
  }
  
  /// Login with API key
  Future<LoginResult> loginWithApiKey(String apiKey, {String? keyId}) {
    final credentials = ApiKeyCredentials(
      apiKey: apiKey,
      keyId: keyId,
    );
    return _provider.authenticate(credentials);
  }
  
  /// Login with OAuth credentials
  Future<LoginResult> loginWithOAuth({
    required String provider,
    required String accessToken,
    String? refreshToken,
    String? idToken,
    List<String>? scope,
  }) {
    final credentials = OAuthCredentials(
      provider: provider,
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
      scope: scope,
    );
    return _provider.authenticate(credentials);
  }
  
  /// Login anonymously
  Future<LoginResult> loginAnonymously({
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    final credentials = AnonymousCredentials(
      userId: userId,
      metadata: metadata,
    );
    return _provider.authenticate(credentials);
  }
  
  /// Authenticate with any credentials
  Future<LoginResult> authenticate(LoginCredentials credentials) {
    return _provider.authenticate(credentials);
  }
  
  /// Refresh an access token
  Future<LoginResult> refreshToken(String refreshToken) {
    return _provider.refreshToken(refreshToken);
  }
  
  /// Logout and invalidate token
  Future<bool> logout(String token) {
    return _provider.logout(token);
  }
  
  /// Check if token is valid
  Future<bool> isTokenValid(String token) {
    return _provider.isTokenValid(token);
  }
  
  /// Get user ID from token
  Future<String?> getUserIdFromToken(String token) {
    return _provider.getUserIdFromToken(token);
  }
  
  /// Get provider information
  Map<String, dynamic> getProviderInfo() {
    return _provider.getProviderInfo();
  }
}