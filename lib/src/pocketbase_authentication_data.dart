import 'package:kiss_auth/kiss_authentication.dart';

/// PocketBase-specific authentication data containing user record information
class PocketBaseAuthenticationData extends AuthenticationData {

  /// Creates PocketBase authentication data
  PocketBaseAuthenticationData({
    required String userId,
    required Map<String, dynamic> claims,
    required this.record,
    this.collectionId,
    this.collectionName,
  }) : _userId = userId, _claims = claims;
  /// The user record data from PocketBase
  final Map<String, dynamic> record;
  /// The collection ID where the user record is stored
  final String? collectionId;
  /// The collection name where the user record is stored
  final String? collectionName;
  final String _userId;
  final Map<String, dynamic> _claims;

  @override
  String get userId => _userId;

  @override
  Map<String, dynamic> get claims => _claims;

  /// Gets the user's email address
  String? get email => record['email'] as String?;
  /// Gets the user's username
  String? get username => record['username'] as String?;
  /// Gets whether the user's email is verified
  bool get verified => record['verified'] as bool? ?? false;
  /// Gets when the user record was created
  DateTime? get created => record['created'] != null 
      ? DateTime.tryParse(record['created'] as String) 
      : null;
  /// Gets when the user record was last updated
  DateTime? get updated => record['updated'] != null 
      ? DateTime.tryParse(record['updated'] as String) 
      : null;

  /// Gets a specific field from the user record
  T? getRecordField<T>(String fieldName) => record[fieldName] as T?;
}
