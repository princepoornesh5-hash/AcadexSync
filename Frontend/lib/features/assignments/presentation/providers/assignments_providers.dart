import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/assignment_models.dart';
import '../../domain/repositories/assignments_repository.dart';
import '../../data/repositories/api_assignments_repository.dart';

final assignmentsRepositoryProvider = Provider<AssignmentsRepository>((ref) {
  return ApiAssignmentsRepository();
});

final facultyCourseAssignmentsProvider = FutureProvider.autoDispose<List<AssignmentModel>>((ref) async {
  final repo = ref.watch(assignmentsRepositoryProvider);
  return repo.getFacultyAssignments();
});

final studentAssignmentsProvider = FutureProvider.autoDispose<List<AssignmentModel>>((ref) async {
  final repo = ref.watch(assignmentsRepositoryProvider);
  return repo.getStudentAssignments();
});

final assignmentDetailProvider = FutureProvider.autoDispose.family<AssignmentModel, String>((ref, id) async {
  final repo = ref.watch(assignmentsRepositoryProvider);
  return repo.getAssignmentDetail(id);
});

class AssignmentActivityNotifier
    extends StateNotifier<AsyncValue<AssignmentActivityResponseModel>> {
  final AssignmentsRepository _repository;
  final String _assignmentId;

  // Local pending mark edits map: studentId -> pending mark
  final Map<String, int> _pendingMarks = {};

  AssignmentActivityNotifier(this._repository, this._assignmentId)
      : super(const AsyncValue.loading()) {
    loadActivity();
  }

  Map<String, int> get pendingMarks => Map.unmodifiable(_pendingMarks);
  bool get hasPendingChanges => _pendingMarks.isNotEmpty;

  Future<void> loadActivity() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getAssignmentActivity(_assignmentId);
      _pendingMarks.clear();
      state = AsyncValue.data(data);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  void updateLocalMark(String studentId, int mark) {
    _pendingMarks[studentId] = mark;

    state.whenData((current) {
      final updatedCompleted = current.completed.map((student) {
        if (student.studentId == studentId) {
          return student.copyWith(
            marks: mark,
            reviewStatus: FacultyReviewStatus.reviewed,
          );
        }
        return student;
      }).toList();

      state = AsyncValue.data(AssignmentActivityResponseModel(
        assignment: current.assignment,
        summary: current.summary,
        completed: updatedCompleted,
        pending: current.pending,
      ));
    });
  }

  Future<bool> saveMarks() async {
    if (_pendingMarks.isEmpty) return true;

    final marksPayload = _pendingMarks.entries
        .map((e) => {'studentId': e.key, 'marks': e.value})
        .toList();

    try {
      final updated = await _repository.recordMarks(_assignmentId, marksPayload);
      _pendingMarks.clear();
      state = AsyncValue.data(updated);
      return true;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      return false;
    }
  }
}

final assignmentActivityProvider = StateNotifierProvider.autoDispose
    .family<AssignmentActivityNotifier, AsyncValue<AssignmentActivityResponseModel>, String>(
  (ref, id) {
    final repo = ref.watch(assignmentsRepositoryProvider);
    return AssignmentActivityNotifier(repo, id);
  },
);

class AssignmentActionState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const AssignmentActionState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });
}

class AssignmentActionNotifier extends StateNotifier<AssignmentActionState> {
  final Ref _ref;

  AssignmentActionNotifier(this._ref) : super(const AssignmentActionState());

  AssignmentsRepository get _repo => _ref.read(assignmentsRepositoryProvider);

  Future<AssignmentModel?> createAssignment({
    required String facultyAssignmentId,
    required String title,
    required String description,
    List<String>? questions,
    AssignmentType? assignmentType,
    required String dueDate,
    required String dueTime,
    required int maximumMarks,
    List<AssignmentAttachmentModel>? attachments,
    AssignmentStatus? status,
  }) async {
    state = const AssignmentActionState(isLoading: true);
    try {
      final created = await _repo.createAssignment(
        facultyAssignmentId: facultyAssignmentId,
        title: title,
        description: description,
        questions: questions,
        assignmentType: assignmentType,
        dueDate: dueDate,
        dueTime: dueTime,
        maximumMarks: maximumMarks,
        attachments: attachments,
        status: status,
      );
      _ref.invalidate(facultyCourseAssignmentsProvider);
      state = const AssignmentActionState(isSuccess: true);
      return created;
    } catch (e) {
      state = AssignmentActionState(error: e.toString());
      return null;
    }
  }

  Future<bool> publishAssignment(String id) async {
    state = const AssignmentActionState(isLoading: true);
    try {
      await _repo.publishAssignment(id);
      _ref.invalidate(facultyCourseAssignmentsProvider);
      _ref.invalidate(assignmentDetailProvider(id));
      state = const AssignmentActionState(isSuccess: true);
      return true;
    } catch (e) {
      state = AssignmentActionState(error: e.toString());
      return false;
    }
  }

  Future<bool> closeAssignment(String id) async {
    state = const AssignmentActionState(isLoading: true);
    try {
      await _repo.closeAssignment(id);
      _ref.invalidate(facultyCourseAssignmentsProvider);
      _ref.invalidate(assignmentDetailProvider(id));
      state = const AssignmentActionState(isSuccess: true);
      return true;
    } catch (e) {
      state = AssignmentActionState(error: e.toString());
      return false;
    }
  }

  Future<bool> completeAssignment(String id) async {
    state = const AssignmentActionState(isLoading: true);
    try {
      await _repo.completeAssignment(id);
      _ref.invalidate(studentAssignmentsProvider);
      _ref.invalidate(assignmentDetailProvider(id));
      state = const AssignmentActionState(isSuccess: true);
      return true;
    } catch (e) {
      state = AssignmentActionState(error: e.toString());
      return false;
    }
  }
}

final assignmentActionProvider =
    StateNotifierProvider.autoDispose<AssignmentActionNotifier, AssignmentActionState>(
  (ref) => AssignmentActionNotifier(ref),
);
