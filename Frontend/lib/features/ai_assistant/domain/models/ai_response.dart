class AiResponse {
  final String answer;
  final String? model;
  final Map<String, dynamic>? proposal;

  const AiResponse({required this.answer, this.model, this.proposal});

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    return AiResponse(
      answer: json['answer'] as String? ?? '',
      model: json['model'] as String?,
      proposal: json['proposal'] as Map<String, dynamic>?,
    );
  }
}
