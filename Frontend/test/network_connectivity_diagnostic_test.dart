import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/network/api_client.dart';
import 'package:campus_management/core/network/network_error_diagnostic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkErrorDiagnostic Unit Tests', () {
    test('Diagnoses TLS certificate failure accurately', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.unknown,
        error: const TlsException('Handshake error: CERTIFICATE_VERIFY_FAILED'),
      );

      final diagnostic = NetworkErrorDiagnostic.diagnose(dioException);
      expect(diagnostic.kind, NetworkFailureKind.tlsCertificateError);
      expect(diagnostic.userMessage, contains('TLS certificate error'));
    });

    test('Diagnoses Android cleartext HTTP restriction', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.connectionError,
        message: 'CLEARTEXT communication to 192.168.1.6 not permitted by network security policy',
      );

      final diagnostic = NetworkErrorDiagnostic.diagnose(dioException);
      expect(diagnostic.kind, NetworkFailureKind.androidCleartextRestricted);
      expect(diagnostic.userMessage, contains('Cleartext HTTP communication is blocked'));
    });

    test('Diagnoses DNS resolution failure', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.connectionError,
        error: const SocketException('Failed host lookup: acadex.internal'),
      );

      final diagnostic = NetworkErrorDiagnostic.diagnose(dioException);
      expect(diagnostic.kind, NetworkFailureKind.dnsResolutionError);
      expect(diagnostic.userMessage, contains('Unable to resolve ACADEX server address'));
    });

    test('Diagnoses Connection Refused', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.connectionError,
        error: const SocketException('OS Error: Connection refused, errno = 111'),
      );

      final diagnostic = NetworkErrorDiagnostic.diagnose(dioException);
      expect(diagnostic.kind, NetworkFailureKind.connectionRefused);
      expect(diagnostic.userMessage, contains('Connection refused by server'));
    });

    test('Diagnoses Connection and Receive Timeout', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.connectionTimeout,
        message: 'Connecting took longer than 15000ms',
      );

      final diagnostic = NetworkErrorDiagnostic.diagnose(dioException);
      expect(diagnostic.kind, NetworkFailureKind.timeout);
      expect(diagnostic.userMessage, contains('Connection timed out'));
    });

    test('Diagnoses HTTP 401 Unauthorized with backend message', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
          data: {
            'success': false,
            'error': {'code': 'UNAUTHORIZED', 'message': 'Invalid credentials'},
          },
        ),
      );

      final diagnostic = NetworkErrorDiagnostic.diagnose(dioException);
      expect(diagnostic.kind, NetworkFailureKind.authenticationFailed);
      expect(diagnostic.userMessage, 'Invalid credentials');
    });

    test('Diagnoses HTTP 403 Forbidden', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 403,
          data: {
            'success': false,
            'error': {'code': 'FORBIDDEN', 'message': 'Account is deactivated'},
          },
        ),
      );

      final diagnostic = NetworkErrorDiagnostic.diagnose(dioException);
      expect(diagnostic.kind, NetworkFailureKind.forbidden);
      expect(diagnostic.userMessage, 'Account is deactivated');
    });

    test('Diagnoses HTTP 404 Route Not Found', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/unknown-route'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/unknown-route'),
          statusCode: 404,
        ),
      );

      final diagnostic = NetworkErrorDiagnostic.diagnose(dioException);
      expect(diagnostic.kind, NetworkFailureKind.routeNotFound);
      expect(diagnostic.userMessage, contains('route not found'));
    });

    test('Diagnoses HTTP 500 Database Unavailable', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 500,
          data: {
            'success': false,
            'error': {'code': 'INTERNAL_ERROR', 'message': 'MongoNetworkError: failed to connect to database'},
          },
        ),
      );

      final diagnostic = NetworkErrorDiagnostic.diagnose(dioException);
      expect(diagnostic.kind, NetworkFailureKind.databaseUnavailable);
      expect(diagnostic.userMessage, contains('database connection is unavailable'));
    });
  });

  group('ApiClient Target Environment and Remote Fallback Tests', () {
    test('Default base URL returns 10.0.2.2 when running on Android emulator', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      ApiClient.isAndroidEmulator = true;
      try {
        expect(ApiClient.defaultBaseUrl, 'http://10.0.2.2:5050/api/v1');
      } finally {
        debugDefaultTargetPlatformOverride = null;
        ApiClient.isAndroidEmulator = false;
      }
    });

    test('updateBaseUrl updates client dio base options correctly', () {
      ApiClient.updateBaseUrl('https://custom-domain.acadex.edu/api/v1');
      expect(ApiClient.defaultBaseUrl, 'https://custom-domain.acadex.edu/api/v1');
      expect(apiClient.dio.options.baseUrl, 'https://custom-domain.acadex.edu/api/v1');
      expect(apiClient.aiDio.options.baseUrl, 'https://custom-domain.acadex.edu/api/v1/ai');
    });

    test('Remote fallback constant points to Render staging backend', () {
      expect(ApiClient.remoteDevelopmentBaseUrl, 'https://acadex-backend-main.onrender.com/api/v1');
      expect(ApiClient.remoteDevelopmentAiUrl, 'https://acadex-backend-main.onrender.com/api/v1/ai');
    });
  });
}
