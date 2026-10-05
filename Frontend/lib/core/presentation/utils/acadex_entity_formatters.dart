library;

/// ACADEX ENTITY FORMATTERS
/// Central presentation layer sanitization to guarantee internal database IDs
/// (MongoDB ObjectIds, UUIDs, raw entity identifiers) are never displayed to users.

class AcadexEntityFormatters {
  AcadexEntityFormatters._();

  static final RegExp _hexObjectIdRegex = RegExp(r'^[a-fA-F0-9]{24}$');
  static final RegExp _uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  /// Detects whether [raw] represents an internal database/backend identifier.
  static bool isRawIdentifier(String? raw) {
    if (raw == null) return false;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return false;
    if (_hexObjectIdRegex.hasMatch(trimmed)) return true;
    if (_uuidRegex.hasMatch(trimmed)) return true;
    if (trimmed.startsWith('ObjectId(') ||
        trimmed.startsWith('sec_') ||
        trimmed.startsWith('crs_') ||
        trimmed.startsWith('sub_') ||
        trimmed.startsWith('dept_') ||
        trimmed.startsWith('fac_') ||
        trimmed.startsWith('usr_')) {
      return true;
    }
    // Hexadecimal string of 16+ hex characters without spaces
    if (trimmed.length >= 16 && !trimmed.contains(' ') && RegExp(r'^[a-fA-F0-9]+$').hasMatch(trimmed)) {
      return true;
    }
    return false;
  }

  /// Formats user-facing Section label.
  /// Example:
  /// - name: 'A', rawId: '6ab93f...' -> 'Section A' (or 'Sec A' if compact)
  /// - name: null, rawId: '6ab93f...' -> 'Assigned Section'
  static String formatSectionLabel(
    String? name, {
    String? rawId,
    String fallback = 'Assigned Section',
    bool prefix = true,
    bool compact = false,
  }) {
    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isNotEmpty && !isRawIdentifier(cleanName)) {
      final pfx = compact ? 'Sec ' : 'Section ';
      if (cleanName.toLowerCase().startsWith('sec')) {
        return cleanName;
      }
      return prefix ? '$pfx$cleanName' : cleanName;
    }

    final cleanId = rawId?.trim();
    if (cleanId != null && cleanId.isNotEmpty && !isRawIdentifier(cleanId)) {
      final pfx = compact ? 'Sec ' : 'Section ';
      if (cleanId.toLowerCase().startsWith('sec')) {
        return cleanId;
      }
      return prefix ? '$pfx$cleanId' : cleanId;
    }

    return fallback;
  }

  /// Formats user-facing Subject label.
  static String formatSubjectLabel(
    String? name, {
    String? code,
    String? rawId,
    String fallback = 'Assigned Subject',
  }) {
    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isNotEmpty && !isRawIdentifier(cleanName)) {
      return cleanName;
    }
    final cleanCode = code?.trim();
    if (cleanCode != null && cleanCode.isNotEmpty && !isRawIdentifier(cleanCode)) {
      return cleanCode;
    }
    final cleanId = rawId?.trim();
    if (cleanId != null && cleanId.isNotEmpty && !isRawIdentifier(cleanId)) {
      return cleanId;
    }
    return fallback;
  }

  /// Formats user-facing Course / Program label.
  static String formatCourseLabel(
    String? name, {
    String? code,
    String? rawId,
    String fallback = 'Academic Program',
  }) {
    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isNotEmpty && !isRawIdentifier(cleanName)) {
      return cleanName;
    }
    final cleanCode = code?.trim();
    if (cleanCode != null && cleanCode.isNotEmpty && !isRawIdentifier(cleanCode)) {
      return cleanCode;
    }
    final cleanId = rawId?.trim();
    if (cleanId != null && cleanId.isNotEmpty && !isRawIdentifier(cleanId)) {
      return cleanId;
    }
    return fallback;
  }

  /// Formats user-facing Semester label.
  static String formatSemesterLabel(
    String? name, {
    int? semesterNumber,
    String? rawId,
    String fallback = 'Current Semester',
    bool compact = false,
  }) {
    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isNotEmpty && !isRawIdentifier(cleanName)) {
      return cleanName;
    }
    if (semesterNumber != null && semesterNumber > 0) {
      return compact ? 'Sem $semesterNumber' : 'Semester $semesterNumber';
    }
    final cleanId = rawId?.trim();
    if (cleanId != null && cleanId.isNotEmpty && !isRawIdentifier(cleanId)) {
      return cleanId;
    }
    return fallback;
  }

  /// Formats user-facing Department label.
  static String formatDepartmentLabel(
    String? name, {
    String? code,
    String? rawId,
    String fallback = 'Academic Department',
  }) {
    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isNotEmpty && !isRawIdentifier(cleanName)) {
      return cleanName;
    }
    final cleanCode = code?.trim();
    if (cleanCode != null && cleanCode.isNotEmpty && !isRawIdentifier(cleanCode)) {
      return cleanCode;
    }
    final cleanId = rawId?.trim();
    if (cleanId != null && cleanId.isNotEmpty && !isRawIdentifier(cleanId)) {
      return cleanId;
    }
    return fallback;
  }

  /// Formats user-facing Faculty label.
  static String formatFacultyLabel(
    String? name, {
    String? rawId,
    String fallback = 'Faculty Member',
  }) {
    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isNotEmpty && !isRawIdentifier(cleanName)) {
      return cleanName;
    }
    final cleanId = rawId?.trim();
    if (cleanId != null && cleanId.isNotEmpty && !isRawIdentifier(cleanId)) {
      return cleanId;
    }
    return fallback;
  }

  /// Formats user-facing Academic Year label.
  static String formatAcademicYearLabel(
    String? name, {
    String? rawId,
    String fallback = 'Current Academic Year',
  }) {
    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isNotEmpty && !isRawIdentifier(cleanName)) {
      return cleanName;
    }
    final cleanId = rawId?.trim();
    if (cleanId != null && cleanId.isNotEmpty && !isRawIdentifier(cleanId)) {
      return cleanId;
    }
    return fallback;
  }

  /// Formats a multi-entity context line (e.g. "Computer Science • Semester 4 • Section A")
  static String formatAcademicContext({
    String? course,
    String? semester,
    String? section,
    String? year,
    String? subject,
    String separator = ' • ',
  }) {
    final segments = <String>[];

    if (course != null && course.isNotEmpty && !isRawIdentifier(course)) {
      segments.add(course);
    }
    if (semester != null && semester.isNotEmpty && !isRawIdentifier(semester)) {
      segments.add(semester);
    }
    if (section != null && section.isNotEmpty && !isRawIdentifier(section)) {
      segments.add(section.toLowerCase().startsWith('sec') ? section : 'Sec $section');
    }
    if (year != null && year.isNotEmpty && !isRawIdentifier(year)) {
      segments.add(year);
    }
    if (subject != null && subject.isNotEmpty && !isRawIdentifier(subject)) {
      segments.add(subject);
    }

    if (segments.isEmpty) {
      return 'Academic Overview';
    }
    return segments.join(separator);
  }
}
