import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/network/api_client.dart';
import 'package:campus_management/core/realtime/services/realtime_service.dart';
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
    test('Android platform resolves defaultBaseUrl to 10.0.2.2 in development for emulator', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      ApiClient.isAndroidEmulator = true;
      try {
        expect(ApiClient.developmentHost, '10.0.2.2');
        expect(ApiClient.defaultBaseUrl, 'http://10.0.2.2:5050/api/v1');
        expect(ApiClient.defaultAiUrl, 'http://10.0.2.2:5001/api/v1/ai');
        expect(RealtimeService().activeWsUrl, 'ws://10.0.2.2:5050/ws');
      } finally {
        debugDefaultTargetPlatformOverride = null;
        ApiClient.isAndroidEmulator = false;
      }
    });

    test('Android physical device resolves defaultBaseUrl to secure remote endpoint in development', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      ApiClient.isAndroidEmulator = false;
      try {
        expect(ApiClient.developmentHost, 'localhost');
        expect(ApiClient.defaultBaseUrl, ApiClient.remoteDevelopmentBaseUrl);
        expect(ApiClient.defaultAiUrl, ApiClient.remoteDevelopmentAiUrl);
        expect(RealtimeService().activeWsUrl, 'wss://acadex-backend-main.onrender.com/ws');
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('updateBaseUrl dynamically synchronizes dio and aiDio instances', () {
      ApiClient.updateBaseUrl('http://192.168.1.100:5050/api/v1', newAiUrl: 'http://192.168.1.100:5001/api/v1/ai');

      expect(ApiClient.defaultBaseUrl, 'http://192.168.1.100:5050/api/v1');
      expect(ApiClient.defaultAiUrl, 'http://192.168.1.100:5001/api/v1/ai');
      expect(apiClient.dio.options.baseUrl, 'http://192.168.1.100:5050/api/v1');
      expect(apiClient.aiDio.options.baseUrl, 'http://192.168.1.100:5001/api/v1/ai');

      // Reset
      ApiClient.updateBaseUrl('');
    });

    test('Non-Android platform resolves defaultBaseUrl to localhost in development', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        expect(ApiClient.developmentHost, 'localhost');
        expect(ApiClient.defaultBaseUrl, 'http://localhost:5050/api/v1');
        expect(ApiClient.defaultAiUrl, 'http://localhost:5001/api/v1/ai');
        expect(RealtimeService().activeWsUrl, 'ws://localhost:5050/ws');
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
