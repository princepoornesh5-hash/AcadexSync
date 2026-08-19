import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/timetable_models.dart';
import '../../data/repositories/timetable_repository.dart';
import '../../data/repositories/mock_timetable_repository.dart';
import '../../data/repositories/firebase_timetable_repository.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
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

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return ref.watch(mockTimetableRepositoryProvider);
  }
  return ref.watch(firebaseTimetableRepositoryProvider);
});

final weeklyTimetableProvider = StreamProvider<Map<TimetableDay, List<TimetableModel>>>((ref) async* {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    yield {for (var day in TimetableDay.values) day: []};
    return;
  }

  final user = authState.user;
  
  // Profile readiness guard: non-super-admin users must have collegeId loaded
  if (!FirebaseInitializer.shouldUseMock && (user.collegeId == null || user.collegeId!.isEmpty) && user.role != AppRole.superAdmin) {
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

final todayScheduleProvider = Provider<AsyncValue<List<TimetableModel>>>((ref) {
  final weeklyData = ref.watch(weeklyTimetableProvider);
  
  return weeklyData.whenData((weekly) {
    final now = DateTime.now();
    // In Dart, DateTime.weekday is 1..7 (Monday=1, Sunday=7)
    // Our TimetableDay enum indices are 0..6
    final currentDay = TimetableDay.values[now.weekday - 1];
    
    return weekly[currentDay] ?? [];
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
    });
  }

  Future<void> updateEntry(TimetableModel entry) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(timetableRepositoryProvider);
      await repository.updateEntry(entry);
    });
  }

  Future<void> deleteEntry(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(timetableRepositoryProvider);
      await repository.deleteEntry(id);
    });
  }
}

final timetableManagementProvider = AsyncNotifierProvider<TimetableManagementNotifier, void>(() {
  return TimetableManagementNotifier();
});
