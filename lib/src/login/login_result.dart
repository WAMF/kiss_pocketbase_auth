/// Result of a login operation
class LoginResult {
  const LoginResult._({
    required this.isSuccess,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.metadata,
    this.error,
    this.errorCode,
  });
  
  /// Whether the login was successful
  final bool isSuccess;
  
  /// User information (only present on success)
  final LoginUser? user;
  
  /// Access token (only present on success)
  final String? accessToken;
  
  /// Refresh token (only present on success, may be null for some providers)
  final String? refreshToken;
  
  /// Additional metadata from the provider
  final Map<String, dynamic>? metadata;
  
  /// Error message (only present on failure)
  final String? error;
  
  /// Error code (only present on failure)
  final String? errorCode;
  
  /// Create a successful login result
  factory LoginResult.success({
    required LoginUser user,
    required String accessToken,
    String? refreshToken,
    Map<String, dynamic>? metadata,
  }) {
    return LoginResult._(
      isSuccess: true,
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      metadata: metadata,
    );
  }
  
  /// Create a failed login result
  factory LoginResult.failure({
    required String error,
    required String errorCode,
  }) {
    return LoginResult._(
      isSuccess: false,
      error: error,
      errorCode: errorCode,
    );
  }
  
  @override
  String toString() {
    if (isSuccess) {
      return 'LoginResult.success(user: ${user?.userId}, hasToken: ${accessToken != null})';
    } else {
      return 'LoginResult.failure(error: $error, code: $errorCode)';
    }
  }
}

/// User information from login
class LoginUser {
  const LoginUser({
    required this.userId,
    this.email,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.metadata,
  });
  
  /// Unique user identifier
  final String userId;
  
  /// User's email address
  final String? email;
  
  /// User's username
  final String? username;
  
  /// User's display name
  final String? displayName;
  
  /// URL to user's avatar image
  final String? avatarUrl;
  
  /// Additional user metadata
  final Map<String, dynamic>? metadata;
  
  @override
  String toString() => 'LoginUser(userId: $userId, email: $email, username: $username)';
  
  /// Get a metadata field value
  T? getMetadata<T>(String key) => metadata?[key] as T?;
}