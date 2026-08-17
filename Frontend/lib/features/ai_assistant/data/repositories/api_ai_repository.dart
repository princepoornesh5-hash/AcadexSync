import '../../domain/repositories/ai_repository.dart';
import '../../../../core/network/api_client.dart';

class ApiAiRepository implements AiRepository {
  @override
  Future<String> sendMessage({
    required String query,
    required Map<String, dynamic> context,
  }) async {
    try {
      final response = await apiClient.aiDio.post(
        '/chat',
        data: {
          'query': query,
          'context': context,
        },
      );
      
      return response.data['answer'] ?? "No answer received from AI Service.";
    } catch (e) {
      throw Exception('Acadex AI is temporarily unavailable.');
    }
  }
}
