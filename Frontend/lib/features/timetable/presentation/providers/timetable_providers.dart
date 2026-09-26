import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/timetable_models.dart';
import '../../domain/models/teacher_substitution.dart';
import '../../data/repositories/timetable_repository.dart';
import '../../data/repositories/mock_timetable_repository.dart';
import '../../data/repositories/firebase_timetable_repository.dart';
import '../../data/repositories/api_timetable_repository.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
export 'timetable_authoring_providers.dart';

final mockTimetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return MockTimetableRepository();
});

final firebaseTimetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUser = ref.watch(currentUserProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return FirebaseTimetableRepository(
    firestoreService,
    currentUser: currentUser,
    notificationService: notificationService,
  );
});

final apiTimetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return ApiTimetableRepository();
});

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return ref.watch(apiTimetableRepositoryProvider);
});

final weeklyTimetableProvider = StreamProvider<Map<TimetableDay, List<TimetableModel>>>((ref) async* {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    yield {for (var day in TimetableDay.values) day: []};
    return;
  }

  final user = authState.user;
  
  // Profile readiness guard: non-super-admin users must have collegeId loaded
  if ((user.collegeId == null || user.collegeId!.isEmpty) && user.role != AppRole.superAdmin) {
    yield {for (var day in TimetableDay.values) day: []};
    return;
  }

  final repository = ref.watch(timetableRepositoryProvider);
  
  String? sectionId;
  if (user.role == AppRole.student) {
    sectionId = user.sectionId;
    if (sectionId == null || sectionId.isEmpty) {
      // Student has no assigned section yet; safely yield empty schedule without querying Firestore
      yield {for (var day in TimetableDay.values) day: []};
      return;
    }
  }

  final stream = repository.watchTimetable(
    role: user.role,
    userId: user.id,
    collegeId: user.collegeId,
    departmentId: user.departmentId,
    sectionId: sectionId,
  );
  
  await for (final entries in stream) {
    final Map<TimetableDay, List<TimetableModel>> grouped = {
      for (var day in TimetableDay.values) day: []
    };
    
    for (var entry in entries) {
      grouped[entry.dayOfWeek]?.add(entry);
    }
    
    for (var day in TimetableDay.values) {
      grouped[day]?.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    
    yield grouped;
  }
});

final dateScheduleProvider = FutureProvider.autoDispose.family<List<TimetableModel>, DateTime>((ref, date) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];

  final user = authState.user;
  if ((user.collegeId == null || user.collegeId!.isEmpty) && user.role != AppRole.superAdmin) {
    return [];
  }

  final repository = ref.watch(timetableRepositoryProvider);
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  final dateStr = '$y-$m-$d';

  String? sectionId;
  if (user.role == AppRole.student) {
    sectionId = user.sectionId;
    if (sectionId == null || sectionId.isEmpty) return [];
  }

  final list = await repository.getTimetable(
    collegeId: user.collegeId ?? '',
    departmentId: user.departmentId,
    sectionId: sectionId,
    facultyId: user.role == AppRole.faculty ? 'me' : null,
    date: dateStr,
    role: user.role,
  );

  final sorted = List<TimetableModel>.from(list)
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  return sorted;
});

final todayScheduleProvider = Provider.autoDispose<AsyncValue<List<TimetableModel>>>((ref) {
  final now = DateTime.now();
  final dateAsync = ref.watch(dateScheduleProvider(DateTime(now.year, now.month, now.day)));

  return dateAsync.when(
    data: (data) => AsyncValue.data(data),
    loading: () {
      final weeklyData = ref.watch(weeklyTimetableProvider);
      return weeklyData.whenData((weekly) {
        final currentDay = TimetableDay.values[now.weekday - 1];
        return weekly[currentDay] ?? [];
      });
    },
    error: (e, st) => AsyncValue.error(e, st),
  );
});

class TeacherSubstitutionsQuery {
  final String? date;
  final String? timetableId;
  final String? departmentId;

  const TeacherSubstitutionsQuery({
    this.date,
    this.timetableId,
    this.departmentId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherSubstitutionsQuery &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          timetableId == other.timetableId &&
          departmentId == other.departmentId;

  @override
  int get hashCode => date.hashCode ^ timetableId.hashCode ^ departmentId.hashCode;
}

final teacherSubstitutionsProvider = FutureProvider.family<List<TeacherSubstitution>, TeacherSubstitutionsQuery>((ref, query) async {
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.getTeacherSubstitutions(
    date: query.date,
    timetableId: query.timetableId,
    departmentId: query.departmentId,
  );
});

final nextClassProvider = Provider<AsyncValue<TimetableModel?>>((ref) {
  final todayAsync = ref.watch(todayScheduleProvider);
  return todayAsync.whenData((todayClasses) {
    if (todayClasses.isEmpty) return null;
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    for (final entry in todayClasses) {
      try {
        final endParts = entry.endTime.split(':');
        final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        if (endMinutes > currentMinutes) {
          return entry;
        }
      } catch (_) {}
    }
    return null;
  });
});

class TimetableManagementNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createEntry(TimetableModel entry) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(timetableRepositoryProvider);
      await repository.createEntry(entry);
      ref.invalidate(weeklyTimetableProvider);
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(studentStatsProvider);
    });
  }

  Future<void> updateEntry(TimetableModel entry) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(timetableRepositoryProvider);
      await repository.updateEntry(entry);
      ref.invalidate(weeklyTimetableProvider);
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(studentStatsProvider);
    });
  }

  /// Deletes a grid entry through its parent container via PUT /timetables/:id.
  Future<void> deleteGridEntry({required String timetableId, required String entryId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(timetableRepositoryProvider);
      await repository.deleteGridEntry(timetableId, entryId);
      ref.invalidate(weeklyTimetableProvider);
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(studentStatsProvider);
    });
  }

  @Deprecated('Use deleteGridEntry with timetableId for container authoring')
  Future<void> deleteEntry(String id) async {
    throw UnsupportedError('Individual entry deletion without container is deprecated. Use deleteGridEntry.');
  }
}

final timetableManagementProvider = AsyncNotifierProvider<TimetableManagementNotifier, void>(() {
  return TimetableManagementNotifier();
});
