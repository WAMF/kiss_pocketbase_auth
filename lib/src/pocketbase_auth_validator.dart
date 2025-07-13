import 'package:kiss_auth/kiss_authentication.dart';
import 'package:pocketbase/pocketbase.dart';
import 'pocketbase_authentication_data.dart';

class PocketBaseAuthValidator implements AuthValidator {
  final PocketBase pb;

  PocketBaseAuthValidator({
    required String baseUrl,
  }) : pb = PocketBase(baseUrl);

  @override
  Future<AuthenticationData> validateToken(String token) async {
    try {
      pb.authStore.save(token, null);
      
      final result = await pb.collection('users').authRefresh();
      
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
    String collection = 'users',
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