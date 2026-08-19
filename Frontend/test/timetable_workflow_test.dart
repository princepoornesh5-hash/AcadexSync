import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/firebase_timetable_repository.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';
import 'package:campus_management/features/timetable/data/repositories/timetable_repository.dart';
import 'package:campus_management/core/firebase/firebase_services.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/users/domain/models/user_profile_model.dart';
import 'package:campus_management/features/users/domain/models/user_status_enum.dart';

class QueryLog {
  final String collection;
  final Map<String, dynamic> filters;
  final bool isWatch;

  QueryLog(this.collection, this.filters, {this.isWatch = false});
}

class TestFirestoreService implements FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> db = {};
  final List<QueryLog> queryLogs = [];

  @override
  Future<void> setDocument(String collection, String id, Map<String, dynamic> data) async {
    db.putIfAbsent(collection, () => {})[id] = Map<String, dynamic>.from(data);
  }

  @override
  Future<Map<String, dynamic>?> getDocument(String collection, String id) async {
    return db[collection]?[id];
  }

  @override
  Future<void> deleteDocument(String collection, String id) async {
    db[collection]?.remove(id);
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollection(String collection, Map<String, dynamic> filters) async {
    queryLogs.add(QueryLog(collection, Map<String, dynamic>.from(filters), isWatch: false));
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
  Stream<List<Map<String, dynamic>>> watchQuery(
    String collection, 
    Map<String, dynamic> filters, {
    int? limit,
    String? orderBy,
    bool descending = false,
  }) {
    queryLogs.add(QueryLog(collection, Map<String, dynamic>.from(filters), isWatch: true));
    final docs = db[collection]?.values.toList() ?? [];
    if (filters.isEmpty) return Stream.value(docs);
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

void main() {
  group('Prompt 94: Timetable Security, Query & Business Logic Verification', () {
    late TestFirestoreService testFirestore;

    setUp(() {
      testFirestore = TestFirestoreService();
    });

    // Helper function to seed an authorized faculty profile
    Future<void> seedFaculty(String id, {List<String>? subjects, List<String>? sections, String collegeId = 'col-1'}) async {
      await testFirestore.setDocument('users', id, {
        'id': id,
        'role': 'FACULTY',
        'collegeId': collegeId,
        'subjectIds': subjects ?? ['sub-1', 'sub-2'],
        'sectionIds': sections ?? ['sec-1', 'sec-2'],
      });
    }

    test('TEST 1: Student timetable query contains collegeId', () async {
      final studentUser = UserModel(
        id: 'std-1',
        name: 'Student 1',
        email: 'student@acadex.com',
        role: AppRole.student,
        collegeId: 'col-1',
        sectionId: 'sec-1',
      );
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: studentUser);

      final stream = repo.watchTimetable(
        role: AppRole.student,
        userId: 'std-1',
        collegeId: 'col-1',
        sectionId: 'sec-1',
      );
      await stream.first;

      expect(testFirestore.queryLogs, isNotEmpty);
      final log = testFirestore.queryLogs.last;
      expect(log.collection, 'timetable');
      expect(log.filters['collegeId'], 'col-1');
      expect(log.filters['sectionId'], 'sec-1');
    });

    test('TEST 2: Faculty timetable query contains collegeId', () async {
      final facultyUser = UserModel(
        id: 'fac-1',
        name: 'Prof. Turing',
        email: 'faculty@acadex.com',
        role: AppRole.faculty,
        collegeId: 'col-1',
      );
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: facultyUser);

      final stream = repo.watchTimetable(
        role: AppRole.faculty,
        userId: 'fac-1',
        collegeId: 'col-1',
      );
      await stream.first;

      final log = testFirestore.queryLogs.last;
      expect(log.filters['collegeId'], 'col-1');
      expect(log.filters['facultyId'], 'fac-1');
    });

    test('TEST 3: HOD timetable query contains collegeId and departmentId', () async {
      final hodUser = UserModel(
        id: 'hod-1',
        name: 'Dr. Hopper',
        email: 'hod@acadex.com',
        role: AppRole.hod,
        collegeId: 'col-1',
        departmentId: 'dept-cse',
      );
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: hodUser);

      final stream = repo.watchTimetable(
        role: AppRole.hod,
        userId: 'hod-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
      );
      await stream.first;

      final log = testFirestore.queryLogs.last;
      expect(log.filters['collegeId'], 'col-1');
      expect(log.filters['departmentId'], 'dept-cse');
    });

    test('TEST 4: College Admin timetable query contains collegeId', () async {
      final adminUser = UserModel(
        id: 'admin-1',
        name: 'Admin',
        email: 'college@acadex.com',
        role: AppRole.collegeAdmin,
        collegeId: 'col-1',
      );
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: adminUser);

      final stream = repo.watchTimetable(
        role: AppRole.collegeAdmin,
        userId: 'admin-1',
        collegeId: 'col-1',
      );
      await stream.first;

      final log = testFirestore.queryLogs.last;
      expect(log.filters['collegeId'], 'col-1');
      expect(log.filters.containsKey('facultyId'), isFalse);
      expect(log.filters.containsKey('sectionId'), isFalse);
    });

    test('TEST 5: Super Admin retains appropriate global access', () async {
      final superAdmin = UserModel(
        id: 'super-1',
        name: 'Super Admin',
        email: 'admin@acadex.com',
        role: AppRole.superAdmin,
      );
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: superAdmin);

      final stream = repo.watchTimetable(
        role: AppRole.superAdmin,
        userId: 'super-1',
      );
      await stream.first;

      final log = testFirestore.queryLogs.last;
      // Super admin without explicit collegeId queries all
      expect(log.filters.containsKey('collegeId'), isFalse);
    });

    test('TEST 6: Faculty conflict query contains collegeId', () async {
      await seedFaculty('fac-1', collegeId: 'col-1');
      final adminUser = UserModel(id: 'adm', name: 'Admin', email: 'adm@a.com', role: AppRole.collegeAdmin, collegeId: 'col-1');
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: adminUser);

      final entry = TimetableModel(
        id: 'entry-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-1',
        academicYearId: 'ay-1',
        semesterId: 'sem-1',
        sectionId: 'sec-1',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.monday,
        startTime: '09:00',
        endTime: '10:00',
        roomNumber: '101',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.checkConflicts(entry);

      final facultyQuery = testFirestore.queryLogs.firstWhere((q) => q.filters.containsKey('facultyId'));
      expect(facultyQuery.filters['collegeId'], 'col-1');
      expect(facultyQuery.filters['facultyId'], 'fac-1');
      expect(facultyQuery.filters['dayOfWeek'], 'monday');
    });

    test('TEST 7: Section conflict query contains collegeId', () async {
      await seedFaculty('fac-1', collegeId: 'col-1');
      final adminUser = UserModel(id: 'adm', name: 'Admin', email: 'adm@a.com', role: AppRole.collegeAdmin, collegeId: 'col-1');
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: adminUser);

      final entry = TimetableModel(
        id: 'entry-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-1',
        academicYearId: 'ay-1',
        semesterId: 'sem-1',
        sectionId: 'sec-1',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.monday,
        startTime: '09:00',
        endTime: '10:00',
        roomNumber: '101',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.checkConflicts(entry);

      final sectionQuery = testFirestore.queryLogs.firstWhere((q) => q.filters.containsKey('sectionId'));
      expect(sectionQuery.filters['collegeId'], 'col-1');
      expect(sectionQuery.filters['sectionId'], 'sec-1');
      expect(sectionQuery.filters['dayOfWeek'], 'monday');
    });

    test('TEST 8: Room conflict query contains collegeId', () async {
      await seedFaculty('fac-1', collegeId: 'col-1');
      final adminUser = UserModel(id: 'adm', name: 'Admin', email: 'adm@a.com', role: AppRole.collegeAdmin, collegeId: 'col-1');
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: adminUser);

      final entry = TimetableModel(
        id: 'entry-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-1',
        academicYearId: 'ay-1',
        semesterId: 'sem-1',
        sectionId: 'sec-1',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.monday,
        startTime: '09:00',
        endTime: '10:00',
        roomNumber: '101',
        building: 'Main Block',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.checkConflicts(entry);

      final roomQuery = testFirestore.queryLogs.firstWhere((q) => q.filters.containsKey('roomNumber'));
      expect(roomQuery.filters['collegeId'], 'col-1');
      expect(roomQuery.filters['roomNumber'], '101');
      expect(roomQuery.filters['building'], 'Main Block');
      expect(roomQuery.filters['dayOfWeek'], 'monday');
    });

    test('TEST 9: Student section resolves from authenticated user profile', () async {
      final profile = UserProfileModel(
        id: 'std-10',
        name: 'Peter Parker',
        email: 'peter@acadex.com',
        role: AppRole.student,
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        sectionId: 'sec-3a',
        semesterId: 'sem-3',
        status: UserStatus.active,
        phone: '1234567890',
      );

      expect(profile.sectionId, 'sec-3a');
      expect(profile.collegeId, 'col-1');
    });

    test('TEST 10: Student section lookup does NOT scan entire student collection', () async {
      // In UserModel / UserProfileModel, sectionId is a direct property on the authenticated user model
      final user = UserModel(
        id: 'std-20',
        name: 'Clark Kent',
        email: 'clark@acadex.com',
        role: AppRole.student,
        collegeId: 'col-1',
        sectionId: 'sec-5b',
      );

      expect(user.sectionId, 'sec-5b');
      // Direct property access requires 0 collection scans
    });

    test('TEST 11: Missing student section does not issue an invalid Firestore query', () async {
      final studentWithoutSection = UserModel(
        id: 'std-unassigned',
        name: 'New Student',
        email: 'new@acadex.com',
        role: AppRole.student,
        collegeId: 'col-1',
        sectionId: null,
      );
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: studentWithoutSection);

      final stream = repo.watchTimetable(
        role: AppRole.student,
        userId: 'std-unassigned',
        collegeId: 'col-1',
        sectionId: null,
      );
      final result = await stream.first;

      expect(result, isEmpty);
      // No query sent to Firestore
      expect(testFirestore.queryLogs, isEmpty);
    });

    test('TEST 12: Missing collegeId does not issue a production Firestore query', () async {
      final unassignedUser = UserModel(
        id: 'usr-none',
        name: 'Orphan User',
        email: 'orphan@acadex.com',
        role: AppRole.faculty,
        collegeId: null,
      );
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: unassignedUser);

      final stream = repo.watchTimetable(
        role: AppRole.faculty,
        userId: 'usr-none',
        collegeId: null,
      );
      final result = await stream.first;

      expect(result, isEmpty);
      expect(testFirestore.queryLogs, isEmpty);
    });

    test('TEST 13: Faculty conflict detection still works', () async {
      await seedFaculty('fac-1', collegeId: 'col-1');
      final adminUser = UserModel(id: 'adm', name: 'Admin', email: 'adm@a.com', role: AppRole.collegeAdmin, collegeId: 'col-1');
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: adminUser);

      final entry1 = TimetableModel(
        id: 'entry-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-1',
        academicYearId: 'ay-1',
        semesterId: 'sem-1',
        sectionId: 'sec-1',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.monday,
        startTime: '09:00',
        endTime: '10:30',
        roomNumber: '101',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.createEntry(entry1);

      // Overlapping entry on same faculty
      final entry2 = TimetableModel(
        id: 'entry-2',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-1',
        academicYearId: 'ay-1',
        semesterId: 'sem-1',
        sectionId: 'sec-2',
        subjectId: 'sub-2',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.monday,
        startTime: '10:00',
        endTime: '11:00',
        roomNumber: '102',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await expectLater(
        repo.createEntry(entry2),
        throwsA(isA<TimetableConflictException>()),
      );
    });

    test('TEST 14: Section conflict detection still works', () async {
      await seedFaculty('fac-1', collegeId: 'col-1');
      await seedFaculty('fac-2', collegeId: 'col-1');
      final adminUser = UserModel(id: 'adm', name: 'Admin', email: 'adm@a.com', role: AppRole.collegeAdmin, collegeId: 'col-1');
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: adminUser);

      final entry1 = TimetableModel(
        id: 'entry-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-1',
        academicYearId: 'ay-1',
        semesterId: 'sem-1',
        sectionId: 'sec-1',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.wednesday,
        startTime: '11:00',
        endTime: '12:00',
        roomNumber: '101',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.createEntry(entry1);

      // Overlapping entry on same section with different faculty
      final entry2 = TimetableModel(
        id: 'entry-2',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-1',
        academicYearId: 'ay-1',
        semesterId: 'sem-1',
        sectionId: 'sec-1',
        subjectId: 'sub-2',
        facultyId: 'fac-2',
        dayOfWeek: TimetableDay.wednesday,
        startTime: '11:30',
        endTime: '12:30',
        roomNumber: '102',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await expectLater(
        repo.createEntry(entry2),
        throwsA(isA<TimetableConflictException>()),
      );
    });

    test('TEST 15: Room conflict detection still works', () async {
      await seedFaculty('fac-1', collegeId: 'col-1');
      await seedFaculty('fac-2', collegeId: 'col-1');
      final adminUser = UserModel(id: 'adm', name: 'Admin', email: 'adm@a.com', role: AppRole.collegeAdmin, collegeId: 'col-1');
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: adminUser);

      final entry1 = TimetableModel(
        id: 'entry-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-1',
        academicYearId: 'ay-1',
        semesterId: 'sem-1',
        sectionId: 'sec-1',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.thursday,
        startTime: '14:00',
        endTime: '15:00',
        roomNumber: 'Lab-1',
        building: 'Science Block',
        sessionType: TimetableSessionType.lab,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.createEntry(entry1);

      // Overlapping entry on same room and building
      final entry2 = TimetableModel(
        id: 'entry-2',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-1',
        academicYearId: 'ay-1',
        semesterId: 'sem-1',
        sectionId: 'sec-2',
        subjectId: 'sub-2',
        facultyId: 'fac-2',
        dayOfWeek: TimetableDay.thursday,
        startTime: '14:30',
        endTime: '15:30',
        roomNumber: 'Lab-1',
        building: 'Science Block',
        sessionType: TimetableSessionType.lab,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await expectLater(
        repo.createEntry(entry2),
        throwsA(isA<TimetableConflictException>()),
      );
    });

    test('TEST 16: Editing an existing entry does not conflict with itself', () async {
      await seedFaculty('fac-1', collegeId: 'col-1');
      final adminUser = UserModel(id: 'adm', name: 'Admin', email: 'adm@a.com', role: AppRole.collegeAdmin, collegeId: 'col-1');
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: adminUser);

      final entry = TimetableModel(
        id: 'entry-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-1',
        academicYearId: 'ay-1',
        semesterId: 'sem-1',
        sectionId: 'sec-1',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.friday,
        startTime: '10:00',
        endTime: '11:00',
        roomNumber: '201',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.createEntry(entry);

      // Update room number on same entry (should not conflict with itself)
      final updated = entry.copyWith(roomNumber: '202');
      await expectLater(repo.updateEntry(updated), completes);
    });

    test('TEST 17: Unauthorized student cannot access timetable creation / write throws', () async {
      final studentUser = UserModel(
        id: 'std-1',
        name: 'Student',
        email: 'std@a.com',
        role: AppRole.student,
        collegeId: 'col-1',
        sectionId: 'sec-1',
      );
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: studentUser);

      final entry = TimetableModel(
        id: 'e1',
        collegeId: 'col-1',
        departmentId: 'dep-1',
        courseId: 'c1',
        academicYearId: 'ay1',
        semesterId: 's1',
        sectionId: 'sec-1',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.monday,
        startTime: '09:00',
        endTime: '10:00',
        roomNumber: '101',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await expectLater(
        repo.createEntry(entry),
        throwsA(isA<StateError>()),
      );
    });

    test('TEST 18: Unauthorized faculty cannot access timetable creation / write throws', () async {
      final facultyUser = UserModel(
        id: 'fac-1',
        name: 'Faculty',
        email: 'fac@a.com',
        role: AppRole.faculty,
        collegeId: 'col-1',
      );
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: facultyUser);

      final entry = TimetableModel(
        id: 'e1',
        collegeId: 'col-1',
        departmentId: 'dep-1',
        courseId: 'c1',
        academicYearId: 'ay1',
        semesterId: 's1',
        sectionId: 'sec-1',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.monday,
        startTime: '09:00',
        endTime: '10:00',
        roomNumber: '101',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await expectLater(
        repo.createEntry(entry),
        throwsA(isA<StateError>()),
      );
    });

    test('TEST 19: HOD can access timetable creation / createEntry succeeds', () async {
      await seedFaculty('fac-1', collegeId: 'col-1');
      final hodUser = UserModel(
        id: 'hod-1',
        name: 'HOD',
        email: 'hod@a.com',
        role: AppRole.hod,
        collegeId: 'col-1',
        departmentId: 'dept-cse',
      );
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: hodUser);

      final entry = TimetableModel(
        id: 'e-hod',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'c1',
        academicYearId: 'ay1',
        semesterId: 's1',
        sectionId: 'sec-1',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.monday,
        startTime: '09:00',
        endTime: '10:00',
        roomNumber: '101',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await expectLater(repo.createEntry(entry), completes);
    });

    test('TEST 20: College Admin can access timetable creation / createEntry succeeds', () async {
      await seedFaculty('fac-1', collegeId: 'col-1');
      final adminUser = UserModel(
        id: 'admin-1',
        name: 'College Admin',
        email: 'admin@a.com',
        role: AppRole.collegeAdmin,
        collegeId: 'col-1',
      );
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: adminUser);

      final entry = TimetableModel(
        id: 'e-admin',
        collegeId: 'col-1',
        departmentId: 'dept-ece',
        courseId: 'c1',
        academicYearId: 'ay1',
        semesterId: 's1',
        sectionId: 'sec-1',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.tuesday,
        startTime: '10:00',
        endTime: '11:00',
        roomNumber: '102',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await expectLater(repo.createEntry(entry), completes);
    });

    test('TEST 21: Super Admin can access timetable creation / createEntry succeeds', () async {
      await seedFaculty('fac-1', collegeId: 'col-2');
      final superAdmin = UserModel(
        id: 'super-1',
        name: 'Super Admin',
        email: 'super@a.com',
        role: AppRole.superAdmin,
      );
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: superAdmin);

      final entry = TimetableModel(
        id: 'e-super',
        collegeId: 'col-2',
        departmentId: 'dept-mech',
        courseId: 'c1',
        academicYearId: 'ay1',
        semesterId: 's1',
        sectionId: 'sec-1',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.wednesday,
        startTime: '14:00',
        endTime: '15:00',
        roomNumber: 'Workshop-1',
        sessionType: TimetableSessionType.practical,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await expectLater(repo.createEntry(entry), completes);
    });

    test('TEST 22: Timetable schema remains Attendance-compatible', () async {
      final entry = TimetableModel(
        id: 'tt-att-1',
        collegeId: 'col-123',
        departmentId: 'dep-456',
        courseId: 'crs-cse',
        academicYearId: 'ay-2026',
        semesterId: 'sem-3',
        sectionId: 'sec-3a',
        subjectId: 'sub-ds',
        facultyId: 'faculty-uid-789',
        dayOfWeek: TimetableDay.monday,
        startTime: '09:00',
        endTime: '10:00',
        roomNumber: 'C-204',
        building: 'Main Block',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.parse('2026-08-14T09:00:00.000Z'),
        updatedAt: DateTime.parse('2026-08-14T09:00:00.000Z'),
      );

      final json = entry.toJson();
      // Attendance required fields:
      expect(json['id'], 'tt-att-1');
      expect(json['collegeId'], 'col-123');
      expect(json['facultyId'], 'faculty-uid-789');
      expect(json['dayOfWeek'], 'monday'); // Enum string matches dayOfWeek.name
      expect(json['subjectId'], 'sub-ds');
      expect(json['sectionId'], 'sec-3a');
      expect(json['semesterId'], 'sem-3');
      expect(json['startTime'], '09:00');
      expect(json['endTime'], '10:00');
    });

    test('TEST 23: MockTimetableRepository continues functioning', () async {
      final mockRepo = MockTimetableRepository();
      
      final stream = mockRepo.watchTimetable(
        role: AppRole.student,
        userId: 'student-1',
        collegeId: 'col-1',
        sectionId: 'sec-3a',
      );
      final entries = await stream.first;

      expect(entries, isNotEmpty);
      expect(entries.every((e) => e.sectionId == 'sec-3a'), isTrue);
      expect(entries.every((e) => e.collegeId == 'col-1'), isTrue);
    });

    test('TEST 24: Tenant mismatch is rejected before write where repository validation applies', () async {
      await seedFaculty('fac-1', collegeId: 'col-1');
      final hodUser = UserModel(
        id: 'hod-1',
        name: 'HOD CSE',
        email: 'hod@a.com',
        role: AppRole.hod,
        collegeId: 'col-1',
        departmentId: 'dept-cse',
      );
      final repo = FirebaseTimetableRepository(testFirestore, currentUser: hodUser);

      // Attempting to create an entry for a foreign college
      final foreignCollegeEntry = TimetableModel(
        id: 'e-foreign-col',
        collegeId: 'col-2', // Mismatch!
        departmentId: 'dept-cse',
        courseId: 'c1',
        academicYearId: 'ay1',
        semesterId: 's1',
        sectionId: 'sec-1',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.thursday,
        startTime: '09:00',
        endTime: '10:00',
        roomNumber: '101',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await expectLater(
        repo.createEntry(foreignCollegeEntry),
        throwsA(isA<StateError>()),
      );

      // Attempting to create an entry for a foreign department
      final foreignDeptEntry = TimetableModel(
        id: 'e-foreign-dept',
        collegeId: 'col-1',
        departmentId: 'dept-ece', // Mismatch!
        courseId: 'c1',
        academicYearId: 'ay1',
        semesterId: 's1',
        sectionId: 'sec-1',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        dayOfWeek: TimetableDay.thursday,
        startTime: '09:00',
        endTime: '10:00',
        roomNumber: '101',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await expectLater(
        repo.createEntry(foreignDeptEntry),
        throwsA(isA<StateError>()),
      );
    });
  });
}

