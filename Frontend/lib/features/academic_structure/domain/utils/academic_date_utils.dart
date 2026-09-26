import 'package:intl/intl.dart';

/// Canonical date parser, normalizer, and serializer for Academic Year calendar dates.
///
/// Ensures strict adherence to the backend API contract (`z.string().datetime()`)
/// while preserving date-only calendar semantics without timezone distortion.
class AcademicYearDateUtils {
  AcademicYearDateUtils._();

  static final RegExp _isoDatePrefixRegex = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');

  /// Deterministically normalizes any [DateTime] to a UTC-anchored calendar date
  /// at midnight (00:00:00.000Z), preserving the exact [year], [month], and [day]
  /// regardless of the client runtime's local timezone.
  static DateTime toUtcDate(DateTime date) {
    if (date.isUtc &&
        date.hour == 0 &&
        date.minute == 0 &&
        date.second == 0 &&
        date.millisecond == 0 &&
        date.microsecond == 0) {
      return date;
    }
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Nullable variant of [toUtcDate].
  static DateTime? toUtcDateNullable(DateTime? date) {
    if (date == null) return null;
    return toUtcDate(date);
  }

  /// Parses a date value from API JSON, dynamic inputs, or ISO strings into
  /// a canonical UTC-anchored [DateTime].
  ///
  /// Extracts the calendar components (year, month, day) directly from the ISO prefix
  /// `YYYY-MM-DD` so that timezone offsets in backend payloads never cause the calendar
  /// day to shift (e.g. preventing `2024-01-01` from becoming `2023-12-31`).
  static DateTime parse(dynamic value) {
    final parsed = tryParse(value);
    if (parsed != null) return parsed;
    return toUtcDate(DateTime.now());
  }

  /// Nullable variant of [parse].
  static DateTime? tryParse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      return toUtcDate(value);
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;

      final match = _isoDatePrefixRegex.firstMatch(trimmed);
      if (match != null) {
        final year = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);
        return DateTime.utc(year, month, day);
      }

      final fallback = DateTime.tryParse(trimmed);
      if (fallback != null) {
        return toUtcDate(fallback);
      }
    }
    return null;
  }

  /// Serializes a calendar [DateTime] to the canonical ISO-8601 UTC string
  /// required by the backend schema (`z.string().datetime()`):
  /// e.g. `2024-01-01T00:00:00.000Z`.
  static String serialize(DateTime date) {
    final utc = toUtcDate(date);
    return utc.toIso8601String();
  }

  /// Nullable variant of [serialize].
  static String? serializeNullable(DateTime? date) {
    if (date == null) return null;
    return serialize(date);
  }

  /// Formats a calendar date for UI presentation using a standard pattern
  /// (defaulting to `'yyyy-MM-dd'`).
  static String formatDisplay(DateTime date, {String pattern = 'yyyy-MM-dd'}) {
    final utc = toUtcDate(date);
    return DateFormat(pattern).format(utc);
  }

  /// Validates whether [endDate] is strictly chronologically after [startDate].
  static bool isRangeValid(DateTime startDate, DateTime endDate) {
    final s = toUtcDate(startDate);
    final e = toUtcDate(endDate);
    return e.isAfter(s);
  }
}