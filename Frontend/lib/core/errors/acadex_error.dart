import 'package:dio/dio.dart';
import '../observability/logger.dart';

/// Authoritative category classification for application-level errors
enum ErrorCategory {
  validation,      // 400, 422: Invalid user input or rule violation
  unauthenticated, // 401: Expired session or missing credentials
  forbidden,       // 403: Role or scope permission denied
  notFound,        // 404: Resource no longer exists
  conflict,        // 409: Duplicate key or operation blocked by dependencies
  rateLimited,     // 429: Too many requests
  serverError,     // 500+: Internal backend failure
  networkTimeout,  // Connect, send, or receive timeout
  offline,         // Socket error, host lookup failure, no internet
  routeError,      // Router resolution failure or unmapped route
  unknown,         // Unclassified fallback
}

/// Central typed exception that converts technical network/backend failures
/// into user-safe, contextual application errors while preserving developer logs.
class AcadexException implements Exception {
  final ErrorCategory category;
  final int? statusCode;
  final String technicalMessage;
  final String userMessage;
  final String? context;
  final bool isRetryable;

  const AcadexException({
    required this.category,
    this.statusCode,
    required this.technicalMessage,
    required this.userMessage,
    this.context,
    this.isRetryable = false,
  });

  /// Factory from a [DioException]
  factory AcadexException.fromDio(DioException error, {String? context, String? fallback}) {
    final statusCode = error.response?.statusCode;
    final dynamic responseData = error.response?.data;
    
    // Extract raw backend error string if present
    String rawBackendMessage = '';
    if (responseData is Map<String, dynamic>) {
      if (responseData['error'] is Map<String, dynamic>) {
        rawBackendMessage = responseData['error']['message']?.toString() ?? '';
      } else if (responseData['message'] != null) {
        rawBackendMessage = responseData['message'].toString();
      }
    } else if (responseData is String && responseData.isNotEmpty) {
      rawBackendMessage = responseData;
    }

    final technicalMsg = rawBackendMessage.isNotEmpty
        ? rawBackendMessage
        : (error.message ?? 'DioException: ${error.type}');

    // Log the actual technical failure internally for developer tracing
    AcadexLogger.error(
      'API Error [${statusCode ?? error.type}]: $technicalMsg',
      error: error,
      stackTrace: error.stackTrace,
      extraContext: {
        'statusCode': statusCode,
        'path': error.requestOptions.path,
        'context': context,
      },
    );

    // 1. Connection / Timeout checks
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return AcadexException(
        category: ErrorCategory.networkTimeout,
        statusCode: statusCode,
        technicalMessage: technicalMsg,
        userMessage: 'Connection timed out. Please check your network connection and try again.',
        context: context,
        isRetryable: true,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return AcadexException(
        category: ErrorCategory.offline,
        statusCode: statusCode,
        technicalMessage: technicalMsg,
        userMessage: 'Unable to connect to the server. Please check your internet connection.',
        context: context,
        isRetryable: true,
      );
    }

    // 2. HTTP Status Code Classification
    switch (statusCode) {
      case 400:
        return AcadexException(
          category: ErrorCategory.validation,
          statusCode: 400,
          technicalMessage: technicalMsg,
          userMessage: _scrubTechnicalTerms(rawBackendMessage, fallback: 'Invalid request. Please check the entered information.'),
          context: context,
          isRetryable: false,
        );
      case 401:
        return AcadexException(
          category: ErrorCategory.unauthenticated,
          statusCode: 401,
          technicalMessage: technicalMsg,
          userMessage: 'Your session has expired. Please sign in again.',
          context: context,
          isRetryable: false,
        );
      case 403:
        return AcadexException(
          category: ErrorCategory.forbidden,
          statusCode: 403,
          technicalMessage: technicalMsg,
          userMessage: _scrubTechnicalTerms(rawBackendMessage, fallback: 'You do not have permission to perform this action.'),
          context: context,
          isRetryable: false,
        );
      case 404:
        final entity = context != null ? '$context not found.' : 'The requested record could not be found.';
        return AcadexException(
          category: ErrorCategory.notFound,
          statusCode: 404,
          technicalMessage: technicalMsg,
          userMessage: _scrubTechnicalTerms(rawBackendMessage, fallback: entity),
          context: context,
          isRetryable: false,
        );
      case 409:
        return AcadexException(
          category: ErrorCategory.conflict,
          statusCode: 409,
          technicalMessage: technicalMsg,
          userMessage: _scrubTechnicalTerms(rawBackendMessage, fallback: 'This operation could not be completed because the record already exists or is currently in use.'),
          context: context,
          isRetryable: false,
        );
      case 422:
        return AcadexException(
          category: ErrorCategory.validation,
          statusCode: 422,
          technicalMessage: technicalMsg,
          userMessage: _scrubTechnicalTerms(rawBackendMessage, fallback: 'Validation failed. Please verify your entered details.'),
          context: context,
          isRetryable: false,
        );
      case 429:
        return AcadexException(
          category: ErrorCategory.rateLimited,
          statusCode: 429,
          technicalMessage: technicalMsg,
          userMessage: 'Too many requests. Please wait a moment before trying again.',
          context: context,
          isRetryable: true,
        );
      default:
        if (statusCode != null && statusCode >= 500) {
          return AcadexException(
            category: ErrorCategory.serverError,
            statusCode: statusCode,
            technicalMessage: technicalMsg,
            userMessage: 'The server is temporarily unavailable. Please try again in a few moments.',
            context: context,
            isRetryable: true,
          );
        }
        return AcadexException(
          category: ErrorCategory.unknown,
          statusCode: statusCode,
          technicalMessage: technicalMsg,
          userMessage: _scrubTechnicalTerms(rawBackendMessage, fallback: 'An unexpected error occurred. Please try again.'),
          context: context,
          isRetryable: true,
        );
    }
  }

  /// Factory from a generic error/exception
  factory AcadexException.fromError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    String? fallback,
  }) {
    if (error is AcadexException) return error;

    if (error is DioException) {
      return AcadexException.fromDio(error, context: context, fallback: fallback);
    }

    final raw = error.toString();
    AcadexLogger.error(
      'Application Error: $raw',
      error: error,
      stackTrace: stackTrace,
      extraContext: {'context': context},
    );

    // Route resolution failures
    if (raw.contains('GoException') || raw.contains('no routes for location')) {
      return AcadexException(
        category: ErrorCategory.routeError,
        technicalMessage: raw,
        userMessage: 'This page could not be opened.',
        context: context,
        isRetryable: false,
      );
    }

    // Permission / Authorization
    if (raw.toLowerCase().contains('permission') || raw.toLowerCase().contains('forbidden') || raw.toLowerCase().contains('unauthorized')) {
      return AcadexException(
        category: ErrorCategory.forbidden,
        technicalMessage: raw,
        userMessage: 'You do not have permission to perform this action.',
        context: context,
        isRetryable: false,
      );
    }

    // Network / Socket
    if (raw.contains('SocketException') || raw.contains('HandshakeException') || raw.contains('Failed host lookup')) {
      return AcadexException(
        category: ErrorCategory.offline,
        technicalMessage: raw,
        userMessage: 'Unable to connect to the server. Please check your internet connection.',
        context: context,
        isRetryable: true,
      );
    }

    // Conflict / Duplicate (409)
    if (raw.contains('409') ||
        raw.toLowerCase().contains('conflict') ||
        raw.toLowerCase().contains('already exists') ||
        raw.toLowerCase().contains('already enrolled') ||
        raw.toLowerCase().contains('duplicate')) {
      return AcadexException(
        category: ErrorCategory.conflict,
        statusCode: 409,
        technicalMessage: raw,
        userMessage: _scrubTechnicalTerms(raw, fallback: 'This record already exists or conflicts with existing data.'),
        context: context,
        isRetryable: false,
      );
    }

    return AcadexException(
      category: ErrorCategory.unknown,
      technicalMessage: raw,
      userMessage: _scrubTechnicalTerms(raw, fallback: fallback ?? 'We couldn\'t load this right now.'),
      context: context,
      isRetryable: true,
    );
  }

  /// Central message sanitizer for any UI component, dialog, or SnackBar
  static String sanitizedMessage(dynamic error, {String fallback = 'An unexpected error occurred. Please try again.'}) {
    if (error == null) return fallback;
    if (error is AcadexException) return error.userMessage;
    if (error is DioException) return AcadexException.fromDio(error).userMessage;

    final raw = error.toString();
    return _scrubTechnicalTerms(raw, fallback: fallback);
  }

  /// Contextual user-friendly action failure message
  static String contextualMessage(dynamic error, {required String actionContext}) {
    final sanitized = sanitizedMessage(error);
    if (sanitized.contains('timed out') || sanitized.contains('connect to the server') || sanitized.contains('permission')) {
      return sanitized;
    }
    return 'Unable to $actionContext. Please try again.';
  }

  /// Scrubs technical phrases, stack traces, database terms, and developer prefixes
  static String _scrubTechnicalTerms(String raw, {required String fallback}) {
    if (raw.isEmpty) return fallback;

    // Remove common Dart/JS prefixes
    var text = raw
        .replaceAll('Exception: ', '')
        .replaceAll('Exception:', '')
        .replaceAll('Error: ', '')
        .replaceAll('Error:', '')
        .replaceAll('DioException [bad response]: ', '')
        .replaceAll('DioException [connection error]: ', '')
        .trim();

    // Map backend date validation messages to clear human-readable messages
    final lower = text.toLowerCase();
    if (lower.contains('startdate must be before enddate')) {
      return 'Start Date must be before End Date.';
    }
    if (lower.contains('invalid start date') || lower.contains('invalid end date')) {
      return 'Please enter valid calendar dates.';
    }

    // Map backend duplicate/conflict messages to clear human-readable domain explanations (Prompt 15)
    if (lower.contains('semester') && (lower.contains('already exist') || lower.contains('duplicate') || lower.contains('e11000'))) {
      return 'That semester already exists for this academic year.';
    }
    if ((lower.contains('faculty') || lower.contains('assignment')) && (lower.contains('already assign') || lower.contains('already exist') || lower.contains('duplicate') || lower.contains('facultyassignment'))) {
      return 'This faculty assignment already exists.';
    }
    if ((lower.contains('student') || lower.contains('enroll')) && (lower.contains('already enroll') || lower.contains('already exist') || lower.contains('duplicate') || lower.contains('enrollment'))) {
      return 'That student is already enrolled in this section.';
    }
    if (lower.contains('course') && (lower.contains('already exist') || lower.contains('duplicate'))) {
      return 'A course with this code already exists.';
    }
    if (lower.contains('section') && (lower.contains('already exist') || lower.contains('duplicate'))) {
      return 'A section with this name already exists for this semester.';
    }
    if (lower.contains('subject') && (lower.contains('already exist') || lower.contains('duplicate'))) {
      return 'A subject with this code already exists for this semester.';
    }
    if (lower.contains('academic year') && (lower.contains('already exist') || lower.contains('duplicate'))) {
      return 'That academic year already exists.';
    }
    if (lower.contains('timetable') && (lower.contains('conflict') || lower.contains('overlap') || lower.contains('already exist'))) {
      return 'A timetable schedule conflict exists for this time slot.';
    }
    final technicalKeywords = [
      'dioexception',
      'formatexception',
      'lateinitializationerror',
      'null check operator used on a null value',
      'nosuchmethoderror',
      'rangeerror',
      'typeerror',
      'unhandled exception',
      'stacktrace',
      'mongodb',
      'objectid',
      'cast to objectid failed',
      'e11000 duplicate key error',
      'cannot read properties of undefined',
      'jwt malformed',
      'invalid signature',
      'at layer.handle',
      'at /app/',
      'at router.',
      'syntaxerror',
      'goexception',
      'postgresql',
      'sqlstate',
      'relation "',
      'internal server error',
    ];

    for (final kw in technicalKeywords) {
      if (lower.contains(kw)) {
        return fallback;
      }
    }

    if (text.length > 180) {
      // Long stack trace or unformatted JSON dump
      return fallback;
    }

    // Capitalize first letter
    if (text.isNotEmpty) {
      text = text[0].toUpperCase() + text.substring(1);
      if (!text.endsWith('.') && !text.endsWith('!') && !text.endsWith('?')) {
        text = '$text.';
      }
    }

    return text.isNotEmpty ? text : fallback;
  }

  @override
  String toString() => userMessage;
}
