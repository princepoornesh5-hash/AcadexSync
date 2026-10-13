import 'package:dio/dio.dart';
import '../../../../core/errors/acadex_error.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/internal_assessment_models.dart';

class ApiAssessmentRepository {
  final ApiClient _apiClient;

  ApiAssessmentRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? apiClientInstance;

  static ApiClient get apiClientInstance => apiClient;

  /// Retrieves or initializes assessment context for a subject and section, or specific assessment.
  Future<AssessmentContextModel> getAssessmentContext({
    String? sectionId,
    String? subjectId,
    String? academicYearId,
    String? assessmentId,
    String? facultyAssignmentId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/assessments/context',
        queryParameters: {
          if (sectionId != null) 'sectionId': sectionId,
          if (subjectId != null) 'subjectId': subjectId,
          if (academicYearId != null) 'academicYearId': academicYearId,
          if (assessmentId != null) 'assessmentId': assessmentId,
          if (facultyAssignmentId != null) 'facultyAssignmentId': facultyAssignmentId,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        return AssessmentContextModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Failed to parse assessment context data.',
        userMessage: 'Unable to load assessment context. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load assessment context');
    }
  }

  /// Opens an assessment for mark entry.
  Future<InternalAssessmentModel> openAssessment({
    String? assessmentId,
    String? sectionId,
    String? subjectId,
  }) async {
    try {
      final endpoint = assessmentId != null
          ? '/assessments/$assessmentId/open'
          : '/assessments/open';
      final response = await _apiClient.dio.post(
        endpoint,
        data: {
          if (assessmentId != null) 'assessmentId': assessmentId,
          if (sectionId != null) 'sectionId': sectionId,
          if (subjectId != null) 'subjectId': subjectId,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        return InternalAssessmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Failed to parse opened assessment data.',
        userMessage: 'Unable to open assessment. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to open assessment');
    }
  }

  /// Closes an assessment to lock mark entries prior to review/publication.
  Future<InternalAssessmentModel> closeAssessment({
    String? assessmentId,
    String? sectionId,
    String? subjectId,
  }) async {
    try {
      final endpoint = assessmentId != null
          ? '/assessments/$assessmentId/close'
          : '/assessments/close';
      final response = await _apiClient.dio.post(
        endpoint,
        data: {
          if (assessmentId != null) 'assessmentId': assessmentId,
          if (sectionId != null) 'sectionId': sectionId,
          if (subjectId != null) 'subjectId': subjectId,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        return InternalAssessmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Failed to parse closed assessment data.',
        userMessage: 'Unable to close assessment. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to close assessment');
    }
  }

  /// Saves draft marks for a class section and subject.
  Future<InternalAssessmentModel> saveDraftMarks({
    String? assessmentId,
    String? sectionId,
    String? subjectId,
    required List<StudentAssessmentEntryModel> entries,
    String? title,
    String? academicYearId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/assessments/draft',
        data: {
          if (assessmentId != null) 'assessmentId': assessmentId,
          if (sectionId != null) 'sectionId': sectionId,
          if (subjectId != null) 'subjectId': subjectId,
          if (title != null) 'title': title,
          if (academicYearId != null) 'academicYearId': academicYearId,
          'entries': entries.map((e) => e.toJson()).toList(),
        },
      );

      if (response.data != null && response.data['data'] != null) {
        return InternalAssessmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Failed to parse saved assessment data.',
        userMessage: 'Unable to save assessment marks. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to save draft marks');
    }
  }

  /// Bulk saves marks.
  Future<InternalAssessmentModel> bulkSaveMarks({
    String? assessmentId,
    String? sectionId,
    String? subjectId,
    required List<StudentAssessmentEntryModel> entries,
    String? title,
    String? academicYearId,
  }) async {
    try {
      final endpoint = assessmentId != null
          ? '/assessments/$assessmentId/marks/bulk'
          : '/assessments/marks/bulk';
      final response = await _apiClient.dio.post(
        endpoint,
        data: {
          if (assessmentId != null) 'assessmentId': assessmentId,
          if (sectionId != null) 'sectionId': sectionId,
          if (subjectId != null) 'subjectId': subjectId,
          if (title != null) 'title': title,
          if (academicYearId != null) 'academicYearId': academicYearId,
          'entries': entries.map((e) => e.toJson()).toList(),
        },
      );

      if (response.data != null && response.data['data'] != null) {
        return InternalAssessmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Failed to parse bulk assessment data.',
        userMessage: 'Unable to bulk save marks. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to bulk save marks');
    }
  }

  /// Marks an assessment as REVIEWED.
  Future<InternalAssessmentModel> reviewMarks({
    String? assessmentId,
    String? sectionId,
    String? subjectId,
    String? comments,
  }) async {
    try {
      final endpoint = assessmentId != null
          ? '/assessments/$assessmentId/review'
          : '/assessments/review';
      final response = await _apiClient.dio.post(
        endpoint,
        data: {
          if (assessmentId != null) 'assessmentId': assessmentId,
          if (sectionId != null) 'sectionId': sectionId,
          if (subjectId != null) 'subjectId': subjectId,
          if (comments != null) 'comments': comments,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        return InternalAssessmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Failed to parse review assessment data.',
        userMessage: 'Unable to update review status. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to review assessment');
    }
  }

  /// Finalizes and publishes internal assessment marks (locking them).
  Future<InternalAssessmentModel> publishMarks({
    String? assessmentId,
    String? sectionId,
    String? subjectId,
  }) async {
    try {
      final endpoint = assessmentId != null
          ? '/assessments/$assessmentId/publish'
          : '/assessments/publish';
      final response = await _apiClient.dio.post(
        endpoint,
        data: {
          if (assessmentId != null) 'assessmentId': assessmentId,
          if (sectionId != null) 'sectionId': sectionId,
          if (subjectId != null) 'subjectId': subjectId,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        return InternalAssessmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Failed to parse published assessment data.',
        userMessage: 'Unable to publish assessment. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to publish marks');
    }
  }

  /// Unlocks a published assessment for edits (Admin/HOD only).
  Future<InternalAssessmentModel> unlockMarks({
    String? assessmentId,
    String? sectionId,
    String? subjectId,
    required String reason,
  }) async {
    try {
      final endpoint = assessmentId != null
          ? '/assessments/$assessmentId/unlock'
          : '/assessments/unlock';
      final response = await _apiClient.dio.post(
        endpoint,
        data: {
          if (assessmentId != null) 'assessmentId': assessmentId,
          'sectionId': sectionId,
          'subjectId': subjectId,
          'reason': reason,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        return InternalAssessmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Failed to parse unlocked assessment data.',
        userMessage: 'Unable to unlock assessment. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to unlock assessment');
    }
  }

  /// Controlled Mark Correction Workflow.
  Future<Map<String, dynamic>> correctMark({
    String? assessmentId,
    String? sectionId,
    String? subjectId,
    required String studentId,
    String? componentKey,
    required double newMark,
    String? status,
    required String reason,
  }) async {
    try {
      final endpoint = assessmentId != null
          ? '/assessments/$assessmentId/marks/correct'
          : '/assessments/marks/correct';
      final response = await _apiClient.dio.post(
        endpoint,
        data: {
          if (assessmentId != null) 'assessmentId': assessmentId,
          if (sectionId != null) 'sectionId': sectionId,
          if (subjectId != null) 'subjectId': subjectId,
          'studentId': studentId,
          if (componentKey != null) 'componentKey': componentKey,
          'newMark': newMark,
          if (status != null) 'status': status,
          'reason': reason,
        },
      );

      return response.data != null && response.data['data'] != null
          ? Map<String, dynamic>.from(response.data['data'] as Map)
          : {};
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to correct mark');
    }
  }

  /// Retrieves subject assessment summary.
  Future<SubjectAssessmentSummaryModel> getSubjectSummary({
    required String subjectId,
    required String semesterId,
    String? studentId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/assessments/subject-summary',
        queryParameters: {
          'subjectId': subjectId,
          'semesterId': semesterId,
          if (studentId != null) 'studentId': studentId,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        return SubjectAssessmentSummaryModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Failed to parse subject assessment summary.',
        userMessage: 'Unable to load subject summary. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load subject summary');
    }
  }

  /// Synchronizes lab experiment observation, record, and viva scores into internal assessment.
  Future<Map<String, dynamic>> syncLabScores({
    required String sectionId,
    required String subjectId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/assessments/sync-lab',
        data: {
          'sectionId': sectionId,
          'subjectId': subjectId,
        },
      );

      return response.data != null && response.data['data'] != null
          ? Map<String, dynamic>.from(response.data['data'] as Map)
          : {};
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to sync lab scores');
    }
  }

  /// Retrieves all published marks for the student.
  Future<List<StudentPublishedMarksItem>> getStudentMarks({String? semesterId}) async {
    try {
      final response = await _apiClient.dio.get(
        '/assessments/student/my-marks',
        queryParameters: {
          if (semesterId != null && semesterId.isNotEmpty) 'semesterId': semesterId,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        final items = response.data['data']['items'] as List? ?? [];
        return items
            .map((item) => StudentPublishedMarksItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load your internal marks');
    }
  }

  /// Lists assessments matching filters for the current context.
  Future<List<InternalAssessmentModel>> listAssessments({
    String? facultyAssignmentId,
    String? sectionId,
    String? subjectId,
    String? semesterId,
    String? academicYearId,
    String? status,
    String? assessmentType,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/assessments',
        queryParameters: {
          if (facultyAssignmentId != null) 'facultyAssignmentId': facultyAssignmentId,
          if (sectionId != null) 'sectionId': sectionId,
          if (subjectId != null) 'subjectId': subjectId,
          if (semesterId != null) 'semesterId': semesterId,
          if (academicYearId != null) 'academicYearId': academicYearId,
          if (status != null) 'status': status,
          if (assessmentType != null) 'assessmentType': assessmentType,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        final items = response.data['data'] as List? ?? [];
        return items
            .map((item) => InternalAssessmentModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to list assessments');
    }
  }

  /// Retrieves assessment details by ID.
  Future<Map<String, dynamic>> getAssessmentById(String assessmentId) async {
    try {
      final response = await _apiClient.dio.get('/assessments/$assessmentId');
      if (response.data != null && response.data['data'] != null) {
        return Map<String, dynamic>.from(response.data['data'] as Map);
      }
      throw const AcadexException(
        category: ErrorCategory.notFound,
        technicalMessage: 'Assessment not found',
        userMessage: 'The selected assessment could not be found.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load assessment details');
    }
  }

  /// Creates a new Assessment.
  Future<InternalAssessmentModel> createAssessment({
    required String title,
    required double maximumMarks,
    String? description,
    String? facultyAssignmentId,
    String? sectionId,
    String? subjectId,
    String? semesterId,
    String? courseId,
    String? departmentId,
    String? academicYearId,
    String? assessmentType,
    DateTime? assessmentDate,
    double? passMarks,
    double? weightage,
    List<AssessmentComponentModel>? components,
    String? sourceType,
    bool? isHistorical,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/assessments',
        data: {
          'title': title,
          'maximumMarks': maximumMarks,
          if (description != null) 'description': description,
          if (facultyAssignmentId != null) 'facultyAssignmentId': facultyAssignmentId,
          if (sectionId != null) 'sectionId': sectionId,
          if (subjectId != null) 'subjectId': subjectId,
          if (semesterId != null) 'semesterId': semesterId,
          if (courseId != null) 'courseId': courseId,
          if (departmentId != null) 'departmentId': departmentId,
          if (academicYearId != null) 'academicYearId': academicYearId,
          if (assessmentType != null) 'assessmentType': assessmentType,
          if (assessmentDate != null) 'assessmentDate': assessmentDate.toIso8601String(),
          if (passMarks != null) 'passMarks': passMarks,
          if (weightage != null) 'weightage': weightage,
          if (components != null) 'components': components.map((c) => c.toJson()).toList(),
          if (sourceType != null) 'sourceType': sourceType,
          if (isHistorical != null) 'isHistorical': isHistorical,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        return InternalAssessmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Failed to parse created assessment.',
        userMessage: 'Assessment created but failed to load response.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to create assessment');
    }
  }

  /// Schedules a date-specific assessment.
  Future<AssessmentScheduleModel> scheduleAssessment({
    required String assessmentId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? roomId,
    String? invigilatorFacultyId,
    String? instructions,
  }) async {
    try {
      final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _apiClient.dio.post(
        '/assessments/$assessmentId/schedule',
        data: {
          'date': dateStr,
          'startTime': startTime,
          'endTime': endTime,
          if (roomId != null) 'roomId': roomId,
          if (invigilatorFacultyId != null) 'invigilatorFacultyId': invigilatorFacultyId,
          if (instructions != null) 'instructions': instructions,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        return AssessmentScheduleModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Failed to parse scheduled assessment.',
        userMessage: 'Exam scheduled but failed to load confirmation.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to schedule exam');
    }
  }

  /// Retrieves date-specific exam timetables.
  Future<List<AssessmentScheduleModel>> getExamTimetable({
    String? sectionId,
    String? semesterId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/assessments/schedules/timetable',
        queryParameters: {
          if (sectionId != null) 'sectionId': sectionId,
          if (semesterId != null) 'semesterId': semesterId,
          if (dateFrom != null) 'dateFrom': dateFrom,
          if (dateTo != null) 'dateTo': dateTo,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        final items = response.data['data'] as List? ?? [];
        return items
            .map((item) => AssessmentScheduleModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load exam timetable');
    }
  }

  /// Retrieves the authoritative marks roster for an assessment.
  Future<MarksRosterResponseModel> getMarksRoster(String assessmentId) async {
    try {
      final response = await _apiClient.dio.get('/assessments/$assessmentId/roster');
      if (response.data != null && response.data['data'] != null) {
        return MarksRosterResponseModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Failed to parse marks roster.',
        userMessage: 'Unable to load marks roster. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load marks roster');
    }
  }

  /// Explicitly completes an assessment when the scheduled exam finishes.
  Future<InternalAssessmentModel> completeAssessment(String assessmentId) async {
    try {
      final response = await _apiClient.dio.post('/assessments/$assessmentId/complete');
      if (response.data != null && response.data['data'] != null) {
        return InternalAssessmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Failed to complete assessment.',
        userMessage: 'Unable to mark exam as completed. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to complete assessment');
    }
  }

  /// Submits marks and transitions assessment to SUBMITTED.
  Future<InternalAssessmentModel> submitMarks({
    required String assessmentId,
    List<StudentAssessmentEntryModel>? entries,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/assessments/$assessmentId/submit',
        data: {
          if (entries != null) 'entries': entries.map((e) => e.toJson()).toList(),
        },
      );
      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        final assessmentMap = data is Map && data['assessment'] != null ? data['assessment'] : data;
        return InternalAssessmentModel.fromJson(
          Map<String, dynamic>.from(assessmentMap as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Failed to submit marks.',
        userMessage: 'Unable to submit marks. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to submit marks');
    }
  }

  /// Locks an assessment and all underlying marks against direct edits.
  Future<InternalAssessmentModel> lockAssessment(String assessmentId) async {
    try {
      final response = await _apiClient.dio.post('/assessments/$assessmentId/lock');
      if (response.data != null && response.data['data'] != null) {
        return InternalAssessmentModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Failed to lock assessment.',
        userMessage: 'Unable to lock assessment. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to lock assessment');
    }
  }

  /// Retrieves summary submission and lock state of an assessment.
  Future<Map<String, dynamic>> getSubmissionState(String assessmentId) async {
    try {
      final response = await _apiClient.dio.get('/assessments/$assessmentId/submission-state');
      if (response.data != null && response.data['data'] != null) {
        return Map<String, dynamic>.from(response.data['data'] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load submission state');
    }
  }

  /// Requests a mark correction through the canonical Request architecture.
  Future<Map<String, dynamic>> requestCorrection({
    required String assessmentId,
    required String studentEnrollmentId,
    double? newMark,
    StudentMarkStatus? newStatus,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/assessments/$assessmentId/corrections/request',
        data: {
          'studentEnrollmentId': studentEnrollmentId,
          if (newMark != null) 'newMark': newMark,
          if (newStatus != null) 'newStatus': newStatus.value,
          'reason': reason,
        },
      );
      if (response.data != null && response.data['data'] != null) {
        return Map<String, dynamic>.from(response.data['data'] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to request mark correction');
    }
  }

  /// Responds to a mark correction request (Approve/Reject).
  Future<Map<String, dynamic>> respondCorrection({
    required String requestId,
    required String action,
    String? message,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/assessments/corrections/$requestId/respond',
        data: {
          'action': action,
          if (message != null) 'message': message,
        },
      );
      if (response.data != null && response.data['data'] != null) {
        return Map<String, dynamic>.from(response.data['data'] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to respond to mark correction');
    }
  }
}
