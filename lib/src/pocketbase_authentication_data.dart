import 'package:kiss_auth/kiss_authentication.dart';

class PocketBaseAuthenticationData extends AuthenticationData {
  final Map<String, dynamic> record;
  final String? collectionId;
  final String? collectionName;
  final String _userId;
  final Map<String, dynamic> _claims;

  PocketBaseAuthenticationData({
    required String userId,
    required Map<String, dynamic> claims,
    required this.record,
    this.collectionId,
    this.collectionName,
  }) : _userId = userId, _claims = claims;

  @override
  String get userId => _userId;

  @override
  Map<String, dynamic> get claims => _claims;

  String? get email => record['email'];
  String? get username => record['username'];
  bool get verified => record['verified'] ?? false;
  DateTime? get created => record['created'] != null 
      ? DateTime.tryParse(record['created']) 
      : null;
  DateTime? get updated => record['updated'] != null 
      ? DateTime.tryParse(record['updated']) 
      : null;

  T? getRecordField<T>(String fieldName) => record[fieldName] as T?;
}