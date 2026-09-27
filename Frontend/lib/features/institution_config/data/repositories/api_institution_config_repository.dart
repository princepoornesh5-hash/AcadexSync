import 'package:dio/dio.dart';
import '../../../../core/errors/acadex_error.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/institution_config_models.dart';
import '../../domain/repositories/institution_config_repository.dart';

class ApiInstitutionConfigRepository implements InstitutionConfigRepository {
  final ApiClient _apiClient;

  ApiInstitutionConfigRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? apiClientInstance;

  static ApiClient get apiClientInstance => apiClient;

  @override
  Future<InstitutionConfigModel> getEffectiveConfiguration() async {
    try {
      final response = await _apiClient.dio.get('/institution-config');
      if (response.data != null && response.data['data'] != null) {
        return InstitutionConfigModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      return const InstitutionConfigModel(collegeId: '');
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load institution configuration');
    }
  }

  @override
  Future<InstitutionConfigModel> updateConfiguration({
    InstitutionType? institutionType,
    AcademicStructureConfig? academicStructure,
    TerminologyConfig? terminology,
    AttendanceAlertsConfig? attendanceAlerts,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (institutionType != null) 'institutionType': institutionType.value,
        if (academicStructure != null) 'academicStructure': academicStructure.toJson(),
        if (terminology != null) 'terminology': terminology.toJson(),
        if (attendanceAlerts != null) 'attendanceAlerts': attendanceAlerts.toJson(),
      };

      final response = await _apiClient.dio.put(
        '/institution-config',
        data: payload,
      );

      if (response.data != null && response.data['data'] != null) {
        return InstitutionConfigModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Failed to update institution configuration',
        userMessage: 'Failed to update institution configuration. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to update institution configuration');
    }
  }

  @override
  Future<List<InstitutionPresetModel>> getPresets() async {
    try {
      final response = await _apiClient.dio.get('/institution-config/presets');
      if (response.data != null && response.data['data'] != null) {
        final list = response.data['data'] as List;
        return list
            .map((item) => InstitutionPresetModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load institution presets');
    }
  }
}
