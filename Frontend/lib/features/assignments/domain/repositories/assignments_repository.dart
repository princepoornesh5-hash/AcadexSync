import '../models/assignment_models.dart';

abstract class AssignmentsRepository {
  Future<List<AssignmentModel>> getFacultyAssignments({
    String? status,
    String? sectionId,
    String? subjectId,
  });

  Future<List<AssignmentModel>> getStudentAssignments();

  Future<AssignmentModel> getAssignmentDetail(String id);

  Future<AssignmentModel> createAssignment({
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
  });

  Future<AssignmentModel> publishAssignment(String id);

  Future<AssignmentModel> closeAssignment(String id);

  Future<void> completeAssignment(String id);

  Future<AssignmentActivityResponseModel> getAssignmentActivity(String id);

  Future<AssignmentActivityResponseModel> recordMarks(
    String id,
    List<Map<String, dynamic>> marks,
  );

  Future<AssignmentModel> updateAssignment({
    required String id,
    String? title,
    String? description,
    List<String>? questions,
    AssignmentType? assignmentType,
    String? dueDate,
    String? dueTime,
    int? maximumMarks,
    List<AssignmentAttachmentModel>? attachments,
  });

  Future<AssignmentModel> archiveAssignment(String id);

  Future<void> deleteAssignment(String id);

  Future<SubmissionModel?> getMySubmission(String assignmentId);

  Future<SubmissionUploadAuthModel> getSubmissionUploadAuth({
    required String assignmentId,
    required String fileName,
    required String fileType,
  });

  Future<SubmissionModel> saveDraftSubmission({
    required String assignmentId,
    String? textResponse,
    List<SubmissionAttachmentModel>? attachments,
  });

  Future<SubmissionModel> submitAssignment({
    required String assignmentId,
    String? textResponse,
    List<SubmissionAttachmentModel>? attachments,
  });

  Future<String> getSubmissionFileDownloadUrl({
    required String submissionId,
    required String fileId,
  });

  Future<SubmissionModel> reviewSingleSubmission({
    required String assignmentId,
    required String studentId,
    double? marks,
    String? feedback,
    FacultyReviewStatus? reviewStatus,
  });
}
