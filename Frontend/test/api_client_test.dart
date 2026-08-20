import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/network/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient Tests', () {
    test('Initializes with correct default configuration', () {
      final client = ApiClient();
      expect(client.dio.options.baseUrl, isNotEmpty);
      expect(client.dio.options.headers['Content-Type'], 'application/json');
      expect(client.aiDio.options.baseUrl, isNotEmpty);
    });

    test('saveTokens and clearTokens operate on storage', () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = FlutterSecureStorage();
      final client = ApiClient(storage: storage);

      await client.saveTokens(accessToken: 'mock_access', refreshToken: 'mock_refresh');
      expect(await client.getToken(), 'mock_access');
      expect(await client.getRefreshToken(), 'mock_refresh');

      await client.clearTokens();
      expect(await client.getToken(), isNull);
      expect(await client.getRefreshToken(), isNull);
    });
  });
}
