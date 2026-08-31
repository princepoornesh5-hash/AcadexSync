import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/models/attendance_session.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/attendance_status.dart';
import 'attendance_providers.dart';

final currentFacultyIdProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id ?? '';
});

// ---------------------------------------------------------
// History List & Filtering
// ---------------------------------------------------------
final historySearchQueryProvider = StateProvider<String>((ref) => '');
final historyStatusFilterProvider = StateProvider<String?>((ref) => null); // 'Draft' or 'Locked'

final facultyHistoryListProvider = FutureProvider<List<AttendanceSession>>((ref) async {
  final facultyId = ref.watch(currentFacultyIdProvider);
  if (facultyId.isEmpty) return [];

  final repo = ref.watch(attendanceRepoProvider);
  return repo.getRecentSessions(facultyId);
});

final filteredFacultyHistoryProvider = Provider<AsyncValue<List<AttendanceSession>>>((ref) {
  final asyncList = ref.watch(facultyHistoryListProvider);
  final searchQuery = ref.watch(historySearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(historyStatusFilterProvider);

  return asyncList.whenData((list) {
    return list.where((session) {
      if (statusFilter != null) {
        if (statusFilter == 'Locked' && !session.isLocked) return false;
        if (statusFilter == 'Draft' && session.isLocked) return false;
      }
      
      if (searchQuery.isNotEmpty) {
        final matchesSub = session.subjectName.toLowerCase().contains(searchQuery);
        final matchesSec = session.sectionName.toLowerCase().contains(searchQuery);
        if (!matchesSub && !matchesSec) return false;
      }
      
      return true;
    }).toList();
  });
});

// ---------------------------------------------------------
// Detail & Edit Mode
// ---------------------------------------------------------
final activeSessionIdProvider = StateProvider<String?>((ref) => null);

final activeSessionProvider = Provider<AttendanceSession?>((ref) {
  final listAsync = ref.watch(facultyHistoryListProvider);
  final activeId = ref.watch(activeSessionIdProvider);
  
  if (activeId == null) return null;
  return listAsync.valueOrNull?.firstWhere((s) => s.id == activeId);
});

final isEditModeProvider = StateProvider<bool>((ref) => false);

class EditSessionNotifier extends StateNotifier<List<AttendanceRecord>> {
  EditSessionNotifier() : super([]);

  void init(List<AttendanceRecord> initialRecords) {
    state = initialRecords.map((r) => r.copyWith(oldStatus: r.status)).toList();
  }

  void updateStatus(String studentId, AttendanceStatus newStatus) {
    state = [
      for (final r in state)
        if (r.studentId == studentId)
          r.copyWith(status: newStatus)
        else
          r
    ];
  }
  
  bool get hasChanges => state.any((r) => r.status != r.oldStatus);
  
  int get remainingCount => state.where((r) => r.status == null).length;
}

final editSessionProvider = StateNotifierProvider<EditSessionNotifier, List<AttendanceRecord>>((ref) {
  return EditSessionNotifier();
});

final saveEditedSessionProvider = FutureProvider<bool>((ref) async {
  final activeSession = ref.read(activeSessionProvider);
  if (activeSession == null) return false;
  
  final records = ref.read(editSessionProvider);
  final repo = ref.read(attendanceRepoProvider);
  
  final updatedSession = activeSession.copyWith(
    records: records,
    version: activeSession.version + 1,
    lastModifiedAt: DateTime.now(),
  );
  final success = await repo.saveSession(updatedSession);
  
  if (success) {
    // Invalidate history and active assigned classes so all screens update in real time
    ref.invalidate(facultyHistoryListProvider);
    ref.invalidate(assignedClassesProvider);
    ref.invalidate(activeStudentListProvider);
    ref.read(isEditModeProvider.notifier).state = false;
  }
  
  return success;
});
