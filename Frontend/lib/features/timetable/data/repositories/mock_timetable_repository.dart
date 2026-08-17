import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../domain/models/timetable_models.dart';
import 'timetable_repository.dart';

class MockTimetableRepository implements TimetableRepository {
  final List<TimetableModel> _entries = [];
  bool _initialized = false;
  
  final _controller = StreamController<List<TimetableModel>>.broadcast();

  Future<void> _delay() async => await Future.delayed(const Duration(milliseconds: 400));

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
              ? allEntries.where((e) => e.sectionId == sectionId).toList()
              : [];
        case AppRole.faculty:
          return allEntries.where((e) => e.facultyId == userId).toList();
        case AppRole.hod:
          return departmentId != null
              ? allEntries.where((e) => e.departmentId == departmentId).toList()
              : [];
        case AppRole.collegeAdmin:
          return collegeId != null
              ? allEntries.where((e) => e.collegeId == collegeId).toList()
              : [];
        case AppRole.superAdmin:
          return allEntries;
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
  }) async {
    await _delay();
    return _entries.where((entry) {
      if (entry.collegeId != collegeId) return false;
      if (departmentId != null && entry.departmentId != departmentId) return false;
      if (courseId != null && entry.courseId != courseId) return false;
      if (semesterId != null && entry.semesterId != semesterId) return false;
      if (sectionId != null && entry.sectionId != sectionId) return false;
      if (facultyId != null && entry.facultyId != facultyId) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> checkConflicts(TimetableModel entry) async {
    await _delay();
    for (final existing in _entries) {
      if (existing.id == entry.id) continue; // Skip self for updates

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
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
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
}
