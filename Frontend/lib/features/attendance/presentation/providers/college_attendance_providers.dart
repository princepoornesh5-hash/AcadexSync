import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/college_attendance_summary.dart';
import '../../domain/models/department_attendance_comparison.dart';
import '../../domain/models/college_insight.dart';
import '../../domain/models/college_faculty_completion.dart';
import '../../domain/models/college_student_shortage.dart';
import 'attendance_providers.dart';

final collegeSummaryProvider = FutureProvider<CollegeAttendanceSummary>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getCollegeSummary();
});

final departmentComparisonProvider = FutureProvider<List<DepartmentAttendanceComparison>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getDepartmentComparisons();
});

final collegeFacultyProvider = FutureProvider<List<CollegeFacultyCompletion>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getCollegeFacultyCompletion(DateTime.now());
});

final collegeShortageProvider = FutureProvider<List<CollegeStudentShortage>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getCollegeStudentShortages();
});

final collegeInsightsProvider = FutureProvider<List<CollegeInsight>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getCollegeInsights();
});
