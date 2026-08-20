import '../../../../core/network/api_client.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/timetable_models.dart';
import 'mock_timetable_repository.dart';
import 'timetable_repository.dart';

class ApiTimetableRepository implements TimetableRepository {
  final ApiClient _client;
  final MockTimetableRepository _fallbackMock;

  ApiTimetableRepository([ApiClient? client])
      : _client = client ?? apiClient,
        _fallbackMock = MockTimetableRepository();

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
        final response = await _client.dio.get('/timetable/faculty/$facultyId');
        final body = response.data;
        final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
        final list = data is List ? data : (data is Map && data['entries'] is List ? data['entries'] as List : null);
        if (list != null && list.isNotEmpty) {
          return _parseEntries(list, collegeId, departmentId, sectionId, facultyId);
        }
      } else if (sectionId != null && sectionId.isNotEmpty) {
        final response = await _client.dio.get('/timetable/sections/$sectionId');
        final body = response.data;
        final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
        final list = data is List ? data : (data is Map && data['entries'] is List ? data['entries'] as List : null);
        if (list != null && list.isNotEmpty) {
          return _parseEntries(list, collegeId, departmentId, sectionId, null);
        }
      } else {
        final response = await _client.dio.get('/timetable/students/me');
        final body = response.data;
        final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
        final list = data is List ? data : (data is Map && data['entries'] is List ? data['entries'] as List : null);
        if (list != null && list.isNotEmpty) {
          return _parseEntries(list, collegeId, departmentId, sectionId, null);
        }
      }

      return _fallbackMock.getTimetable(
        collegeId: collegeId,
        departmentId: departmentId,
        courseId: courseId,
        semesterId: semesterId,
        sectionId: sectionId,
        facultyId: facultyId,
      );
    } catch (_) {
      return _fallbackMock.getTimetable(
        collegeId: collegeId,
        departmentId: departmentId,
        courseId: courseId,
        semesterId: semesterId,
        sectionId: sectionId,
        facultyId: facultyId,
      );
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

  @override
  Future<void> createEntry(TimetableModel entry) => _fallbackMock.createEntry(entry);

  @override
  Future<void> updateEntry(TimetableModel entry) => _fallbackMock.updateEntry(entry);

  @override
  Future<void> deleteEntry(String entryId) => _fallbackMock.deleteEntry(entryId);

  @override
  Future<void> checkConflicts(TimetableModel entry) => _fallbackMock.checkConflicts(entry);

  @override
  Future<void> createTimetableContainer(TimetableContainerModel container) async {
    try {
      await _client.dio.post('/timetable', data: {
        'collegeId': container.collegeId,
        'departmentId': container.departmentId,
        'courseId': container.courseId,
        'academicYearId': container.academicYearId,
        'semesterId': container.semesterId,
        'sectionId': container.sectionId,
        'name': container.name,
        'status': container.status.name.toUpperCase(),
        'timingMode': container.timingMode.name,
        'activeDays': container.activeDays.map((d) => d.name.toUpperCase()).toList(),
      });
    } catch (_) {
      await _fallbackMock.createTimetableContainer(container);
    }
  }

  @override
  Future<void> updateTimetableContainer(TimetableContainerModel container) async {
    try {
      await _client.dio.put('/timetable/${container.id}', data: {
        'name': container.name,
        'status': container.status.name.toUpperCase(),
        'timingMode': container.timingMode.name,
      });
    } catch (_) {
      await _fallbackMock.updateTimetableContainer(container);
    }
  }

  @override
  Future<void> deleteTimetableContainer(String timetableId) async {
    try {
      await _client.dio.post('/timetable/$timetableId/archive');
    } catch (_) {
      await _fallbackMock.deleteTimetableContainer(timetableId);
    }
  }

  @override
  Future<TimetableContainerModel?> getTimetableContainer(String timetableId) async {
    try {
      final response = await _client.dio.get('/timetable/$timetableId');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      if (data is Map<String, dynamic>) {
        return TimetableContainerModel.fromJson(data);
      }
      return _fallbackMock.getTimetableContainer(timetableId);
    } catch (_) {
      return _fallbackMock.getTimetableContainer(timetableId);
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
        if (departmentId != null) 'departmentId': departmentId,
        if (courseId != null) 'courseId': courseId,
        if (academicYearId != null) 'academicYearId': academicYearId,
        if (semesterId != null) 'semesterId': semesterId,
        if (sectionId != null) 'sectionId': sectionId,
        if (status != null) 'status': status.name.toUpperCase(),
      };

      final response = await _client.dio.get('/timetable', queryParameters: queryParams);
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      final list = data is List ? data : (data is Map && data['items'] is List ? data['items'] as List : null);

      if (list != null && list.isNotEmpty) {
        return list.map((e) => TimetableContainerModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return _fallbackMock.getTimetableContainers(
        collegeId: collegeId,
        departmentId: departmentId,
        courseId: courseId,
        academicYearId: academicYearId,
        semesterId: semesterId,
        sectionId: sectionId,
        status: status,
      );
    } catch (_) {
      return _fallbackMock.getTimetableContainers(
        collegeId: collegeId,
        departmentId: departmentId,
        courseId: courseId,
        academicYearId: academicYearId,
        semesterId: semesterId,
        sectionId: sectionId,
        status: status,
      );
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

  @override
  Future<void> savePeriod(String timetableId, TimetablePeriodModel period) =>
      _fallbackMock.savePeriod(timetableId, period);

  @override
  Future<void> savePeriodsBatch(String timetableId, List<TimetablePeriodModel> periods) =>
      _fallbackMock.savePeriodsBatch(timetableId, periods);

  @override
  Future<void> deletePeriod(String timetableId, String periodId) =>
      _fallbackMock.deletePeriod(timetableId, periodId);

  @override
  Future<List<TimetablePeriodModel>> getPeriods(String timetableId) =>
      _fallbackMock.getPeriods(timetableId);

  @override
  Stream<List<TimetablePeriodModel>> watchPeriods(String timetableId) =>
      _fallbackMock.watchPeriods(timetableId);

  @override
  Future<void> saveBreak(String timetableId, TimetableBreakModel breakModel) =>
      _fallbackMock.saveBreak(timetableId, breakModel);

  @override
  Future<void> saveBreaksBatch(String timetableId, List<TimetableBreakModel> breaks) =>
      _fallbackMock.saveBreaksBatch(timetableId, breaks);

  @override
  Future<void> deleteBreak(String timetableId, String breakId) =>
      _fallbackMock.deleteBreak(timetableId, breakId);

  @override
  Future<List<TimetableBreakModel>> getBreaks(String timetableId) =>
      _fallbackMock.getBreaks(timetableId);

  @override
  Stream<List<TimetableBreakModel>> watchBreaks(String timetableId) =>
      _fallbackMock.watchBreaks(timetableId);

  @override
  Future<void> saveGridEntry(String timetableId, TimetableGridEntryModel entry) =>
      _fallbackMock.saveGridEntry(timetableId, entry);

  @override
  Future<void> saveGridEntriesBatch(String timetableId, List<TimetableGridEntryModel> entries) =>
      _fallbackMock.saveGridEntriesBatch(timetableId, entries);

  @override
  Future<void> deleteGridEntry(String timetableId, String entryId) =>
      _fallbackMock.deleteGridEntry(timetableId, entryId);

  @override
  Future<List<TimetableGridEntryModel>> getGridEntries(String timetableId) =>
      _fallbackMock.getGridEntries(timetableId);

  @override
  Stream<List<TimetableGridEntryModel>> watchGridEntries(String timetableId) =>
      _fallbackMock.watchGridEntries(timetableId);

  @override
  Future<void> validateTimetableForPublishing(String timetableId) =>
      _fallbackMock.validateTimetableForPublishing(timetableId);

  @override
  Future<void> publishTimetable(String timetableId, {required String publishedBy}) async {
    try {
      await _client.dio.post('/timetable/$timetableId/publish');
    } catch (_) {
      await _fallbackMock.publishTimetable(timetableId, publishedBy: publishedBy);
    }
  }

  @override
  Future<void> unpublishTimetable(String timetableId) async {
    try {
      await _client.dio.post('/timetable/$timetableId/unpublish');
    } catch (_) {
      await _fallbackMock.unpublishTimetable(timetableId);
    }
  }
}
