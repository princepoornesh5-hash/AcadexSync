import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/super_admin_attendance_summary.dart';
import '../../domain/models/college_attendance_comparison.dart';
import '../../domain/models/super_admin_insight.dart';
import '../../domain/models/super_admin_system_health.dart';
import '../../domain/models/super_admin_faculty_completion.dart';
import '../../domain/models/super_admin_student_shortage.dart';
import 'attendance_providers.dart';

final superAdminSummaryProvider = FutureProvider<SuperAdminAttendanceSummary>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getSuperAdminSummary();
});

final collegeComparisonProvider = FutureProvider<List<CollegeAttendanceComparison>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getCollegeComparisons();
});

final superAdminFacultyProvider = FutureProvider<List<SuperAdminFacultyCompletion>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getSuperAdminFacultyCompletion(DateTime.now());
});

final superAdminShortageProvider = FutureProvider<List<SuperAdminStudentShortage>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getSuperAdminStudentShortages();
});

final superAdminInsightsProvider = FutureProvider<List<SuperAdminInsight>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getSuperAdminInsights();
});

final superAdminSystemHealthProvider = FutureProvider<SuperAdminSystemHealth>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getSuperAdminSystemHealth();
});
