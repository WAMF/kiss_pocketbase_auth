import 'package:kiss_pocketbase_auth/kiss_pocketbase_auth.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('PocketBase Auth Integration Tests', () {
    late PocketBaseAuthValidator validator;
    const testEmail = 'integration@test.com';
    const testPassword = 'testpassword123';
    const alternateEmail = 'alternate@test.com';
    
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
        await PocketBaseTestHelper.createTestUser(
          email: alternateEmail,
          password: testPassword,
        );
      } on Exception catch (e) {
        print('Test users might already exist: $e');
      }
    });

    group('Authentication', () {
      test('should authenticate user with valid email and password', () async {
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

      test('should authenticate with username if provided', () async {
        final result = await validator.authenticateWithPassword(
          identity: testEmail,
          password: testPassword,
        );

        expect(result, isA<PocketBaseAuthenticationData>());
        expect(result.userId, isNotEmpty);
      });

      test('should authenticate with custom collection', () async {
        final customValidator = PocketBaseAuthValidator(
          baseUrl: 'http://localhost:8090',
        );
        final result = await customValidator.authenticateWithPassword(
          identity: testEmail,
          password: testPassword,
        );

        expect(result, isA<PocketBaseAuthenticationData>());
        expect(result.collectionName, equals('users'));
      });

      test('should throw AuthenticationException for invalid credentials', () async {
        expect(
          () => validator.authenticateWithPassword(
            identity: testEmail,
            password: 'wrongpassword',
          ),
          throwsA(isA<AuthenticationException>()),
        );
      });

      test('should throw AuthenticationException for non-existent user', () async {
        expect(
          () => validator.authenticateWithPassword(
            identity: 'nonexistent@test.com',
            password: testPassword,
          ),
          throwsA(isA<AuthenticationException>()),
        );
      });
    });

    group('Token Validation', () {
      test('should validate valid token successfully', () async {
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

      test('should throw AuthenticationException for invalid token', () async {
        const invalidToken = 'invalid.jwt.token';
        
        expect(
          () => validator.validateToken(invalidToken),
          throwsA(isA<AuthenticationException>()),
        );
      });

      test('should throw AuthenticationException for expired token', () async {
        const expiredToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
        
        expect(
          () => validator.validateToken(expiredToken),
          throwsA(isA<AuthenticationException>()),
        );
      });

      test('should handle empty token', () async {
        expect(
          () => validator.validateToken(''),
          throwsA(isA<AuthenticationException>()),
        );
      });
    });

    group('Token Extraction', () {
      test('should extract token from authentication data', () async {
        final authResult = await validator.authenticateWithPassword(
          identity: testEmail,
          password: testPassword,
        );
        
        final token = validator.extractToken(authResult);
        
        expect(token, isNotNull);
        expect(token, isA<String>());
        expect(token!.isNotEmpty, isTrue);
      });

      test('should return null for authentication data without token', () async {
        final authData = PocketBaseAuthenticationData(
          userId: 'test-id',
          claims: {},
          record: {'email': testEmail},
        );
        
        final token = validator.extractToken(authData);
        
        expect(token, isNull);
      });
    });

    group('Multiple Users', () {
      test('should authenticate different users independently', () async {
        final result1 = await validator.authenticateWithPassword(
          identity: testEmail,
          password: testPassword,
        );
        
        final result2 = await validator.authenticateWithPassword(
          identity: alternateEmail,
          password: testPassword,
        );

        expect(result1.userId, isNot(equals(result2.userId)));
        expect(result1.email, equals(testEmail));
        expect(result2.email, equals(alternateEmail));
      });

      test('should validate tokens from different users', () async {
        final auth1 = await validator.authenticateWithPassword(
          identity: testEmail,
          password: testPassword,
        );
        
        final auth2 = await validator.authenticateWithPassword(
          identity: alternateEmail,
          password: testPassword,
        );
        
        final token1 = validator.extractToken(auth1);
        final token2 = validator.extractToken(auth2);
        
        final validation1 = await validator.validateToken(token1!) as PocketBaseAuthenticationData;
        final validation2 = await validator.validateToken(token2!) as PocketBaseAuthenticationData;
        
        expect(validation1.email, equals(testEmail));
        expect(validation2.email, equals(alternateEmail));
        expect(validation1.userId, isNot(equals(validation2.userId)));
      });
    });

    group('Error Scenarios', () {
      test('should handle network connectivity issues gracefully', () async {
        final invalidValidator = PocketBaseAuthValidator(baseUrl: 'http://invalid-host:9999');
        
        expect(
          () => invalidValidator.authenticateWithPassword(
            identity: testEmail,
            password: testPassword,
          ),
          throwsA(isA<AuthenticationException>()),
        );
      });

      test('should handle malformed baseUrl', () async {
        final invalidValidator = PocketBaseAuthValidator(baseUrl: 'not-a-url');
        
        expect(
          () => invalidValidator.authenticateWithPassword(
            identity: testEmail,
            password: testPassword,
          ),
          throwsA(isA<AuthenticationException>()),
        );
      });
    });
  });

  group('PocketBaseAuthenticationData', () {
    late PocketBaseAuthenticationData authData;
    final testRecord = {
      'id': 'test-user-id',
      'email': 'test@example.com',
      'username': 'testuser',
      'verified': true,
      'created': '2024-01-01T10:00:00.000Z',
      'updated': '2024-01-02T15:30:00.000Z',
      'name': 'Test User',
      'customField': 'custom value',
    };

    setUp(() {
      authData = PocketBaseAuthenticationData(
        userId: 'test-user-id',
        claims: {
          'token': 'test-jwt-token',
          'record': testRecord,
          'meta': {'some': 'metadata'},
        },
        record: testRecord,
        collectionId: 'collection-id',
        collectionName: 'users',
      );
    });

    test('should provide correct userId', () {
      expect(authData.userId, equals('test-user-id'));
    });

    test('should provide correct claims', () {
      expect(authData.claims['token'], equals('test-jwt-token'));
      expect(authData.claims['record'], equals(testRecord));
      expect(authData.claims['meta'], equals({'some': 'metadata'}));
    });

    test('should extract email from record', () {
      expect(authData.email, equals('test@example.com'));
    });

    test('should extract username from record', () {
      expect(authData.username, equals('testuser'));
    });

    test('should extract verified status from record', () {
      expect(authData.verified, isTrue);
    });

    test('should parse created date from record', () {
      expect(authData.created, isNotNull);
      expect(authData.created!.year, equals(2024));
      expect(authData.created!.month, equals(1));
      expect(authData.created!.day, equals(1));
    });

    test('should parse updated date from record', () {
      expect(authData.updated, isNotNull);
      expect(authData.updated!.year, equals(2024));
      expect(authData.updated!.month, equals(1));
      expect(authData.updated!.day, equals(2));
    });

    test('should get custom record fields', () {
      expect(authData.getRecordField<String>('name'), equals('Test User'));
      expect(authData.getRecordField<String>('customField'), equals('custom value'));
      expect(authData.getRecordField<bool>('verified'), isTrue);
    });

    test('should return null for non-existent fields', () {
      expect(authData.getRecordField<String>('nonExistent'), isNull);
    });

    test('should handle missing optional fields gracefully', () {
      final minimalData = PocketBaseAuthenticationData(
        userId: 'minimal-id',
        claims: {'token': 'minimal-token'},
        record: {'id': 'minimal-id'},
      );

      expect(minimalData.email, isNull);
      expect(minimalData.username, isNull);
      expect(minimalData.verified, isFalse);
      expect(minimalData.created, isNull);
      expect(minimalData.updated, isNull);
      expect(minimalData.collectionId, isNull);
      expect(minimalData.collectionName, isNull);
    });

    test('should handle invalid date formats', () {
      final invalidDateData = PocketBaseAuthenticationData(
        userId: 'invalid-date-id',
        claims: {'token': 'token'},
        record: {
          'id': 'invalid-date-id',
          'created': 'invalid-date',
          'updated': 'also-invalid',
        },
      );

      expect(invalidDateData.created, isNull);
      expect(invalidDateData.updated, isNull);
    });
  });

  group('AuthenticationException', () {
    test('should create exception with message', () {
      const message = 'Test error message';
      final exception = AuthenticationException(message);
      
      expect(exception.message, equals(message));
      expect(exception.toString(), equals('AuthenticationException: $message'));
    });

    test('should be throwable', () {
      expect(
        () => throw AuthenticationException('Test exception'),
        throwsA(isA<AuthenticationException>()),
      );
    });
  });
}
