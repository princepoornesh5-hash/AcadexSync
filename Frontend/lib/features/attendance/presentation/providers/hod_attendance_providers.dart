import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/department_attendance_summary.dart';
import '../../domain/models/faculty_attendance_completion.dart';
import '../../domain/models/student_shortage.dart';
import '../../domain/models/section_attendance_summary.dart';
import 'attendance_providers.dart';

// In a real app this comes from Auth/User context
final currentDepartmentIdProvider = Provider<String>((ref) => 'dept1');

final hodDepartmentSummaryProvider = FutureProvider<DepartmentAttendanceSummary>((ref) async {
  final deptId = ref.watch(currentDepartmentIdProvider);
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getDepartmentSummary(deptId);
});

final hodFacultyCompletionProvider = FutureProvider<List<FacultyAttendanceCompletion>>((ref) async {
  final deptId = ref.watch(currentDepartmentIdProvider);
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getFacultyCompletionStatus(deptId, DateTime.now());
});

final hodStudentShortageProvider = FutureProvider<List<StudentShortage>>((ref) async {
  final deptId = ref.watch(currentDepartmentIdProvider);
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getStudentShortages(deptId);
});

final hodSectionAttendanceProvider = FutureProvider<List<SectionAttendanceSummary>>((ref) async {
  final deptId = ref.watch(currentDepartmentIdProvider);
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getSectionAttendance(deptId, DateTime.now());
});
