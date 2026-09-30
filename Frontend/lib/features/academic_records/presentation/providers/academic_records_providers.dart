import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/academic_records_repository.dart';
import '../../domain/models/academic_record_models.dart';

final academicRecordsRepositoryProvider = Provider<AcademicRecordsRepository>((ref) {
  return ApiAcademicRecordsRepository();
});

/// Fetches chronological academic history for a student.
/// If `studentId` is null, fetches authenticated student's own history.
final studentAcademicRecordsHistoryProvider =
    FutureProvider.family<List<AcademicHistoryItemModel>, String?>((ref, studentId) async {
  final repo = ref.watch(academicRecordsRepositoryProvider);
  return repo.getStudentHistory(studentId: studentId);
});

/// Fetches full structured detail for a single academic record.
final academicRecordDetailProvider =
    FutureProvider.family<AcademicRecordDetailModel, String>((ref, recordId) async {
  final repo = ref.watch(academicRecordsRepositoryProvider);
  return repo.getRecordDetail(recordId);
});

/// Filter state for department/college academic records list.
class DepartmentRecordsFilter {
  final String? departmentId;
  final String? courseId;
  final String? semesterId;
  final String? academicYearId;
  final String? progressionStatus;
  final int page;
  final int limit;

  const DepartmentRecordsFilter({
    this.departmentId,
    this.courseId,
    this.semesterId,
    this.academicYearId,
    this.progressionStatus,
    this.page = 1,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepartmentRecordsFilter &&
          runtimeType == other.runtimeType &&
          departmentId == other.departmentId &&
          courseId == other.courseId &&
          semesterId == other.semesterId &&
          academicYearId == other.academicYearId &&
          progressionStatus == other.progressionStatus &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode =>
      departmentId.hashCode ^
      courseId.hashCode ^
      semesterId.hashCode ^
      academicYearId.hashCode ^
      progressionStatus.hashCode ^
      page.hashCode ^
      limit.hashCode;

  DepartmentRecordsFilter copyWith({
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? academicYearId,
    String? progressionStatus,
    int? page,
    int? limit,
  }) {
    return DepartmentRecordsFilter(
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      academicYearId: academicYearId ?? this.academicYearId,
      progressionStatus: progressionStatus ?? this.progressionStatus,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

final departmentRecordsFilterProvider = StateProvider<DepartmentRecordsFilter>((ref) {
  return const DepartmentRecordsFilter();
});

/// Department records list provider watching current filter state.
final departmentAcademicRecordsProvider =
    FutureProvider.family<PaginatedAcademicRecordsModel, DepartmentRecordsFilter>((ref, filter) async {
  final repo = ref.watch(academicRecordsRepositoryProvider);
  return repo.getDepartmentRecords(
    departmentId: filter.departmentId,
    courseId: filter.courseId,
    semesterId: filter.semesterId,
    academicYearId: filter.academicYearId,
    progressionStatus: filter.progressionStatus,
    page: filter.page,
    limit: filter.limit,
  );
});

/// Controller for mutating academic progression status & subject status.
class AcademicRecordActionController extends StateNotifier<AsyncValue<void>> {
  final AcademicRecordsRepository _repository;
  final Ref _ref;

  AcademicRecordActionController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> updateProgression(
    String recordId, {
    required AcademicProgressionStatus status,
    String? remarks,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateProgressionStatus(recordId, status: status, remarks: remarks);
      // Invalidate relevant providers to trigger immediate reactive refresh
      _ref.invalidate(academicRecordDetailProvider(recordId));
      _ref.invalidate(studentAcademicRecordsHistoryProvider(null));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateSubjectStatus(
    String subjectRecordId, {
    required SubjectAcademicStatus status,
    String? remarks,
    String? parentRecordId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateSubjectStatus(subjectRecordId, status: status, remarks: remarks);
      if (parentRecordId != null) {
        _ref.invalidate(academicRecordDetailProvider(parentRecordId));
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final academicRecordActionControllerProvider =
    StateNotifierProvider<AcademicRecordActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(academicRecordsRepositoryProvider);
  return AcademicRecordActionController(repo, ref);
});
