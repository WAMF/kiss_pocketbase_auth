import 'dart:convert';

import 'package:kiss_auth/kiss_login.dart';
import 'package:pocketbase/pocketbase.dart';

/// PocketBase implementation of LoginProvider
class PocketBaseLoginProvider implements LoginProvider {
  /// Creates a PocketBase login provider
  PocketBaseLoginProvider({
    required String baseUrl,
    this.collection = 'users',
    this.onUnsupportedCredentialType,
  }) : pb = PocketBase(baseUrl);

  /// PocketBase client instance
  final PocketBase pb;

  /// Collection name for user records
  final String collection;

  /// Optional handler for unsupported credential types
  final void Function(String type, LoginCredentials credentials)?
      onUnsupportedCredentialType;

  @override
  Future<LoginResult> authenticate(LoginCredentials credentials) async {
    try {
      switch (credentials.type) {
        case _CredentialType.emailPassword:
          return _authenticateWithEmail(
              credentials as EmailPasswordCredentials);
        case _CredentialType.usernamePassword:
          return _authenticateWithUsername(
              credentials as UsernamePasswordCredentials);
        case _CredentialType.oauth:
          return _authenticateWithOAuth(credentials as OAuthCredentials);
        case _CredentialType.apiKey:
          return _authenticateWithApiKey(credentials as ApiKeyCredentials);
        case _CredentialType.anonymous:
          return _authenticateAnonymously(credentials as AnonymousCredentials);
        default:
          onUnsupportedCredentialType?.call(credentials.type, credentials);
          return LoginResult.failure(
            error: 'Unsupported credential type: ${credentials.type}',
            errorCode: _ErrorCode.unsupportedCredentialType.value,
          );
      }
    } on Exception catch (e) {
      return LoginResult.failure(
        error: 'Authentication failed: $e',
        errorCode: _ErrorCode.authenticationError.value,
      );
    }
  }

  Future<LoginResult> _authenticateWithEmail(
      EmailPasswordCredentials credentials) async {
    try {
      final result = await pb.collection(collection).authWithPassword(
            credentials.email,
            credentials.password,
          );

      return LoginResult.success(
        user: UserProfile(
          userId: result.record!.id,
          email: result.record!.data[_Field.email.value] as String?,
          username: result.record!.data[_Field.username.value] as String?,
          claims: {
            ...result.record!.toJson(),
            _ClaimKey.displayName.value:
                result.record!.data[_Field.name.value] as String?,
            _ClaimKey.avatarUrl.value:
                result.record!.data[_Field.avatar.value] as String?,
          },
        ),
        accessToken: result.token,
        metadata: {
          _MetadataKey.collection.value: collection,
          _MetadataKey.record.value: result.record!.toJson(),
          _MetadataKey.meta.value: result.meta,
        },
      );
    } on Exception catch (e) {
      var errorCode = _ErrorCode.authenticationFailed.value;
      var errorMessage = 'Authentication failed: $e';

      if (e.toString().contains(_HttpStatusCode.badRequest.value)) {
        errorCode = _ErrorCode.invalidCredentials.value;
        errorMessage = _ErrorMessage.invalidEmailOrPassword.value;
      } else if (e.toString().contains(_HttpStatusCode.forbidden.value)) {
        errorCode = _ErrorCode.accountDisabled.value;
        errorMessage = _ErrorMessage.accountDisabled.value;
      }

      return LoginResult.failure(
        error: errorMessage,
        errorCode: errorCode,
      );
    }
  }

  Future<LoginResult> _authenticateWithUsername(
      UsernamePasswordCredentials credentials) async {
    try {
      final result = await pb.collection(collection).authWithPassword(
            credentials.username,
            credentials.password,
          );

      return LoginResult.success(
        user: UserProfile(
          userId: result.record!.id,
          email: result.record!.data[_Field.email.value] as String?,
          username: result.record!.data[_Field.username.value] as String?,
          claims: {
            ...result.record!.toJson(),
            _ClaimKey.displayName.value:
                result.record!.data[_Field.name.value] as String?,
            _ClaimKey.avatarUrl.value:
                result.record!.data[_Field.avatar.value] as String?,
          },
        ),
        accessToken: result.token,
        metadata: {
          _MetadataKey.collection.value: collection,
          _MetadataKey.record.value: result.record!.toJson(),
          _MetadataKey.meta.value: result.meta,
        },
      );
    } on Exception catch (e) {
      var errorCode = _ErrorCode.authenticationFailed.value;
      var errorMessage = 'Authentication failed: $e';

      if (e.toString().contains(_HttpStatusCode.badRequest.value)) {
        errorCode = _ErrorCode.invalidCredentials.value;
        errorMessage = _ErrorMessage.invalidUsernameOrPassword.value;
      } else if (e.toString().contains(_HttpStatusCode.forbidden.value)) {
        errorCode = _ErrorCode.accountDisabled.value;
        errorMessage = _ErrorMessage.accountDisabled.value;
      }

      return LoginResult.failure(
        error: errorMessage,
        errorCode: errorCode,
      );
    }
  }

  Future<LoginResult> _authenticateWithOAuth(
      OAuthCredentials credentials) async {
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
                ? {_Field.idToken.value: credentials.idToken}
                : {},
          );

      return LoginResult.success(
        user: UserProfile(
          userId: result.record!.id,
          email: result.record!.data[_Field.email.value] as String?,
          username: result.record!.data[_Field.username.value] as String?,
          claims: {
            ...result.record!.toJson(),
            _MetadataKey.oauthProvider.value: credentials.provider,
            _ClaimKey.displayName.value:
                result.record!.data[_Field.name.value] as String?,
            _ClaimKey.avatarUrl.value:
                result.record!.data[_Field.avatar.value] as String?,
          },
        ),
        accessToken: result.token,
        metadata: {
          _MetadataKey.collection.value: collection,
          _MetadataKey.record.value: result.record!.toJson(),
          _MetadataKey.meta.value: result.meta,
          _MetadataKey.oauthProvider.value: credentials.provider,
        },
      );
    } on Exception catch (e) {
      var errorCode = _ErrorCode.oauthAuthenticationFailed.value;
      var errorMessage = 'OAuth authentication failed: $e';

      if (e.toString().contains(_HttpStatusCode.badRequest.value)) {
        errorCode = _ErrorCode.invalidOAuthCode.value;
        errorMessage = _ErrorMessage.invalidOAuthCode.value;
      } else if (e.toString().contains(_HttpStatusCode.forbidden.value)) {
        errorCode = _ErrorCode.oauthAccountDisabled.value;
        errorMessage = _ErrorMessage.oauthAccountDisabled.value;
      }

      return LoginResult.failure(
        error: errorMessage,
        errorCode: errorCode,
      );
    }
  }

  Future<LoginResult> _authenticateWithApiKey(
      ApiKeyCredentials credentials) async {
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
            email: result.record!.data[_Field.email.value] as String?,
            username: result.record!.data[_Field.username.value] as String?,
            claims: {
              ...result.record!.toJson(),
              _ClaimKey.displayName.value:
                  result.record!.data[_Field.name.value] as String?,
              _ClaimKey.avatarUrl.value:
                  result.record!.data[_Field.avatar.value] as String?,
              _MetadataKey.apiKeyId.value: credentials.keyId,
              _MetadataKey.authMethod.value: _CredentialType.apiKey,
            },
          ),
          accessToken: result.token,
          metadata: {
            _MetadataKey.collection.value: collection,
            _MetadataKey.record.value: result.record!.toJson(),
            _MetadataKey.meta.value: result.meta,
            _MetadataKey.authMethod.value: _CredentialType.apiKey,
            _MetadataKey.apiKeyId.value: credentials.keyId,
          },
        );
      } else {
        // For non-JWT API keys, you would typically:
        // 1. Query your API keys collection/table
        // 2. Validate the key exists and is active
        // 3. Get the associated user record
        // 4. Generate a session token

        throw Exception(_ErrorMessage.apiKeyRequiresJwt.value);
      }
    } on Exception catch (e) {
      var errorCode = _ErrorCode.apiKeyAuthenticationFailed.value;
      var errorMessage = 'API key authentication failed: $e';

      if (e.toString().contains(_HttpStatusCode.badRequest.value) ||
          e.toString().contains(_HttpStatusCode.unauthorized.value)) {
        errorCode = _ErrorCode.invalidApiKey.value;
        errorMessage = _ErrorMessage.invalidApiKey.value;
      }

      return LoginResult.failure(
        error: errorMessage,
        errorCode: errorCode,
      );
    }
  }

  Future<LoginResult> _authenticateAnonymously(
      AnonymousCredentials credentials) async {
    // PocketBase doesn't support anonymous authentication natively
    // This would typically require a custom implementation or guest user creation
    return LoginResult.failure(
      error: _ErrorMessage.anonymousNotSupported.value,
      errorCode: _ErrorCode.anonymousAuthNotSupported.value,
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
          email: result.record!.data[_Field.email.value] as String?,
          username: result.record!.data[_Field.username.value] as String?,
          claims: {
            ...result.record!.toJson(),
            _ClaimKey.displayName.value:
                result.record!.data[_Field.name.value] as String?,
            _ClaimKey.avatarUrl.value:
                result.record!.data[_Field.avatar.value] as String?,
          },
        ),
        accessToken: result.token,
        metadata: {
          _MetadataKey.collection.value: collection,
          _MetadataKey.record.value: result.record!.toJson(),
          _MetadataKey.meta.value: result.meta,
        },
      );
    } on Exception catch (e) {
      return LoginResult.failure(
        error: 'Token refresh failed: $e',
        errorCode: _ErrorCode.refreshFailed.value,
      );
    }
  }

  @override
  Future<bool> logout(String token) async {
    try {
      pb.authStore.clear();
      return true;
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> isTokenValid(String token) async {
    try {
      pb.authStore.save(token, null);
      await pb.collection(collection).authRefresh();
      return true;
    } on Exception {
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

      return claims[_Field.id.value] as String?;
    } on Exception {
      return null;
    }
  }

  @override
  Map<String, dynamic> getProviderInfo() {
    return {
      'name': _ProviderInfo.name,
      'version': _ProviderInfo.version,
      'service': _ProviderInfo.service,
      'capabilities': [
        _CredentialType.emailPassword,
        _CredentialType.usernamePassword,
        _CredentialType.oauth,
        _CredentialType.apiKey
      ],
      'unsupported': [_CredentialType.anonymous],
      'baseUrl': pb.baseUrl,
      'collection': collection,
      'oauth_providers': _OAuthProviders.supportedProviders,
      'api_key_format': _ProviderInfo.apiKeyFormat,
    };
  }
}

// Private enums for better type safety and organization
enum _Field {
  email('email'),
  username('username'),
  name('name'),
  avatar('avatar'),
  idToken('id_token'),
  id('id');

  const _Field(this.value);
  final String value;
}

enum _MetadataKey {
  collection('collection'),
  record('record'),
  meta('meta'),
  oauthProvider('oauth_provider'),
  authMethod('auth_method'),
  apiKeyId('api_key_id');

  const _MetadataKey(this.value);
  final String value;
}

enum _ClaimKey {
  displayName('displayName'),
  avatarUrl('avatarUrl');

  const _ClaimKey(this.value);
  final String value;
}

enum _ErrorCode {
  authenticationFailed('authentication_failed'),
  invalidCredentials('invalid_credentials'),
  accountDisabled('account_disabled'),
  oauthAuthenticationFailed('oauth_authentication_failed'),
  invalidOAuthCode('invalid_oauth_code'),
  oauthAccountDisabled('oauth_account_disabled'),
  apiKeyAuthenticationFailed('api_key_authentication_failed'),
  invalidApiKey('invalid_api_key'),
  anonymousAuthNotSupported('anonymous_auth_not_supported'),
  refreshFailed('refresh_failed'),
  unsupportedCredentialType('unsupported_credential_type'),
  authenticationError('authentication_error');

  const _ErrorCode(this.value);
  final String value;
}

enum _ErrorMessage {
  invalidEmailOrPassword('Invalid email or password'),
  invalidUsernameOrPassword('Invalid username or password'),
  accountDisabled('Account is disabled'),
  invalidOAuthCode('Invalid OAuth authorization code'),
  oauthAccountDisabled('OAuth account is disabled'),
  invalidApiKey('Invalid or expired API key'),
  anonymousNotSupported(
      'Anonymous authentication is not supported by PocketBase. Consider using guest user accounts or implementing a custom anonymous auth flow.'),
  apiKeyRequiresJwt(
      'API key authentication requires JWT token format or custom implementation');

  const _ErrorMessage(this.value);
  final String value;
}

enum _HttpStatusCode {
  badRequest('400'),
  unauthorized('401'),
  forbidden('403');

  const _HttpStatusCode(this.value);
  final String value;
}

class _CredentialType {
  static const String emailPassword = 'email_password';
  static const String usernamePassword = 'username_password';
  static const String oauth = 'oauth';
  static const String apiKey = 'api_key';
  static const String anonymous = 'anonymous';
}

class _ProviderInfo {
  static const String name = 'PocketBaseLoginProvider';
  static const String version = '1.0.0';
  static const String service = 'pocketbase';
  static const String apiKeyFormat =
      'JWT token or custom implementation required';
}

class _OAuthProviders {
  static const List<String> supportedProviders = [
    'google',
    'facebook',
    'twitter',
    'github',
    'gitlab',
    'discord',
    'microsoft',
    'spotify',
    'kakao',
    'twitch',
    'strava',
    'gitee',
    'livechat',
    'gitpod',
    'instagram',
    'vk',
    'yandex',
    'patreon',
    'mailcow'
  ];
}
