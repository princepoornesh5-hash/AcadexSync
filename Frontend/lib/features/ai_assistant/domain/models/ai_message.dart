import 'package:uuid/uuid.dart';

class AiMessage {
  final String id;
  final String text;
  final bool isAi;
  final DateTime timestamp;
  final Map<String, dynamic>? proposal;
  final String? actionStatus; // 'PENDING', 'CONFIRMING', 'EXECUTED', 'CANCELLED', 'FAILED', 'EXPIRED', 'UNCERTAIN', 'RECONCILING'
  final String? executionResultSummary;
  final bool isStreaming;
  final bool isInterrupted;
  final String? correlationId;

  AiMessage({
    String? id,
    required this.text,
    required this.isAi,
    DateTime? timestamp,
    this.proposal,
    this.actionStatus,
    this.executionResultSummary,
    this.isStreaming = false,
    this.isInterrupted = false,
    this.correlationId,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  AiMessage copyWith({
    String? id,
    String? text,
    bool? isAi,
    DateTime? timestamp,
    Map<String, dynamic>? proposal,
    String? actionStatus,
    String? executionResultSummary,
    bool? isStreaming,
    bool? isInterrupted,
    String? correlationId,
  }) {
    return AiMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isAi: isAi ?? this.isAi,
      timestamp: timestamp ?? this.timestamp,
      proposal: proposal ?? this.proposal,
      actionStatus: actionStatus ?? this.actionStatus,
      executionResultSummary: executionResultSummary ?? this.executionResultSummary,
      isStreaming: isStreaming ?? this.isStreaming,
      isInterrupted: isInterrupted ?? this.isInterrupted,
      correlationId: correlationId ?? this.correlationId,
    );
  }
}
