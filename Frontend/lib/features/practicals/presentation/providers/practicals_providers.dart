import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/practicals_repository.dart';
import '../../domain/models/practical_models.dart';

final practicalsRepositoryProvider = Provider<PracticalsRepository>((ref) {
  return ApiPracticalsRepository();
});

class PracticalFilter {
  final String? facultyAssignmentId;
  final String? subjectId;
  final String? sectionId;
  final String? status;

  const PracticalFilter({
    this.facultyAssignmentId,
    this.subjectId,
    this.sectionId,
    this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticalFilter &&
          runtimeType == other.runtimeType &&
          facultyAssignmentId == other.facultyAssignmentId &&
          subjectId == other.subjectId &&
          sectionId == other.sectionId &&
          status == other.status;

  @override
  int get hashCode =>
      facultyAssignmentId.hashCode ^
      subjectId.hashCode ^
      sectionId.hashCode ^
      status.hashCode;

  PracticalFilter copyWith({
    String? facultyAssignmentId,
    String? subjectId,
    String? sectionId,
    String? status,
  }) {
    return PracticalFilter(
      facultyAssignmentId: facultyAssignmentId ?? this.facultyAssignmentId,
      subjectId: subjectId ?? this.subjectId,
      sectionId: sectionId ?? this.sectionId,
      status: status ?? this.status,
    );
  }
}

final practicalFilterProvider = StateProvider<PracticalFilter>((ref) {
  return const PracticalFilter();
});

final practicalSessionsListProvider = FutureProvider.family<List<PracticalSessionModel>, PracticalFilter>((ref, filter) async {
  final repo = ref.watch(practicalsRepositoryProvider);
  return repo.getSessions(
    facultyAssignmentId: filter.facultyAssignmentId,
    subjectId: filter.subjectId,
    sectionId: filter.sectionId,
    status: filter.status,
  );
});

final practicalSessionDetailProvider = FutureProvider.family<
    ({PracticalSessionModel session, List<PracticalParticipationModel> participations}),
    String>((ref, sessionId) async {
  final repo = ref.watch(practicalsRepositoryProvider);
  return repo.getSessionById(sessionId);
});

final studentPracticalHistoryProvider = FutureProvider.family<List<StudentPracticalHistoryModel>, String?>((ref, subjectId) async {
  final repo = ref.watch(practicalsRepositoryProvider);
  return repo.getStudentHistory(subjectId: subjectId);
});

class PracticalActionNotifier extends StateNotifier<AsyncValue<void>> {
  final PracticalsRepository _repo;
  final Ref _ref;

  PracticalActionNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<PracticalSessionModel?> createSession(Map<String, dynamic> payload) async {
    state = const AsyncValue.loading();
    try {
      final session = await _repo.createSession(payload);
      state = const AsyncValue.data(null);
      _ref.invalidate(practicalSessionsListProvider);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<PracticalSessionModel?> openSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final session = await _repo.openSession(sessionId);
      state = const AsyncValue.data(null);
      _ref.invalidate(practicalSessionDetailProvider(sessionId));
      _ref.invalidate(practicalSessionsListProvider);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<PracticalSessionModel?> completeSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final session = await _repo.completeSession(sessionId);
      state = const AsyncValue.data(null);
      _ref.invalidate(practicalSessionDetailProvider(sessionId));
      _ref.invalidate(practicalSessionsListProvider);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<PracticalSessionModel?> cancelSession(String sessionId, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      final session = await _repo.cancelSession(sessionId, reason: reason);
      state = const AsyncValue.data(null);
      _ref.invalidate(practicalSessionDetailProvider(sessionId));
      _ref.invalidate(practicalSessionsListProvider);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateParticipation({
    required String sessionId,
    required String studentId,
    required PracticalParticipationStatus status,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateParticipation(
        sessionId: sessionId,
        studentId: studentId,
        status: status,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(practicalSessionDetailProvider(sessionId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> bulkUpdateParticipation({
    required String sessionId,
    required List<Map<String, dynamic>> updates,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.bulkUpdateParticipation(
        sessionId: sessionId,
        updates: updates,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(practicalSessionDetailProvider(sessionId));
      _ref.invalidate(practicalSessionsListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final practicalActionProvider = StateNotifierProvider<PracticalActionNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(practicalsRepositoryProvider);
  return PracticalActionNotifier(repo, ref);
});
