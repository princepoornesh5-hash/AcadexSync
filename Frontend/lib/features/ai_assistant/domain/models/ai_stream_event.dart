enum AiStreamStatus {
  idle,
  connecting,
  waitingForFirstChunk,
  streaming,
  completed,
  failed,
  cancelled,
}

sealed class AiStreamEvent {
  const AiStreamEvent();
}

class AiStreamStartEvent extends AiStreamEvent {
  final String model;
  final String correlationId;

  const AiStreamStartEvent({
    required this.model,
    required this.correlationId,
  });
}

class AiStreamDeltaEvent extends AiStreamEvent {
  final String text;

  const AiStreamDeltaEvent({required this.text});
}

class AiStreamProposalEvent extends AiStreamEvent {
  final Map<String, dynamic> proposal;

  const AiStreamProposalEvent({required this.proposal});
}

class AiStreamDoneEvent extends AiStreamEvent {
  final String answer;
  final String? model;
  final Map<String, dynamic>? proposal;

  const AiStreamDoneEvent({
    required this.answer,
    this.model,
    this.proposal,
  });
}

class AiStreamErrorEvent extends AiStreamEvent {
  final String code;
  final String message;
  final int? httpStatus;
  final int? retryAfterSeconds;
  final String? category;
  final String? correlationId;

  const AiStreamErrorEvent({
    required this.code,
    required this.message,
    this.httpStatus,
    this.retryAfterSeconds,
    this.category,
    this.correlationId,
  });
}
