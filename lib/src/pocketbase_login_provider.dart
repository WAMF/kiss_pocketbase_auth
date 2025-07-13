import 'dart:convert';
import 'package:pocketbase/pocketbase.dart';
import 'login/login_provider.dart';
import 'login/login_credentials.dart';
import 'login/login_result.dart';

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
        user: LoginUser(
          userId: result.record!.id,
          email: result.record!.data['email'],
          username: result.record!.data['username'],
          displayName: result.record!.data['name'],
          avatarUrl: result.record!.data['avatar'],
          metadata: result.record!.toJson(),
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
        user: LoginUser(
          userId: result.record!.id,
          email: result.record!.data['email'],
          username: result.record!.data['username'],
          displayName: result.record!.data['name'],
          avatarUrl: result.record!.data['avatar'],
          metadata: result.record!.toJson(),
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

  @override
  Future<LoginResult> refreshToken(String refreshToken) async {
    try {
      // PocketBase uses authRefresh which doesn't require the refresh token parameter
      // The token is stored in the authStore
      pb.authStore.save(refreshToken, null);
      final result = await pb.collection(collection).authRefresh();

      return LoginResult.success(
        user: LoginUser(
          userId: result.record!.id,
          email: result.record!.data['email'],
          username: result.record!.data['username'],
          displayName: result.record!.data['name'],
          avatarUrl: result.record!.data['avatar'],
          metadata: result.record!.toJson(),
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
      'capabilities': ['email_password', 'username_password'],
      'baseUrl': pb.baseUrl,
      'collection': collection,
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
}