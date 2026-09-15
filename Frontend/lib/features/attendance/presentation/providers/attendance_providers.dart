import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/notifications/presentation/providers/notification_providers.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_providers.dart';
import '../../../../features/reports/presentation/providers/reports_providers.dart';
import '../../../timetable/presentation/providers/timetable_providers.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/attendance_session.dart';
import '../../domain/models/attendance_status.dart';
import '../../domain/models/assigned_class.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../data/repositories/api_attendance_repository.dart';
import '../../data/repositories/firebase_attendance_repository.dart';

final firebaseAttendanceRepoProvider = Provider<AttendanceRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUser = ref.watch(currentUserProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return FirebaseAttendanceRepository(
    firestoreService, 
    currentUser,
    notificationService: notificationService,
  );
});

final apiAttendanceRepoProvider = Provider<AttendanceRepository>((ref) {
  return ApiAttendanceRepository();
});

final attendanceRepoProvider = Provider<AttendanceRepository>((ref) {
  return ref.watch(apiAttendanceRepoProvider);
});

// ---------------------------------------------------------
// Faculty's Assigned Classes (Dashboard)
// ---------------------------------------------------------
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final assignedClassesProvider = FutureProvider<List<AssignedClass>>((ref) async {
  final date = ref.watch(selectedDateProvider);
  final repo = ref.watch(attendanceRepoProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null || currentUser.id.isEmpty) {
    return [];
  }
  
  return repo.getAssignedClasses(currentUser.id, date);
});

// ---------------------------------------------------------
// Active Session (Marking Screen)
// ---------------------------------------------------------
final activeClassProvider = StateProvider<AssignedClass?>((ref) => null);

final activeStudentListProvider = FutureProvider<List<AttendanceRecord>>((ref) async {
  final activeClass = ref.watch(activeClassProvider);
  if (activeClass == null) return [];
  
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getStudentsForSection(
    activeClass.sectionId,
    activeClass.subjectId,
    activeClass.date,
    timetableEntryId: activeClass.effectiveTimetableEntryId,
  );
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

  void markUnmarked(AttendanceStatus status) {
    state = [
      for (final rec in state)
        if (rec.status == null)
          rec.copyWith(status: status, lastModified: DateTime.now())
        else
          rec
    ];
  }

  void clearAll() {
    state = [
      for (final rec in state)
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
  final asyncList = ref.watch(activeStudentListProvider);
  return MarkingSessionNotifier(asyncList.valueOrNull ?? []);
});

// ---------------------------------------------------------
// Save Action
// ---------------------------------------------------------
final saveSessionProvider = FutureProvider.family<bool, String>((ref, activeClassId) async {
  final activeClass = ref.read(activeClassProvider);
  if (activeClass == null) return false;
  
  final records = ref.read(markingSessionProvider);
  final repo = ref.read(attendanceRepoProvider);
  final currentUser = ref.read(currentUserProvider);

  final facultyId = activeClass.facultyId?.isNotEmpty == true
      ? activeClass.facultyId!
      : (currentUser?.id ?? '');
  final collegeId = currentUser?.collegeId ?? '';
  final departmentId = currentUser?.departmentId ?? '';

  if (facultyId.isEmpty || collegeId.isEmpty) {
    throw StateError("Cannot save attendance: Incomplete user profile.");
  }

  final dateKey = '${activeClass.date.year}${activeClass.date.month.toString().padLeft(2, '0')}${activeClass.date.day.toString().padLeft(2, '0')}';
  final slotKey = activeClass.effectiveTimetableEntryId.replaceAll('pub_', '');
  final sessionId = slotKey.isNotEmpty
      ? '${activeClass.sectionId}_${activeClass.subjectId}_${dateKey}_$slotKey'
      : '${activeClass.sectionId}_${activeClass.subjectId}_$dateKey';

  final session = AttendanceSession(
    id: sessionId,
    collegeId: collegeId,
    departmentId: departmentId,
    facultyId: facultyId,
    subjectId: activeClass.subjectId,
    subjectName: activeClass.subjectName,
    sectionId: activeClass.sectionId,
    sectionName: activeClass.sectionName,
    timeSlot: activeClass.timeSlot,
    date: activeClass.date,
    records: records,
    timetableId: activeClass.timetableId,
    timetableEntryId: activeClass.effectiveTimetableEntryId,
    facultyAssignmentId: activeClass.facultyAssignmentId,
    roomNumber: activeClass.roomNumber,
    building: activeClass.building,
  );
  
  final success = await repo.saveSession(session);
  if (success) {
    // Invalidate assigned classes, sessions, dashboard stats, and reports in real time
    ref.invalidate(assignedClassesProvider);
    ref.invalidate(facultySessionsProvider);
    ref.invalidate(weeklyTimetableProvider);
    ref.invalidate(todayScheduleProvider);
    ref.invalidate(studentStatsProvider);
    ref.invalidate(facultyStatsProvider);
    ref.invalidate(hodStatsProvider);
    ref.invalidate(collegeAdminStatsProvider);
    ref.invalidate(superAdminStatsProvider);
    ref.invalidate(roleDashboardReportProvider);
    ref.invalidate(myAttendanceReportProvider);
  }
  return success;
});

// ---------------------------------------------------------
// Faculty Sessions (History)
// ---------------------------------------------------------
final facultySessionsProvider = FutureProvider<List<AttendanceSession>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null || currentUser.id.isEmpty) return [];
  return repo.getFacultySessions();
});

// ---------------------------------------------------------
// Single Session Detail
// ---------------------------------------------------------
final sessionDetailProvider = FutureProvider.family<AttendanceSession, String>((ref, sessionId) async {
  final repo = ref.watch(attendanceRepoProvider);
  return repo.getSessionById(sessionId);
});

// ---------------------------------------------------------
// Session Lifecycle Actions
// ---------------------------------------------------------
final lockSessionProvider = FutureProvider.family<AttendanceSession, String>((ref, sessionId) async {
  final repo = ref.read(attendanceRepoProvider);
  final session = await repo.lockSession(sessionId);
  ref.invalidate(sessionDetailProvider(sessionId));
  ref.invalidate(facultySessionsProvider);
  ref.invalidate(assignedClassesProvider);
  return session;
});

final closeSessionProvider = FutureProvider.family<AttendanceSession, String>((ref, sessionId) async {
  final repo = ref.read(attendanceRepoProvider);
  final session = await repo.closeSession(sessionId);
  ref.invalidate(sessionDetailProvider(sessionId));
  ref.invalidate(facultySessionsProvider);
  return session;
});

final cancelSessionProvider = FutureProvider.family<AttendanceSession, String>((ref, sessionId) async {
  final repo = ref.read(attendanceRepoProvider);
  final session = await repo.cancelSession(sessionId);
  ref.invalidate(sessionDetailProvider(sessionId));
  ref.invalidate(facultySessionsProvider);
  return session;
});

// ---------------------------------------------------------
// HOD & Admin Record Correction Action
// ---------------------------------------------------------
final correctRecordProvider = FutureProvider.family<AttendanceRecord, ({String recordId, AttendanceStatus newStatus, String reason, String? sessionId})>((ref, args) async {
  final repo = ref.read(attendanceRepoProvider);
  final record = await repo.correctRecord(
    args.recordId,
    newStatus: args.newStatus,
    reason: args.reason,
  );
  if (args.sessionId != null) {
    ref.invalidate(sessionDetailProvider(args.sessionId!));
  }
  ref.invalidate(facultySessionsProvider);
  return record;
});
