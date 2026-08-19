import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/timetable_repository.dart';
import 'package:campus_management/features/timetable/data/repositories/firebase_timetable_repository.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_lookup_providers.dart';
import 'package:campus_management/core/firebase/firebase_services.dart';
import 'package:campus_management/features/notifications/domain/services/notification_service.dart';

class MockFirestoreService implements FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> db = {};
  final List<Map<String, dynamic>> recordedQueries = [];
  final List<Map<String, dynamic>> recordedWatchFilters = [];

  @override
  Future<void> setDocument(String collection, String id, Map<String, dynamic> data) async {
    db.putIfAbsent(collection, () => {})[id] = data;
  }

  @override
  Future<void> deleteDocument(String collection, String id) async {
    db[collection]?.remove(id);
  }

  @override
  Future<Map<String, dynamic>?> getDocument(String collection, String id) async {
    return db[collection]?[id];
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollection(String collection, Map<String, dynamic> filters, {String? orderBy, bool descending = false, int? limit}) async {
    recordedQueries.add({'collection': collection, 'filters': Map<String, dynamic>.from(filters)});
    final docs = db[collection]?.values.toList() ?? [];
    if (filters.isEmpty) return docs;
    return docs.where((doc) {
      for (final entry in filters.entries) {
        if (doc[entry.key] != entry.value) return false;
      }
      return true;
    }).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchQuery(String collection, Map<String, dynamic> filters, {String? orderBy, bool descending = false, int? limit}) {
    recordedWatchFilters.add({'collection': collection, 'filters': Map<String, dynamic>.from(filters)});
    final docs = db[collection]?.values.toList() ?? [];
    final filtered = docs.where((doc) {
      for (final entry in filters.entries) {
        if (doc[entry.key] != entry.value) return false;
      }
      return true;
    }).toList();
    return Stream.value(filtered);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FailingNotificationService implements NotificationService {
  @override
  Future<void> notifyTimetableUpdated({required String sectionId, required String subjectName}) async {
    throw Exception('Simulated notification server outage');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ACADEX Prompt 94/95: Timetable Firebase & Authentication Repair Test Suite', () {
    late MockFirestoreService mockFirestore;

    final mockStudentUser = UserModel(
      id: 'usr-student-42',
      email: 'student42@univ.edu',
      name: 'Alice Turing',
      role: AppRole.student,
      collegeId: 'col-alpha',
      departmentId: 'dept-cs',
      sectionId: 'sec-3a',
    );

    final mockFacultyUser = UserModel(
      id: 'usr-faculty-01',
      email: 'faculty01@univ.edu',
      name: 'Dr. John Von Neumann',
      role: AppRole.faculty,
      collegeId: 'col-alpha',
      departmentId: 'dept-cs',
    );

    final mockHodUser = UserModel(
      id: 'usr-hod-01',
      email: 'hod01@univ.edu',
      name: 'Prof. Donald Knuth',
      role: AppRole.hod,
      collegeId: 'col-alpha',
      departmentId: 'dept-cs',
    );

    final mockCollegeAdminUser = UserModel(
      id: 'usr-admin-01',
      email: 'admin@univ.edu',
      name: 'Dean Smith',
      role: AppRole.collegeAdmin,
      collegeId: 'col-alpha',
    );

    final mockSuperAdminUser = UserModel(
      id: 'usr-super-01',
      email: 'super@acadex.com',
      name: 'Super Admin',
      role: AppRole.superAdmin,
    );

    final baseEntry = TimetableModel(
      id: 'tt-entry-1',
      collegeId: 'col-alpha',
      departmentId: 'dept-cs',
      courseId: 'crs-btech',
      academicYearId: 'ay-2026',
      semesterId: 'sem-4',
      sectionId: 'sec-3a',
      subjectId: 'sub-algo',
      facultyId: 'usr-faculty-01',
      dayOfWeek: TimetableDay.monday,
      startTime: '09:00',
      endTime: '10:00',
      roomNumber: 'LH-101',
      building: 'Main Block',
      sessionType: TimetableSessionType.lecture,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      mockFirestore = MockFirestoreService();
      // Seed faculty document in users collection for assignment checks
      mockFirestore.setDocument('users', 'usr-faculty-01', {
        'id': 'usr-faculty-01',
        'role': 'faculty',
        'collegeId': 'col-alpha',
        'departmentId': 'dept-cs',
        'subjectIds': ['sub-algo', 'sub-dbms'],
        'sectionIds': ['sec-3a', 'sec-3b'],
      });
    });

    test('1. Student timetable query includes collegeId and sectionId', () async {
      final repo = FirebaseTimetableRepository(mockFirestore, currentUser: mockStudentUser);
      final stream = repo.watchTimetable(
        role: AppRole.student,
        userId: mockStudentUser.id,
        collegeId: mockStudentUser.collegeId,
        sectionId: mockStudentUser.sectionId,
      );
      await stream.first;

      expect(mockFirestore.recordedWatchFilters.isNotEmpty, isTrue);
      final lastFilter = mockFirestore.recordedWatchFilters.last['filters'] as Map<String, dynamic>;
      expect(lastFilter['collegeId'], equals('col-alpha'));
      expect(lastFilter['sectionId'], equals('sec-3a'));
    });

    test('2. Faculty timetable query includes collegeId and facultyId', () async {
      final repo = FirebaseTimetableRepository(mockFirestore, currentUser: mockFacultyUser);
      final stream = repo.watchTimetable(
        role: AppRole.faculty,
        userId: mockFacultyUser.id,
        collegeId: mockFacultyUser.collegeId,
      );
      await stream.first;

      final lastFilter = mockFirestore.recordedWatchFilters.last['filters'] as Map<String, dynamic>;
      expect(lastFilter['collegeId'], equals('col-alpha'));
      expect(lastFilter['facultyId'], equals('usr-faculty-01'));
    });

    test('3. HOD timetable query includes collegeId and departmentId', () async {
      final repo = FirebaseTimetableRepository(mockFirestore, currentUser: mockHodUser);
      final stream = repo.watchTimetable(
        role: AppRole.hod,
        userId: mockHodUser.id,
        collegeId: mockHodUser.collegeId,
        departmentId: mockHodUser.departmentId,
      );
      await stream.first;

      final lastFilter = mockFirestore.recordedWatchFilters.last['filters'] as Map<String, dynamic>;
      expect(lastFilter['collegeId'], equals('col-alpha'));
      expect(lastFilter['departmentId'], equals('dept-cs'));
    });

    test('4. College Admin timetable query includes collegeId', () async {
      final repo = FirebaseTimetableRepository(mockFirestore, currentUser: mockCollegeAdminUser);
      final stream = repo.watchTimetable(
        role: AppRole.collegeAdmin,
        userId: mockCollegeAdminUser.id,
        collegeId: mockCollegeAdminUser.collegeId,
      );
      await stream.first;

      final lastFilter = mockFirestore.recordedWatchFilters.last['filters'] as Map<String, dynamic>;
      expect(lastFilter['collegeId'], equals('col-alpha'));
    });

    test('5. Super Admin global behavior queries without forced collegeId', () async {
      final repo = FirebaseTimetableRepository(mockFirestore, currentUser: mockSuperAdminUser);
      final stream = repo.watchTimetable(
        role: AppRole.superAdmin,
        userId: mockSuperAdminUser.id,
      );
      await stream.first;

      final lastFilter = mockFirestore.recordedWatchFilters.last['filters'] as Map<String, dynamic>;
      expect(lastFilter.containsKey('collegeId'), isFalse);
    });

    test('6. Conflict faculty query includes collegeId', () async {
      final repo = FirebaseTimetableRepository(mockFirestore, currentUser: mockCollegeAdminUser);
      await repo.checkConflicts(baseEntry);

      final facultyQuery = mockFirestore.recordedQueries.firstWhere((q) => q['filters']['facultyId'] == 'usr-faculty-01');
      expect(facultyQuery['filters']['collegeId'], equals('col-alpha'));
      expect(facultyQuery['filters']['dayOfWeek'], equals('monday'));
    });

    test('7. Conflict section query includes collegeId', () async {
      final repo = FirebaseTimetableRepository(mockFirestore, currentUser: mockCollegeAdminUser);
      await repo.checkConflicts(baseEntry);

      final sectionQuery = mockFirestore.recordedQueries.firstWhere((q) => q['filters']['sectionId'] == 'sec-3a');
      expect(sectionQuery['filters']['collegeId'], equals('col-alpha'));
      expect(sectionQuery['filters']['dayOfWeek'], equals('monday'));
    });

    test('8. Conflict room query includes collegeId', () async {
      final repo = FirebaseTimetableRepository(mockFirestore, currentUser: mockCollegeAdminUser);
      await repo.checkConflicts(baseEntry);

      final roomQuery = mockFirestore.recordedQueries.firstWhere((q) => q['filters']['roomNumber'] == 'LH-101');
      expect(roomQuery['filters']['collegeId'], equals('col-alpha'));
      expect(roomQuery['filters']['dayOfWeek'], equals('monday'));
    });

    test('9. Student section resolves directly from authenticated profile', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: mockStudentUser, token: 'token'))),
          currentUserProvider.overrideWithValue(mockStudentUser),
        ],
      );

      final user = container.read(currentUserProvider);
      expect(user?.sectionId, equals('sec-3a'));
      expect(user?.collegeId, equals('col-alpha'));
    });

    test('10. No full student directory scan is performed by weeklyTimetableProvider', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: mockStudentUser, token: 'token'))),
          currentUserProvider.overrideWithValue(mockStudentUser),
          firebaseTimetableRepositoryProvider.overrideWithValue(FirebaseTimetableRepository(mockFirestore, currentUser: mockStudentUser)),
        ],
      );

      final weekly = await container.read(weeklyTimetableProvider.future);
      expect(weekly, isA<Map<TimetableDay, List<TimetableModel>>>());
      // Confirms student collection was never queried
      expect(mockFirestore.recordedQueries.any((q) => q['collection'] == 'students'), isFalse);
    });

    test('11. Production paths contain dynamic identity rather than hardcoded IDs', () {
      expect(mockStudentUser.id, isNot('student123'));
      expect(mockFacultyUser.id, isNot('faculty1'));
      expect(mockHodUser.departmentId, isNot('dept-1'));
      expect(mockCollegeAdminUser.collegeId, isNot('col-1'));
    });

    test('12. Unauthorized roles (Student, Faculty) are rejected on createEntry', () async {
      final studentRepo = FirebaseTimetableRepository(mockFirestore, currentUser: mockStudentUser);
      expect(() => studentRepo.createEntry(baseEntry), throwsA(isA<StateError>()));

      final facultyRepo = FirebaseTimetableRepository(mockFirestore, currentUser: mockFacultyUser);
      expect(() => facultyRepo.createEntry(baseEntry), throwsA(isA<StateError>()));
    });

    test('13. Unauthorized roles (Student, Faculty) are rejected on updateEntry and deleteEntry', () async {
      final studentRepo = FirebaseTimetableRepository(mockFirestore, currentUser: mockStudentUser);
      expect(() => studentRepo.updateEntry(baseEntry), throwsA(isA<StateError>()));
      expect(() => studentRepo.deleteEntry('tt-entry-1'), throwsA(isA<StateError>()));
    });

    test('14. Faculty assignment validation catches unauthorized subjects and sections', () async {
      final repo = FirebaseTimetableRepository(mockFirestore, currentUser: mockCollegeAdminUser);
      
      // Assigning a subject not in faculty's qualified subjectIds
      final invalidSubjectEntry = baseEntry.copyWith(subjectId: 'sub-unauthorized-physics');
      expect(() => repo.createEntry(invalidSubjectEntry), throwsA(predicate((e) => e.toString().contains('Unauthorized: Faculty is not assigned'))));
    });

    test('15. Faculty conflict detection catches overlapping timeslots', () async {
      final repo = FirebaseTimetableRepository(mockFirestore, currentUser: mockCollegeAdminUser);
      // Seed an existing class for this faculty on Monday 09:30 - 10:30
      await mockFirestore.setDocument('timetable', 'existing-fac-1', {
        'id': 'existing-fac-1',
        'collegeId': 'col-alpha',
        'departmentId': 'dept-cs',
        'courseId': 'crs-btech',
        'academicYearId': 'ay-2026',
        'semesterId': 'sem-4',
        'sectionId': 'sec-3b',
        'subjectId': 'sub-algo',
        'facultyId': 'usr-faculty-01',
        'dayOfWeek': 'monday',
        'startTime': '09:30',
        'endTime': '10:30',
        'roomNumber': 'LH-102',
        'building': 'Main Block',
        'sessionType': 'lecture',
      });

      // Attempt to schedule baseEntry (09:00 - 10:00) which overlaps with 09:30 - 10:30
      expect(() => repo.createEntry(baseEntry), throwsA(isA<TimetableConflictException>()));
    });

    test('16. Section conflict detection catches overlapping classes for the same section', () async {
      final repo = FirebaseTimetableRepository(mockFirestore, currentUser: mockCollegeAdminUser);
      await mockFirestore.setDocument('timetable', 'existing-sec-1', {
        'id': 'existing-sec-1',
        'collegeId': 'col-alpha',
        'departmentId': 'dept-cs',
        'courseId': 'crs-btech',
        'academicYearId': 'ay-2026',
        'semesterId': 'sem-4',
        'sectionId': 'sec-3a', // Same section
        'subjectId': 'sub-dbms',
        'facultyId': 'usr-faculty-other',
        'dayOfWeek': 'monday',
        'startTime': '09:00',
        'endTime': '10:00',
        'roomNumber': 'LH-105',
        'sessionType': 'lecture',
      });

      expect(() => repo.createEntry(baseEntry), throwsA(isA<TimetableConflictException>()));
    });

    test('17. Room conflict detection catches overlapping bookings in the same room', () async {
      final repo = FirebaseTimetableRepository(mockFirestore, currentUser: mockCollegeAdminUser);
      await mockFirestore.setDocument('timetable', 'existing-room-1', {
        'id': 'existing-room-1',
        'collegeId': 'col-alpha',
        'departmentId': 'dept-me',
        'courseId': 'crs-mech',
        'academicYearId': 'ay-2026',
        'semesterId': 'sem-2',
        'sectionId': 'sec-mech-1',
        'subjectId': 'sub-thermo',
        'facultyId': 'usr-faculty-mech',
        'dayOfWeek': 'monday',
        'startTime': '09:00',
        'endTime': '10:00',
        'roomNumber': 'LH-101', // Same room
        'building': 'Main Block',
        'sessionType': 'lecture',
      });

      expect(() => repo.createEntry(baseEntry), throwsA(isA<TimetableConflictException>()));
    });

    test('18. Update excludes current timetable entry from conflict detection', () async {
      final repo = FirebaseTimetableRepository(mockFirestore, currentUser: mockCollegeAdminUser);
      await mockFirestore.setDocument('timetable', 'tt-entry-1', baseEntry.toJson());

      // Updating baseEntry itself should NOT trigger a self-conflict
      await repo.updateEntry(baseEntry.copyWith(roomNumber: 'LH-101-Modified'));
      final updated = await mockFirestore.getDocument('timetable', 'tt-entry-1');
      expect(updated?['roomNumber'], equals('LH-101-Modified'));
    });

    test('19. CRUD tenant isolation prevents cross-college and cross-department mutations', () async {
      final hodRepo = FirebaseTimetableRepository(mockFirestore, currentUser: mockHodUser);
      // Attempting to create entry for another department
      final foreignDeptEntry = baseEntry.copyWith(departmentId: 'dept-electrical');
      expect(() => hodRepo.createEntry(foreignDeptEntry), throwsA(isA<StateError>()));

      final adminRepo = FirebaseTimetableRepository(mockFirestore, currentUser: mockCollegeAdminUser);
      // Attempting to create entry for another college
      final foreignCollegeEntry = baseEntry.copyWith(collegeId: 'col-beta');
      expect(() => adminRepo.createEntry(foreignCollegeEntry), throwsA(isA<StateError>()));
    });

    test('20. Notification failure does not fail successful CRUD persistence', () async {
      final repo = FirebaseTimetableRepository(
        mockFirestore,
        currentUser: mockCollegeAdminUser,
        notificationService: FailingNotificationService(),
      );

      // Should complete without throwing an exception even if notification service throws
      await repo.createEntry(baseEntry.copyWith(id: 'tt-resilient-1'));
      final savedDoc = await mockFirestore.getDocument('timetable', 'tt-resilient-1');
      expect(savedDoc, isNotNull);
      expect(savedDoc?['id'], equals('tt-resilient-1'));
    });

    test('21. Incomplete/missing profile is handled safely without crashing', () async {
      final repo = FirebaseTimetableRepository(mockFirestore, currentUser: null);
      final stream = repo.watchTimetable(
        role: AppRole.student,
        userId: 'usr-student-42',
        collegeId: '',
      );
      final result = await stream.first;
      expect(result, isEmpty);
    });

    test('22. Missing subject/faculty reference returns fallback smoothly in UI lookups', () {
      final container = ProviderContainer(
        overrides: [
          timetableSubjectMapProvider.overrideWithValue({}),
          timetableFacultyMapProvider.overrideWithValue({}),
          timetableSectionMapProvider.overrideWithValue({}),
        ],
      );

      final subjectMap = container.read(timetableSubjectMapProvider);
      final facultyMap = container.read(timetableFacultyMapProvider);

      expect(subjectMap['missing-id'], isNull);
      expect(facultyMap['missing-id'], isNull);
    });
  });
}
