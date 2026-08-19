import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../storage/presentation/providers/storage_providers.dart';
import '../../data/repositories/firebase_achievement_repository.dart';
import '../../data/repositories/mock_achievement_repository.dart';
import '../../domain/models/achievement_models.dart';
import '../../domain/repositories/achievement_repository.dart';

/// Active Achievement Repository Provider.
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState is AuthAuthenticated ? authState.user : null;

  if (FirebaseInitializer.shouldUseMock) {
    return MockAchievementRepository(currentUser: user);
  }

  final firestore = ref.watch(firestoreServiceProvider);
  final storage = ref.watch(fileStorageRepositoryProvider);
  return FirebaseAchievementRepository(firestore, fileStorageRepository: storage);
});

/// Stream of student-owned achievements.
final studentAchievementsProvider = StreamProvider.autoDispose<List<Achievement>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    return Stream.value([]);
  }

  final user = authState.user;
  final repo = ref.watch(achievementRepositoryProvider);

  return repo.watchStudentAchievements(
    studentUid: user.id,
    collegeId: user.collegeId ?? 'default',
  );
});

/// Stream of scoped achievements for reviewers (Faculty, HOD, College Admin).
final scopedAchievementsProvider = StreamProvider.autoDispose<List<Achievement>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    return Stream.value([]);
  }

  final user = authState.user;
  final repo = ref.watch(achievementRepositoryProvider);

  return repo.watchScopedAchievements(requester: user);
});

/// Filter state for student achievements.
final achievementFilterProvider = StateProvider.autoDispose<AchievementFilter>((ref) {
  return const AchievementFilter();
});

/// Filtered achievements for presentation in the student dashboard.
final filteredStudentAchievementsProvider = Provider.autoDispose<List<Achievement>>((ref) {
  final asyncAchievements = ref.watch(studentAchievementsProvider);
  final filter = ref.watch(achievementFilterProvider);

  final achievements = asyncAchievements.valueOrNull ?? [];
  return _applyFilter(achievements, filter);
});

/// Filtered achievements for administrative review.
final filteredScopedAchievementsProvider = Provider.autoDispose<List<Achievement>>((ref) {
  final asyncAchievements = ref.watch(scopedAchievementsProvider);
  final filter = ref.watch(achievementFilterProvider);

  final achievements = asyncAchievements.valueOrNull ?? [];
  return _applyFilter(achievements, filter);
});

List<Achievement> _applyFilter(List<Achievement> list, AchievementFilter filter) {
  var filtered = list.where((a) {
    // Search query across title, issuer, description, tags
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      final titleMatch = a.title.toLowerCase().contains(q);
      final issuerMatch = a.issuer.toLowerCase().contains(q);
      final descMatch = a.description.toLowerCase().contains(q);
      final skillsMatch = a.skills.any((s) => s.toLowerCase().contains(q));
      if (!titleMatch && !issuerMatch && !descMatch && !skillsMatch) {
        return false;
      }
    }

    // Category filter
    if (filter.category != null && a.category != filter.category) {
      return false;
    }

    // Verification status filter
    if (filter.verificationStatus != null && a.verificationStatus != filter.verificationStatus) {
      return false;
    }

    // Year filter
    if (filter.year != null && a.year != filter.year) {
      return false;
    }

    return true;
  }).toList();

  // Sorting
  switch (filter.sortOption) {
    case AchievementSortOption.newest:
      filtered.sort((a, b) => b.achievementDate.compareTo(a.achievementDate));
      break;
    case AchievementSortOption.oldest:
      filtered.sort((a, b) => a.achievementDate.compareTo(b.achievementDate));
      break;
    case AchievementSortOption.alphabetical:
      filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
    case AchievementSortOption.verifiedFirst:
      filtered.sort((a, b) {
        if (a.isVerified && !b.isVerified) return -1;
        if (!a.isVerified && b.isVerified) return 1;
        return b.achievementDate.compareTo(a.achievementDate);
      });
      break;
  }

  return filtered;
}

/// Computes student achievement summary metrics.
final studentAchievementMetricsProvider = Provider.autoDispose<AchievementMetrics>((ref) {
  final asyncAchievements = ref.watch(studentAchievementsProvider);
  final list = asyncAchievements.valueOrNull ?? [];
  final currentYear = DateTime.now().year;

  return AchievementMetrics(
    total: list.length,
    verified: list.where((a) => a.isVerified).length,
    pending: list.where((a) => a.isPending).length,
    unverified: list.where((a) => a.isUnverified).length,
    rejected: list.where((a) => a.isRejected).length,
    currentYearCount: list.where((a) => a.year == currentYear).length,
  );
});

/// Computes admin review summary metrics.
final adminAchievementMetricsProvider = Provider.autoDispose<AchievementMetrics>((ref) {
  final asyncAchievements = ref.watch(scopedAchievementsProvider);
  final list = asyncAchievements.valueOrNull ?? [];
  final currentYear = DateTime.now().year;

  return AchievementMetrics(
    total: list.length,
    verified: list.where((a) => a.isVerified).length,
    pending: list.where((a) => a.isPending).length,
    unverified: list.where((a) => a.isUnverified).length,
    rejected: list.where((a) => a.isRejected).length,
    currentYearCount: list.where((a) => a.year == currentYear).length,
  );
});

/// Fetches a single achievement by ID.
final achievementDetailProvider = FutureProvider.family<Achievement?, String>((ref, id) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getAchievementById(id);
});
