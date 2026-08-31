import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _envAiUrl = String.fromEnvironment('AI_BASE_URL');

  static String get defaultBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.1.6:5050/api/v1';
    }
    return 'http://localhost:5050/api/v1';
  }

  static String get defaultAiUrl {
    if (_envAiUrl.isNotEmpty) return _envAiUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.1.6:5001/api/v1/ai';
    }
    return 'http://localhost:5001/api/v1/ai';
  }

  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';

  late final Dio dio;
  late final Dio aiDio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;

  ApiClient({
    String? baseUrl,
    String? aiUrl,
    Dio? customDio,
    Dio? customAiDio,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage() {
    final activeBaseUrl = baseUrl ?? defaultBaseUrl;
    final activeAiUrl = aiUrl ?? defaultAiUrl;

    dio = customDio ??
        Dio(BaseOptions(
          baseUrl: activeBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ));

    aiDio = customAiDio ??
        Dio(BaseOptions(
          baseUrl: activeAiUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ));

    if (customDio == null) {
      // Primary Auth & Refresh Interceptor
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _storage.read(key: keyAccessToken);
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final isAuthEndpoint = error.requestOptions.path.contains('/auth/login') ||
              error.requestOptions.path.contains('/auth/refresh') ||
              error.requestOptions.path.contains('/auth/activate');

          if (error.response?.statusCode == 401 && !isAuthEndpoint && !_isRefreshing) {
            _isRefreshing = true;
            try {
              final refreshToken = await _storage.read(key: keyRefreshToken);
              if (refreshToken != null && refreshToken.isNotEmpty) {
                // Isolated Dio to avoid infinite interceptor loops
                final refreshDio = Dio(BaseOptions(baseUrl: activeBaseUrl));
                final response = await refreshDio.post('/auth/refresh', data: {
                  'refreshToken': refreshToken,
                });

                if (response.statusCode == 200 && response.data != null) {
                  final data = response.data['data'] as Map<String, dynamic>? ?? response.data;
                  final newAccessToken = data['accessToken'] as String?;
                  if (newAccessToken != null) {
                    await _storage.write(key: keyAccessToken, value: newAccessToken);

                    // Retry original request with fresh access token
                    final opts = error.requestOptions;
                    opts.headers['Authorization'] = 'Bearer $newAccessToken';
                    final clonedRequest = await dio.fetch(opts);
                    _isRefreshing = false;
                    return handler.resolve(clonedRequest);
                  }
                }
              }
            } catch (_) {
              // Refresh failed — clear stored tokens
              await clearTokens();
            } finally {
              _isRefreshing = false;
            }
          }

          return handler.next(error);
        },
      ));
    }

    if (customAiDio == null) {
      aiDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _storage.read(key: keyAccessToken);
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
          return handler.next(options);
        },
      ));
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: keyRefreshToken, value: refreshToken);
    }
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: keyAccessToken, value: token);
  }

  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: keyAccessToken);
      await _storage.delete(key: keyRefreshToken);
    } catch (_) {}
  }

  Future<void> clearToken() async => clearTokens();

  Future<String?> getToken() async => _storage.read(key: keyAccessToken);
  Future<String?> getRefreshToken() async => _storage.read(key: keyRefreshToken);
}

final apiClient = ApiClient();
