import 'package:test/test.dart';
import 'integration/pocketbase_auth_validator_test.dart' as integration_tests;
import 'pocketbase_auth_test.dart' as auth_tests;
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    print('Starting PocketBase container for all tests...');
    await PocketBaseTestHelper.startPocketBase();
  });

  tearDownAll(() async {
    print('Stopping PocketBase container after all tests...');
    await PocketBaseTestHelper.stopPocketBase();
  });

  group('All Tests', () {
    integration_tests.main();
    auth_tests.main();
  });
}
