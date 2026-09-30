import 'package:dio/dio.dart';
import '../../../../core/errors/acadex_error.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/assignment_models.dart';
import '../../domain/repositories/assignments_repository.dart';

class ApiAssignmentsRepository implements AssignmentsRepository {
  final ApiClient _apiClient;

  ApiAssignmentsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? apiClientInstance;

  static ApiClient get apiClientInstance => apiClient;

  @override
  Future<List<AssignmentModel>> getFacultyAssignments({
    String? status,
    String? sectionId,
    String? subjectId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (status != null && status.isNotEmpty) 'status': status,
        if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
        if (subjectId != null && subjectId.isNotEmpty) 'subjectId': subjectId,
      };

      final response = await _apiClient.dio.get(
        '/assignments',
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['data'] != null) {
        final list = response.data['data'] as List;
        return list
            .map((item) => AssignmentModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load assignments');
    }
  }

  @override
  Future<List<AssignmentModel>> getStudentAssignments() async {
    try {
      final response = await _apiClient.dio.get('/assignments/my');

      if (response.data != null && response.data['data'] != null) {
        final list = response.data['data'] as List;
        return list
            .map((item) => AssignmentModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load your assignments');
    }
  }

  @override
  Future<AssignmentModel> getAssignmentDetail(String id) async {
    try {
      final response = await _apiClient.dio.get('/assignments/$id');

      if (response.data != null && response.data['data'] != null) {
        return AssignmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.notFound,
        technicalMessage: 'Assignment not found',
        userMessage: 'Assignment not found',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load assignment details');
    }
  }

  @override
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
  }) async {
    try {
      final payload = {
        'facultyAssignmentId': facultyAssignmentId,
        'title': title,
        'description': description,
        'questions': questions ?? [],
        'assignmentType': (assignmentType ?? AssignmentType.homework).label,
        'dueDate': dueDate,
        'dueTime': dueTime,
        'maximumMarks': maximumMarks,
        'attachments': (attachments ?? []).map((a) => a.toJson()).toList(),
        'status': (status ?? AssignmentStatus.draft).name.toUpperCase(),
      };

      final response = await _apiClient.dio.post(
        '/assignments',
        data: payload,
      );

      if (response.data != null && response.data['data'] != null) {
        return AssignmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: "Couldn't publish the assignment. Please try again.",
        userMessage: "Couldn't publish the assignment. Please try again.",
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: "Couldn't publish the assignment. Please try again.");
    }
  }

  @override
  Future<AssignmentModel> publishAssignment(String id) async {
    try {
      final response = await _apiClient.dio.post('/assignments/$id/publish');

      if (response.data != null && response.data['data'] != null) {
        return AssignmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Failed to publish assignment',
        userMessage: 'Failed to publish assignment',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to publish assignment');
    }
  }

  @override
  Future<AssignmentModel> closeAssignment(String id) async {
    try {
      final response = await _apiClient.dio.post('/assignments/$id/close');

      if (response.data != null && response.data['data'] != null) {
        return AssignmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Failed to close assignment',
        userMessage: 'Failed to close assignment',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to close assignment');
    }
  }

  @override
  Future<void> completeAssignment(String id) async {
    try {
      await _apiClient.dio.post('/assignments/$id/complete');
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to mark assignment as done');
    }
  }

  @override
  Future<AssignmentActivityResponseModel> getAssignmentActivity(String id) async {
    try {
      final response = await _apiClient.dio.get('/assignments/$id/activity');

      if (response.data != null && response.data['data'] != null) {
        return AssignmentActivityResponseModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.notFound,
        technicalMessage: 'Failed to load assignment activity',
        userMessage: 'Failed to load assignment activity',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load assignment activity');
    }
  }

  @override
  Future<AssignmentActivityResponseModel> recordMarks(
    String id,
    List<Map<String, dynamic>> marks,
  ) async {
    try {
      final response = await _apiClient.dio.patch(
        '/assignments/$id/marks',
        data: {'marks': marks},
      );

      if (response.data != null && response.data['data'] != null) {
        return AssignmentActivityResponseModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Failed to save marks',
        userMessage: 'Failed to save marks',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to save marks');
    }
  }

  @override
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
  }) async {
    try {
      final payload = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (questions != null) 'questions': questions,
        if (assignmentType != null) 'assignmentType': assignmentType.label,
        if (dueDate != null) 'dueDate': dueDate,
        if (dueTime != null) 'dueTime': dueTime,
        if (maximumMarks != null) 'maximumMarks': maximumMarks,
        if (attachments != null)
          'attachments': attachments.map((a) => a.toJson()).toList(),
      };

      final response = await _apiClient.dio.put(
        '/assignments/$id',
        data: payload,
      );

      if (response.data != null && response.data['data'] != null) {
        return AssignmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Failed to update assignment',
        userMessage: 'Failed to update assignment',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to update assignment');
    }
  }

  @override
  Future<AssignmentModel> archiveAssignment(String id) async {
    try {
      final response = await _apiClient.dio.post('/assignments/$id/archive');

      if (response.data != null && response.data['data'] != null) {
        return AssignmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Failed to archive assignment',
        userMessage: 'Failed to archive assignment',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to archive assignment');
    }
  }

  @override
  Future<void> deleteAssignment(String id) async {
    try {
      await _apiClient.dio.delete('/assignments/$id');
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to delete draft assignment');
    }
  }

  @override
  Future<SubmissionModel?> getMySubmission(String assignmentId) async {
    try {
      final response = await _apiClient.dio.get('/assignments/$assignmentId/submission');
      if (response.data != null && response.data['data'] != null) {
        return SubmissionModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw AcadexException.fromDio(e, context: 'Failed to load submission');
    }
  }

  @override
  Future<SubmissionUploadAuthModel> getSubmissionUploadAuth({
    required String assignmentId,
    required String fileName,
    required String fileType,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/assignments/$assignmentId/submission/upload-auth',
        data: {
          'fileName': fileName,
          'fileType': fileType,
        },
      );
      if (response.data != null && response.data['data'] != null) {
        return SubmissionUploadAuthModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Failed to obtain upload authorization',
        userMessage: 'Upload authorization failed',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to authorize file upload');
    }
  }

  @override
  Future<SubmissionModel> saveDraftSubmission({
    required String assignmentId,
    String? textResponse,
    List<SubmissionAttachmentModel>? attachments,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (textResponse != null) 'textResponse': textResponse,
        if (attachments != null)
          'attachments': attachments.map((a) => a.toJson()).toList(),
      };
      final response = await _apiClient.dio.post(
        '/assignments/$assignmentId/submission/draft',
        data: payload,
      );
      if (response.data != null && response.data['data'] != null) {
        return SubmissionModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Failed to save draft submission',
        userMessage: 'Failed to save draft',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to save draft submission');
    }
  }

  @override
  Future<SubmissionModel> submitAssignment({
    required String assignmentId,
    String? textResponse,
    List<SubmissionAttachmentModel>? attachments,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (textResponse != null) 'textResponse': textResponse,
        if (attachments != null)
          'attachments': attachments.map((a) => a.toJson()).toList(),
      };
      final response = await _apiClient.dio.post(
        '/assignments/$assignmentId/submission',
        data: payload,
      );
      if (response.data != null && response.data['data'] != null) {
        return SubmissionModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Failed to submit assignment',
        userMessage: 'Submission failed',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to submit assignment');
    }
  }

  @override
  Future<String> getSubmissionFileDownloadUrl({
    required String submissionId,
    required String fileId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/assignments/submissions/$submissionId/files/$fileId/download-url',
      );
      if (response.data != null && response.data['data'] != null) {
        return response.data['data']['downloadUrl']?.toString() ?? '';
      }
      throw const AcadexException(
        category: ErrorCategory.notFound,
        technicalMessage: 'Download URL not found',
        userMessage: 'Could not access file',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to obtain download URL');
    }
  }

  @override
  Future<SubmissionModel> reviewSingleSubmission({
    required String assignmentId,
    required String studentId,
    double? marks,
    String? feedback,
    FacultyReviewStatus? reviewStatus,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (marks != null) 'marks': marks,
        if (feedback != null) 'feedback': feedback,
        if (reviewStatus != null)
          'reviewStatus': reviewStatus == FacultyReviewStatus.reviewed
              ? 'REVIEWED'
              : 'UNDER_REVIEW',
      };
      final response = await _apiClient.dio.patch(
        '/assignments/$assignmentId/submissions/$studentId/review',
        data: payload,
      );
      if (response.data != null && response.data['data'] != null) {
        return SubmissionModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Failed to review submission',
        userMessage: 'Failed to save review',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to review submission');
    }
  }
}

