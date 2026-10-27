import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/network/network_error_diagnostic.dart';

void main() {
  group('NetworkErrorDiagnostic Tests', () {
    final testRequestOptions = RequestOptions(path: '/auth/login', baseUrl: 'http://localhost:5050/api/v1');

    test('Diagnoses TLS certificate validation failure correctly', () {
      final dioError = DioException(
        requestOptions: testRequestOptions,
        type: DioExceptionType.badCertificate,
        error: const CertificateException('CERTIFICATE_VERIFY_FAILED: certificate has expired'),
      );

      final diag = NetworkErrorDiagnostic.diagnose(dioError);
      expect(diag.kind, NetworkFailureKind.tlsCertificateError);
      expect(diag.userMessage, contains('TLS certificate error'));
    });

    test('Diagnoses Android Cleartext HTTP policy restriction correctly', () {
      final dioError = DioException(
        requestOptions: testRequestOptions,
        type: DioExceptionType.unknown,
        message: 'CLEARTEXT communication to 192.168.1.6 not permitted by network security policy',
      );

      final diag = NetworkErrorDiagnostic.diagnose(dioError);
      expect(diag.kind, NetworkFailureKind.androidCleartextRestricted);
      expect(diag.userMessage, contains('Cleartext HTTP communication is blocked'));
    });

    test('Diagnoses DNS host resolution failure correctly', () {
      final dioError = DioException(
        requestOptions: testRequestOptions,
        type: DioExceptionType.connectionError,
        error: const SocketException('Failed host lookup: acadex-backend.local', osError: OSError('nodename nor servname provided', 7)),
      );

      final diag = NetworkErrorDiagnostic.diagnose(dioError);
      expect(diag.kind, NetworkFailureKind.dnsResolutionError);
      expect(diag.userMessage, contains('Unable to resolve ACADEX server address'));
    });

    test('Diagnoses Connection Refused correctly', () {
      final dioError = DioException(
        requestOptions: testRequestOptions,
        type: DioExceptionType.connectionError,
        error: const SocketException('Connection refused', osError: OSError('Connection refused', 111)),
      );

      final diag = NetworkErrorDiagnostic.diagnose(dioError);
      expect(diag.kind, NetworkFailureKind.connectionRefused);
      expect(diag.userMessage, contains('Connection refused by server'));
    });

    test('Diagnoses Connection Timeout correctly', () {
      final dioError = DioException(
        requestOptions: testRequestOptions,
        type: DioExceptionType.connectionTimeout,
        message: 'The connection has timed out after 15000ms',
      );

      final diag = NetworkErrorDiagnostic.diagnose(dioError);
      expect(diag.kind, NetworkFailureKind.timeout);
      expect(diag.userMessage, contains('Connection timed out'));
    });

    test('Diagnoses HTTP 401 Invalid Credentials correctly', () {
      final dioError = DioException(
        requestOptions: testRequestOptions,
        response: Response(
          requestOptions: testRequestOptions,
          statusCode: 401,
          data: {'error': {'message': 'Invalid credentials'}},
        ),
      );

      final diag = NetworkErrorDiagnostic.diagnose(dioError);
      expect(diag.kind, NetworkFailureKind.authenticationFailed);
      expect(diag.userMessage, 'Invalid credentials');
    });

    test('Diagnoses HTTP 403 Account Pending Activation correctly', () {
      final dioError = DioException(
        requestOptions: testRequestOptions,
        response: Response(
          requestOptions: testRequestOptions,
          statusCode: 403,
          data: {'error': {'message': 'Account is pending activation. Please activate your account first.'}},
        ),
      );

      final diag = NetworkErrorDiagnostic.diagnose(dioError);
      expect(diag.kind, NetworkFailureKind.forbidden);
      expect(diag.userMessage, contains('pending activation'));
    });

    test('Diagnoses HTTP 404 Route Not Found correctly', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/auth/nonexistent'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/auth/nonexistent'),
          statusCode: 404,
        ),
      );

      final diag = NetworkErrorDiagnostic.diagnose(dioError);
      expect(diag.kind, NetworkFailureKind.routeNotFound);
      expect(diag.userMessage, contains('route not found'));
    });

    test('Diagnoses HTTP 500 Backend Server Error correctly', () {
      final dioError = DioException(
        requestOptions: testRequestOptions,
        response: Response(
          requestOptions: testRequestOptions,
          statusCode: 500,
          data: {'error': {'message': 'Internal Server Error'}},
        ),
      );

      final diag = NetworkErrorDiagnostic.diagnose(dioError);
      expect(diag.kind, NetworkFailureKind.backendServerError);
      expect(diag.userMessage, contains('internal error'));
    });

    test('Diagnoses HTTP 500 Database Unavailable correctly', () {
      final dioError = DioException(
        requestOptions: testRequestOptions,
        response: Response(
          requestOptions: testRequestOptions,
          statusCode: 500,
          data: {'error': {'message': 'MongoDB Atlas connection lost'}},
        ),
      );

      final diag = NetworkErrorDiagnostic.diagnose(dioError);
      expect(diag.kind, NetworkFailureKind.databaseUnavailable);
      expect(diag.userMessage, contains('database connection is unavailable'));
    });
  });
}
