import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/timetable_models.dart';
import '../../domain/models/calendar_override.dart';
import '../../domain/models/teacher_substitution.dart';
import 'timetable_repository.dart';

class MockTimetableRepository implements TimetableRepository {
  final List<TimetableModel> _entries = [];
  bool _initialized = false;
  final Duration latency;
  
  final _controller = StreamController<List<TimetableModel>>.broadcast();

  MockTimetableRepository({this.latency = Duration.zero}) {
    _generateInitialData();
    _initialized = true;
  }

  Future<void> _delay() async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.from(_entries));
    }
  }

  @override
  Stream<List<TimetableModel>> watchTimetable({
    required AppRole role,
    required String userId,
    String? collegeId,
    String? departmentId,
    String? sectionId,
    String? date,
  }) {
    if (!_initialized) {
      _generateInitialData();
      _initialized = true;
    }

    Future.microtask(() => _emit());

    return _controller.stream.map((allEntries) {
      switch (role) {
        case AppRole.student:
          return sectionId != null
              ? allEntries.where((e) => e.sectionId == sectionId && (collegeId == null || e.collegeId == collegeId)).toList()
              : [];
        case AppRole.faculty:
          return allEntries.where((e) => e.facultyId == userId && (collegeId == null || e.collegeId == collegeId)).toList();
        case AppRole.hod:
          return departmentId != null
              ? allEntries.where((e) => e.departmentId == departmentId && (collegeId == null || e.collegeId == collegeId)).toList()
              : [];
        case AppRole.collegeAdmin:
          return collegeId != null
              ? allEntries.where((e) => e.collegeId == collegeId).toList()
              : [];
        case AppRole.superAdmin:
          return collegeId != null
              ? allEntries.where((e) => e.collegeId == collegeId).toList()
              : allEntries;
      }
    });
  }

  @override
  Future<List<TimetableModel>> getTimetable({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? facultyId,
    String? date,
  }) async {
    await _delay();
    var list = _entries.where((entry) {
      if (entry.collegeId != collegeId) return false;
      if (departmentId != null && entry.departmentId != departmentId) return false;
      if (courseId != null && entry.courseId != courseId) return false;
      if (semesterId != null && entry.semesterId != semesterId) return false;
      if (sectionId != null && entry.sectionId != sectionId) return false;
      return true;
    }).toList();

    if (date != null && date.isNotEmpty) {
      // 1. Calendar overrides
      final overrides = _overrides.where((o) => o.date == date).toList();
      final hasHoliday = overrides.any((o) => o.type == CalendarOverrideType.holiday);
      if (hasHoliday) return [];

      list = list.where((entry) {
        final isCancelled = overrides.any((o) =>
            o.type == CalendarOverrideType.cancelled &&
            (o.timetableEntryId == null || o.timetableEntryId!.isEmpty || o.timetableEntryId == entry.id));
        return !isCancelled;
      }).toList();

      // 2. Substitutions
      final activeSubs = _substitutions.where((s) => s.date == date && s.status.toLowerCase() != 'cancelled').toList();
      list = list.map((entry) {
        final sub = activeSubs.where((s) => s.timetableEntryId == entry.id).firstOrNull;
        if (sub != null) {
          return entry.copyWith(
            facultyId: sub.substituteFacultyId,
            isSubstituted: true,
          );
        }
        return entry;
      }).toList();

      if (facultyId != null && facultyId.isNotEmpty && facultyId != 'me') {
        list = list.where((entry) => entry.facultyId == facultyId).toList();
      }
    } else {
      if (facultyId != null && facultyId.isNotEmpty && facultyId != 'me') {
        list = list.where((entry) => entry.facultyId == facultyId).toList();
      }
    }

    return list;
  }

  @override
  Future<void> checkConflicts(TimetableModel entry) async {
    await _delay();
    for (final existing in _entries) {
      if (existing.id == entry.id) continue; // Skip self for updates
      if (existing.collegeId.isNotEmpty && entry.collegeId.isNotEmpty && existing.collegeId != entry.collegeId) {
        continue; // Different college
      }

      if (existing.overlapsWith(entry)) {
        // Faculty Conflict
        if (existing.facultyId == entry.facultyId) {
          throw TimetableConflictException(
            "Faculty already has a class scheduled during this time.",
            conflictingEntry: existing,
          );
        }
        // Section Conflict
        if (existing.sectionId == entry.sectionId) {
          throw TimetableConflictException(
            "This section already has a class scheduled during this time.",
            conflictingEntry: existing,
          );
        }
        // Room Conflict
        if (existing.roomNumber == entry.roomNumber && existing.building == entry.building) {
          throw TimetableConflictException(
            "Room ${entry.roomNumber} is already occupied during this time.",
            conflictingEntry: existing,
          );
        }
      }
    }
  }

  @override
  Future<void> createEntry(TimetableModel entry) async {
    await checkConflicts(entry);
    
    final newEntry = entry.copyWith(
      id: entry.id.isNotEmpty ? entry.id : const Uuid().v4(),
      createdAt: entry.createdAt,
      updatedAt: DateTime.now(),
    );
    
    _entries.add(newEntry);
    _emit();
  }

  @override
  Future<void> updateEntry(TimetableModel entry) async {
    await checkConflicts(entry);
    
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) throw Exception("Entry not found");

    _entries[index] = entry.copyWith(updatedAt: DateTime.now());
    _emit();
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    await _delay();
    _entries.removeWhere((e) => e.id == entryId);
    _emit();
  }

  // =========================================================
  // AUTHORING ARCHITECTURE (MOCK IN-MEMORY IMPLEMENTATION)
  // =========================================================

  final Map<String, TimetableContainerModel> _containers = {};
  final Map<String, List<TimetablePeriodModel>> _periods = {};
  final Map<String, List<TimetableBreakModel>> _breaks = {};
  final Map<String, List<TimetableGridEntryModel>> _gridEntries = {};

  final _containersController = StreamController<List<TimetableContainerModel>>.broadcast();

  @override
  Future<String> createTimetableContainer(TimetableContainerModel container) async {
    await _delay();
    container.validate();
    // Simulate server-assigned MongoDB ObjectId (or use container.id if provided e.g. for pre-seeded mocks)
    final id = container.id.isNotEmpty
        ? container.id
        : '507f1f77bcf86cd799439${(_containers.length + 100).toRadixString(16).padLeft(3, '0')}';
    final toSave = container.copyWith(id: id, createdAt: DateTime.now(), updatedAt: DateTime.now());
    _containers[id] = toSave;
    _containersController.add(_containers.values.toList());
    return id;
  }

  @override
  Future<void> updateTimetableContainer(TimetableContainerModel container) async {
    await _delay();
    container.validate();
    _containers[container.id] = container.copyWith(updatedAt: DateTime.now());
    _containersController.add(_containers.values.toList());
  }

  bool simulateAttendanceConflictOnDelete = false;

  @override
  Future<void> deleteTimetableContainer(String timetableId) async {
    await _delay();
    if (simulateAttendanceConflictOnDelete) {
      throw Exception('Cannot delete timetable with existing attendance sessions. Please archive the timetable instead to preserve historical attendance records.');
    }
    _containers.remove(timetableId);
    _periods.remove(timetableId);
    _breaks.remove(timetableId);
    _gridEntries.remove(timetableId);
    _entries.removeWhere((e) => e.id.startsWith('pub_${timetableId}_'));
    _emit();
    _containersController.add(_containers.values.toList());
  }

  @override
  Future<void> archiveTimetableContainer(String timetableId) async {
    await _delay();
    final existing = _containers[timetableId];
    if (existing != null) {
      _containers[timetableId] = existing.copyWith(
        status: TimetableStatus.archived,
        updatedAt: DateTime.now(),
      );
      _containersController.add(_containers.values.toList());
    }
  }

  @override
  Future<TimetableContainerModel?> getTimetableContainer(String timetableId) async {
    await _delay();
    return _containers[timetableId];
  }

  @override
  Stream<TimetableContainerModel?> watchTimetableContainer(String timetableId) async* {
    yield _containers[timetableId];
    yield* _containersController.stream.map((_) => _containers[timetableId]);
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
    await _delay();
    return _containers.values.where((c) {
      if (c.collegeId != collegeId) return false;
      if (departmentId != null && c.departmentId != departmentId) return false;
      if (courseId != null && c.courseId != courseId) return false;
      if (academicYearId != null && c.academicYearId != academicYearId) return false;
      if (semesterId != null && c.semesterId != semesterId) return false;
      if (sectionId != null && c.sectionId != sectionId) return false;
      if (status != null && c.status != status) return false;
      return true;
    }).toList();
  }

  @override
  Stream<List<TimetableContainerModel>> watchTimetableContainers({
    required String collegeId,
    String? departmentId,
    String? sectionId,
    TimetableStatus? status,
  }) async* {
    List<TimetableContainerModel> filter(List<TimetableContainerModel> list) {
      return list.where((c) {
        if (c.collegeId != collegeId) return false;
        if (departmentId != null && c.departmentId != departmentId) return false;
        if (sectionId != null && c.sectionId != sectionId) return false;
        if (status != null && c.status != status) return false;
        return true;
      }).toList();
    }

    yield filter(_containers.values.toList());
    yield* _containersController.stream.map((list) => filter(list));
  }

  @override
  Future<void> savePeriod(String timetableId, TimetablePeriodModel period) async {
    await _delay();
    period.validate();
    final list = _periods.putIfAbsent(timetableId, () => []);
    list.removeWhere((p) => p.id == period.id);
    list.add(period);
  }

  @override
  Future<void> savePeriodsBatch(String timetableId, List<TimetablePeriodModel> periods) async {
    await _delay();
    for (final p in periods) {
      p.validate();
    }
    final list = _periods.putIfAbsent(timetableId, () => []);
    for (final p in periods) {
      list.removeWhere((existing) => existing.id == p.id);
      list.add(p);
    }
  }

  @override
  Future<void> deletePeriod(String timetableId, String periodId) async {
    await _delay();
    _periods[timetableId]?.removeWhere((p) => p.id == periodId);
  }

  @override
  Future<List<TimetablePeriodModel>> getPeriods(String timetableId) async {
    await _delay();
    final list = List<TimetablePeriodModel>.from(_periods[timetableId] ?? []);
    list.sort((a, b) => a.index.compareTo(b.index));
    return list;
  }

  @override
  Stream<List<TimetablePeriodModel>> watchPeriods(String timetableId) {
    return Stream.value(List<TimetablePeriodModel>.from(_periods[timetableId] ?? []));
  }

  @override
  Future<void> saveBreak(String timetableId, TimetableBreakModel breakModel) async {
    await _delay();
    breakModel.validate();
    final list = _breaks.putIfAbsent(timetableId, () => []);
    list.removeWhere((b) => b.id == breakModel.id);
    list.add(breakModel);
  }

  @override
  Future<void> saveBreaksBatch(String timetableId, List<TimetableBreakModel> breaks) async {
    await _delay();
    for (final b in breaks) {
      b.validate();
    }
    final list = _breaks.putIfAbsent(timetableId, () => []);
    for (final b in breaks) {
      list.removeWhere((existing) => existing.id == b.id);
      list.add(b);
    }
  }

  @override
  Future<void> deleteBreak(String timetableId, String breakId) async {
    await _delay();
    _breaks[timetableId]?.removeWhere((b) => b.id == breakId);
  }

  @override
  Future<List<TimetableBreakModel>> getBreaks(String timetableId) async {
    await _delay();
    return List<TimetableBreakModel>.from(_breaks[timetableId] ?? []);
  }

  @override
  Stream<List<TimetableBreakModel>> watchBreaks(String timetableId) {
    return Stream.value(List<TimetableBreakModel>.from(_breaks[timetableId] ?? []));
  }

  @override
  Future<void> saveGridEntry(String timetableId, TimetableGridEntryModel entry) async {
    await _delay();
    entry.validate();
    final list = _gridEntries.putIfAbsent(timetableId, () => []);
    list.removeWhere((e) => e.id == entry.id);
    list.add(entry);
  }

  @override
  Future<void> saveGridEntriesBatch(String timetableId, List<TimetableGridEntryModel> entries) async {
    await _delay();
    for (final e in entries) {
      e.validate();
    }
    final list = _gridEntries.putIfAbsent(timetableId, () => []);
    for (final e in entries) {
      list.removeWhere((existing) => existing.id == e.id);
      list.add(e);
    }
  }

  @override
  Future<void> deleteGridEntry(String timetableId, String entryId) async {
    await _delay();
    _gridEntries[timetableId]?.removeWhere((e) => e.id == entryId);
  }

  @override
  Future<List<TimetableGridEntryModel>> getGridEntries(String timetableId) async {
    await _delay();
    return List<TimetableGridEntryModel>.from(_gridEntries[timetableId] ?? []);
  }

  @override
  Stream<List<TimetableGridEntryModel>> watchGridEntries(String timetableId) {
    return Stream.value(List<TimetableGridEntryModel>.from(_gridEntries[timetableId] ?? []));
  }

  @override
  Future<void> validateTimetableForPublishing(String timetableId) async {
    final container = _containers[timetableId];
    if (container == null) throw Exception("Container not found");
    container.validate();

    final periods = _periods[timetableId] ?? [];
    final breaks = _breaks[timetableId] ?? [];
    final entries = _gridEntries[timetableId] ?? [];

    if (periods.isEmpty) throw ArgumentError("No periods defined");

    for (int i = 0; i < entries.length; i++) {
      for (int j = i + 1; j < entries.length; j++) {
        final e1 = entries[i];
        final e2 = entries[j];
        if (e1.dayOfWeek == e2.dayOfWeek && (e1.overlapsHorizontallyWith(e2) || e1.overlapsTimeWith(e2))) {
          throw TimetableConflictException("Conflict detected on ${e1.dayOfWeek.displayName}");
        }
      }
    }

    for (final entry in entries) {
      for (final b in breaks) {
        if (entry.conflictsWithBreak(b)) {
          throw TimetableConflictException("Conflict with break ${b.name}");
        }
      }
    }
  }

  @override
  Future<void> publishTimetable(String timetableId, {required String publishedBy}) async {
    await validateTimetableForPublishing(timetableId);
    final container = _containers[timetableId]!;
    final entries = _gridEntries[timetableId] ?? [];
    final now = DateTime.now();

    final updated = container.copyWith(
      status: TimetableStatus.published,
      publishedAt: now,
      publishedBy: publishedBy,
      version: container.version + 1,
      updatedAt: now,
    );
    _containers[timetableId] = updated;

    // Purge previous published projection for this timetable
    _entries.removeWhere((e) => e.id.startsWith('pub_${timetableId}_'));

    for (final entry in entries) {
      final projectedId = 'pub_${timetableId}_${entry.id}';
      _entries.removeWhere((e) => e.id == projectedId);
      _entries.add(TimetableModel(
        id: projectedId,
        collegeId: container.collegeId,
        departmentId: container.departmentId,
        courseId: container.courseId,
        academicYearId: container.academicYearId,
        semesterId: container.semesterId,
        sectionId: container.sectionId,
        subjectId: entry.subjectId,
        facultyId: entry.facultyId,
        dayOfWeek: entry.dayOfWeek,
        startTime: entry.startTime,
        endTime: entry.endTime,
        roomNumber: entry.roomNumber,
        building: entry.building,
        sessionType: entry.sessionType,
        createdAt: container.createdAt,
        updatedAt: now,
      ));
    }
    _emit();
    _containersController.add(_containers.values.toList());
  }

  @override
  Future<void> unpublishTimetable(String timetableId) async {
    final container = _containers[timetableId];
    if (container == null) return;
    _entries.removeWhere((e) => e.id.startsWith('pub_${timetableId}_'));
    _containers[timetableId] = container.copyWith(status: TimetableStatus.draft, clearPublished: true, updatedAt: DateTime.now());
    _emit();
    _containersController.add(_containers.values.toList());
  }

  void _generateInitialData() {
    final now = DateTime.now();
    
    // Mock Data for "col-1" -> "dept-cse" -> "sec-3a"
    _entries.addAll([
      TimetableModel(
        id: 'tt-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        academicYearId: 'ay-2023',
        semesterId: 'sem-3',
        sectionId: 'sec-3a',
        subjectId: 'sub-ds',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.monday,
        startTime: '09:00',
        endTime: '10:00',
        roomNumber: 'C-204',
        building: 'Main Block',
        sessionType: TimetableSessionType.lecture,
        createdAt: now,
        updatedAt: now,
      ),
      TimetableModel(
        id: 'tt-2',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        academicYearId: 'ay-2023',
        semesterId: 'sem-3',
        sectionId: 'sec-3a',
        subjectId: 'sub-os',
        facultyId: 'fac-2',
        dayOfWeek: TimetableDay.monday,
        startTime: '10:00',
        endTime: '11:00',
        roomNumber: 'C-205',
        building: 'Main Block',
        sessionType: TimetableSessionType.lecture,
        createdAt: now,
        updatedAt: now,
      ),
      TimetableModel(
        id: 'tt-3',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        academicYearId: 'ay-2023',
        semesterId: 'sem-3',
        sectionId: 'sec-3a',
        subjectId: 'sub-dbms',
        facultyId: 'fac-1', // Same faculty as tt-1
        dayOfWeek: TimetableDay.tuesday,
        startTime: '09:00',
        endTime: '11:00',
        roomNumber: 'Lab-1',
        building: 'Lab Block',
        sessionType: TimetableSessionType.lab,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  }

  final List<CalendarOverride> _overrides = [];

  @override
  Future<List<CalendarOverride>> getCalendarOverrides({String? date, String? from, String? to}) async {
    await _delay();
    var list = List<CalendarOverride>.from(_overrides);
    if (date != null) list = list.where((o) => o.date == date).toList();
    return list;
  }

  @override
  Future<CalendarOverride> createCalendarOverride(CalendarOverride override) async {
    await _delay();
    _overrides.add(override);
    return override;
  }

  @override
  Future<void> deleteCalendarOverride(String id) async {
    await _delay();
    _overrides.removeWhere((o) => o.id == id);
  }

  final List<TeacherSubstitution> _substitutions = [];

  @override
  Future<List<TeacherSubstitution>> getTeacherSubstitutions({
    String? date,
    String? timetableId,
    String? departmentId,
  }) async {
    await _delay();
    var list = List<TeacherSubstitution>.from(_substitutions);
    if (date != null) list = list.where((s) => s.date == date).toList();
    if (timetableId != null) list = list.where((s) => s.timetableId == timetableId).toList();
    if (departmentId != null) list = list.where((s) => s.departmentId == departmentId).toList();
    return list;
  }

  @override
  Future<TeacherSubstitution> createTeacherSubstitution(TeacherSubstitution substitution) async {
    await _delay();
    final duplicate = _substitutions.where((s) =>
      s.timetableId == substitution.timetableId &&
      s.timetableEntryId == substitution.timetableEntryId &&
      s.date == substitution.date &&
      s.status.toLowerCase() != 'cancelled').firstOrNull;
    if (duplicate != null) {
      throw Exception('An active substitution already exists for this timetable entry on this date.');
    }
    final created = substitution.id.isNotEmpty
        ? substitution
        : substitution.copyWith(id: const Uuid().v4());
    _substitutions.add(created);
    return created;
  }

  @override
  Future<void> deleteTeacherSubstitution(String id) async {
    await _delay();
    _substitutions.removeWhere((s) => s.id == id);
  }
}

