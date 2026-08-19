import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/firebase/firebase_services.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/timetable_repository.dart';
import 'package:campus_management/features/timetable/data/repositories/firebase_timetable_repository.dart';

class AuthoringMockFirestoreService implements FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> db = {};

  @override
  Future<void> setDocument(String collection, String id, Map<String, dynamic> data) async {
    db.putIfAbsent(collection, () => {})[id] = data;
  }

  @override
  Future<void> batchSetDocuments(Map<String, Map<String, dynamic>> documentPathToDataMap) async {
    for (final entry in documentPathToDataMap.entries) {
      final parts = entry.key.split('/');
      if (parts.length >= 2) {
        final collection = parts.sublist(0, parts.length - 1).join('/');
        final docId = parts.last;
        db.putIfAbsent(collection, () => {})[docId] = entry.value;
      }
    }
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
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    return db[collection]?.values.toList() ?? [];
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollection(String collection, Map<String, dynamic> filters, {String? orderBy, bool descending = false, int? limit}) async {
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
  Stream<Map<String, dynamic>?> watchDocument(String collection, String id) {
    return Stream.value(db[collection]?[id]);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchCollection(String collection) {
    return Stream.value(db[collection]?.values.toList() ?? []);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchQuery(String collection, Map<String, dynamic> filters, {String? orderBy, bool descending = false, int? limit}) {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ACADEX Phase 3: Firebase Authoring Architecture & Security Tests', () {
    late AuthoringMockFirestoreService firestoreService;

    // Users
    final superAdminUser = UserModel(
      id: 'usr-super-admin',
      name: 'Super Admin',
      email: 'super@acadex.edu',
      role: AppRole.superAdmin,
    );

    final collegeAdminUser = UserModel(
      id: 'usr-ca-1',
      name: 'College Admin',
      email: 'admin@col1.edu',
      role: AppRole.collegeAdmin,
      collegeId: 'col-1',
    );

    final hodCseUser = UserModel(
      id: 'usr-hod-cse',
      name: 'HOD CSE',
      email: 'hod.cse@col1.edu',
      role: AppRole.hod,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    final facultyNormalUser = UserModel(
      id: 'usr-fac-normal',
      name: 'Normal Faculty',
      email: 'fac.normal@col1.edu',
      role: AppRole.faculty,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    final facultyDelegatedUser = UserModel(
      id: 'usr-fac-delegated',
      name: 'Senior Timetable Coordinator',
      email: 'fac.coord@col1.edu',
      role: AppRole.faculty,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    final studentUser = UserModel(
      id: 'usr-student-1',
      name: 'Student One',
      email: 'student@col1.edu',
      role: AppRole.student,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
      sectionId: 'sec-4a',
    );

    setUp(() async {
      firestoreService = AuthoringMockFirestoreService();

      // Seed Users into Firestore
      await firestoreService.setDocument('users', superAdminUser.id, superAdminUser.toJson());
      await firestoreService.setDocument('users', collegeAdminUser.id, collegeAdminUser.toJson());
      await firestoreService.setDocument('users', hodCseUser.id, hodCseUser.toJson());
      await firestoreService.setDocument('users', facultyNormalUser.id, facultyNormalUser.toJson());
      
      final delegatedJson = facultyDelegatedUser.toJson();
      delegatedJson['canManageTimetable'] = true;
      delegatedJson['isTimetableCoordinator'] = true;
      await firestoreService.setDocument('users', facultyDelegatedUser.id, delegatedJson);

      await firestoreService.setDocument('users', studentUser.id, studentUser.toJson());
    });

    // Helper to create test container
    TimetableContainerModel createSampleContainer({
      String id = 'tt-cont-cse-4a',
      String collegeId = 'col-1',
      String departmentId = 'dept-cse',
      String sectionId = 'sec-4a',
    }) {
      final now = DateTime.now();
      return TimetableContainerModel(
        id: id,
        collegeId: collegeId,
        departmentId: departmentId,
        courseId: 'crs-btech-cse',
        academicYearId: 'ay-2026',
        semesterId: 'sem-4',
        sectionId: sectionId,
        name: 'B.Tech CSE Sem 4 Sec A',
        status: TimetableStatus.draft,
        version: 1,
        activeDays: [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday, TimetableDay.thursday, TimetableDay.friday],
        timingMode: TimetableTimingMode.sameEveryDay,
        createdAt: now,
        updatedAt: now,
      );
    }

    // =========================================================================
    // 1. Role-Based Management & Security
    // =========================================================================
    group('1. Role-Based Permissions & Tenant Isolation', () {
      test('1. HOD can create timetable container for their own department', () async {
        final repo = FirebaseTimetableRepository(firestoreService, currentUser: hodCseUser);
        final container = createSampleContainer();

        await repo.createTimetableContainer(container);
        final saved = await repo.getTimetableContainer(container.id);

        expect(saved, isNotNull);
        expect(saved!.id, container.id);
        expect(saved.departmentId, 'dept-cse');
        expect(saved.isDraft, isTrue);
      });

      test('2. HOD is REJECTED when attempting to create timetable for another department', () async {
        final repo = FirebaseTimetableRepository(firestoreService, currentUser: hodCseUser);
        final foreignDeptContainer = createSampleContainer(
          id: 'tt-cont-ece-4a',
          departmentId: 'dept-ece',
        );

        expect(
          () => repo.createTimetableContainer(foreignDeptContainer),
          throwsA(isA<StateError>()),
        );
      });

      test('3. College Admin can manage timetables across all departments in their college', () async {
        final repo = FirebaseTimetableRepository(firestoreService, currentUser: collegeAdminUser);
        final eceContainer = createSampleContainer(
          id: 'tt-cont-ece',
          departmentId: 'dept-ece',
        );

        await repo.createTimetableContainer(eceContainer);
        final saved = await repo.getTimetableContainer('tt-cont-ece');
        expect(saved, isNotNull);
        expect(saved!.departmentId, 'dept-ece');
      });

      test('4. College Admin is REJECTED when creating timetable for another college (Tenant Isolation)', () async {
        final repo = FirebaseTimetableRepository(firestoreService, currentUser: collegeAdminUser);
        final foreignCollegeContainer = createSampleContainer(
          id: 'tt-cont-col2',
          collegeId: 'col-2',
        );

        expect(
          () => repo.createTimetableContainer(foreignCollegeContainer),
          throwsA(isA<StateError>()),
        );
      });

      test('5. Normal Faculty cannot create or update timetable containers', () async {
        final repo = FirebaseTimetableRepository(firestoreService, currentUser: facultyNormalUser);
        final container = createSampleContainer();

        expect(
          () => repo.createTimetableContainer(container),
          throwsA(isA<StateError>()),
        );
      });

      test('6. Delegated Senior Faculty (Coordinator) can manage timetables in their department', () async {
        final repo = FirebaseTimetableRepository(firestoreService, currentUser: facultyDelegatedUser);
        final container = createSampleContainer(id: 'tt-cont-delegated');

        await repo.createTimetableContainer(container);
        final saved = await repo.getTimetableContainer('tt-cont-delegated');
        expect(saved, isNotNull);
        expect(saved!.name, container.name);
      });

      test('7. Student cannot create or manage timetable containers', () async {
        final repo = FirebaseTimetableRepository(firestoreService, currentUser: studentUser);
        final container = createSampleContainer();

        expect(
          () => repo.createTimetableContainer(container),
          throwsA(isA<StateError>()),
        );
      });
    });

    // =========================================================================
    // 2. Subcollections: Periods, Breaks, Grid Entries CRUD & Batch
    // =========================================================================
    group('2. Subcollections CRUD and Batch Operations', () {
      late FirebaseTimetableRepository repo;
      const ttId = 'tt-test-subcollections';

      setUp(() async {
        repo = FirebaseTimetableRepository(firestoreService, currentUser: hodCseUser);
        await repo.createTimetableContainer(createSampleContainer(id: ttId));
      });

      test('8. Periods Batch write and retrieval in order', () async {
        final periods = [
          TimetablePeriodModel(id: 'p-1', index: 1, name: 'P1', startTime: '09:00', endTime: '10:00'),
          TimetablePeriodModel(id: 'p-2', index: 2, name: 'P2', startTime: '10:00', endTime: '11:00'),
          TimetablePeriodModel(id: 'p-3', index: 3, name: 'P3', startTime: '11:15', endTime: '12:15'),
        ];

        await repo.savePeriodsBatch(ttId, periods);

        final loaded = await repo.getPeriods(ttId);
        expect(loaded.length, 3);
        expect(loaded[0].index, 1);
        expect(loaded[1].index, 2);
        expect(loaded[2].index, 3);

        // Delete single period
        await repo.deletePeriod(ttId, 'p-2');
        final remaining = await repo.getPeriods(ttId);
        expect(remaining.length, 2);
        expect(remaining.any((p) => p.id == 'p-2'), isFalse);
      });

      test('9. Breaks Batch write, retrieval and deletion', () async {
        final breaks = [
          TimetableBreakModel(
            id: 'b-tea',
            name: 'Tea Break',
            startTime: '11:00',
            endTime: '11:15',
            appliesToDays: [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday],
            breakType: TimetableBreakType.tea,
          ),
          TimetableBreakModel(
            id: 'b-lunch',
            name: 'Lunch Break',
            startTime: '13:00',
            endTime: '14:00',
            appliesToDays: [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday, TimetableDay.thursday, TimetableDay.friday],
            breakType: TimetableBreakType.lunch,
          ),
        ];

        await repo.saveBreaksBatch(ttId, breaks);

        final loaded = await repo.getBreaks(ttId);
        expect(loaded.length, 2);
        expect(loaded.any((b) => b.name == 'Tea Break'), isTrue);
        expect(loaded.any((b) => b.name == 'Lunch Break'), isTrue);
      });

      test('10. Grid Entries Batch write and retrieval', () async {
        final entries = [
          TimetableGridEntryModel(
            id: 'e-1',
            dayOfWeek: TimetableDay.monday,
            startPeriodIndex: 1,
            periodSpan: 1,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: 'sub-dsa',
            facultyId: 'usr-fac-normal',
            roomNumber: 'LH-1',
            sessionType: TimetableSessionType.lecture,
          ),
          TimetableGridEntryModel(
            id: 'e-2',
            dayOfWeek: TimetableDay.monday,
            startPeriodIndex: 2,
            periodSpan: 2, // Merged Lab (P2 & P3)
            startTime: '10:00',
            endTime: '12:15',
            subjectId: 'sub-dsa-lab',
            facultyId: 'usr-fac-delegated',
            roomNumber: 'Lab-1',
            sessionType: TimetableSessionType.lab,
          ),
        ];

        await repo.saveGridEntriesBatch(ttId, entries);

        final loaded = await repo.getGridEntries(ttId);
        expect(loaded.length, 2);
        expect(loaded.firstWhere((e) => e.id == 'e-2').isMergedHorizontal, isTrue);
        expect(loaded.firstWhere((e) => e.id == 'e-2').endPeriodIndex, 3);
      });
    });

    // =========================================================================
    // 3. Publishing Architecture, Conflict Checks & Projection
    // =========================================================================
    group('3. Publishing Architecture, Conflict Checks & Legacy /timetable Projection', () {
      late FirebaseTimetableRepository repo;
      const ttId = 'tt-publish-test';

      setUp(() async {
        repo = FirebaseTimetableRepository(firestoreService, currentUser: hodCseUser);
        await repo.createTimetableContainer(createSampleContainer(id: ttId));

        // Setup base periods
        await repo.savePeriodsBatch(ttId, [
          TimetablePeriodModel(id: 'p-1', index: 1, name: 'P1', startTime: '09:00', endTime: '10:00'),
          TimetablePeriodModel(id: 'p-2', index: 2, name: 'P2', startTime: '10:00', endTime: '11:00'),
          TimetablePeriodModel(id: 'p-3', index: 3, name: 'P3', startTime: '11:15', endTime: '12:15'),
          TimetablePeriodModel(id: 'p-4', index: 4, name: 'P4', startTime: '12:15', endTime: '13:15'),
        ]);

        // Setup base breaks
        await repo.saveBreaksBatch(ttId, [
          TimetableBreakModel(
            id: 'brk-tea',
            name: 'Tea Break',
            startTime: '11:00',
            endTime: '11:15',
            appliesToDays: [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday, TimetableDay.thursday, TimetableDay.friday],
            breakType: TimetableBreakType.tea,
          ),
          TimetableBreakModel(
            id: 'brk-lunch',
            name: 'Lunch Break',
            startTime: '13:15',
            endTime: '14:15',
            appliesToDays: [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday, TimetableDay.thursday, TimetableDay.friday],
            breakType: TimetableBreakType.lunch,
          ),
        ]);
      });

      test('11. Draft data isolation: Draft container data does NOT enter /timetable collection', () async {
        await repo.saveGridEntry(ttId, TimetableGridEntryModel(
          id: 'draft-entry-1',
          dayOfWeek: TimetableDay.monday,
          startPeriodIndex: 1,
          periodSpan: 1,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: 'sub-dsa',
          facultyId: 'usr-fac-normal',
          roomNumber: 'LH-1',
          sessionType: TimetableSessionType.lecture,
        ));

        // Direct query legacy collection /timetable
        final legacyDocs = await firestoreService.getCollection('timetable');
        expect(legacyDocs.any((d) => d['id'] == 'pub_${ttId}_draft-entry-1'), isFalse);
      });

      test('12. Conflict rejection: Faculty conflict on same timeslot blocks publishing', () async {
        await repo.saveGridEntriesBatch(ttId, [
          TimetableGridEntryModel(
            id: 'e-1',
            dayOfWeek: TimetableDay.monday,
            startPeriodIndex: 1,
            periodSpan: 1,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: 'sub-dsa',
            facultyId: 'usr-fac-normal',
            roomNumber: 'LH-1',
            sessionType: TimetableSessionType.lecture,
          ),
          TimetableGridEntryModel(
            id: 'e-2',
            dayOfWeek: TimetableDay.monday,
            startPeriodIndex: 1,
            periodSpan: 1,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: 'sub-os',
            facultyId: 'usr-fac-normal', // Same faculty, same period
            roomNumber: 'LH-2',
            sessionType: TimetableSessionType.lecture,
          ),
        ]);

        expect(
          () => repo.publishTimetable(ttId, publishedBy: hodCseUser.id),
          throwsA(isA<TimetableConflictException>()),
        );

        // Verify timetable remains in draft status and NOT published
        final container = await repo.getTimetableContainer(ttId);
        expect(container!.isDraft, isTrue);
        expect(container.isPublished, isFalse);
      });

      test('13. Conflict rejection: Class overlapping with a Break blocks publishing', () async {
        // Break is 11:00 - 11:15
        await repo.saveGridEntry(ttId, TimetableGridEntryModel(
          id: 'e-break-overlap',
          dayOfWeek: TimetableDay.monday,
          startPeriodIndex: 2,
          periodSpan: 1,
          startTime: '10:30',
          endTime: '11:15', // Overlaps Tea Break
          subjectId: 'sub-dsa',
          facultyId: 'usr-fac-normal',
          roomNumber: 'LH-1',
          sessionType: TimetableSessionType.lecture,
        ));

        expect(
          () => repo.publishTimetable(ttId, publishedBy: hodCseUser.id),
          throwsA(isA<TimetableConflictException>()),
        );
      });

      test('14. Successful Publishing: Atomic conversion to /timetable with 100% Attendance fields & breaks excluded', () async {
        await repo.saveGridEntriesBatch(ttId, [
          TimetableGridEntryModel(
            id: 'e-lecture-1',
            dayOfWeek: TimetableDay.monday,
            startPeriodIndex: 1,
            periodSpan: 1,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: 'sub-dsa',
            facultyId: 'usr-fac-normal',
            roomNumber: 'LH-101',
            building: 'Main Block',
            sessionType: TimetableSessionType.lecture,
          ),
          TimetableGridEntryModel(
            id: 'e-lab-1',
            dayOfWeek: TimetableDay.monday,
            startPeriodIndex: 3,
            periodSpan: 2, // Merged Lab: Periods 3 & 4 (11:15 - 13:15)
            startTime: '11:15',
            endTime: '13:15',
            subjectId: 'sub-os-lab',
            facultyId: 'usr-fac-delegated',
            roomNumber: 'Lab-202',
            building: 'Tech Block',
            sessionType: TimetableSessionType.lab,
          ),
        ]);

        await repo.publishTimetable(ttId, publishedBy: hodCseUser.id);

        // 1. Container status updated to published
        final publishedContainer = await repo.getTimetableContainer(ttId);
        expect(publishedContainer!.isPublished, isTrue);
        expect(publishedContainer.publishedBy, hodCseUser.id);
        expect(publishedContainer.version, 2);

        // 2. Projected legacy documents in /timetable
        final legacyDocs = await firestoreService.getCollection('timetable');
        expect(legacyDocs.length, 2);

        // Breaks must NEVER be projected to /timetable
        expect(legacyDocs.any((d) => d['subjectId'] == 'Tea Break'), isFalse);
        expect(legacyDocs.any((d) => d['subjectId'] == 'Lunch Break'), isFalse);

        // Check Lecture projection and all Attendance required fields
        final lectureDoc = legacyDocs.firstWhere((d) => d['id'] == 'pub_${ttId}_e-lecture-1');
        expect(lectureDoc['collegeId'], 'col-1');
        expect(lectureDoc['departmentId'], 'dept-cse');
        expect(lectureDoc['courseId'], 'crs-btech-cse');
        expect(lectureDoc['academicYearId'], 'ay-2026');
        expect(lectureDoc['semesterId'], 'sem-4');
        expect(lectureDoc['sectionId'], 'sec-4a');
        expect(lectureDoc['subjectId'], 'sub-dsa');
        expect(lectureDoc['facultyId'], 'usr-fac-normal');
        expect(lectureDoc['dayOfWeek'], 'monday');
        expect(lectureDoc['startTime'], '09:00');
        expect(lectureDoc['endTime'], '10:00');
        expect(lectureDoc['roomNumber'], 'LH-101');
        expect(lectureDoc['building'], 'Main Block');
        expect(lectureDoc['sessionType'], 'lecture');

        // Check Merged Lab projection
        final labDoc = legacyDocs.firstWhere((d) => d['id'] == 'pub_${ttId}_e-lab-1');
        expect(labDoc['startTime'], '11:15');
        expect(labDoc['endTime'], '13:15');
        expect(labDoc['sessionType'], 'lab');
      });

      test('15. Republish / Version increment behavior', () async {
        await repo.saveGridEntry(ttId, TimetableGridEntryModel(
          id: 'e-1',
          dayOfWeek: TimetableDay.tuesday,
          startPeriodIndex: 1,
          periodSpan: 1,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: 'sub-dsa',
          facultyId: 'usr-fac-normal',
          roomNumber: 'LH-1',
          sessionType: TimetableSessionType.lecture,
        ));

        // First publish -> version 2
        await repo.publishTimetable(ttId, publishedBy: hodCseUser.id);
        var container = await repo.getTimetableContainer(ttId);
        expect(container!.version, 2);

        // Update entry and republish -> version 3
        await repo.saveGridEntry(ttId, TimetableGridEntryModel(
          id: 'e-1',
          dayOfWeek: TimetableDay.tuesday,
          startPeriodIndex: 1,
          periodSpan: 1,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: 'sub-advanced-algo',
          facultyId: 'usr-fac-normal',
          roomNumber: 'LH-102',
          sessionType: TimetableSessionType.lecture,
        ));

        await repo.publishTimetable(ttId, publishedBy: hodCseUser.id);
        container = await repo.getTimetableContainer(ttId);
        expect(container!.version, 3);

        final legacyDocs = await firestoreService.getCollection('timetable');
        final projected = legacyDocs.firstWhere((d) => d['id'] == 'pub_${ttId}_e-1');
        expect(projected['subjectId'], 'sub-advanced-algo');
      });

      test('16. Unpublish reverts container to draft and clears /timetable projection', () async {
        await repo.saveGridEntry(ttId, TimetableGridEntryModel(
          id: 'e-1',
          dayOfWeek: TimetableDay.wednesday,
          startPeriodIndex: 1,
          periodSpan: 1,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: 'sub-dbms',
          facultyId: 'usr-fac-normal',
          roomNumber: 'LH-1',
          sessionType: TimetableSessionType.lecture,
        ));

        await repo.publishTimetable(ttId, publishedBy: hodCseUser.id);
        expect((await repo.getTimetableContainer(ttId))!.isPublished, isTrue);

        await repo.unpublishTimetable(ttId);
        final reverted = await repo.getTimetableContainer(ttId);
        expect(reverted!.isDraft, isTrue);
        expect(reverted.isPublished, isFalse);

        final legacyDocs = await firestoreService.getCollection('timetable');
        expect(legacyDocs.any((d) => d['id'] == 'pub_${ttId}_e-1'), isFalse);
      });
    });
  });
}
