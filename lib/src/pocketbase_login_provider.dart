import 'dart:convert';
import 'package:pocketbase/pocketbase.dart';
import 'package:kiss_auth/kiss_login.dart';

/// PocketBase implementation of LoginProvider
class PocketBaseLoginProvider implements LoginProvider {
  final PocketBase pb;
  final String collection;

  PocketBaseLoginProvider({
    required String baseUrl,
    this.collection = 'users',
  }) : pb = PocketBase(baseUrl);

  @override
  Future<LoginResult> authenticate(LoginCredentials credentials) async {
    try {
      switch (credentials.type) {
        case 'email_password':
          return _authenticateWithEmail(credentials as EmailPasswordCredentials);
        case 'username_password':
          return _authenticateWithUsername(credentials as UsernamePasswordCredentials);
        case 'oauth':
          return _authenticateWithOAuth(credentials as OAuthCredentials);
        case 'api_key':
          return _authenticateWithApiKey(credentials as ApiKeyCredentials);
        case 'anonymous':
          return _authenticateAnonymously(credentials as AnonymousCredentials);
        default:
          return LoginResult.failure(
            error: 'Unsupported credential type: ${credentials.type}',
            errorCode: 'unsupported_credential_type',
          );
      }
    } catch (e) {
      return LoginResult.failure(
        error: 'Authentication failed: $e',
        errorCode: 'authentication_error',
      );
    }
  }

  Future<LoginResult> _authenticateWithEmail(EmailPasswordCredentials credentials) async {
    try {
      final result = await pb.collection(collection).authWithPassword(
        credentials.email,
        credentials.password,
      );

      return LoginResult.success(
        user: UserProfile(
          userId: result.record!.id,
          email: result.record!.data['email'],
          username: result.record!.data['username'],
          claims: {
            ...result.record!.toJson(),
            'displayName': result.record!.data['name'],
            'avatarUrl': result.record!.data['avatar'],
          },
        ),
        accessToken: result.token,
        refreshToken: null, // PocketBase uses token refresh mechanism
        metadata: {
          'collection': collection,
          'record': result.record!.toJson(),
          'meta': result.meta,
        },
      );
    } catch (e) {
      String errorCode = 'authentication_failed';
      String errorMessage = 'Authentication failed: $e';
      
      if (e.toString().contains('400')) {
        errorCode = 'invalid_credentials';
        errorMessage = 'Invalid email or password';
      } else if (e.toString().contains('403')) {
        errorCode = 'account_disabled';
        errorMessage = 'Account is disabled';
      }
      
      return LoginResult.failure(
        error: errorMessage,
        errorCode: errorCode,
      );
    }
  }

  Future<LoginResult> _authenticateWithUsername(UsernamePasswordCredentials credentials) async {
    try {
      final result = await pb.collection(collection).authWithPassword(
        credentials.username,
        credentials.password,
      );

      return LoginResult.success(
        user: UserProfile(
          userId: result.record!.id,
          email: result.record!.data['email'],
          username: result.record!.data['username'],
          claims: {
            ...result.record!.toJson(),
            'displayName': result.record!.data['name'],
            'avatarUrl': result.record!.data['avatar'],
          },
        ),
        accessToken: result.token,
        refreshToken: null,
        metadata: {
          'collection': collection,
          'record': result.record!.toJson(),
          'meta': result.meta,
        },
      );
    } catch (e) {
      String errorCode = 'authentication_failed';
      String errorMessage = 'Authentication failed: $e';
      
      if (e.toString().contains('400')) {
        errorCode = 'invalid_credentials';
        errorMessage = 'Invalid username or password';
      } else if (e.toString().contains('403')) {
        errorCode = 'account_disabled';
        errorMessage = 'Account is disabled';
      }
      
      return LoginResult.failure(
        error: errorMessage,
        errorCode: errorCode,
      );
    }
  }

  Future<LoginResult> _authenticateWithOAuth(OAuthCredentials credentials) async {
    try {
      // For OAuth, we need to use the authWithOAuth2Code method
      // This requires the OAuth2 authorization code from the provider
      final result = await pb.collection(collection).authWithOAuth2Code(
        credentials.provider,
        credentials.accessToken, // Using accessToken as the OAuth2 code
        '', // codeVerifier (empty for PKCE-less flow)
        '', // redirectUrl (empty for mobile/desktop apps)
        // Additional user data can be passed here
        createData: credentials.idToken != null 
          ? {'id_token': credentials.idToken} 
          : {},
      );

      return LoginResult.success(
        user: UserProfile(
          userId: result.record!.id,
          email: result.record!.data['email'],
          username: result.record!.data['username'],
          claims: {
            ...result.record!.toJson(),
            'oauth_provider': credentials.provider,
            'displayName': result.record!.data['name'],
            'avatarUrl': result.record!.data['avatar'],
          },
        ),
        accessToken: result.token,
        refreshToken: null,
        metadata: {
          'collection': collection,
          'record': result.record!.toJson(),
          'meta': result.meta,
          'oauth_provider': credentials.provider,
        },
      );
    } catch (e) {
      String errorCode = 'oauth_authentication_failed';
      String errorMessage = 'OAuth authentication failed: $e';
      
      if (e.toString().contains('400')) {
        errorCode = 'invalid_oauth_code';
        errorMessage = 'Invalid OAuth authorization code';
      } else if (e.toString().contains('403')) {
        errorCode = 'oauth_account_disabled';
        errorMessage = 'OAuth account is disabled';
      }
      
      return LoginResult.failure(
        error: errorMessage,
        errorCode: errorCode,
      );
    }
  }

  Future<LoginResult> _authenticateWithApiKey(ApiKeyCredentials credentials) async {
    try {
      // For API key authentication, we validate the key and return user info
      // This simulates API key authentication by treating the API key as a JWT token
      // In a real implementation, you'd validate the API key against your API key store
      
      // Check if the API key is a valid JWT token
      final parts = credentials.apiKey.split('.');
      if (parts.length == 3) {
        // Try to validate it as a JWT token
        pb.authStore.save(credentials.apiKey, null);
        final result = await pb.collection(collection).authRefresh();
        
        return LoginResult.success(
          user: UserProfile(
            userId: result.record!.id,
            email: result.record!.data['email'],
            username: result.record!.data['username'],
            claims: {
              ...result.record!.toJson(),
              'displayName': result.record!.data['name'],
              'avatarUrl': result.record!.data['avatar'],
              'api_key_id': credentials.keyId,
              'auth_method': 'api_key',
            },
          ),
          accessToken: result.token,
          refreshToken: null,
          metadata: {
            'collection': collection,
            'record': result.record!.toJson(),
            'meta': result.meta,
            'auth_method': 'api_key',
            'api_key_id': credentials.keyId,
          },
        );
      } else {
        // For non-JWT API keys, you would typically:
        // 1. Query your API keys collection/table
        // 2. Validate the key exists and is active
        // 3. Get the associated user record
        // 4. Generate a session token
        
        throw Exception('API key authentication requires JWT token format or custom implementation');
      }
    } catch (e) {
      String errorCode = 'api_key_authentication_failed';
      String errorMessage = 'API key authentication failed: $e';
      
      if (e.toString().contains('400') || e.toString().contains('401')) {
        errorCode = 'invalid_api_key';
        errorMessage = 'Invalid or expired API key';
      }
      
      return LoginResult.failure(
        error: errorMessage,
        errorCode: errorCode,
      );
    }
  }

  Future<LoginResult> _authenticateAnonymously(AnonymousCredentials credentials) async {
    // PocketBase doesn't support anonymous authentication natively
    // This would typically require a custom implementation or guest user creation
    return LoginResult.failure(
      error: 'Anonymous authentication is not supported by PocketBase. Consider using guest user accounts or implementing a custom anonymous auth flow.',
      errorCode: 'anonymous_auth_not_supported',
    );
  }

  @override
  Future<LoginResult> refreshToken(String refreshToken) async {
    try {
      // PocketBase uses authRefresh which doesn't require the refresh token parameter
      // The token is stored in the authStore
      pb.authStore.save(refreshToken, null);
      final result = await pb.collection(collection).authRefresh();

      return LoginResult.success(
        user: UserProfile(
          userId: result.record!.id,
          email: result.record!.data['email'],
          username: result.record!.data['username'],
          claims: {
            ...result.record!.toJson(),
            'displayName': result.record!.data['name'],
            'avatarUrl': result.record!.data['avatar'],
          },
        ),
        accessToken: result.token,
        refreshToken: null,
        metadata: {
          'collection': collection,
          'record': result.record!.toJson(),
          'meta': result.meta,
        },
      );
    } catch (e) {
      return LoginResult.failure(
        error: 'Token refresh failed: $e',
        errorCode: 'refresh_failed',
      );
    }
  }

  @override
  Future<bool> logout(String token) async {
    try {
      pb.authStore.clear();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isTokenValid(String token) async {
    try {
      pb.authStore.save(token, null);
      await pb.collection(collection).authRefresh();
      return true;
    } catch (e) {
      pb.authStore.clear();
      return false;
    }
  }

  @override
  Future<String?> getUserIdFromToken(String token) async {
    try {
      // Parse JWT token to extract user ID
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final payloadData = utf8.decode(base64Url.decode(normalizedPayload));
      final claims = jsonDecode(payloadData) as Map<String, dynamic>;
      
      return claims['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic> getProviderInfo() {
    return {
      'name': 'PocketBaseLoginProvider',
      'version': '1.0.0',
      'service': 'pocketbase',
      'capabilities': ['email_password', 'username_password', 'oauth', 'api_key'],
      'unsupported': ['anonymous'],
      'baseUrl': pb.baseUrl,
      'collection': collection,
      'oauth_providers': ['google', 'facebook', 'twitter', 'github', 'gitlab', 'discord', 'microsoft', 'spotify', 'kakao', 'twitch', 'strava', 'gitee', 'livechat', 'gitpod', 'instagram', 'vk', 'yandex', 'patreon', 'mailcow'],
      'api_key_format': 'JWT token or custom implementation required',
    };
  }

  /// Create a new user account in PocketBase
  Future<LoginResult> createUser({
    required String email,
    required String password,
    String? username,
    String? name,
    String? emailVisibility,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final body = <String, dynamic>{
        'email': email,
        'password': password,
        'passwordConfirm': password,
      };

      if (emailVisibility != null) body['emailVisibility'] = emailVisibility;
      if (username != null) body['username'] = username;
      if (name != null) body['name'] = name;
      if (additionalData != null) body.addAll(additionalData);

      await pb.collection(collection).create(body: body);
      
      // Authenticate the newly created user
      return _authenticateWithEmail(EmailPasswordCredentials(
        email: email,
        password: password,
      ));
    } catch (e) {
      String errorCode = 'user_creation_failed';
      String errorMessage = 'User creation failed: $e';
      
      if (e.toString().contains('400')) {
        if (e.toString().contains('email')) {
          errorCode = 'email_already_exists';
          errorMessage = 'Email already exists';
        } else if (e.toString().contains('username')) {
          errorCode = 'username_already_exists';
          errorMessage = 'Username already exists';
        }
      }
      
      return LoginResult.failure(
        error: errorMessage,
        errorCode: errorCode,
      );
    }
  }

  /// Get OAuth2 authorization URL for the specified provider
  /// This is useful for web/mobile apps to redirect users to OAuth provider
  String getOAuth2AuthUrl({
    required String provider,
    required String redirectUrl,
    String? codeChallenge,
    String? state,
    List<String>? scopes,
  }) {
    // Build OAuth2 authorization URL
    final baseUrl = pb.baseUrl;
    final url = '$baseUrl/api/oauth2-providers/$provider/auth-url';
    
    final params = <String, String>{
      'redirect': redirectUrl,
      if (codeChallenge != null) 'codeChallenge': codeChallenge,
      if (state != null) 'state': state,
      if (scopes != null) 'scopes': scopes.join(' '),
    };
    
    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$url?$queryString';
  }

  /// Get list of available OAuth2 providers from PocketBase
  Future<List<Map<String, dynamic>>> getAvailableOAuth2Providers() async {
    try {
      // This would typically call the PocketBase API to get available providers
      // For now, we return the commonly supported providers
      return [
        {'name': 'google', 'displayName': 'Google'},
        {'name': 'facebook', 'displayName': 'Facebook'},
        {'name': 'github', 'displayName': 'GitHub'},
        {'name': 'gitlab', 'displayName': 'GitLab'},
        {'name': 'discord', 'displayName': 'Discord'},
        {'name': 'microsoft', 'displayName': 'Microsoft'},
        {'name': 'twitter', 'displayName': 'Twitter'},
        {'name': 'spotify', 'displayName': 'Spotify'},
      ];
    } catch (e) {
      return [];
    }
  }

  /// Login with OAuth2 authorization code (PocketBase specific)
  Future<LoginResult> loginWithOAuth2Code({
    required String provider,
    required String authorizationCode,
    String? codeVerifier,
    String? redirectUrl,
    String? idToken,
    List<String>? scope,
  }) {
    final credentials = OAuthCredentials(
      provider: provider,
      accessToken: authorizationCode, // Using accessToken field for auth code
      idToken: idToken,
    );
    return authenticate(credentials);
  }
  
  /// Login with OAuth2 access token (for other OAuth flows)
  Future<LoginResult> loginWithOAuth2Token({
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
    );
    return authenticate(credentials);
  }
  
  Future<LoginResult> loginWithPassword(String email, String password) {
    final credentials = EmailPasswordCredentials(
      email: email,
      password: password,
    );
    return authenticate(credentials);
  }
  
  Future<LoginResult> loginWithUsername(String username, String password) {
    final credentials = UsernamePasswordCredentials(
      username: username,
      password: password,
    );
    return authenticate(credentials);
  }
  
  Future<LoginResult> loginWithApiKey(String apiKey, {String? keyId}) {
    final credentials = ApiKeyCredentials(
      apiKey: apiKey,
      keyId: keyId,
    );
    return authenticate(credentials);
  }
  
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
    );
    return authenticate(credentials);
  }

  Future<LoginResult> loginAnonymously({
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    // Override to provide PocketBase-specific error message
    return LoginResult.failure(
      error: 'Anonymous authentication is not natively supported by PocketBase. You can implement guest users by creating temporary accounts or using a custom auth flow.',
      errorCode: 'anonymous_auth_not_supported',
    );
  }
  
  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await pb.collection(collection).requestPasswordReset(email);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Send email verification
  Future<bool> sendEmailVerification(String email) async {
    try {
      await pb.collection(collection).requestVerification(email);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Confirm password reset with token
  Future<bool> confirmPasswordReset({
    required String token,
    required String password,
  }) async {
    try {
      await pb.collection(collection).confirmPasswordReset(
        token,
        password,
        password, // passwordConfirm
      );
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Confirm email verification with token
  Future<bool> confirmEmailVerification(String token) async {
    try {
      await pb.collection(collection).confirmVerification(token);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Change password for authenticated user
  Future<LoginResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // First verify current password by trying to authenticate
      final currentUser = pb.authStore.model;
      if (currentUser == null) {
        return LoginResult.failure(
          error: 'No authenticated user found',
          errorCode: 'not_authenticated',
        );
      }
      
      // Update user password
      final updatedRecord = await pb.collection(collection).update(
        currentUser.id,
        body: {
          'password': newPassword,
          'passwordConfirm': newPassword,
          'oldPassword': oldPassword,
        },
      );
      
      // Return success with updated user info
      return LoginResult.success(
        user: UserProfile(
          userId: updatedRecord.id,
          email: updatedRecord.data['email'],
          username: updatedRecord.data['username'],
          claims: {
            ...updatedRecord.toJson(),
            'displayName': updatedRecord.data['name'],
            'avatarUrl': updatedRecord.data['avatar'],
          },
        ),
        accessToken: pb.authStore.token,
        metadata: {
          'action': 'password_changed',
          'collection': collection,
        },
      );
    } catch (e) {
      return LoginResult.failure(
        error: 'Password change failed: $e',
        errorCode: 'password_change_failed',
      );
    }
  }
}