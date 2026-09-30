import 'package:dio/dio.dart';
import '../../../../core/errors/acadex_error.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/calendar_event_model.dart';
import '../../domain/repositories/calendar_repository.dart';

class ApiCalendarRepository implements CalendarRepository {
  final ApiClient _apiClient;

  ApiCalendarRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? apiClientInstance;

  static ApiClient get apiClientInstance => apiClient;

  @override
  Future<List<CalendarEventModel>> getCalendar({
    String? startDate,
    String? endDate,
    String? eventType,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (eventType != null) 'eventType': eventType,
      };

      final response = await _apiClient.dio.get(
        '/calendar',
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['data'] is List) {
        final list = response.data['data'] as List;
        return list
            .map((item) => CalendarEventModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load calendar events');
    }
  }

  @override
  Future<CalendarEventModel> getEventById(String id) async {
    try {
      final response = await _apiClient.dio.get('/calendar/$id');
      if (response.data != null && response.data['data'] != null) {
        return CalendarEventModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.notFound,
        technicalMessage: 'Calendar event not found',
        userMessage: 'The requested calendar event could not be found.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load calendar event detail');
    }
  }

  @override
  Future<CalendarEventModel> createEvent(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/calendar', data: data);
      if (response.data != null && response.data['data'] != null) {
        return CalendarEventModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Failed to create calendar event',
        userMessage: 'Failed to create event. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to create calendar event');
    }
  }

  @override
  Future<CalendarEventModel> updateEvent(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/calendar/$id', data: data);
      if (response.data != null && response.data['data'] != null) {
        return CalendarEventModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Failed to update calendar event',
        userMessage: 'Failed to update event. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to update calendar event');
    }
  }

  @override
  Future<CalendarEventModel> cancelEvent(String id, {String? reason}) async {
    try {
      final response = await _apiClient.dio.post(
        '/calendar/$id/cancel',
        data: reason != null ? {'reason': reason} : {},
      );
      if (response.data != null && response.data['data'] != null) {
        return CalendarEventModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Failed to cancel calendar event',
        userMessage: 'Failed to cancel event. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to cancel calendar event');
    }
  }

  @override
  Future<CalendarEventModel> publishEvent(String id) async {
    try {
      final response = await _apiClient.dio.post('/calendar/$id/publish');
      if (response.data != null && response.data['data'] != null) {
        return CalendarEventModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Failed to publish calendar event',
        userMessage: 'Failed to publish event. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to publish calendar event');
    }
  }

  @override
  Future<List<AcademicCalendarModel>> getAcademicCalendars({
    String? academicYearId,
    String? semesterId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (academicYearId != null) 'academicYearId': academicYearId,
        if (semesterId != null) 'semesterId': semesterId,
      };

      final response = await _apiClient.dio.get(
        '/academic-calendars',
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['data'] is List) {
        final list = response.data['data'] as List;
        return list
            .map((item) => AcademicCalendarModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load academic calendars');
    }
  }

  @override
  Future<AcademicCalendarModel> createAcademicCalendar(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/academic-calendars', data: data);
      if (response.data != null && response.data['data'] != null) {
        return AcademicCalendarModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Failed to create academic calendar',
        userMessage: 'Failed to create calendar. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to create academic calendar');
    }
  }

  @override
  Future<WorkingDayResolution> resolveWorkingDay(
    String date, {
    String? semesterId,
    String? departmentId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'date': date,
        if (semesterId != null) 'semesterId': semesterId,
        if (departmentId != null) 'departmentId': departmentId,
      };

      final response = await _apiClient.dio.get(
        '/academic-calendars/resolve-working-day',
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['data'] != null) {
        return WorkingDayResolution.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      return WorkingDayResolution(date: date, isWorkingDay: true, isHoliday: false);
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to resolve working day');
    }
  }

  @override
  Future<void> declareHoliday(Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.post('/academic-calendars/declare-holiday', data: data);
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to declare holiday');
    }
  }
}
