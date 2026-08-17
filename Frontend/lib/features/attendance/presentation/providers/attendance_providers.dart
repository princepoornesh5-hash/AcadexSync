import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/attendance_session.dart';
import '../../domain/models/attendance_status.dart';
import '../../domain/models/assigned_class.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../data/repositories/firebase_attendance_repository.dart';
import '../../data/repositories/mock_attendance_repository.dart';

final attendanceRepoProvider = Provider<AttendanceRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return mockAttendanceRepo;
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FirebaseAttendanceRepository(firestoreService);
});

// ---------------------------------------------------------
// Faculty's Assigned Classes (Dashboard)
// ---------------------------------------------------------
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final assignedClassesProvider = FutureProvider<List<AssignedClass>>((ref) async {
  final date = ref.watch(selectedDateProvider);
  final repo = ref.watch(attendanceRepoProvider);
  // In a real app, facultyId comes from Auth
  return repo.getAssignedClasses('faculty1', date);
});


// ---------------------------------------------------------
// Active Session (Marking Screen)
// ---------------------------------------------------------
final activeClassProvider = StateProvider<AssignedClass?>((ref) => null);

final activeStudentListProvider = FutureProvider<List<AttendanceRecord>>((ref) async {
  final activeClass = ref.watch(activeClassProvider);
  if (activeClass == null) return [];
  
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getStudentsForSection(activeClass.sectionId, activeClass.subjectId, activeClass.date);
});

class MarkingSessionNotifier extends StateNotifier<List<AttendanceRecord>> {
  MarkingSessionNotifier(super.initialState);

  void setRecords(List<AttendanceRecord> records) {
    state = records;
  }

  void markStatus(String studentId, AttendanceStatus status) {
    state = [
      for (final rec in state)
        if (rec.studentId == studentId)
          rec.copyWith(status: status, lastModified: DateTime.now())
        else
          rec
    ];
  }

  void markAll(AttendanceStatus status) {
    state = [
      for (final rec in state)
        rec.copyWith(status: status, lastModified: DateTime.now())
    ];
  }

  void clearAll() {
    state = [
      for (final rec in state)
        // using the fact that our copyWith allows setting if we just don't pass anything?
        // Wait, copyWith in attendance_record doesn't allow setting status to null easily if we use `??`.
        // Let's explicitly create a new object or we modify copyWith.
        // Actually, we can just instantiate a new record with status: null
        AttendanceRecord(
          id: rec.id,
          studentId: rec.studentId,
          studentName: rec.studentName,
          rollNumber: rec.rollNumber,
          sectionId: rec.sectionId,
          status: null,
          lastModified: null,
          modifiedBy: null,
        )
    ];
  }

  bool get isComplete => state.every((r) => r.status != null);
  
  int get remainingCount => state.where((r) => r.status == null).length;
  
  Map<AttendanceStatus, int> get summary {
    final map = <AttendanceStatus, int>{};
    for (var status in AttendanceStatus.values) {
      map[status] = state.where((r) => r.status == status).length;
    }
    return map;
  }
}

final markingSessionProvider = StateNotifierProvider<MarkingSessionNotifier, List<AttendanceRecord>>((ref) {
  // Sync the future provider data into the state notifier initially
  final asyncList = ref.watch(activeStudentListProvider);
  return MarkingSessionNotifier(asyncList.valueOrNull ?? []);
});


// ---------------------------------------------------------
// Save Action
// ---------------------------------------------------------
final saveSessionProvider = FutureProvider.family<bool, String>((ref, facultyId) async {
  final activeClass = ref.read(activeClassProvider);
  if (activeClass == null) return false;
  
  final records = ref.read(markingSessionProvider);
  final repo = ref.read(attendanceRepoProvider);
  
  final session = AttendanceSession(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    facultyId: facultyId,
    subjectId: activeClass.subjectId,
    subjectName: activeClass.subjectName,
    sectionId: activeClass.sectionId,
    sectionName: activeClass.sectionName,
    timeSlot: activeClass.timeSlot,
    date: activeClass.date,
    records: records,
  );
  
  return repo.saveSession(session);
});
