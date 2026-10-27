import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StaleWorkspaceResponseException implements Exception {
  final String? requestWorkspaceId;
  final int currentWorkspaceEpoch;
  final int requestEpoch;

  const StaleWorkspaceResponseException({
    this.requestWorkspaceId,
    required this.currentWorkspaceEpoch,
    required this.requestEpoch,
  });

  @override
  String toString() =>
      'StaleWorkspaceResponseException: Discarded response from prior workspace epoch ($requestEpoch vs current $currentWorkspaceEpoch)';
}

class ApiClient {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _envAiUrl = String.fromEnvironment('AI_BASE_URL');
  static const String _envDevHost = String.fromEnvironment('DEV_HOST');
  static const String _envApiHost = String.fromEnvironment('API_HOST');
  static const bool _envUseLocalhost = bool.fromEnvironment('USE_LOCALHOST', defaultValue: false);
  static const bool _envUseAdbReverse = bool.fromEnvironment('USE_ADB_REVERSE', defaultValue: false);

  /// Resolves the platform-aware development host:
  /// 1. Compile-time host override (`DEV_HOST` or `API_HOST`).
  /// 2. Explicit localhost flag (`USE_LOCALHOST=true` or `USE_ADB_REVERSE=true`) for physical devices over `adb reverse`.
  /// 3. Platform default:
  ///    - Android (`TargetPlatform.android` when not Web): `10.0.2.2` (Android emulator host loopback alias).
  ///    - Other platforms (Web, iOS Simulator, macOS/desktop): `localhost`.
  static String get developmentHost {
    if (_envDevHost.isNotEmpty) return _envDevHost;
    if (_envApiHost.isNotEmpty) return _envApiHost;
    if (_envUseLocalhost || _envUseAdbReverse) return 'localhost';

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  static String get defaultBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kReleaseMode) {
      return 'https://acadex-backend-main.onrender.com/api/v1';
    }
    return 'http://$developmentHost:5050/api/v1';
  }

  static String get defaultAiUrl {
    if (_envAiUrl.isNotEmpty) return _envAiUrl;
    if (kReleaseMode) {
      return 'https://acadex-backend-main.onrender.com/api/v1/ai';
    }
    return 'http://$developmentHost:5001/api/v1/ai';
  }

  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyActiveWorkspaceId = 'active_workspace_id';

  int _workspaceEpoch = 0;
  int get currentWorkspaceEpoch => _workspaceEpoch;

  void incrementWorkspaceEpoch() {
    _workspaceEpoch++;
    debugPrint('[API_CLIENT] Advanced workspace epoch to $_workspaceEpoch');
  }

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
            final workspaceId = await _storage.read(key: keyActiveWorkspaceId);
            if (workspaceId != null && workspaceId.isNotEmpty) {
              options.headers['X-Workspace-Id'] = workspaceId;
            }
            options.extra['workspace_epoch'] = _workspaceEpoch;
            options.extra['request_workspace_id'] = workspaceId;
          } catch (_) {}
          return handler.next(options);
        },

        onResponse: (response, handler) {
          final reqEpoch = response.requestOptions.extra['workspace_epoch'];
          final isAuthOrSwitch = response.requestOptions.path.contains('/auth/login') ||
              response.requestOptions.path.contains('/auth/refresh') ||
              response.requestOptions.path.contains('/auth/activate') ||
              response.requestOptions.path.contains('/workspaces/switch');

          if (!isAuthOrSwitch && reqEpoch != null && reqEpoch != _workspaceEpoch) {
            debugPrint(
              '[API_CLIENT] Discarding response from stale workspace epoch $reqEpoch (current is $_workspaceEpoch)',
            );
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                error: StaleWorkspaceResponseException(
                  requestWorkspaceId:
                      response.requestOptions.extra['request_workspace_id'] as String?,
                  currentWorkspaceEpoch: _workspaceEpoch,
                  requestEpoch: reqEpoch as int,
                ),
                type: DioExceptionType.unknown,
              ),
            );
          }
          return handler.next(response);
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
    incrementWorkspaceEpoch();
    try {
      await _storage.delete(key: keyAccessToken);
      await _storage.delete(key: keyRefreshToken);
      await _storage.delete(key: keyActiveWorkspaceId);
    } catch (_) {}
  }

  Future<void> clearToken() async => clearTokens();

  Future<void> setActiveWorkspace(String? workspaceId) async {
    if (workspaceId != null && workspaceId.isNotEmpty) {
      await _storage.write(key: keyActiveWorkspaceId, value: workspaceId);
    } else {
      await _storage.delete(key: keyActiveWorkspaceId);
    }
  }

  Future<String?> getActiveWorkspace() async => _storage.read(key: keyActiveWorkspaceId);

  Future<String?> getToken() async => _storage.read(key: keyAccessToken);
  Future<String?> getRefreshToken() async => _storage.read(key: keyRefreshToken);

}

final apiClient = ApiClient();
