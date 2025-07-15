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
        userId: result.record.id,
        claims: {
          'token': result.token,
          'record': result.record.toJson(),
          'meta': result.meta,
        },
        record: result.record.toJson(),
        collectionId: result.record.collectionId,
        collectionName: result.record.collectionName,
      );
    } on Exception catch (e) {
      pb.authStore.clear();
      throw AuthenticationException('Invalid or expired token: $e');
    }
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
