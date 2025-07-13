import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class PocketBaseTestHelper {
  static const String baseUrl = 'http://localhost:8090';
  static const String adminEmail = 'admin@test.com';
  static const String adminPassword = 'testpassword123';
  
  static bool _isStarting = false;
  static bool _isStarted = false;
  static Completer<void>? _startupCompleter;
  
  static Future<void> startPocketBase() async {
    if (_isStarted || await _isPocketBaseRunning()) {
      print('PocketBase is already running!');
      _isStarted = true;
      return;
    }
    
    if (_isStarting) {
      print('PocketBase is already starting, waiting...');
      await _startupCompleter?.future;
      return;
    }
    
    _isStarting = true;
    _startupCompleter = Completer<void>();
    
    try {
      print('Starting PocketBase container...');
      
      await _forceCleanupContainers();
      
      await _runCommand(['docker-compose', '-f', 'docker-compose.test.yml', 'up', '-d', '--force-recreate']);
      
      await _waitForPocketBase();
      print('PocketBase is ready!');
      
      _isStarted = true;
      _startupCompleter!.complete();
    } catch (e) {
      _startupCompleter!.completeError(e);
      rethrow;
    } finally {
      _isStarting = false;
    }
  }

  static Future<void> stopPocketBase() async {
    if (!_isStarted) {
      print('PocketBase was not started by tests, skipping stop.');
      return;
    }
    
    print('Stopping PocketBase container...');
    
    await _runCommand(['docker-compose', '-f', 'docker-compose.test.yml', 'down']);
    
    _isStarted = false;
    print('PocketBase stopped.');
  }

  static Future<bool> _isPocketBaseRunning() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _waitForPocketBase() async {
    const maxAttempts = 30;
    const delay = Duration(seconds: 2);
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      if (await _isPocketBaseRunning()) {
        return;
      }
      
      print('Attempt $attempt: PocketBase not ready yet...');
      
      if (attempt < maxAttempts) {
        await Future.delayed(delay);
      }
    }
    
    throw Exception('PocketBase failed to start after $maxAttempts attempts');
  }

  static Future<String> createTestUser({
    required String email,
    required String password,
    String? username,
    String? name,
  }) async {
    final client = http.Client();
    
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/collections/users/records'),
        headers: {'Content-Type': 'application/json'},
        body: '''
        {
          "email": "$email",
          "password": "$password",
          "passwordConfirm": "$password"
        }
        ''',
      );
      
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to create test user: ${response.statusCode} ${response.body}');
      }
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> authenticateTestUser({
    required String email,
    required String password,
  }) async {
    final client = http.Client();
    
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/collections/users/auth-with-password'),
        headers: {'Content-Type': 'application/json'},
        body: '''
        {
          "identity": "$email",
          "password": "$password"
        }
        ''',
      );
      
      if (response.statusCode == 200) {
        return {
          'statusCode': response.statusCode,
          'body': response.body,
        };
      } else {
        throw Exception('Failed to authenticate test user: ${response.statusCode} ${response.body}');
      }
    } finally {
      client.close();
    }
  }

  static Future<void> _forceCleanupContainers() async {
    print('Checking for existing containers...');
    
    try {
      final containerCheck = await Process.run('docker', ['ps', '-aq', '--filter', 'name=pocketbase_test']);
      if (containerCheck.exitCode == 0 && containerCheck.stdout.toString().trim().isEmpty) {
        print('No existing pocketbase_test container found.');
        return;
      }
    } catch (e) {
      print('Warning: Failed to check for existing containers: $e');
    }
    
    print('Cleaning up existing containers...');
    
    try {
      await _runCommand(['docker-compose', '-f', 'docker-compose.test.yml', 'down', '--remove-orphans', '--volumes']);
    } catch (e) {
      print('Warning: Failed to cleanup with docker-compose: $e');
    }
    
    try {
      final result = await Process.run('docker', ['ps', '-aq', '--filter', 'name=pocketbase_test']);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final containerIds = result.stdout.toString().trim().split('\n').where((id) => id.isNotEmpty);
        for (final containerId in containerIds) {
          print('Force removing container: $containerId');
          await Process.run('docker', ['rm', '-f', containerId]);
        }
      }
    } catch (e) {
      print('Warning: Failed to remove containers by name: $e');
    }
    
    try {
      final result = await Process.run('docker', ['ps', '-aq', '--filter', 'ancestor=pocketbase/pocketbase']);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final containerIds = result.stdout.toString().trim().split('\n').where((id) => id.isNotEmpty);
        for (final containerId in containerIds) {
          print('Force removing pocketbase container: $containerId');
          await Process.run('docker', ['rm', '-f', containerId]);
        }
      }
    } catch (e) {
      print('Warning: Failed to remove pocketbase containers: $e');
    }
    
    await Future.delayed(Duration(seconds: 1));
  }

  static Future<void> _runCommand(List<String> command) async {
    final result = await Process.run(
      command.first,
      command.skip(1).toList(),
      workingDirectory: Directory.current.path,
    );
    
    if (result.exitCode != 0) {
      throw Exception('Command failed: ${command.join(' ')}\n${result.stderr}');
    }
  }

  static Future<void> cleanupTestData() async {
    try {
      await _runCommand(['docker-compose', '-f', 'docker-compose.test.yml', 'down', '-v']);
    } catch (e) {
      print('Warning: Failed to cleanup test data: $e');
    }
  }
}