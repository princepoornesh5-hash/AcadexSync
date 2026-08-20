import '../models/attendance_analytics_models.dart';
import '../models/attendance_report_models.dart';
import '../models/attendance_session.dart';
import '../../../timetable/domain/models/timetable_models.dart';

/// Centralized domain service handling administrative reconciliation, data consistency checks,
/// and session audit extraction.
class AttendanceAdminService {
  const AttendanceAdminService();

  /// Compares scheduled timetable classes against recorded attendance sessions
  /// to detect missing classes and calculate operational compliance.
  AttendanceReconciliationResult calculateReconciliation({
    required List<TimetableModel> scheduledEntries,
    required List<AttendanceSession> recordedSessions,
    AttendanceDateRange? dateRange,
  }) {
    if (scheduledEntries.isEmpty && recordedSessions.isEmpty) {
      return const AttendanceReconciliationResult(
        expectedSessions: 0,
        recordedSessions: 0,
        missingSessions: 0,
        compliancePercentage: 100.0,
      );
    }

    final missing = <MissingSessionInfo>[];
    final recordedKeySet = <String>{};

    for (final s in recordedSessions) {
      final dateKey = '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
      if (s.timetableEntryId != null && s.timetableEntryId!.isNotEmpty) {
        recordedKeySet.add('${s.timetableEntryId}_$dateKey');
      }
      // Also index by section_subject_date_slot
      final slotKey = s.timeSlot.replaceAll(RegExp(r'\s+'), '');
      recordedKeySet.add('${s.sectionId}_${s.subjectId}_${dateKey}_$slotKey');
      recordedKeySet.add('${s.sectionId}_${s.subjectId}_$dateKey');
    }

    // Determine target dates to evaluate
    final targetDates = <DateTime>[];
    if (dateRange != null) {
      DateTime cur = DateTime(dateRange.startDate.year, dateRange.startDate.month, dateRange.startDate.day);
      final end = DateTime(dateRange.endDate.year, dateRange.endDate.month, dateRange.endDate.day);
      while (!cur.isAfter(end)) {
        targetDates.add(cur);
        cur = cur.add(const Duration(days: 1));
      }
    } else {
      // Default to recorded dates or today
      if (recordedSessions.isNotEmpty) {
        final uniqueDates = recordedSessions.map((s) => DateTime(s.date.year, s.date.month, s.date.day)).toSet();
        targetDates.addAll(uniqueDates);
      } else {
        targetDates.add(DateTime.now());
      }
    }

    int expectedTotal = 0;

    for (final date in targetDates) {
      final dayOfWeek = _getTimetableDay(date.weekday);
      if (dayOfWeek == null) continue;

      final dayEntries = scheduledEntries.where((e) => e.dayOfWeek == dayOfWeek).toList();
      expectedTotal += dayEntries.length;

      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      for (final entry in dayEntries) {
        final slotKey = '${entry.startTime}-${entry.endTime}'.replaceAll(RegExp(r'\s+'), '');
        final hasMatch = recordedKeySet.contains('${entry.id}_$dateKey') ||
            recordedKeySet.contains('${entry.sectionId}_${entry.subjectId}_${dateKey}_$slotKey') ||
            recordedKeySet.contains('${entry.sectionId}_${entry.subjectId}_$dateKey');

        if (!hasMatch) {
          missing.add(MissingSessionInfo(
            timetableEntryId: entry.id,
            subjectId: entry.subjectId,
            subjectName: entry.subjectId,
            sectionId: entry.sectionId,
            facultyId: entry.facultyId,
            facultyName: entry.facultyId,
            timeSlot: '${entry.startTime} - ${entry.endTime}',
            scheduledDate: date,
          ));
        }
      }
    }

    final recordedCount = recordedSessions.length;
    final effectiveExpected = expectedTotal > 0 ? expectedTotal : recordedCount;
    final missingCount = missing.length;
    final compliance = effectiveExpected > 0
        ? ((effectiveExpected - missingCount) / effectiveExpected * 100).clamp(0.0, 100.0)
        : 100.0;

    return AttendanceReconciliationResult(
      expectedSessions: effectiveExpected,
      recordedSessions: recordedCount,
      missingSessions: missingCount,
      compliancePercentage: compliance,
      missingDetails: missing,
    );
  }

  /// Scans attendance sessions to identify anomalies, corruption, or inconsistent states.
  List<AttendanceConsistencyIssue> checkDataConsistency({
    required List<AttendanceSession> sessions,
    Set<String>? validSectionIds,
    Set<String>? validSubjectIds,
  }) {
    final issues = <AttendanceConsistencyIssue>[];
    final seenSessionIds = <String>{};
    final seenSlots = <String>{};
    final now = DateTime.now();

    for (final s in sessions) {
      // 1. Duplicate Session ID check
      if (seenSessionIds.contains(s.id)) {
        issues.add(AttendanceConsistencyIssue(
          sessionId: s.id,
          issueType: AttendanceConsistencyType.duplicateSession,
          description: 'Duplicate session ID "${s.id}" detected in dataset.',
          severity: 'critical',
          detectedAt: now,
        ));
      } else {
        seenSessionIds.add(s.id);
      }

      // 2. Duplicate Date/Time slot for same section check
      final dateKey = '${s.date.year}${s.date.month.toString().padLeft(2, '0')}${s.date.day.toString().padLeft(2, '0')}';
      final slotFingerprint = '${s.sectionId}_${dateKey}_${s.timeSlot}';
      if (s.timeSlot.isNotEmpty && seenSlots.contains(slotFingerprint)) {
        issues.add(AttendanceConsistencyIssue(
          sessionId: s.id,
          issueType: AttendanceConsistencyType.duplicateSession,
          description: 'Multiple sessions found for Section "${s.sectionName}" at slot "${s.timeSlot}" on $dateKey.',
          severity: 'warning',
          detectedAt: now,
        ));
      } else {
        seenSlots.add(slotFingerprint);
      }

      // 3. Percentage Range Check
      final pct = s.attendancePercentage;
      if (pct < 0.0 || pct > 100.0) {
        issues.add(AttendanceConsistencyIssue(
          sessionId: s.id,
          issueType: AttendanceConsistencyType.invalidPercentage,
          description: 'Session has invalid attendance percentage: ${pct.toStringAsFixed(1)}%.',
          severity: 'critical',
          detectedAt: now,
        ));
      }

      // 4. Mismatched Student Counts Check
      final counted = s.presentCount + s.absentCount + s.lateCount + s.excusedCount + s.unmarkedCount;
      if (s.records.length != counted) {
        issues.add(AttendanceConsistencyIssue(
          sessionId: s.id,
          issueType: AttendanceConsistencyType.mismatchedCounts,
          description: 'Session student count (${s.records.length}) does not match status breakdown sum ($counted).',
          severity: 'critical',
          detectedAt: now,
        ));
      }

      // 5. Unmarked records in submitted session
      if (s.isSubmitted && s.unmarkedCount > 0) {
        issues.add(AttendanceConsistencyIssue(
          sessionId: s.id,
          issueType: AttendanceConsistencyType.unmarkedInSubmitted,
          description: 'Submitted session contains ${s.unmarkedCount} unmarked student records.',
          severity: 'warning',
          detectedAt: now,
        ));
      }

      // 6. Missing timetable reference check
      if (s.timetableEntryId == null || s.timetableEntryId!.isEmpty) {
        issues.add(AttendanceConsistencyIssue(
          sessionId: s.id,
          issueType: AttendanceConsistencyType.missingTimetableRef,
          description: 'Session was recorded without a published timetable entry reference.',
          severity: 'info',
          detectedAt: now,
        ));
      }

      // 7. Orphan Section Reference check
      if (validSectionIds != null && validSectionIds.isNotEmpty && !validSectionIds.contains(s.sectionId)) {
        issues.add(AttendanceConsistencyIssue(
          sessionId: s.id,
          issueType: AttendanceConsistencyType.orphanSection,
          description: 'Session references deleted or nonexistent section ID: "${s.sectionId}".',
          severity: 'critical',
          detectedAt: now,
        ));
      }
    }

    return issues;
  }

  /// Extracts structured version delta audit logs from modified attendance sessions
  List<AttendanceAuditEntry> extractAuditHistory({
    required List<AttendanceSession> sessions,
  }) {
    final auditList = <AttendanceAuditEntry>[];

    for (final s in sessions) {
      if (s.version > 1 || s.lastModifiedAt != null || s.lastModifiedBy != null) {
        final changedRecords = s.records.where((r) => r.oldStatus != null || r.lastModified != null).length;
        auditList.add(AttendanceAuditEntry(
          sessionId: s.id,
          fromVersion: s.version > 1 ? s.version - 1 : 1,
          toVersion: s.version,
          modifiedBy: s.lastModifiedBy ?? (s.createdBy ?? 'Faculty / Administrator'),
          modifiedAt: s.lastModifiedAt ?? (s.createdAt ?? s.date),
          subjectName: s.subjectName.isNotEmpty ? s.subjectName : s.subjectId,
          sectionName: s.sectionName.isNotEmpty ? s.sectionName : s.sectionId,
          recordsChangedCount: changedRecords > 0 ? changedRecords : s.totalStudents,
          details: 'Session v${s.version} updated by ${s.lastModifiedBy ?? s.createdBy ?? 'Faculty'}. ($changedRecords student status records corrected).',
        ));
      }
    }

    auditList.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return auditList;
  }

  TimetableDay? _getTimetableDay(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return TimetableDay.monday;
      case DateTime.tuesday:
        return TimetableDay.tuesday;
      case DateTime.wednesday:
        return TimetableDay.wednesday;
      case DateTime.thursday:
        return TimetableDay.thursday;
      case DateTime.friday:
        return TimetableDay.friday;
      case DateTime.saturday:
        return TimetableDay.saturday;
      case DateTime.sunday:
        return TimetableDay.sunday;
      default:
        return null;
    }
  }
}
