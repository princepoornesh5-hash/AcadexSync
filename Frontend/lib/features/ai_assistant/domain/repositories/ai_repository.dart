import '../models/ai_response.dart';
import '../models/ai_stream_event.dart';

abstract class AiRepository {
  Future<String> sendMessage({
    required String query,
    required Map<String, dynamic> context,
  });

  Future<AiResponse> sendChatMessage({
    required String query,
    required Map<String, dynamic> context,
    List<Map<String, String>>? history,
  });

  Stream<AiStreamEvent> streamChatMessage({
    required String query,
    required Map<String, dynamic> context,
    List<Map<String, String>>? history,
  });

  Future<Map<String, dynamic>> confirmAction({
    required String actionId,
    String? idempotencyKey,
  });

  Future<Map<String, dynamic>> cancelAction({
    required String actionId,
  });

  Future<Map<String, dynamic>> getActionStatus({
    required String actionId,
  });
}
