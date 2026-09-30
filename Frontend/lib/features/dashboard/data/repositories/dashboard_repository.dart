import '../../../../core/network/api_client.dart';
import '../../domain/models/home_dashboard_models.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? apiClientInstance;

  static ApiClient get apiClientInstance => apiClient;

  /// Fetches canonical role-aware operational home summary DTO
  Future<HomeDashboardModel> getHomeDashboard({String? date}) async {
    final response = await _apiClient.dio.get(
      '/dashboard/home',
      queryParameters: date != null ? {'date': date} : null,
    );

    if (response.data != null && response.data['data'] != null) {
      return HomeDashboardModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    }

    throw Exception('Invalid response received from dashboard service');
  }
}
