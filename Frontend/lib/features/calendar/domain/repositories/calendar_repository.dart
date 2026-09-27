import '../models/calendar_event_model.dart';

abstract class CalendarRepository {
  Future<List<CalendarEventModel>> getCalendar({
    String? startDate,
    String? endDate,
    String? eventType,
  });

  Future<CalendarEventModel> getEventById(String id);

  Future<CalendarEventModel> createEvent(Map<String, dynamic> data);

  Future<CalendarEventModel> updateEvent(String id, Map<String, dynamic> data);

  Future<CalendarEventModel> cancelEvent(String id, {String? reason});

  Future<CalendarEventModel> publishEvent(String id);
}
