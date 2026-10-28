import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Categories of network/server connectivity failures for precise diagnosis.
enum NetworkFailureKind {
  tlsCertificateError,
  androidCleartextRestricted,
  dnsResolutionError,
  connectionRefused,
  timeout,
  offlineOrUnreachable,
  authenticationFailed,
  forbidden,
  routeNotFound,
  backendServerError,
  databaseUnavailable,
  unknown,
}

/// Diagnoses Dio and network failures accurately, distinguishing
/// between DNS errors, timeouts, connection refused, cleartext HTTP blocks,
/// TLS cert failures, and HTTP status codes, while safely logging technical details.
class NetworkErrorDiagnostic {
  final NetworkFailureKind kind;
  final String userMessage;
  final String technicalMessage;
  final int? statusCode;
  final Uri? requestUri;

  const NetworkErrorDiagnostic({
    required this.kind,
    required this.userMessage,
    required this.technicalMessage,
    this.statusCode,
    this.requestUri,
  });

  /// Analyzes a [DioException] and returns a detailed [NetworkErrorDiagnostic].
  static NetworkErrorDiagnostic diagnose(
    DioException e, {
    String fallback = 'Operation failed',
  }) {
    final status = e.response?.statusCode;
    final uri = e.requestOptions.uri;
    final rawMessage = e.message ?? '';
    final innerError = e.error;
    final innerErrorString = innerError != null ? innerError.toString() : '';
    final combined = '$rawMessage $innerErrorString ${e.type}'.toLowerCase();

    // Preserve original error for safe diagnostic logging
    debugPrint(
      '[ACADEX DIAGNOSTIC] Target: $uri | Type: ${e.type} | Status: $status | '
      'Error: $innerErrorString | Message: $rawMessage',
    );

    // 1. Check response-less network layer errors
    if (e.response == null) {
      // A. TLS Certificate Errors
      if (e.type == DioExceptionType.badCertificate ||
          innerError is HandshakeException ||
          innerError is TlsException ||
          combined.contains('handshake') ||
          combined.contains('certificate_verify_failed') ||
          combined.contains('tlsexception') ||
          combined.contains('cert_has_expired') ||
          combined.contains('bad certificate')) {
        return NetworkErrorDiagnostic(
          kind: NetworkFailureKind.tlsCertificateError,
          userMessage:
              'Secure connection failed (TLS certificate error). Please check your device date and security settings.',
          technicalMessage:
              'TLS Handshake / Certificate failure: $innerErrorString',
          statusCode: status,
          requestUri: uri,
        );
      }

      // B. Android Cleartext HTTP Restrictions
      if (combined.contains('cleartext') ||
          combined.contains('not permitted by network security policy') ||
          combined.contains('cleartext communication')) {
        return NetworkErrorDiagnostic(
          kind: NetworkFailureKind.androidCleartextRestricted,
          userMessage:
              'Cleartext HTTP communication is blocked by device security policy. Please use HTTPS or permit cleartext traffic.',
          technicalMessage: 'Cleartext HTTP blocked: $rawMessage',
          statusCode: status,
          requestUri: uri,
        );
      }

      // C. DNS / Host Resolution Failure
      if (innerError is SocketException &&
              (innerError.osError?.errorCode == 7 ||
                  innerError.message.toLowerCase().contains(
                    'failed host lookup',
                  )) ||
          combined.contains('failed host lookup') ||
          combined.contains('nodename nor servname provided')) {
        return NetworkErrorDiagnostic(
          kind: NetworkFailureKind.dnsResolutionError,
          userMessage:
              'Unable to resolve ACADEX server address. Please verify your internet connection or host settings.',
          technicalMessage: 'DNS resolution failure: $innerErrorString',
          statusCode: status,
          requestUri: uri,
        );
      }

      // D. Connection Refused
      if ((innerError is SocketException &&
              (innerError.osError?.errorCode == 111 ||
                  innerError.osError?.errorCode == 61 ||
                  innerError.message.toLowerCase().contains(
                    'connection refused',
                  ))) ||
          combined.contains('connection refused')) {
        return NetworkErrorDiagnostic(
          kind: NetworkFailureKind.connectionRefused,
          userMessage:
              'Connection refused by server. The ACADEX backend service may not be running or the port is inaccessible.',
          technicalMessage: 'Connection refused: $innerErrorString',
          statusCode: status,
          requestUri: uri,
        );
      }

      // E. Connection, Send, or Receive Timeout
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          combined.contains('timed out') ||
          combined.contains('timeout')) {
        return NetworkErrorDiagnostic(
          kind: NetworkFailureKind.timeout,
          userMessage:
              'Connection timed out while reaching ACADEX server. Please check your connection and try again.',
          technicalMessage: 'Timeout (${e.type}): $rawMessage',
          statusCode: status,
          requestUri: uri,
        );
      }

      // F. Generic Connection Error (Offline, no route, 10.0.2.2 on physical device)
      if (e.type == DioExceptionType.connectionError ||
          combined.contains('xmlhttprequest') ||
          combined.contains('network is unreachable') ||
          combined.contains('no route to host')) {
        return NetworkErrorDiagnostic(
          kind: NetworkFailureKind.offlineOrUnreachable,
          userMessage:
              'Unable to reach ACADEX server. Please check your network or verify backend service connectivity.',
          technicalMessage: 'Connection error: $rawMessage ($innerErrorString)',
          statusCode: status,
          requestUri: uri,
        );
      }
    }

    // 2. HTTP Status Codes with Response
    if (status != null) {
      final backendMsg = e.response?.data is Map
          ? (e.response?.data['error']?['message'] ??
                e.response?.data['message'])
          : null;

      if (status == 401) {
        return NetworkErrorDiagnostic(
          kind: NetworkFailureKind.authenticationFailed,
          userMessage:
              backendMsg?.toString() ??
              'Invalid credentials. Please verify your identifier and password.',
          technicalMessage: 'HTTP 401: $backendMsg',
          statusCode: status,
          requestUri: uri,
        );
      }

      if (status == 403) {
        return NetworkErrorDiagnostic(
          kind: NetworkFailureKind.forbidden,
          userMessage:
              backendMsg?.toString() ??
              'Access denied. Your account may be inactive, pending activation, or suspended.',
          technicalMessage: 'HTTP 403: $backendMsg',
          statusCode: status,
          requestUri: uri,
        );
      }

      if (status == 404) {
        return NetworkErrorDiagnostic(
          kind: NetworkFailureKind.routeNotFound,
          userMessage:
              'ACADEXSYNC API route not found ($uri). Please verify backend versioning.',
          technicalMessage: 'HTTP 404 Route Not Found: $uri',
          statusCode: status,
          requestUri: uri,
        );
      }

      if (status >= 500) {
        final isDbError =
            backendMsg != null &&
            (backendMsg.toString().toLowerCase().contains('database') ||
                backendMsg.toString().toLowerCase().contains('mongo'));

        return NetworkErrorDiagnostic(
          kind: isDbError
              ? NetworkFailureKind.databaseUnavailable
              : NetworkFailureKind.backendServerError,
          userMessage: isDbError
              ? 'ACADEXSYNC database connection is unavailable. Please try again in a moment.'
              : 'ACADEXSYNC server encountered an internal error. Please try again shortly.',
          technicalMessage: 'HTTP $status Server Error: $backendMsg',
          statusCode: status,
          requestUri: uri,
        );
      }
    }

    // Default fallback
    final message =
        (e.response?.data is Map
            ? (e.response?.data['error']?['message'] ??
                  e.response?.data['message'])
            : null) ??
        (rawMessage.isNotEmpty && !rawMessage.contains('XMLHttpRequest')
            ? rawMessage
            : fallback);

    return NetworkErrorDiagnostic(
      kind: NetworkFailureKind.unknown,
      userMessage: message.toString(),
      technicalMessage: 'Unclassified Dio error ($status): $rawMessage',
      statusCode: status,
      requestUri: uri,
    );
  }

  /// Convenience helper that returns an [Exception] with the user-facing message.
  static Exception toException(DioException e, String fallback) {
    final diagnostic = diagnose(e, fallback: fallback);
    return Exception(diagnostic.userMessage);
  }
}
