import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/repositories/ai_repository.dart';

class FirebaseAiRepository implements AiRepository {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Future<String> sendMessage({
    required String query,
    required Map<String, dynamic> context,
  }) async {
    try {
      final callable = _functions.httpsCallable('askAssistant');
      
      // We pass the context Map directly. Cloud Functions automatically
      // handles JSON serialization/deserialization.
      final result = await callable.call({
        'query': query,
        'context': context,
      });

      if (result.data != null && result.data['answer'] != null) {
        return result.data['answer'] as String;
      }
      return "No answer received from AI Service.";
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        throw Exception('You must be logged in to use the AI assistant.');
      } else if (e.code == 'permission-denied') {
        throw Exception('Access denied. Missing context.');
      }
      throw Exception(e.message ?? 'Acadex AI is temporarily unavailable.');
    } catch (e) {
      throw Exception('Acadex AI is temporarily unavailable.');
    }
  }
}
