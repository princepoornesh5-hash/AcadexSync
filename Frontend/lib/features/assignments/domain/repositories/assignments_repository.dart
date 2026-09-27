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
}
