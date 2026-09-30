import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/calendar_event_model.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../data/repositories/api_calendar_repository.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return ApiCalendarRepository();
});

/// Currently selected day in the calendar grid (default: today)
final selectedCalendarDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Current viewed month in the calendar (default: 1st of current month)
final currentMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// Optional event filter: null ('All'), 'HOLIDAY', 'EXAM', 'DEADLINE', 'EVENT'
final calendarFilterProvider = StateProvider<String?>((ref) => null);

class CalendarEventsNotifier extends StateNotifier<AsyncValue<List<CalendarEventModel>>> {
  final CalendarRepository _repository;
  DateTime? _lastLoadedMonth;

  CalendarEventsNotifier(this._repository) : super(const AsyncValue.loading()) {
    final now = DateTime.now();
    loadEvents(DateTime(now.year, now.month, 1));
  }

  Future<void> loadEvents(DateTime month, {bool force = false}) async {
    if (!force && _lastLoadedMonth != null &&
        _lastLoadedMonth!.year == month.year &&
        _lastLoadedMonth!.month == month.month &&
        state.hasValue) {
      return;
    }

    _lastLoadedMonth = month;
    state = const AsyncValue.loading();

    try {
      // Calculate start and end date covering viewed month plus padding
      final startDate = DateTime(month.year, month.month - 1, 20);
      final endDate = DateTime(month.year, month.month + 1, 15);

      final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final events = await _repository.getCalendar(startDate: startStr, endDate: endStr);
      state = AsyncValue.data(events);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<CalendarEventModel> createEvent(Map<String, dynamic> data) async {
    final newEvent = await _repository.createEvent(data);
    if (_lastLoadedMonth != null) {
      await loadEvents(_lastLoadedMonth!, force: true);
    }
    return newEvent;
  }

  Future<CalendarEventModel> updateEvent(String id, Map<String, dynamic> data) async {
    final updated = await _repository.updateEvent(id, data);
    if (_lastLoadedMonth != null) {
      await loadEvents(_lastLoadedMonth!, force: true);
    }
    return updated;
  }

  Future<CalendarEventModel> cancelEvent(String id, {String? reason}) async {
    final cancelled = await _repository.cancelEvent(id, reason: reason);
    if (_lastLoadedMonth != null) {
      await loadEvents(_lastLoadedMonth!, force: true);
    }
    return cancelled;
  }

  Future<CalendarEventModel> publishEvent(String id) async {
    final published = await _repository.publishEvent(id);
    if (_lastLoadedMonth != null) {
      await loadEvents(_lastLoadedMonth!, force: true);
    }
    return published;
  }
}

final calendarEventsProvider =
    StateNotifierProvider<CalendarEventsNotifier, AsyncValue<List<CalendarEventModel>>>((ref) {
  final repo = ref.watch(calendarRepositoryProvider);
  return CalendarEventsNotifier(repo);
});

/// Events matching the selected date
bool _matchesFilter(CalendarEventModel e, String? filter) {
  if (filter == null || filter.isEmpty) return true;
  switch (filter.toUpperCase()) {
    case 'HOLIDAY':
      return e.eventType == CalendarEventType.holiday ||
          e.eventType == CalendarEventType.publicHoliday ||
          e.eventType == CalendarEventType.institutionHoliday;
    case 'EXAM':
      return e.eventType == CalendarEventType.exam ||
          e.eventType == CalendarEventType.examination;
    case 'ASSESSMENT':
      return e.eventType == CalendarEventType.internalAssessment ||
          e.eventType == CalendarEventType.classTest ||
          e.sourceType == CalendarSourceType.assessment;
    case 'DEADLINE':
      return e.eventType == CalendarEventType.deadline ||
          e.eventType == CalendarEventType.assignmentDeadline ||
          e.sourceType == CalendarSourceType.assignment;
    case 'CLASS':
    case 'TIMETABLE_CLASS':
      return e.eventType == CalendarEventType.timetableClass ||
          e.sourceType == CalendarSourceType.timetable;
    case 'PRACTICAL':
      return e.eventType == CalendarEventType.practical ||
          e.eventType == CalendarEventType.labViva ||
          e.sourceType == CalendarSourceType.practical;
    case 'RESULT':
    case 'RESULT_PUBLICATION':
      return e.eventType == CalendarEventType.resultPublication ||
          e.sourceType == CalendarSourceType.academicResult;
    case 'EVENT':
      return e.eventType == CalendarEventType.event ||
          e.eventType == CalendarEventType.seminar ||
          e.eventType == CalendarEventType.workshop ||
          e.eventType == CalendarEventType.collegeEvent ||
          e.eventType == CalendarEventType.academicEvent;
    default:
      return true;
  }
}

/// Events matching the selected date
final selectedDayEventsProvider = Provider<List<CalendarEventModel>>((ref) {
  final eventsAsync = ref.watch(calendarEventsProvider);
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final filter = ref.watch(calendarFilterProvider);

  return eventsAsync.maybeWhen(
    data: (events) {
      final dateStr =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

      return events.where((e) {
        if (!_matchesFilter(e, filter)) return false;
        // Check if selectedDate is within [startDate, endDate]
        return dateStr.compareTo(e.startDate) >= 0 && dateStr.compareTo(e.endDate) <= 0;
      }).toList();
    },
    orElse: () => [],
  );
});

/// Upcoming events starting from today onwards
final upcomingEventsProvider = Provider<List<CalendarEventModel>>((ref) {
  final eventsAsync = ref.watch(calendarEventsProvider);
  final filter = ref.watch(calendarFilterProvider);
  final now = DateTime.now();
  final todayStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  return eventsAsync.maybeWhen(
    data: (events) {
      return events.where((e) {
        if (!_matchesFilter(e, filter)) return false;
        return e.endDate.compareTo(todayStr) >= 0;
      }).toList();
    },
    orElse: () => [],
  );
});

/// Academic Calendars list provider
final academicCalendarsProvider =
    FutureProvider.autoDispose<List<AcademicCalendarModel>>((ref) async {
  final repo = ref.watch(calendarRepositoryProvider);
  return repo.getAcademicCalendars();
});

/// Working day resolution provider for a given date string (YYYY-MM-DD)
final workingDayResolutionProvider =
    FutureProvider.autoDispose.family<WorkingDayResolution, String>((ref, date) async {
  final repo = ref.watch(calendarRepositoryProvider);
  return repo.resolveWorkingDay(date);
});
