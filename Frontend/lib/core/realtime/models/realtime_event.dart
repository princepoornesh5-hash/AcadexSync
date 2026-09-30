enum RealtimeConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class RealtimeEvent {
  final String eventId;
  final int eventVersion;
  final String eventType;
  final String aggregateType;
  final String aggregateId;
  final String action;
  final DateTime occurredAt;
  final String collegeId;
  final Map<String, dynamic> scope;
  final Map<String, dynamic> payload;

  const RealtimeEvent({
    required this.eventId,
    required this.eventVersion,
    required this.eventType,
    required this.aggregateType,
    required this.aggregateId,
    required this.action,
    required this.occurredAt,
    required this.collegeId,
    required this.scope,
    required this.payload,
  });

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return RealtimeEvent(
      eventId: json['eventId'] as String? ?? '',
      eventVersion: (json['eventVersion'] as num?)?.toInt() ?? 1,
      eventType: json['eventType'] as String? ?? '',
      aggregateType: json['aggregateType'] as String? ?? '',
      aggregateId: json['aggregateId'] as String? ?? '',
      action: json['action'] as String? ?? '',
      occurredAt: parseDate(json['occurredAt']),
      collegeId: json['collegeId'] as String? ?? '',
      scope: (json['scope'] as Map<String, dynamic>?) ?? {},
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventVersion': eventVersion,
      'eventType': eventType,
      'aggregateType': aggregateType,
      'aggregateId': aggregateId,
      'action': action,
      'occurredAt': occurredAt.toIso8601String(),
      'collegeId': collegeId,
      'scope': scope,
      'payload': payload,
    };
  }

  @override
  String toString() =>
      'RealtimeEvent($eventType, id: $eventId, aggregate: $aggregateType:$aggregateId, action: $action)';
}
