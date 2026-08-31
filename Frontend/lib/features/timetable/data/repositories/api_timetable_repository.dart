import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/timetable_models.dart';
import 'timetable_repository.dart';

class ApiTimetableRepository implements TimetableRepository {
  final ApiClient _client;

  final Map<String, List<TimetablePeriodModel>> _periods = {};
  final Map<String, List<TimetableBreakModel>> _breaks = {};
  final Map<String, List<TimetableGridEntryModel>> _gridEntries = {};

  final _periodsStreamController = StreamController<Map<String, List<TimetablePeriodModel>>>.broadcast();
  final _breaksStreamController = StreamController<Map<String, List<TimetableBreakModel>>>.broadcast();
  final _gridEntriesStreamController = StreamController<Map<String, List<TimetableGridEntryModel>>>.broadcast();

  ApiTimetableRepository([ApiClient? client]) : _client = client ?? apiClient;

  Exception _extractError(DioException e, String fallback) {
    final message = e.response?.data?['error']?['message'] ??
        e.response?.data?['message'] ??
        e.message ??
        fallback;
    return Exception(message);
  }

  // =========================================================================
  // 1. SPECIALIZED TIMETABLE RETRIEVALS
  // =========================================================================

  @override
  Stream<List<TimetableModel>> watchTimetable({
    required AppRole role,
    required String userId,
    String? collegeId,
    String? departmentId,
    String? sectionId,
  }) async* {
    final list = await getTimetable(
      collegeId: collegeId ?? '',
      departmentId: departmentId,
      sectionId: sectionId,
      facultyId: role == AppRole.faculty ? userId : null,
    );
    yield list;
  }

  @override
  Future<List<TimetableModel>> getTimetable({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? facultyId,
  }) async {
    try {
      if (facultyId != null && facultyId.isNotEmpty) {
        final response = await _client.dio.get('/timetables/faculty/$facultyId');
        final body = response.data;
        final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
        final list = data is List ? data : (data is Map && data['entries'] is List ? data['entries'] as List : null);
        if (list != null) {
          return _parseEntries(list, collegeId, departmentId, sectionId, facultyId);
        }
      } else if (sectionId != null && sectionId.isNotEmpty) {
        final response = await _client.dio.get('/timetables/sections/$sectionId');
        final body = response.data;
        final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
        final list = data is List ? data : (data is Map && data['entries'] is List ? data['entries'] as List : null);
        if (list != null) {
          return _parseEntries(list, collegeId, departmentId, sectionId, null);
        }
      } else {
        final response = await _client.dio.get('/timetables/students/me');
        final body = response.data;
        final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
        final list = data is List ? data : (data is Map && data['entries'] is List ? data['entries'] as List : null);
        if (list != null) {
          return _parseEntries(list, collegeId, departmentId, sectionId, null);
        }
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _extractError(e, 'Failed to fetch timetable schedule');
    } catch (e) {
      throw Exception('Error loading timetable: $e');
    }
  }

  List<TimetableModel> _parseEntries(
    List<dynamic> list,
    String collegeId,
    String? departmentId,
    String? sectionId,
    String? facultyId,
  ) {
    return list.map((item) {
      final m = item as Map<String, dynamic>;
      final dayStr = (m['dayOfWeek'] ?? m['day'] ?? 'monday').toString().toLowerCase();
      final day = TimetableDay.values.firstWhere(
        (d) => d.name.toLowerCase() == dayStr,
        orElse: () => TimetableDay.monday,
      );

      final sessionTypeStr = (m['sessionType'] ?? 'lecture').toString().toLowerCase();
      final sessionType = TimetableSessionType.values.firstWhere(
        (s) => s.name.toLowerCase() == sessionTypeStr,
        orElse: () => TimetableSessionType.lecture,
      );

      return TimetableModel(
        id: (m['id'] ?? m['_id'] ?? '').toString(),
        collegeId: (m['collegeId'] ?? collegeId).toString(),
        departmentId: (m['departmentId'] ?? departmentId ?? '').toString(),
        courseId: (m['courseId'] ?? '').toString(),
        academicYearId: (m['academicYearId'] ?? '').toString(),
        semesterId: (m['semesterId'] ?? '').toString(),
        sectionId: (m['sectionId'] ?? sectionId ?? '').toString(),
        subjectId: (m['subjectId'] ?? m['subject']?['_id'] ?? '').toString(),
        facultyId: (m['facultyId'] ?? m['faculty']?['_id'] ?? facultyId ?? '').toString(),
        dayOfWeek: day,
        startTime: (m['startTime'] ?? '09:00').toString(),
        endTime: (m['endTime'] ?? '10:00').toString(),
        roomNumber: (m['roomNumber'] ?? m['room'] ?? 'Room 101').toString(),
        building: m['building']?.toString(),
        sessionType: sessionType,
        createdAt: m['createdAt'] != null ? DateTime.tryParse(m['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
        updatedAt: m['updatedAt'] != null ? DateTime.tryParse(m['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
      );
    }).toList();
  }

  // =========================================================================
  // 2. TIMETABLE CONTAINER CRUD & LIFECYCLE
  // =========================================================================

  @override
  Future<void> createTimetableContainer(TimetableContainerModel container) async {
    try {
      await _client.dio.post('/timetables', data: {
        'collegeId': container.collegeId,
        'departmentId': container.departmentId,
        'courseId': container.courseId,
        'academicYearId': container.academicYearId,
        'semesterId': container.semesterId,
        'sectionId': container.sectionId,
        'name': container.name,
        'status': container.status.name.toLowerCase(),
        'timingMode': container.timingMode.name,
        'activeDays': container.activeDays.map((d) => d.name.toLowerCase()).toList(),
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create timetable');
    }
  }

  @override
  Future<void> updateTimetableContainer(TimetableContainerModel container) async {
    try {
      await _client.dio.put('/timetables/${container.id}', data: {
        'name': container.name,
        'status': container.status.name.toLowerCase(),
        'timingMode': container.timingMode.name,
        'activeDays': container.activeDays.map((d) => d.name.toLowerCase()).toList(),
        if (_periods.containsKey(container.id))
          'periods': _periods[container.id]!.map((p) => p.toJson()).toList(),
        if (_breaks.containsKey(container.id))
          'breaks': _breaks[container.id]!.map((b) => b.toJson()).toList(),
        if (_gridEntries.containsKey(container.id))
          'entries': _gridEntries[container.id]!.map((e) => e.toJson()).toList(),
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update timetable');
    }
  }

  @override
  Future<void> deleteTimetableContainer(String timetableId) async {
    try {
      await _client.dio.post('/timetables/$timetableId/archive');
      _periods.remove(timetableId);
      _breaks.remove(timetableId);
      _gridEntries.remove(timetableId);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to archive timetable');
    }
  }

  @override
  Future<TimetableContainerModel?> getTimetableContainer(String timetableId) async {
    try {
      final response = await _client.dio.get('/timetables/$timetableId');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      if (data is Map<String, dynamic>) {
        if (data['periods'] is List) {
          _periods[timetableId] = (data['periods'] as List)
              .map((p) => TimetablePeriodModel.fromJson(p as Map<String, dynamic>))
              .toList();
        }
        if (data['breaks'] is List) {
          _breaks[timetableId] = (data['breaks'] as List)
              .map((b) => TimetableBreakModel.fromJson(b as Map<String, dynamic>))
              .toList();
        }
        if (data['entries'] is List) {
          _gridEntries[timetableId] = (data['entries'] as List)
              .map((e) => TimetableGridEntryModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return TimetableContainerModel.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _extractError(e, 'Failed to fetch timetable details');
    }
  }

  @override
  Stream<TimetableContainerModel?> watchTimetableContainer(String timetableId) async* {
    final container = await getTimetableContainer(timetableId);
    yield container;
  }

  @override
  Future<List<TimetableContainerModel>> getTimetableContainers({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    TimetableStatus? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'collegeId': collegeId,
        if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
        if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
        if (academicYearId != null && academicYearId.isNotEmpty) 'academicYearId': academicYearId,
        if (semesterId != null && semesterId.isNotEmpty) 'semesterId': semesterId,
        if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
        if (status != null) 'status': status.name.toLowerCase(),
      };

      final response = await _client.dio.get('/timetables', queryParameters: queryParams);
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      final list = data is List ? data : (data is Map && data['items'] is List ? data['items'] as List : null);

      if (list != null) {
        return list.map((e) => TimetableContainerModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _extractError(e, 'Failed to list timetables');
    }
  }

  @override
  Stream<List<TimetableContainerModel>> watchTimetableContainers({
    required String collegeId,
    String? departmentId,
    String? sectionId,
    TimetableStatus? status,
  }) async* {
    final list = await getTimetableContainers(
      collegeId: collegeId,
      departmentId: departmentId,
      sectionId: sectionId,
      status: status,
    );
    yield list;
  }

  // =========================================================================
  // 3. PERIODS, BREAKS & GRID ENTRIES
  // =========================================================================

  @override
  Future<void> savePeriod(String timetableId, TimetablePeriodModel period) async {
    final current = _periods[timetableId] ?? [];
    final updated = [
      for (final p in current)
        if (p.id == period.id) period else p,
      if (!current.any((p) => p.id == period.id)) period,
    ];
    _periods[timetableId] = updated;
    _periodsStreamController.add(_periods);
    try {
      await _client.dio.put('/timetables/$timetableId', data: {
        'periods': updated.map((p) => p.toJson()).toList(),
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to save timetable period');
    }
  }

  @override
  Future<void> savePeriodsBatch(String timetableId, List<TimetablePeriodModel> periods) async {
    _periods[timetableId] = periods;
    _periodsStreamController.add(_periods);
    try {
      await _client.dio.put('/timetables/$timetableId', data: {
        'periods': periods.map((p) => p.toJson()).toList(),
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to save timetable periods');
    }
  }

  @override
  Future<void> deletePeriod(String timetableId, String periodId) async {
    final current = _periods[timetableId] ?? [];
    final updated = current.where((p) => p.id != periodId).toList();
    _periods[timetableId] = updated;
    _periodsStreamController.add(_periods);
    try {
      await _client.dio.put('/timetables/$timetableId', data: {
        'periods': updated.map((p) => p.toJson()).toList(),
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to delete timetable period');
    }
  }

  @override
  Future<List<TimetablePeriodModel>> getPeriods(String timetableId) async {
    if (_periods.containsKey(timetableId)) return _periods[timetableId]!;
    await getTimetableContainer(timetableId);
    return _periods[timetableId] ?? [];
  }

  @override
  Stream<List<TimetablePeriodModel>> watchPeriods(String timetableId) async* {
    final initial = await getPeriods(timetableId);
    yield initial;
    yield* _periodsStreamController.stream.map((map) => map[timetableId] ?? []);
  }

  @override
  Future<void> saveBreak(String timetableId, TimetableBreakModel breakModel) async {
    final current = _breaks[timetableId] ?? [];
    final updated = [
      for (final b in current)
        if (b.id == breakModel.id) breakModel else b,
      if (!current.any((b) => b.id == breakModel.id)) breakModel,
    ];
    _breaks[timetableId] = updated;
    _breaksStreamController.add(_breaks);
    try {
      await _client.dio.put('/timetables/$timetableId', data: {
        'breaks': updated.map((b) => b.toJson()).toList(),
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to save timetable break');
    }
  }

  @override
  Future<void> saveBreaksBatch(String timetableId, List<TimetableBreakModel> breaks) async {
    _breaks[timetableId] = breaks;
    _breaksStreamController.add(_breaks);
    try {
      await _client.dio.put('/timetables/$timetableId', data: {
        'breaks': breaks.map((b) => b.toJson()).toList(),
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to save timetable breaks');
    }
  }

  @override
  Future<void> deleteBreak(String timetableId, String breakId) async {
    final current = _breaks[timetableId] ?? [];
    final updated = current.where((b) => b.id != breakId).toList();
    _breaks[timetableId] = updated;
    _breaksStreamController.add(_breaks);
    try {
      await _client.dio.put('/timetables/$timetableId', data: {
        'breaks': updated.map((b) => b.toJson()).toList(),
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to delete timetable break');
    }
  }

  @override
  Future<List<TimetableBreakModel>> getBreaks(String timetableId) async {
    if (_breaks.containsKey(timetableId)) return _breaks[timetableId]!;
    await getTimetableContainer(timetableId);
    return _breaks[timetableId] ?? [];
  }

  @override
  Stream<List<TimetableBreakModel>> watchBreaks(String timetableId) async* {
    final initial = await getBreaks(timetableId);
    yield initial;
    yield* _breaksStreamController.stream.map((map) => map[timetableId] ?? []);
  }

  @override
  Future<void> saveGridEntry(String timetableId, TimetableGridEntryModel entry) async {
    final current = _gridEntries[timetableId] ?? [];
    final updated = [
      for (final e in current)
        if (e.id == entry.id) entry else e,
      if (!current.any((e) => e.id == entry.id)) entry,
    ];
    _gridEntries[timetableId] = updated;
    _gridEntriesStreamController.add(_gridEntries);
    try {
      await _client.dio.put('/timetables/$timetableId', data: {
        'entries': updated.map((e) => e.toJson()).toList(),
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to save timetable grid entry');
    }
  }

  @override
  Future<void> saveGridEntriesBatch(String timetableId, List<TimetableGridEntryModel> entries) async {
    _gridEntries[timetableId] = entries;
    _gridEntriesStreamController.add(_gridEntries);
    try {
      await _client.dio.put('/timetables/$timetableId', data: {
        'entries': entries.map((e) => e.toJson()).toList(),
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to save timetable grid entries');
    }
  }

  @override
  Future<void> deleteGridEntry(String timetableId, String entryId) async {
    final current = _gridEntries[timetableId] ?? [];
    final updated = current.where((e) => e.id != entryId).toList();
    _gridEntries[timetableId] = updated;
    _gridEntriesStreamController.add(_gridEntries);
    try {
      await _client.dio.put('/timetables/$timetableId', data: {
        'entries': updated.map((e) => e.toJson()).toList(),
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to delete timetable grid entry');
    }
  }

  @override
  Future<List<TimetableGridEntryModel>> getGridEntries(String timetableId) async {
    if (_gridEntries.containsKey(timetableId)) return _gridEntries[timetableId]!;
    await getTimetableContainer(timetableId);
    return _gridEntries[timetableId] ?? [];
  }

  @override
  Stream<List<TimetableGridEntryModel>> watchGridEntries(String timetableId) async* {
    final initial = await getGridEntries(timetableId);
    yield initial;
    yield* _gridEntriesStreamController.stream.map((map) => map[timetableId] ?? []);
  }

  @override
  Future<void> validateTimetableForPublishing(String timetableId) async {
    final container = await getTimetableContainer(timetableId);
    if (container == null) throw Exception('Timetable not found');
    final entries = _gridEntries[timetableId] ?? [];
    if (entries.isEmpty) {
      throw Exception('Cannot publish an empty timetable');
    }
  }

  @override
  Future<void> publishTimetable(String timetableId, {required String publishedBy}) async {
    try {
      await _client.dio.post('/timetables/$timetableId/publish');
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to publish timetable');
    }
  }

  @override
  Future<void> unpublishTimetable(String timetableId) async {
    try {
      await _client.dio.post('/timetables/$timetableId/unpublish');
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to unpublish timetable');
    }
  }

  @override
  Future<void> createEntry(TimetableModel entry) async {
    throw UnimplementedError('Individual entry creation deprecated. Use container authoring.');
  }

  @override
  Future<void> updateEntry(TimetableModel entry) async {
    throw UnimplementedError('Individual entry update deprecated. Use container authoring.');
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    throw UnimplementedError('Individual entry delete deprecated. Use container authoring.');
  }

  @override
  Future<void> checkConflicts(TimetableModel entry) async {
    // Conflict checking is executed authoritatively during backend publication
  }
}
