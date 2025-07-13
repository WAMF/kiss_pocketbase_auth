import 'package:test/test.dart';
import 'package:kiss_pocketbase_auth/kiss_pocketbase_auth.dart';
import '../test_helper.dart';

void main() {
  group('PocketBaseAuthValidator Integration Tests', () {
    late PocketBaseAuthValidator validator;
    const testEmail = 'test@example.com';
    const testPassword = 'testpassword123';
    
    setUpAll(() async {
      await PocketBaseTestHelper.startPocketBase();
      validator = PocketBaseAuthValidator(baseUrl: PocketBaseTestHelper.baseUrl);
    });

    setUp(() async {
      try {
        await PocketBaseTestHelper.createTestUser(
          email: testEmail,
          password: testPassword,
        );
      } catch (e) {
        print('User might already exist: $e');
      }
    });

    test('should authenticate user with valid password', () async {
      final result = await validator.authenticateWithPassword(
        identity: testEmail,
        password: testPassword,
      );

      expect(result, isA<PocketBaseAuthenticationData>());
      expect(result.email, equals(testEmail));
      expect(result.userId, isNotEmpty);
      expect(result.claims['token'], isNotNull);
      expect(result.record, isNotEmpty);
    });

    test('should throw exception for invalid credentials', () async {
      expect(
        () => validator.authenticateWithPassword(
          identity: testEmail,
          password: 'wrongpassword',
        ),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('should validate valid token', () async {
      final authResult = await validator.authenticateWithPassword(
        identity: testEmail,
        password: testPassword,
      );
      
      final token = validator.extractToken(authResult);
      expect(token, isNotNull);

      final validationResult = await validator.validateToken(token!) as PocketBaseAuthenticationData;
      
      expect(validationResult, isA<PocketBaseAuthenticationData>());
      expect(validationResult.userId, equals(authResult.userId));
      expect(validationResult.email, equals(testEmail));
    });

    test('should throw exception for invalid token', () async {
      const invalidToken = 'invalid.token.here';
      
      expect(
        () => validator.validateToken(invalidToken),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('should access user record fields', () async {
      final result = await validator.authenticateWithPassword(
        identity: testEmail,
        password: testPassword,
      );

      expect(result.getRecordField<String>('email'), equals(testEmail));
      expect(result.created, isNotNull);
      expect(result.updated, isNotNull);
    });

    test('should authenticate with email as identity', () async {
      final result = await validator.authenticateWithPassword(
        identity: testEmail,
        password: testPassword,
      );

      expect(result, isA<PocketBaseAuthenticationData>());
      expect(result.email, equals(testEmail));
    });

    test('should handle collection parameter', () async {
      final result = await validator.authenticateWithPassword(
        identity: testEmail,
        password: testPassword,
        collection: 'users',
      );

      expect(result, isA<PocketBaseAuthenticationData>());
      expect(result.collectionName, equals('users'));
    });

    test('should preserve token across auth refresh', () async {
      final authResult = await validator.authenticateWithPassword(
        identity: testEmail,
        password: testPassword,
      );
      
      final originalToken = validator.extractToken(authResult);
      
      final refreshResult = await validator.validateToken(originalToken!) as PocketBaseAuthenticationData;
      final refreshedToken = validator.extractToken(refreshResult);
      
      expect(refreshedToken, isNotNull);
      expect(refreshResult.userId, equals(authResult.userId));
    });

    test('should handle authentication data claims', () async {
      final result = await validator.authenticateWithPassword(
        identity: testEmail,
        password: testPassword,
      );

      expect(result.claims, containsPair('token', isNotNull));
      expect(result.claims, containsPair('record', isA<Map>()));
      
      final recordFromClaims = result.claims['record'] as Map<String, dynamic>;
      expect(recordFromClaims['email'], equals(testEmail));
    });
  });
}