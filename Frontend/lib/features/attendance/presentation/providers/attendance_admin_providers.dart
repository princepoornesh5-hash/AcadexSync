import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/attendance_analytics_models.dart';
import '../../domain/models/attendance_report_models.dart';
import '../../domain/models/attendance_session.dart';
import '../../domain/models/student_shortage.dart';
import '../../domain/services/attendance_admin_service.dart';
import '../../presentation/providers/attendance_providers.dart';
import '../../../timetable/presentation/providers/timetable_providers.dart';

final attendanceAdminServiceProvider = Provider<AttendanceAdminService>((ref) {
  return const AttendanceAdminService();
});

/// Current active report filter state in Report Center
final attendanceReportFilterProvider = StateProvider<AttendanceReportFilter>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState is AuthAuthenticated ? authState.user : null;

  return AttendanceReportFilter(
    reportType: AttendanceReportType.student,
    collegeId: user?.collegeId,
    departmentId: user?.departmentId,
  );
});

/// Generates report preview and export data from live domain analytics and session repositories
final attendanceReportDataProvider = FutureProvider.family<AttendanceReportResult, AttendanceReportFilter>((ref, filter) async {
  final authState = ref.watch(authProvider);
  final user = authState is AuthAuthenticated ? authState.user : null;
  final repo = ref.watch(attendanceRepoProvider);

  final generatedBy = user != null ? '${user.name} (${user.role.name.toUpperCase()})' : 'System Administrator';
  final now = DateTime.now();

  switch (filter.reportType) {
    case AttendanceReportType.student:
      final studentId = filter.studentId ?? user?.id ?? 'STU-001';
      final analytics = await repo.getStudentAttendanceAnalytics(studentId, dateRange: filter.dateRange);

      final headers = [
        'Metric / Parameter',
        'Student Value',
        'Institutional Standard',
        'Compliance Status',
      ];

      final rows = [
        ['Student Name', analytics.studentName, '-', 'VERIFIED'],
        ['Roll Number', analytics.rollNumber, '-', 'ACTIVE'],
        ['Section', analytics.sectionId, '-', 'ASSIGNED'],
        ['Overall Attendance', '${analytics.attendancePercentage.toStringAsFixed(1)}%', '75.0%', analytics.isLowAttendance ? 'NON-COMPLIANT' : 'GOOD STANDING'],
        ['Total Sessions Tracked', analytics.totalSessions.toString(), '-', 'RECORDED'],
        ['Sessions Present', analytics.presentCount.toString(), '-', 'ATTENDED'],
        ['Sessions Absent', analytics.absentCount.toString(), '-', 'UNATTENDED'],
        ['Sessions Late', analytics.lateCount.toString(), '-', 'LATE'],
        ['Sessions Excused', analytics.excusedCount.toString(), '-', 'APPROVED'],
        ['Recovery Needed for 75%', analytics.isLowAttendance ? '${analytics.recoverySessionsNeeded} consecutive classes' : 'None', '0', analytics.isLowAttendance ? 'ACTION REQUIRED' : 'ON TRACK'],
        ['Risk Standing', analytics.riskLevel.name.toUpperCase(), 'LOW', analytics.riskLevel == AttendanceRiskLevel.critical ? 'CRITICAL' : 'STABLE'],
      ];

      return AttendanceReportResult(
        reportType: filter.reportType,
        title: 'Student Attendance Report — ${analytics.studentName}',
        scopeDescription: 'Student ID: $studentId | Roll: ${analytics.rollNumber} | Section: ${analytics.sectionId}',
        generatedAt: now,
        generatedBy: generatedBy,
        dateRange: filter.dateRange,
        totalRecords: analytics.totalSessions,
        summaryStatistics: {
          'Overall Attendance': '${analytics.attendancePercentage.toStringAsFixed(1)}%',
          'Total Sessions': analytics.totalSessions,
          'Present Count': analytics.presentCount,
          'Absent Count': analytics.absentCount,
          'Risk Level': analytics.riskLevel.name.toUpperCase(),
          'Shortage Flag': analytics.isLowAttendance ? 'YES (<75%)' : 'NO',
        },
        headers: headers,
        rows: rows,
      );

    case AttendanceReportType.subject:
      final subjectId = filter.subjectId ?? 'SUB-DEFAULT';
      final analytics = await repo.getSubjectAttendanceAnalytics(subjectId, sectionId: filter.sectionId, dateRange: filter.dateRange);

      final headers = [
        'Metric',
        'Value',
        'Distribution %',
      ];

      final total = analytics.totalStudentRecords;
      final rows = [
        ['Subject Name', analytics.subjectName.isNotEmpty ? analytics.subjectName : analytics.subjectId, '-'],
        ['Subject Code', analytics.subjectId, '-'],
        ['Overall Attendance', '${analytics.attendancePercentage.toStringAsFixed(1)}%', '-'],
        ['Total Sessions Conducted', analytics.totalSessions.toString(), '-'],
        ['Total Student Attendances', total.toString(), '100%'],
        ['Present Records', analytics.presentCount.toString(), total > 0 ? '${(analytics.presentCount / total * 100).toStringAsFixed(1)}%' : '0%'],
        ['Absent Records', analytics.absentCount.toString(), total > 0 ? '${(analytics.absentCount / total * 100).toStringAsFixed(1)}%' : '0%'],
        ['Late Records', analytics.lateCount.toString(), total > 0 ? '${(analytics.lateCount / total * 100).toStringAsFixed(1)}%' : '0%'],
        ['Excused Records', analytics.excusedCount.toString(), total > 0 ? '${(analytics.excusedCount / total * 100).toStringAsFixed(1)}%' : '0%'],
      ];

      return AttendanceReportResult(
        reportType: filter.reportType,
        title: 'Subject Attendance Report — ${analytics.subjectName.isNotEmpty ? analytics.subjectName : analytics.subjectId}',
        scopeDescription: 'Subject Code: $subjectId | Section: ${filter.sectionId ?? "All Sections"}',
        generatedAt: now,
        generatedBy: generatedBy,
        dateRange: filter.dateRange,
        totalRecords: analytics.totalSessions,
        summaryStatistics: {
          'Subject Name': analytics.subjectName,
          'Overall Attendance': '${analytics.attendancePercentage.toStringAsFixed(1)}%',
          'Sessions Conducted': analytics.totalSessions,
          'Total Records': analytics.totalStudentRecords,
        },
        headers: headers,
        rows: rows,
      );

    case AttendanceReportType.section:
      final sectionId = filter.sectionId ?? 'SEC-A';
      final analytics = await repo.getSectionAttendanceAnalytics(sectionId, dateRange: filter.dateRange);

      final headers = [
        'Rank',
        'Student Name',
        'Roll Number',
        'Attendance %',
        'Present',
        'Absent',
        'Total',
        'Recovery (75%)',
        'Risk Status',
      ];

      final rows = <List<dynamic>>[];
      final sortedStudents = List<StudentAttendanceAnalytics>.from(analytics.studentAnalytics)
        ..sort((a, b) => b.attendancePercentage.compareTo(a.attendancePercentage));

      for (int i = 0; i < sortedStudents.length; i++) {
        final s = sortedStudents[i];
        rows.add([
          (i + 1).toString(),
          s.studentName.isNotEmpty ? s.studentName : s.studentId,
          s.rollNumber,
          '${s.attendancePercentage.toStringAsFixed(1)}%',
          s.presentCount.toString(),
          s.absentCount.toString(),
          s.totalSessions.toString(),
          s.isLowAttendance ? s.recoverySessionsNeeded.toString() : '0',
          s.riskLevel.name.toUpperCase(),
        ]);
      }

      return AttendanceReportResult(
        reportType: filter.reportType,
        title: 'Section Attendance Report — ${analytics.sectionName.isNotEmpty ? analytics.sectionName : analytics.sectionId}',
        scopeDescription: 'Section: $sectionId | Total Students: ${analytics.totalStudents}',
        generatedAt: now,
        generatedBy: generatedBy,
        dateRange: filter.dateRange,
        totalRecords: analytics.totalStudents,
        summaryStatistics: {
          'Section Name': analytics.sectionName,
          'Average Attendance': '${analytics.attendancePercentage.toStringAsFixed(1)}%',
          'Total Students': analytics.totalStudents,
          'Total Sessions': analytics.totalSessions,
          'Students Below 75%': analytics.lowAttendanceStudentCount,
        },
        headers: headers,
        rows: rows,
      );

    case AttendanceReportType.faculty:
      final facultyId = filter.facultyId ?? user?.id ?? 'FAC-001';
      final analytics = await repo.getFacultyAttendanceAnalytics(facultyId, dateRange: filter.dateRange);

      final headers = [
        'Metric',
        'Value',
      ];

      final rows = [
        ['Faculty ID', analytics.facultyId],
        ['Faculty Name', analytics.facultyName.isNotEmpty ? analytics.facultyName : analytics.facultyId],
        ['Sessions Conducted', analytics.totalSessionsConducted.toString()],
        ['Students Tracked', analytics.totalStudentRecords.toString()],
        ['Average Attendance %', '${analytics.attendancePercentage.toStringAsFixed(1)}%'],
        ['Present Attendances', analytics.presentCount.toString()],
        ['Absent Attendances', analytics.absentCount.toString()],
        ['Late Attendances', analytics.lateCount.toString()],
        ['Excused Attendances', analytics.excusedCount.toString()],
      ];

      return AttendanceReportResult(
        reportType: filter.reportType,
        title: 'Faculty Attendance Report — ${analytics.facultyName.isNotEmpty ? analytics.facultyName : analytics.facultyId}',
        scopeDescription: 'Faculty ID: $facultyId',
        generatedAt: now,
        generatedBy: generatedBy,
        dateRange: filter.dateRange,
        totalRecords: analytics.totalSessionsConducted,
        summaryStatistics: {
          'Faculty Name': analytics.facultyName,
          'Sessions Conducted': analytics.totalSessionsConducted,
          'Average Attendance': '${analytics.attendancePercentage.toStringAsFixed(1)}%',
          'Total Records Tracked': analytics.totalStudentRecords,
        },
        headers: headers,
        rows: rows,
      );

    case AttendanceReportType.department:
      final deptId = filter.departmentId ?? user?.departmentId ?? 'DEP-CSE';
      final deptSummary = await repo.getDepartmentSummary(deptId);
      final sections = await repo.getSectionAttendance(deptId, now);

      final headers = [
        'Section Name',
        'Semester',
        'Enrolled Students',
        'Present',
        'Absent',
        'Average Attendance %',
        'Standing',
      ];

      final rows = sections.map((s) => [
        s.sectionName,
        s.semester,
        s.totalStudents.toString(),
        s.present.toString(),
        s.absent.toString(),
        '${s.attendancePercentage.toStringAsFixed(1)}%',
        s.attendancePercentage < 70 ? 'CRITICAL' : (s.attendancePercentage < 75 ? 'WARNING' : 'HEALTHY'),
      ]).toList();

      return AttendanceReportResult(
        reportType: filter.reportType,
        title: 'Department Attendance Report — $deptId',
        scopeDescription: 'Department: $deptId | Total Sections: ${sections.length}',
        generatedAt: now,
        generatedBy: generatedBy,
        dateRange: filter.dateRange,
        totalRecords: sections.length,
        summaryStatistics: {
          'Department ID': deptId,
          'Department Attendance': '${deptSummary.overallPercentage.toStringAsFixed(1)}%',
          'Total Students': deptSummary.totalStudents,
          'Total Shortage Count': deptSummary.studentsBelow75,
        },
        headers: headers,
        rows: rows,
      );

    case AttendanceReportType.college:
      final collegeId = filter.collegeId ?? user?.collegeId ?? 'COL-001';
      final collegeSummary = await repo.getCollegeSummary();
      final deptComparisons = await repo.getDepartmentComparisons();

      final headers = [
        'Department Name',
        'Overall Attendance %',
        'Student Count',
        'Faculty Count',
      ];

      final rows = deptComparisons.map((d) => [
        d.departmentName,
        '${d.attendancePercentage.toStringAsFixed(1)}%',
        d.studentCount.toString(),
        d.facultyCount.toString(),
      ]).toList();

      return AttendanceReportResult(
        reportType: filter.reportType,
        title: 'College Attendance Report — $collegeId',
        scopeDescription: 'College: $collegeId | Departments: ${deptComparisons.length}',
        generatedAt: now,
        generatedBy: generatedBy,
        dateRange: filter.dateRange,
        totalRecords: deptComparisons.length,
        summaryStatistics: {
          'College ID': collegeId,
          'College Attendance': '${collegeSummary.todayAttendancePercentage.toStringAsFixed(1)}%',
          'Total Students': collegeSummary.totalStudents,
          'Total Departments': collegeSummary.totalDepartments,
          'Students Below Threshold': collegeSummary.studentsBelowThreshold,
        },
        headers: headers,
        rows: rows,
      );

    case AttendanceReportType.session:
      final facultyId = filter.facultyId ?? user?.id ?? '';
      final sessions = await repo.getRecentSessions(facultyId);

      final headers = [
        'Session Date',
        'Time Slot',
        'Subject',
        'Section',
        'Enrolled',
        'Present',
        'Absent',
        'Attendance %',
        'Status',
        'Version',
      ];

      final rows = sessions.map((s) => [
        s.date.toIso8601String().split('T').first,
        s.timeSlot,
        s.subjectName.isNotEmpty ? s.subjectName : s.subjectId,
        s.sectionName.isNotEmpty ? s.sectionName : s.sectionId,
        s.totalStudents.toString(),
        s.presentCount.toString(),
        s.absentCount.toString(),
        '${s.attendancePercentage.toStringAsFixed(1)}%',
        s.isSubmitted ? 'Submitted' : 'Draft',
        'v${s.version}',
      ]).toList();

      return AttendanceReportResult(
        reportType: filter.reportType,
        title: 'Attendance Sessions Report',
        scopeDescription: 'Total Sessions: ${sessions.length}',
        generatedAt: now,
        generatedBy: generatedBy,
        dateRange: filter.dateRange,
        totalRecords: sessions.length,
        summaryStatistics: {
          'Total Sessions': sessions.length,
          'Submitted Sessions': sessions.where((s) => s.isSubmitted).length,
          'Draft Sessions': sessions.where((s) => !s.isSubmitted).length,
        },
        headers: headers,
        rows: rows,
      );

    case AttendanceReportType.lowAttendance:
      final deptId = filter.departmentId ?? user?.departmentId ?? '';
      final shortages = await repo.getStudentShortages(deptId);

      final headers = [
        'Priority',
        'Student Name',
        'Roll Number',
        'Section',
        'Semester',
        'Current Attendance %',
        'Standing',
      ];

      final rows = <List<dynamic>>[];
      for (int i = 0; i < shortages.length; i++) {
        final s = shortages[i];
        rows.add([
          (i + 1).toString(),
          s.studentName,
          s.rollNumber,
          s.section,
          s.semester,
          '${s.currentPercentage.toStringAsFixed(1)}%',
          s.status == ShortageStatus.critical ? 'CRITICAL' : 'WARNING',
        ]);
      }

      return AttendanceReportResult(
        reportType: filter.reportType,
        title: 'Low Attendance Action & Intervention Report',
        scopeDescription: 'Scope: ${deptId.isNotEmpty ? "Department $deptId" : "Institution"} | Threshold: 75.0%',
        generatedAt: now,
        generatedBy: generatedBy,
        dateRange: filter.dateRange,
        totalRecords: shortages.length,
        summaryStatistics: {
          'Threshold': '75.0%',
          'Students in Shortage': shortages.length,
          'Critical (<65%)': shortages.where((s) => s.status == ShortageStatus.critical).length,
          'Warning (65-75%)': shortages.where((s) => s.status == ShortageStatus.warning).length,
        },
        headers: headers,
        rows: rows,
      );
  }
});

/// Reconciles timetable classes with recorded attendance sessions
final attendanceReconciliationProvider = FutureProvider.family<AttendanceReconciliationResult, ({String? departmentId, String? sectionId, AttendanceDateRange? dateRange})>((ref, args) async {
  final adminService = ref.watch(attendanceAdminServiceProvider);
  final timetableRepo = ref.watch(timetableRepositoryProvider);
  final attendanceRepo = ref.watch(attendanceRepoProvider);
  final authState = ref.watch(authProvider);
  final user = authState is AuthAuthenticated ? authState.user : null;

  final collegeId = user?.collegeId ?? 'COL-001';
  final scheduledEntries = await timetableRepo.getTimetable(
    collegeId: collegeId,
    departmentId: args.departmentId,
    sectionId: args.sectionId,
  );

  final recordedSessions = await attendanceRepo.getRecentSessions(user?.id ?? '');

  return adminService.calculateReconciliation(
    scheduledEntries: scheduledEntries,
    recordedSessions: recordedSessions,
    dateRange: args.dateRange,
  );
});

/// Evaluates data consistency anomalies across attendance sessions
final attendanceConsistencyProvider = FutureProvider.family<List<AttendanceConsistencyIssue>, ({String? departmentId, AttendanceDateRange? dateRange})>((ref, args) async {
  final adminService = ref.watch(attendanceAdminServiceProvider);
  final attendanceRepo = ref.watch(attendanceRepoProvider);
  final authState = ref.watch(authProvider);
  final user = authState is AuthAuthenticated ? authState.user : null;

  final sessions = await attendanceRepo.getRecentSessions(user?.id ?? '');
  return adminService.checkDataConsistency(sessions: sessions);
});

/// Session audit logs for administrators
final attendanceAuditHistoryProvider = FutureProvider.family<List<AttendanceAuditEntry>, ({String? departmentId, AttendanceDateRange? dateRange})>((ref, args) async {
  final adminService = ref.watch(attendanceAdminServiceProvider);
  final attendanceRepo = ref.watch(attendanceRepoProvider);
  final authState = ref.watch(authProvider);
  final user = authState is AuthAuthenticated ? authState.user : null;

  final sessions = await attendanceRepo.getRecentSessions(user?.id ?? '');
  return adminService.extractAuditHistory(sessions: sessions);
});

/// Administrative search, sorting, and pagination for sessions
final attendanceAdminSessionsProvider = FutureProvider.family<List<AttendanceSession>, ({String? query, String? sectionId, String? facultyId, int page, int pageSize})>((ref, args) async {
  final attendanceRepo = ref.watch(attendanceRepoProvider);
  final authState = ref.watch(authProvider);
  final user = authState is AuthAuthenticated ? authState.user : null;

  var sessions = await attendanceRepo.getRecentSessions(args.facultyId ?? user?.id ?? '');

  if (args.sectionId != null && args.sectionId!.isNotEmpty) {
    sessions = sessions.where((s) => s.sectionId == args.sectionId).toList();
  }

  if (args.query != null && args.query!.trim().isNotEmpty) {
    final q = args.query!.toLowerCase().trim();
    sessions = sessions.where((s) =>
      s.subjectName.toLowerCase().contains(q) ||
      s.subjectId.toLowerCase().contains(q) ||
      s.sectionName.toLowerCase().contains(q) ||
      s.sectionId.toLowerCase().contains(q) ||
      s.facultyId.toLowerCase().contains(q)
    ).toList();
  }

  final startIndex = (args.page - 1) * args.pageSize;
  if (startIndex >= sessions.length) return [];
  final endIndex = (startIndex + args.pageSize).clamp(0, sessions.length);

  return sessions.sublist(startIndex, endIndex);
});
