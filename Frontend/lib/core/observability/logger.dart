import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Centralized Observability & Logging Service
/// Ensures production error tracing without leaking sensitive context.
class AcadexLogger {
  /// General info logging
  static void info(String message, {String tag = 'Acadex'}) {
    if (kDebugMode) {
      developer.log(message, name: tag);
    }
  }

  /// Warning logging
  static void warn(String message, {String tag = 'Acadex'}) {
    developer.log(message, name: tag, level: 900); // 900 is WARNING
  }

  /// Error reporting.
  /// In a full production environment, this would forward to Crashlytics or Sentry.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String tag = 'Acadex.Error',
    Map<String, dynamic>? extraContext,
  }) {
    // Scrub sensitive keys if they accidentally make it here
    final scrubbedContext = _scrubSensitiveContext(extraContext);

    developer.log(
      message,
      name: tag,
      error: error,
      stackTrace: stackTrace,
      level: 1000, // 1000 is SEVERE
    );
    
    if (scrubbedContext != null) {
      developer.log('Context: $scrubbedContext', name: tag);
    }
    
    // TODO: Forward to Firebase Crashlytics if enabled
  }

  /// Ensure we don't accidentally log API keys, auth tokens, or PII.
  static Map<String, dynamic>? _scrubSensitiveContext(Map<String, dynamic>? context) {
    if (context == null) return null;
    
    final safeContext = Map<String, dynamic>.from(context);
    final sensitiveKeys = ['password', 'token', 'secret', 'apikey', 'auth', 'credentials'];

    for (var key in safeContext.keys.toList()) {
      final lowercaseKey = key.toLowerCase();
      if (sensitiveKeys.any((sensitive) => lowercaseKey.contains(sensitive))) {
        safeContext[key] = '[REDACTED]';
      }
    }
    
    return safeContext;
  }
}
