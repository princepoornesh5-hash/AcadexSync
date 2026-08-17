import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/subject_attendance.dart';
import '../../domain/models/attendance_history_record.dart';
import '../../domain/models/monthly_attendance_summary.dart';
import 'attendance_providers.dart'; // To get attendanceRepoProvider

// In a real app, this would come from the auth state
final currentStudentIdProvider = Provider<String>((ref) => 'student123');

// ---------------------------------------------------------
// Overview Stats
// ---------------------------------------------------------
final studentSubjectAttendanceProvider = FutureProvider<List<SubjectAttendance>>((ref) async {
  final studentId = ref.watch(currentStudentIdProvider);
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getStudentSubjectAttendance(studentId);
});

final overallAttendancePercentageProvider = Provider<AsyncValue<double>>((ref) {
  final subjectsAsync = ref.watch(studentSubjectAttendanceProvider);
  
  return subjectsAsync.whenData((subjects) {
    if (subjects.isEmpty) return 0.0;
    
    int totalConducted = 0;
    int totalAttended = 0;
    
    for (final s in subjects) {
      totalConducted += s.totalClasses;
      totalAttended += s.attendedClasses;
    }
    
    if (totalConducted == 0) return 0.0;
    return (totalAttended / totalConducted) * 100;
  });
});

// ---------------------------------------------------------
// History & Filters
// ---------------------------------------------------------
final selectedHistorySubjectProvider = StateProvider<String?>((ref) => null);
final selectedHistoryMonthProvider = StateProvider<int?>((ref) => null); // 1-12

final studentHistoryProvider = FutureProvider<List<AttendanceHistoryRecord>>((ref) async {
  final studentId = ref.watch(currentStudentIdProvider);
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getStudentAttendanceHistory(studentId);
});

final filteredStudentHistoryProvider = Provider<AsyncValue<List<AttendanceHistoryRecord>>>((ref) {
  final historyAsync = ref.watch(studentHistoryProvider);
  final selectedSubject = ref.watch(selectedHistorySubjectProvider);
  final selectedMonth = ref.watch(selectedHistoryMonthProvider);

  return historyAsync.whenData((history) {
    return history.where((record) {
      if (selectedSubject != null && record.subjectId != selectedSubject) {
        return false;
      }
      if (selectedMonth != null && record.date.month != selectedMonth) {
        return false;
      }
      return true;
    }).toList();
  });
});

// ---------------------------------------------------------
// Monthly Summaries
// ---------------------------------------------------------
final studentMonthlySummaryProvider = FutureProvider<List<MonthlyAttendanceSummary>>((ref) async {
  final studentId = ref.watch(currentStudentIdProvider);
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getStudentMonthlySummary(studentId);
});
