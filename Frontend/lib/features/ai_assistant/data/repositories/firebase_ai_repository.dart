import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/models/ai_response.dart';

class FirebaseAiRepository implements AiRepository {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Future<String> sendMessage({
    required String query,
    required Map<String, dynamic> context,
  }) async {
    final res = await sendChatMessage(query: query, context: context);
    return res.answer;
  }

  @override
  Future<AiResponse> sendChatMessage({
    required String query,
    required Map<String, dynamic> context,
    List<Map<String, String>>? history,
  }) async {
    try {
      final callable = _functions.httpsCallable('askAssistant');
      
      final result = await callable.call({
        'query': query,
        'context': context,
      });

      if (result.data != null && result.data is Map) {
        final data = result.data as Map;
        final answer = data['answer'] as String? ?? 'No answer received from AI Service.';
        final proposal = data['proposal'] as Map<String, dynamic>?;
        return AiResponse(answer: answer, proposal: proposal);
      }
      return const AiResponse(answer: 'No answer received from AI Service.');
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        throw Exception('You must be logged in to use the AI assistant.');
      } else if (e.code == 'permission-denied') {
        throw Exception('Access denied. Missing context.');
      }
      throw Exception(e.message ?? 'Acadex AI is temporarily unavailable.');
    } catch (_) {
      throw Exception('Acadex AI is temporarily unavailable.');
    }
  }

  @override
  Future<Map<String, dynamic>> confirmAction({
    required String actionId,
    String? idempotencyKey,
  }) async {
    try {
      final callable = _functions.httpsCallable('confirmAiAction');
      final result = await callable.call({
        'actionId': actionId,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      });
      if (result.data != null && result.data is Map) {
        return Map<String, dynamic>.from(result.data as Map);
      }
      return {'status': 'EXECUTED'};
    } catch (e) {
      throw Exception('Failed to confirm action via Firebase functions.');
    }
  }

  @override
  Future<Map<String, dynamic>> cancelAction({
    required String actionId,
  }) async {
    try {
      final callable = _functions.httpsCallable('cancelAiAction');
      final result = await callable.call({
        'actionId': actionId,
      });
      if (result.data != null && result.data is Map) {
        return Map<String, dynamic>.from(result.data as Map);
      }
      return {'status': 'CANCELLED'};
    } catch (e) {
      throw Exception('Failed to cancel action via Firebase functions.');
    }
  }

  @override
  Future<Map<String, dynamic>> getActionStatus({
    required String actionId,
  }) async {
    try {
      final callable = _functions.httpsCallable('getAiActionStatus');
      final result = await callable.call({
        'actionId': actionId,
      });
      if (result.data != null && result.data is Map) {
        return Map<String, dynamic>.from(result.data as Map);
      }
      return {'actionId': actionId, 'status': 'UNKNOWN'};
    } catch (e) {
      throw Exception('Failed to check action status via Firebase functions.');
    }
  }
}
