import 'package:uuid/uuid.dart';

class AiMessage {
  final String id;
  final String text;
  final bool isAi;
  final DateTime timestamp;

  AiMessage({
    String? id,
    required this.text,
    required this.isAi,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();
}
