import 'package:kiss_auth/kiss_authentication.dart';
import 'package:kiss_pocketbase_auth/src/pocketbase_authentication_data.dart';
import 'package:pocketbase/pocketbase.dart';

/// PocketBase implementation of AuthValidator for token validation
class PocketBaseAuthValidator implements AuthValidator {

  /// Creates a new PocketBase auth validator
  PocketBaseAuthValidator({
    required String baseUrl,
    this.collection = 'users',
  }) : pb = PocketBase(baseUrl);
  /// PocketBase client instance
  final PocketBase pb;
  /// Collection name for user records
  final String collection;

  @override
  Future<AuthenticationData> validateToken(String token) async {
    try {
      pb.authStore.save(token, null);

      final result = await pb.collection(collection).authRefresh();

      return PocketBaseAuthenticationData(
        userId: result.record!.id,
        claims: {
          'token': result.token,
          'record': result.record!.toJson(),
          'meta': result.meta,
        },
        record: result.record!.toJson(),
        collectionId: result.record!.collectionId,
        collectionName: result.record!.collectionName,
      );
    } on Exception catch (e) {
      pb.authStore.clear();
      throw AuthenticationException('Invalid or expired token: $e');
    }
  }

  /// Authenticates user with password (email or username)
  Future<PocketBaseAuthenticationData> authenticateWithPassword({
    required String identity,
    required String password,
  }) async {
    try {
      final result = await pb.collection(collection).authWithPassword(
            identity,
            password,
          );

      return PocketBaseAuthenticationData(
        userId: result.record!.id,
        claims: {
          'token': result.token,
          'record': result.record!.toJson(),
          'meta': result.meta,
        },
        record: result.record!.toJson(),
        collectionId: result.record!.collectionId,
        collectionName: result.record!.collectionName,
      );
    } on Exception catch (e) {
      throw AuthenticationException('Authentication failed: $e');
    }
  }

  /// Creates a new user account and returns authentication data
  Future<PocketBaseAuthenticationData> createUser({
    required String email,
    required String password,
    String? emailVisibility,
    String? username,
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
      if (additionalData != null) body.addAll(additionalData);

      await pb.collection(collection).create(body: body);

      final authResult = await pb.collection(collection).authWithPassword(
            email,
            password,
          );

      return PocketBaseAuthenticationData(
        userId: authResult.record!.id,
        claims: {
          'token': authResult.token,
          'record': authResult.record!.toJson(),
          'meta': authResult.meta,
        },
        record: authResult.record!.toJson(),
        collectionId: authResult.record!.collectionId,
        collectionName: authResult.record!.collectionName,
      );
    } on Exception catch (e) {
      throw AuthenticationException('User creation failed: $e');
    }
  }

  /// Extracts token from authentication data
  String? extractToken(PocketBaseAuthenticationData authData) {
    return authData.claims['token'] as String?;
  }
}

/// Exception thrown when authentication fails
class AuthenticationException implements Exception {

  /// Creates an authentication exception with a message
  AuthenticationException(this.message);
  /// The error message
  final String message;

  @override
  String toString() => 'AuthenticationException: $message';
}
