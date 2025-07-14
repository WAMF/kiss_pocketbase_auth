import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kiss_auth/kiss_authentication.dart';
import 'package:kiss_pocketbase_example/screens/login_screen.dart';
import 'package:kiss_pocketbase_example/services/auth_service.dart';

/// Extension for extracting PocketBase-specific data from AuthenticationData
extension PocketBaseAuthenticationDataExtension on AuthenticationData {
  /// Gets the PocketBase record from claims
  Map<String, dynamic>? get pocketBaseRecord =>
      claims['record'] as Map<String, dynamic>?;

  /// Gets the email from PocketBase record
  String get email => pocketBaseRecord?['email']?.toString() ?? 'N/A';

  /// Gets the username from PocketBase record
  String get username => pocketBaseRecord?['username']?.toString() ?? 'N/A';

  /// Gets the verified status from PocketBase record
  String get verifiedStatus => 
      (pocketBaseRecord?['verified'] == true) ? 'Yes' : 'No';

  /// Gets the collection name from claims
  String get collectionName => claims['collectionName']?.toString() ?? 'N/A';

  /// Gets the created timestamp from PocketBase record
  String get createdAt => pocketBaseRecord?['created']?.toString() ?? 'N/A';

  /// Gets the updated timestamp from PocketBase record
  String get updatedAt => pocketBaseRecord?['updated']?.toString() ?? 'N/A';
}

/// Home screen displaying user information and authentication data
class HomeScreen extends StatelessWidget {
  /// Constructor for HomeScreen
  HomeScreen({required this.authData, super.key});

  /// The authentication data for the logged-in user
  final AuthenticationData authData;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (context.mounted) {
                await Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('User ID', authData.userId),
                    _buildInfoRow('Email', authData.email),
                    _buildInfoRow('Username', authData.username),
                    _buildInfoRow('Verified', authData.verifiedStatus),
                    _buildInfoRow('Collection', authData.collectionName),
                    _buildInfoRow('Created', authData.createdAt),
                    _buildInfoRow('Updated', authData.updatedAt),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentication Claims',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        _formatClaims(authData.claims),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Record Data',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        _formatRecord(authData.claims),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (authData.claims['token'] != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JWT Token',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          authData.claims['token'] as String,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatClaims(Map<String, dynamic> claims) {
    final filteredClaims = Map<String, dynamic>.from(claims)
      ..remove('record'); // Remove record from claims display
    return _prettyPrintJson(filteredClaims);
  }

  String _formatRecord(Map<String, dynamic> record) {
    return _prettyPrintJson(record);
  }

  String _prettyPrintJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}
