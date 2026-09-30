import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/api_academic_result_repository.dart';
import '../../domain/models/academic_result_models.dart';

final academicResultRepositoryProvider = Provider<ApiAcademicResultRepository>((ref) {
  return ApiAcademicResultRepository();
});

/// Student official result provider for a given semester (or null for latest).
final studentOfficialResultProvider = FutureProvider.family<StudentOfficialResultModel?, String?>(
  (ref, semesterId) async {
    final repo = ref.watch(academicResultRepositoryProvider);
    return repo.getStudentOfficialResult(semesterId: semesterId);
  },
);

/// Filter state for admin/HOD academic results querying.
class AcademicResultFilterState {
  final String? courseId;
  final String? academicYearId;
  final String? semesterId;
  final String? sectionId;
  final ResultLifecycleStatus? status;
  final int page;
  final int limit;

  const AcademicResultFilterState({
    this.courseId,
    this.academicYearId,
    this.semesterId,
    this.sectionId,
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  AcademicResultFilterState copyWith({
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    ResultLifecycleStatus? status,
    bool clearStatus = false,
    int? page,
    int? limit,
  }) {
    return AcademicResultFilterState(
      courseId: courseId ?? this.courseId,
      academicYearId: academicYearId ?? this.academicYearId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      status: clearStatus ? null : (status ?? this.status),
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

class AcademicResultFilterNotifier extends StateNotifier<AcademicResultFilterState> {
  AcademicResultFilterNotifier() : super(const AcademicResultFilterState());

  void setCourseId(String? id) => state = state.copyWith(courseId: id, page: 1);
  void setAcademicYearId(String? id) => state = state.copyWith(academicYearId: id, page: 1);
  void setSemesterId(String? id) => state = state.copyWith(semesterId: id, page: 1);
  void setSectionId(String? id) => state = state.copyWith(sectionId: id, page: 1);
  void setStatus(ResultLifecycleStatus? status) {
    if (status == null) {
      state = state.copyWith(clearStatus: true, page: 1);
    } else {
      state = state.copyWith(status: status, page: 1);
    }
  }
  void setPage(int page) => state = state.copyWith(page: page);
  void reset() => state = const AcademicResultFilterState();
}

final academicResultFilterProvider = StateNotifierProvider<AcademicResultFilterNotifier, AcademicResultFilterState>((ref) {
  return AcademicResultFilterNotifier();
});

/// Provider for queried admin/HOD results list.
final adminResultsQueryProvider = FutureProvider<({List<AcademicResultModel> results, int total, int page, int pages})>((ref) async {
  final filters = ref.watch(academicResultFilterProvider);
  final repo = ref.watch(academicResultRepositoryProvider);

  return repo.queryResults(
    courseId: filters.courseId,
    academicYearId: filters.academicYearId,
    semesterId: filters.semesterId,
    sectionId: filters.sectionId,
    status: filters.status,
    page: filters.page,
    limit: filters.limit,
  );
});

/// Single result detail provider.
final resultDetailProvider = FutureProvider.family<AcademicResultModel, String>((ref, id) async {
  final repo = ref.watch(academicResultRepositoryProvider);
  return repo.getResultDetail(id);
});

/// Action controller for admin result operations (review, finalize, publish, reopen, calculate).
class AcademicResultActionNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiAcademicResultRepository _repo;
  final Ref _ref;

  AcademicResultActionNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<bool> calculateClass({
    required String semesterId,
    required String academicYearId,
    required String courseId,
    String? sectionId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.calculateClassResults(
        semesterId: semesterId,
        academicYearId: academicYearId,
        courseId: courseId,
        sectionId: sectionId,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(adminResultsQueryProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> reviewResult(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.reviewResult(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(adminResultsQueryProvider);
      _ref.invalidate(resultDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> finalizeResult(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.finalizeResult(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(adminResultsQueryProvider);
      _ref.invalidate(resultDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> publishResult(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.publishResult(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(adminResultsQueryProvider);
      _ref.invalidate(resultDetailProvider(id));
      _ref.invalidate(studentOfficialResultProvider(null));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> reopenResult(String id, {required String reason}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.reopenResult(id, reason: reason);
      state = const AsyncValue.data(null);
      _ref.invalidate(adminResultsQueryProvider);
      _ref.invalidate(resultDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final academicResultActionProvider = StateNotifierProvider<AcademicResultActionNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(academicResultRepositoryProvider);
  return AcademicResultActionNotifier(repo, ref);
});
