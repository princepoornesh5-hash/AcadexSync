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

final mySubmissionProvider = FutureProvider.autoDispose.family<SubmissionModel?, String>((ref, assignmentId) async {
  final repo = ref.watch(assignmentsRepositoryProvider);
  return repo.getMySubmission(assignmentId);
});

class AssignmentActivityNotifier
    extends StateNotifier<AsyncValue<AssignmentActivityResponseModel>> {
  final AssignmentsRepository _repository;
  final String _assignmentId;

  // Local pending mark edits map: studentId -> pending mark
  final Map<String, double> _pendingMarks = {};

  AssignmentActivityNotifier(this._repository, this._assignmentId)
      : super(const AsyncValue.loading()) {
    loadActivity();
  }

  Map<String, double> get pendingMarks => Map.unmodifiable(_pendingMarks);
  bool get hasPendingChanges => _pendingMarks.isNotEmpty;

  Future<void> loadActivity() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getAssignmentActivity(_assignmentId);
      if (!mounted) return;
      _pendingMarks.clear();
      state = AsyncValue.data(data);
    } catch (err, stack) {
      if (!mounted) return;
      state = AsyncValue.error(err, stack);
    }
  }

  void updateLocalMark(String studentId, double mark) {
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

      if (!mounted) return;
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
      if (!mounted) return true;
      _pendingMarks.clear();
      state = AsyncValue.data(updated);
      return true;
    } catch (err, stack) {
      if (!mounted) return false;
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

  Future<AssignmentModel?> updateAssignment({
    required String id,
    String? title,
    String? description,
    List<String>? questions,
    AssignmentType? assignmentType,
    String? dueDate,
    String? dueTime,
    int? maximumMarks,
    List<AssignmentAttachmentModel>? attachments,
  }) async {
    state = const AssignmentActionState(isLoading: true);
    try {
      final updated = await _repo.updateAssignment(
        id: id,
        title: title,
        description: description,
        questions: questions,
        assignmentType: assignmentType,
        dueDate: dueDate,
        dueTime: dueTime,
        maximumMarks: maximumMarks,
        attachments: attachments,
      );
      _ref.invalidate(facultyCourseAssignmentsProvider);
      _ref.invalidate(assignmentDetailProvider(id));
      state = const AssignmentActionState(isSuccess: true);
      return updated;
    } catch (e) {
      state = AssignmentActionState(error: e.toString());
      return null;
    }
  }

  Future<bool> archiveAssignment(String id) async {
    state = const AssignmentActionState(isLoading: true);
    try {
      await _repo.archiveAssignment(id);
      _ref.invalidate(facultyCourseAssignmentsProvider);
      _ref.invalidate(assignmentDetailProvider(id));
      state = const AssignmentActionState(isSuccess: true);
      return true;
    } catch (e) {
      state = AssignmentActionState(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteAssignment(String id) async {
    state = const AssignmentActionState(isLoading: true);
    try {
      await _repo.deleteAssignment(id);
      _ref.invalidate(facultyCourseAssignmentsProvider);
      state = const AssignmentActionState(isSuccess: true);
      return true;
    } catch (e) {
      state = AssignmentActionState(error: e.toString());
      return false;
    }
  }

  Future<SubmissionModel?> saveDraftSubmission({
    required String assignmentId,
    String? textResponse,
    List<SubmissionAttachmentModel>? attachments,
  }) async {
    state = const AssignmentActionState(isLoading: true);
    try {
      final sub = await _repo.saveDraftSubmission(
        assignmentId: assignmentId,
        textResponse: textResponse,
        attachments: attachments,
      );
      _ref.invalidate(mySubmissionProvider(assignmentId));
      state = const AssignmentActionState(isSuccess: true);
      return sub;
    } catch (e) {
      state = AssignmentActionState(error: e.toString());
      return null;
    }
  }

  Future<SubmissionModel?> submitAssignment({
    required String assignmentId,
    String? textResponse,
    List<SubmissionAttachmentModel>? attachments,
  }) async {
    state = const AssignmentActionState(isLoading: true);
    try {
      final sub = await _repo.submitAssignment(
        assignmentId: assignmentId,
        textResponse: textResponse,
        attachments: attachments,
      );
      _ref.invalidate(mySubmissionProvider(assignmentId));
      _ref.invalidate(studentAssignmentsProvider);
      _ref.invalidate(assignmentDetailProvider(assignmentId));
      _ref.invalidate(assignmentActivityProvider(assignmentId));
      state = const AssignmentActionState(isSuccess: true);
      return sub;
    } catch (e) {
      state = AssignmentActionState(error: e.toString());
      return null;
    }
  }

  Future<SubmissionModel?> reviewSingleSubmission({
    required String assignmentId,
    required String studentId,
    double? marks,
    String? feedback,
    FacultyReviewStatus? reviewStatus,
  }) async {
    state = const AssignmentActionState(isLoading: true);
    try {
      final sub = await _repo.reviewSingleSubmission(
        assignmentId: assignmentId,
        studentId: studentId,
        marks: marks,
        feedback: feedback,
        reviewStatus: reviewStatus,
      );
      _ref.invalidate(assignmentActivityProvider(assignmentId));
      _ref.invalidate(mySubmissionProvider(assignmentId));
      state = const AssignmentActionState(isSuccess: true);
      return sub;
    } catch (e) {
      state = AssignmentActionState(error: e.toString());
      return null;
    }
  }
}

final assignmentActionProvider =
    StateNotifierProvider.autoDispose<AssignmentActionNotifier, AssignmentActionState>(
  (ref) => AssignmentActionNotifier(ref),
);
