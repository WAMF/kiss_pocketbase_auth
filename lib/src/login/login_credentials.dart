/// Base class for login credentials
abstract class LoginCredentials {
  const LoginCredentials();
  
  /// Type identifier for the credential
  String get type;
}

/// Email and password credentials
class EmailPasswordCredentials extends LoginCredentials {
  const EmailPasswordCredentials({
    required this.email,
    required this.password,
  });
  
  final String email;
  final String password;
  
  @override
  String get type => 'email_password';
  
  @override
  String toString() => 'EmailPasswordCredentials(email: $email)';
}

/// Username and password credentials
class UsernamePasswordCredentials extends LoginCredentials {
  const UsernamePasswordCredentials({
    required this.username,
    required this.password,
  });
  
  final String username;
  final String password;
  
  @override
  String get type => 'username_password';
  
  @override
  String toString() => 'UsernamePasswordCredentials(username: $username)';
}

/// API key credentials
class ApiKeyCredentials extends LoginCredentials {
  const ApiKeyCredentials({
    required this.apiKey,
    this.keyId,
  });
  
  final String apiKey;
  final String? keyId;
  
  @override
  String get type => 'api_key';
  
  @override
  String toString() => 'ApiKeyCredentials(keyId: $keyId)';
}

/// OAuth credentials
class OAuthCredentials extends LoginCredentials {
  const OAuthCredentials({
    required this.provider,
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    this.scope,
  });
  
  final String provider;
  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final List<String>? scope;
  
  @override
  String get type => 'oauth';
  
  @override
  String toString() => 'OAuthCredentials(provider: $provider)';
}

/// Anonymous credentials (no authentication required)
class AnonymousCredentials extends LoginCredentials {
  const AnonymousCredentials({
    this.userId,
    this.metadata,
  });
  
  final String? userId;
  final Map<String, dynamic>? metadata;
  
  @override
  String get type => 'anonymous';
  
  @override
  String toString() => 'AnonymousCredentials(userId: $userId)';
}