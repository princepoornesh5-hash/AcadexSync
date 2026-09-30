import 'package:dio/dio.dart';
import '../../../../core/errors/acadex_error.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/internal_assessment_models.dart';

class ApiAssessmentRepository {
  final ApiClient _apiClient;

  ApiAssessmentRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? apiClientInstance;

  static ApiClient get apiClientInstance => apiClient;

  /// Retrieves or initializes assessment context for a subject and section.
  Future<AssessmentContextModel> getAssessmentContext({
    required String sectionId,
    required String subjectId,
    String? academicYearId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/assessments/context',
        queryParameters: {
          'sectionId': sectionId,
          'subjectId': subjectId,
          if (academicYearId != null) 'academicYearId': academicYearId,
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
    required String sectionId,
    required String subjectId,
    required List<StudentAssessmentEntryModel> entries,
    String? title,
    String? academicYearId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/assessments/draft',
        data: {
          if (assessmentId != null) 'assessmentId': assessmentId,
          'sectionId': sectionId,
          'subjectId': subjectId,
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
    required String sectionId,
    required String subjectId,
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
          'sectionId': sectionId,
          'subjectId': subjectId,
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
    required String sectionId,
    required String subjectId,
  }) async {
    try {
      final endpoint = assessmentId != null
          ? '/assessments/$assessmentId/publish'
          : '/assessments/publish';
      final response = await _apiClient.dio.post(
        endpoint,
        data: {
          if (assessmentId != null) 'assessmentId': assessmentId,
          'sectionId': sectionId,
          'subjectId': subjectId,
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
    required String sectionId,
    required String subjectId,
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
}
