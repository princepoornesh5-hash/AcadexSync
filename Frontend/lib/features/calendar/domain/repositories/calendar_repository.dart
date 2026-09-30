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

  Future<List<AcademicCalendarModel>> getAcademicCalendars({
    String? academicYearId,
    String? semesterId,
  });

  Future<AcademicCalendarModel> createAcademicCalendar(Map<String, dynamic> data);

  Future<WorkingDayResolution> resolveWorkingDay(
    String date, {
    String? semesterId,
    String? departmentId,
  });

  Future<void> declareHoliday(Map<String, dynamic> data);
}
