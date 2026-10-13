import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/workspace_model.dart';

class WorkspaceRepository {
  final ApiClient _client;

  WorkspaceRepository([ApiClient? client]) : _client = client ?? apiClient;

  Future<List<WorkspaceMembershipModel>> getMyMemberships() async {
    try {
      final response = await _client.dio.get('/workspaces/my-memberships');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      final membershipsJson = (data['memberships'] as List<dynamic>?) ?? [];

      return membershipsJson
          .map((m) => WorkspaceMembershipModel.fromJson(m as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Failed to load workspaces';
      throw Exception(errorMsg);
    }
  }

  Future<SwitchWorkspaceResult> switchWorkspace(String targetCollegeId) async {
    try {
      final response = await _client.dio.post(
        '/workspaces/switch',
        data: {'targetCollegeId': targetCollegeId.trim()},
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;

      return SwitchWorkspaceResult.fromJson(data);
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Failed to switch workspace';
      throw Exception(errorMsg);
    }
  }
}
