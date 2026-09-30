import 'package:dio/dio.dart';
import '../../../../core/errors/acadex_error.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/practical_models.dart';

abstract class PracticalsRepository {
  Future<List<PracticalSessionModel>> getSessions({
    String? facultyAssignmentId,
    String? subjectId,
    String? sectionId,
    String? status,
  });

  Future<({PracticalSessionModel session, List<PracticalParticipationModel> participations})> getSessionById(
    String sessionId,
  );

  Future<PracticalSessionModel> createSession(Map<String, dynamic> payload);

  Future<PracticalSessionModel> openSession(String sessionId);

  Future<PracticalSessionModel> completeSession(String sessionId);

  Future<PracticalSessionModel> cancelSession(String sessionId, {String? reason});

  Future<PracticalParticipationModel> updateParticipation({
    required String sessionId,
    required String studentId,
    required PracticalParticipationStatus status,
    String? notes,
  });

  Future<PracticalSessionModel> bulkUpdateParticipation({
    required String sessionId,
    required List<Map<String, dynamic>> updates,
  });

  Future<List<StudentPracticalHistoryModel>> getStudentHistory({
    String? studentId,
    String? subjectId,
  });
}

class ApiPracticalsRepository implements PracticalsRepository {
  final ApiClient _apiClient;

  ApiPracticalsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? apiClientInstance;

  static ApiClient get apiClientInstance => apiClient;

  @override
  Future<List<PracticalSessionModel>> getSessions({
    String? facultyAssignmentId,
    String? subjectId,
    String? sectionId,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (facultyAssignmentId != null && facultyAssignmentId.isNotEmpty)
          'facultyAssignmentId': facultyAssignmentId,
        if (subjectId != null && subjectId.isNotEmpty) 'subjectId': subjectId,
        if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final response = await _apiClient.dio.get(
        '/practicals/sessions',
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['data'] != null) {
        final list = response.data['data'] as List;
        return list
            .map((item) => PracticalSessionModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load practical sessions');
    }
  }

  @override
  Future<({PracticalSessionModel session, List<PracticalParticipationModel> participations})> getSessionById(
    String sessionId,
  ) async {
    try {
      final response = await _apiClient.dio.get('/practicals/sessions/$sessionId');
      final data = response.data['data'] as Map<String, dynamic>;

      final session = PracticalSessionModel.fromJson(Map<String, dynamic>.from(data['session'] as Map));
      final rawParticipations = (data['participations'] as List? ?? []);
      final participations = rawParticipations
          .map((item) => PracticalParticipationModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      return (session: session, participations: participations);
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load practical session details');
    }
  }

  @override
  Future<PracticalSessionModel> createSession(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post(
        '/practicals/sessions',
        data: payload,
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return PracticalSessionModel.fromJson(data);
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to schedule practical session');
    }
  }

  @override
  Future<PracticalSessionModel> openSession(String sessionId) async {
    try {
      final response = await _apiClient.dio.post('/practicals/sessions/$sessionId/open');
      final data = response.data['data'] as Map<String, dynamic>;
      return PracticalSessionModel.fromJson(data);
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to open practical session');
    }
  }

  @override
  Future<PracticalSessionModel> completeSession(String sessionId) async {
    try {
      final response = await _apiClient.dio.post('/practicals/sessions/$sessionId/complete');
      final data = response.data['data'] as Map<String, dynamic>;
      return PracticalSessionModel.fromJson(data);
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to complete practical session');
    }
  }

  @override
  Future<PracticalSessionModel> cancelSession(String sessionId, {String? reason}) async {
    try {
      final response = await _apiClient.dio.post(
        '/practicals/sessions/$sessionId/cancel',
        data: reason != null ? {'reason': reason} : {},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return PracticalSessionModel.fromJson(data);
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to cancel practical session');
    }
  }

  @override
  Future<PracticalParticipationModel> updateParticipation({
    required String sessionId,
    required String studentId,
    required PracticalParticipationStatus status,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '/practicals/sessions/$sessionId/students/$studentId',
        data: {
          'status': status.backendValue,
          if (notes != null) 'notes': notes,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return PracticalParticipationModel.fromJson(data);
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to update student participation');
    }
  }

  @override
  Future<PracticalSessionModel> bulkUpdateParticipation({
    required String sessionId,
    required List<Map<String, dynamic>> updates,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/practicals/sessions/$sessionId/participation/bulk',
        data: {'updates': updates},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return PracticalSessionModel.fromJson(Map<String, dynamic>.from(data['session'] as Map));
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to bulk update student participation');
    }
  }

  @override
  Future<List<StudentPracticalHistoryModel>> getStudentHistory({
    String? studentId,
    String? subjectId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (studentId != null && studentId.isNotEmpty) 'studentId': studentId,
        if (subjectId != null && subjectId.isNotEmpty) 'subjectId': subjectId,
      };

      final response = await _apiClient.dio.get(
        '/practicals/history',
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['data'] != null) {
        final list = response.data['data'] as List;
        return list
            .map((item) => StudentPracticalHistoryModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load student practical history');
    }
  }
}
