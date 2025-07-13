import 'package:kiss_auth/kiss_authentication.dart';
import 'package:pocketbase/pocketbase.dart';

import 'pocketbase_authentication_data.dart';

class PocketBaseAuthValidator implements AuthValidator {
  final PocketBase pb;
  final String collection;

  PocketBaseAuthValidator({
    required String baseUrl,
    this.collection = 'users',
  }) : pb = PocketBase(baseUrl);

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
    } catch (e) {
      pb.authStore.clear();
      throw AuthenticationException('Invalid or expired token: $e');
    }
  }

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
    } catch (e) {
      throw AuthenticationException('Authentication failed: $e');
    }
  }

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
    } catch (e) {
      throw AuthenticationException('User creation failed: $e');
    }
  }

  String? extractToken(PocketBaseAuthenticationData authData) {
    return authData.claims['token'] as String?;
  }
}

class AuthenticationException implements Exception {
  final String message;

  AuthenticationException(this.message);

  @override
  String toString() => 'AuthenticationException: $message';
}
