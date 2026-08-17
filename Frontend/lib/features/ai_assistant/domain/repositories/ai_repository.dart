abstract class AiRepository {
  Future<String> sendMessage({
    required String query,
    required Map<String, dynamic> context,
  });
}
