import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/models/department_attendance_summary.dart';
import '../../domain/models/faculty_attendance_completion.dart';
import '../../domain/models/student_shortage.dart';
import '../../domain/models/section_attendance_summary.dart';
import 'attendance_providers.dart';

final currentDepartmentIdProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.departmentId ?? '';
});

final hodDepartmentSummaryProvider = FutureProvider<DepartmentAttendanceSummary>((ref) async {
  final deptId = ref.watch(currentDepartmentIdProvider);
  if (deptId.isEmpty) {
    return DepartmentAttendanceSummary(
      overallPercentage: 0,
      studentsBelow75: 0,
      facultyCompleted: 0,
      facultyPending: 0,
      todayClasses: 0,
      totalStudents: 0,
      totalFaculty: 0,
    );
  }
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getDepartmentSummary(deptId);
});

final hodFacultyCompletionProvider = FutureProvider<List<FacultyAttendanceCompletion>>((ref) async {
  final deptId = ref.watch(currentDepartmentIdProvider);
  if (deptId.isEmpty) return [];

  final repo = ref.watch(attendanceRepoProvider);
  return repo.getFacultyCompletionStatus(deptId, DateTime.now());
});

final hodStudentShortageProvider = FutureProvider<List<StudentShortage>>((ref) async {
  final deptId = ref.watch(currentDepartmentIdProvider);
  if (deptId.isEmpty) return [];

  final repo = ref.watch(attendanceRepoProvider);
  return repo.getStudentShortages(deptId);
});

final hodSectionAttendanceProvider = FutureProvider<List<SectionAttendanceSummary>>((ref) async {
  final deptId = ref.watch(currentDepartmentIdProvider);
  if (deptId.isEmpty) return [];

  final repo = ref.watch(attendanceRepoProvider);
  return repo.getSectionAttendance(deptId, DateTime.now());
});
