import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_status.dart';
import 'package:campus_management/features/attendance/data/repositories/firebase_attendance_repository.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/firebase_timetable_repository.dart';
import 'package:campus_management/core/firebase/firebase_services.dart';

class FakeFirestoreService implements FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> _db = {};

  @override
  Future<void> setDocument(String collection, String id, Map<String, dynamic> data) async {
    _db.putIfAbsent(collection, () => {})[id] = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> batchSetDocuments(Map<String, Map<String, dynamic>> documentPathToDataMap) async {
    for (final entry in documentPathToDataMap.entries) {
      final parts = entry.key.split('/');
      if (parts.length >= 2) {
        final collection = parts.sublist(0, parts.length - 1).join('/');
        final docId = parts.last;
        _db.putIfAbsent(collection, () => {})[docId] = Map<String, dynamic>.from(entry.value);
      }
    }
  }

  @override
  Future<Map<String, dynamic>?> getDocument(String collection, String id) async {
    return _db[collection]?[id];
  }

  @override
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    return _db[collection]?.values.toList() ?? [];
  }

  @override
  Future<void> deleteDocument(String collection, String id) async {
    _db[collection]?.remove(id);
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollection(String collection, Map<String, dynamic> filters) async {
    final docs = _db[collection]?.values.toList() ?? [];
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
    return Stream.value(_db[collection]?[id]);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchQuery(
    String collection,
    Map<String, dynamic> filters, {
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    return Stream.value(_db[collection]?.values.toList() ?? []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ACADEX Phase 6: Timetable → Attendance End-to-End Integration Tests', () {
    late FakeFirestoreService fakeFirestore;

    final facultyAlan = UserModel(
      id: 'fac-alan',
      name: 'Dr. Alan Turing',
      email: 'alan@git.edu',
      role: AppRole.faculty,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    final facultyGrace = UserModel(
      id: 'fac-grace',
      name: 'Dr. Grace Hopper',
      email: 'grace@git.edu',
      role: AppRole.faculty,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    final hodCse = UserModel(
      id: 'usr-hod',
      name: 'HOD CSE',
      email: 'hod@git.edu',
      role: AppRole.hod,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    final testContainer = TimetableContainerModel(
      id: 'tt-cs4-a',
      collegeId: 'col-1',
      departmentId: 'dept-cse',
      courseId: 'crs-btech',
      academicYearId: 'ay-2026',
      semesterId: 'sem-4',
      sectionId: 'sec-4a',
      name: 'CSE Sem 4 Sec A',
      status: TimetableStatus.draft,
      version: 1,
      activeDays: [
        TimetableDay.monday,
        TimetableDay.tuesday,
        TimetableDay.wednesday,
        TimetableDay.thursday,
        TimetableDay.friday,
      ],
      timingMode: TimetableTimingMode.sameEveryDay,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final testPeriods = [
      TimetablePeriodModel(id: 'p1', index: 1, name: 'Period 1', startTime: '09:00', endTime: '10:00'),
      TimetablePeriodModel(id: 'p2', index: 2, name: 'Period 2', startTime: '10:00', endTime: '11:00'),
      TimetablePeriodModel(id: 'p3', index: 3, name: 'Period 3', startTime: '11:00', endTime: '12:00'),
      TimetablePeriodModel(id: 'p4', index: 4, name: 'Period 4', startTime: '13:00', endTime: '14:00'),
      TimetablePeriodModel(id: 'p5', index: 5, name: 'Period 5', startTime: '14:00', endTime: '15:00'),
      TimetablePeriodModel(id: 'p6', index: 6, name: 'Period 6', startTime: '15:00', endTime: '16:00'),
    ];

    final testBreaks = [
      TimetableBreakModel(
        id: 'brk-lunch',
        name: 'Lunch Break',
        breakType: TimetableBreakType.lunch,
        startTime: '12:00',
        endTime: '13:00',
        appliesToDays: [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday],
      ),
    ];

    final testEntries = [
      // Alan: DBMS Monday P1 (09:00 - 10:00)
      TimetableGridEntryModel(
        id: 'e-dbms',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'sub-dbms',
        facultyId: 'fac-alan',
        roomNumber: 'LH-101',
        building: 'CS Block',
        sessionType: TimetableSessionType.lecture,
      ),
      // Grace: OS Lab Monday P2+P3 (10:00 - 12:00) - Merged 2 periods
      TimetableGridEntryModel(
        id: 'e-os-lab',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 2,
        periodSpan: 2,
        startTime: '10:00',
        endTime: '12:00',
        subjectId: 'sub-os-lab',
        facultyId: 'fac-grace',
        roomNumber: 'Lab-201',
        building: 'CS Block',
        sessionType: TimetableSessionType.lab,
      ),
      // Alan: DBMS Lab Monday P5+P6 (14:00 - 16:00) - Same subject later in day
      TimetableGridEntryModel(
        id: 'e-dbms-lab',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 5,
        periodSpan: 2,
        startTime: '14:00',
        endTime: '16:00',
        subjectId: 'sub-dbms',
        facultyId: 'fac-alan',
        roomNumber: 'Lab-202',
        building: 'CS Block',
        sessionType: TimetableSessionType.practical,
      ),
    ];

    setUp(() async {
      fakeFirestore = FakeFirestoreService();

      // Seed Subjects and Sections
      await fakeFirestore.setDocument('subjects', 'sub-dbms', {
        'id': 'sub-dbms',
        'name': 'Database Management Systems',
        'code': 'CS201',
      });
      await fakeFirestore.setDocument('subjects', 'sub-os-lab', {
        'id': 'sub-os-lab',
        'name': 'Operating Systems Laboratory',
        'code': 'CS202L',
      });
      await fakeFirestore.setDocument('sections', 'sec-4a', {
        'id': 'sec-4a',
        'name': 'Section 4-A',
      });

      // Seed Students in sec-4a
      await fakeFirestore.setDocument('students', 'std-1', {
        'id': 'std-1',
        'name': 'John von Neumann',
        'rollNumber': 'CS2026001',
        'sectionId': 'sec-4a',
        'collegeId': 'col-1',
        'isActive': true,
      });
      await fakeFirestore.setDocument('students', 'std-2', {
        'id': 'std-2',
        'name': 'Claude Shannon',
        'rollNumber': 'CS2026002',
        'sectionId': 'sec-4a',
        'collegeId': 'col-1',
        'isActive': true,
      });
    });

    // =========================================================================
    // 1. DRAFT ISOLATION & PUBLISH FLOW
    // =========================================================================
    test('1. Draft timetable does not appear in attendance until published', () async {
      final ttRepo = FirebaseTimetableRepository(fakeFirestore, currentUser: hodCse);
      final attRepo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);

      // Create draft container with entries
      await ttRepo.createTimetableContainer(testContainer);
      await ttRepo.savePeriodsBatch(testContainer.id, testPeriods);
      await ttRepo.saveBreaksBatch(testContainer.id, testBreaks);
      await ttRepo.saveGridEntriesBatch(testContainer.id, testEntries);

      final monday = DateTime(2026, 8, 17); // A Monday

      // Before publish -> Faculty Alan sees 0 classes
      var classes = await attRepo.getAssignedClasses(facultyAlan.id, monday);
      expect(classes.isEmpty, isTrue);

      // Publish Timetable
      await ttRepo.publishTimetable(testContainer.id, publishedBy: hodCse.id);

      // After publish -> Faculty Alan sees 2 scheduled classes (DBMS lecture & DBMS lab)
      classes = await attRepo.getAssignedClasses(facultyAlan.id, monday);
      expect(classes.length, equals(2));
      expect(classes[0].subjectName, equals('Database Management Systems'));
      expect(classes[0].timeSlot, equals('09:00 - 10:00'));
      expect(classes[0].roomNumber, equals('LH-101'));
      expect(classes[0].timetableEntryId, equals('pub_tt-cs4-a_e-dbms'));

      expect(classes[1].subjectName, equals('Database Management Systems'));
      expect(classes[1].timeSlot, equals('14:00 - 16:00'));
      expect(classes[1].roomNumber, equals('Lab-202'));
      expect(classes[1].timetableEntryId, equals('pub_tt-cs4-a_e-dbms-lab'));
    });

    // =========================================================================
    // 2. CHRONOLOGICAL SORTING & EXCLUSIONS
    // =========================================================================
    test('2. Classes are chronologically sorted and breaks are strictly excluded', () async {
      final ttRepo = FirebaseTimetableRepository(fakeFirestore, currentUser: hodCse);
      final attRepo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);

      await ttRepo.createTimetableContainer(testContainer);
      await ttRepo.savePeriodsBatch(testContainer.id, testPeriods);
      await ttRepo.saveBreaksBatch(testContainer.id, testBreaks);
      await ttRepo.saveGridEntriesBatch(testContainer.id, testEntries);
      await ttRepo.publishTimetable(testContainer.id, publishedBy: hodCse.id);

      final monday = DateTime(2026, 8, 17);
      final classes = await attRepo.getAssignedClasses(facultyAlan.id, monday);

      // Chronological order: 09:00 comes before 14:00
      expect(classes[0].startTime, equals('09:00'));
      expect(classes[1].startTime, equals('14:00'));

      // No breaks present in assigned classes
      expect(classes.any((c) => c.subjectName.contains('Lunch') || c.subjectId.contains('brk')), isFalse);
    });

    // =========================================================================
    // 3. FACULTY SCOPE & TENANT ISOLATION
    // =========================================================================
    test('3. Faculty receives only their own classes and tenant isolation is enforced', () async {
      final ttRepo = FirebaseTimetableRepository(fakeFirestore, currentUser: hodCse);
      final alanAttRepo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);
      final graceAttRepo = FirebaseAttendanceRepository(fakeFirestore, facultyGrace);

      await ttRepo.createTimetableContainer(testContainer);
      await ttRepo.savePeriodsBatch(testContainer.id, testPeriods);
      await ttRepo.saveBreaksBatch(testContainer.id, testBreaks);
      await ttRepo.saveGridEntriesBatch(testContainer.id, testEntries);
      await ttRepo.publishTimetable(testContainer.id, publishedBy: hodCse.id);

      final monday = DateTime(2026, 8, 17);

      // Alan has 2 classes
      final alanClasses = await alanAttRepo.getAssignedClasses(facultyAlan.id, monday);
      expect(alanClasses.length, equals(2));
      expect(alanClasses.every((c) => c.facultyId == 'fac-alan'), isTrue);

      // Grace has 1 class (OS Lab)
      final graceClasses = await graceAttRepo.getAssignedClasses(facultyGrace.id, monday);
      expect(graceClasses.length, equals(1));
      expect(graceClasses.first.subjectName, equals('Operating Systems Laboratory'));
      expect(graceClasses.first.timeSlot, equals('10:00 - 12:00'));
    });

    // =========================================================================
    // 4. MERGED CLASS PRODUCES ONE ATTENDANCE CLASS
    // =========================================================================
    test('4. Merged 2-period class produces exactly ONE attendance class with spanned timing', () async {
      final ttRepo = FirebaseTimetableRepository(fakeFirestore, currentUser: hodCse);
      final graceAttRepo = FirebaseAttendanceRepository(fakeFirestore, facultyGrace);

      await ttRepo.createTimetableContainer(testContainer);
      await ttRepo.savePeriodsBatch(testContainer.id, testPeriods);
      await ttRepo.saveBreaksBatch(testContainer.id, testBreaks);
      await ttRepo.saveGridEntriesBatch(testContainer.id, testEntries);
      await ttRepo.publishTimetable(testContainer.id, publishedBy: hodCse.id);

      final monday = DateTime(2026, 8, 17);
      final graceClasses = await graceAttRepo.getAssignedClasses(facultyGrace.id, monday);

      // 1 class covering 10:00 - 12:00 (not 2 separate 1-hour sessions)
      expect(graceClasses.length, equals(1));
      expect(graceClasses.first.timeSlot, equals('10:00 - 12:00'));
      expect(graceClasses.first.startTime, equals('10:00'));
      expect(graceClasses.first.endTime, equals('12:00'));
    });

    // =========================================================================
    // 5. ATTENDANCE ROSTER, MARKING & SAVE SESSION
    // =========================================================================
    test('5. Faculty marks attendance, saves session, and prevents duplicate session collision', () async {
      final ttRepo = FirebaseTimetableRepository(fakeFirestore, currentUser: hodCse);
      final alanAttRepo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);

      await ttRepo.createTimetableContainer(testContainer);
      await ttRepo.savePeriodsBatch(testContainer.id, testPeriods);
      await ttRepo.saveBreaksBatch(testContainer.id, testBreaks);
      await ttRepo.saveGridEntriesBatch(testContainer.id, testEntries);
      await ttRepo.publishTimetable(testContainer.id, publishedBy: hodCse.id);

      final monday = DateTime(2026, 8, 17);
      final alanClasses = await alanAttRepo.getAssignedClasses(facultyAlan.id, monday);

      final morningClass = alanClasses[0]; // P1 09:00 - 10:00
      final afternoonClass = alanClasses[1]; // P5+P6 14:00 - 16:00 (Same subject DBMS)

      // 1. Fetch roster for morning class
      final morningRoster = await alanAttRepo.getStudentsForSection(
        morningClass.sectionId,
        morningClass.subjectId,
        monday,
        timetableEntryId: morningClass.timetableEntryId,
      );
      expect(morningRoster.length, equals(2));

      // Mark morning attendance: John Present, Claude Absent
      final morningSession = AttendanceSession(
        id: '${morningClass.sectionId}_${morningClass.subjectId}_20260817_e-dbms',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: facultyAlan.id,
        subjectId: morningClass.subjectId,
        subjectName: morningClass.subjectName,
        sectionId: morningClass.sectionId,
        sectionName: morningClass.sectionName,
        timeSlot: morningClass.timeSlot,
        date: monday,
        records: [
          morningRoster[0].copyWith(status: AttendanceStatus.present),
          morningRoster[1].copyWith(status: AttendanceStatus.absent),
        ],
      );
      final saveMorningSuccess = await alanAttRepo.saveSession(morningSession);
      expect(saveMorningSuccess, isTrue);

      // 2. Mark afternoon attendance (same section & subject, different slot): John Absent, Claude Present
      final afternoonSession = AttendanceSession(
        id: '${afternoonClass.sectionId}_${afternoonClass.subjectId}_20260817_e-dbms-lab',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: facultyAlan.id,
        subjectId: afternoonClass.subjectId,
        subjectName: afternoonClass.subjectName,
        sectionId: afternoonClass.sectionId,
        sectionName: afternoonClass.sectionName,
        timeSlot: afternoonClass.timeSlot,
        date: monday,
        records: [
          morningRoster[0].copyWith(status: AttendanceStatus.absent),
          morningRoster[1].copyWith(status: AttendanceStatus.present),
        ],
      );
      final saveAfternoonSuccess = await alanAttRepo.saveSession(afternoonSession);
      expect(saveAfternoonSuccess, isTrue);

      // 3. Verify both sessions exist independently without overwriting each other!
      final morningFetched = await alanAttRepo.getStudentsForSection(
        morningClass.sectionId,
        morningClass.subjectId,
        monday,
        timetableEntryId: morningClass.timetableEntryId,
      );
      final afternoonFetched = await alanAttRepo.getStudentsForSection(
        afternoonClass.sectionId,
        afternoonClass.subjectId,
        monday,
        timetableEntryId: afternoonClass.timetableEntryId,
      );

      expect(morningFetched[0].status, equals(AttendanceStatus.present));
      expect(morningFetched[1].status, equals(AttendanceStatus.absent));

      expect(afternoonFetched[0].status, equals(AttendanceStatus.absent));
      expect(afternoonFetched[1].status, equals(AttendanceStatus.present));
    });

    // =========================================================================
    // 6. REPUBLISH & HISTORICAL ATTENDANCE PRESERVATION
    // =========================================================================
    test('6. Republishing timetable updates future schedule while preserving historical attendance sessions', () async {
      final ttRepo = FirebaseTimetableRepository(fakeFirestore, currentUser: hodCse);
      final alanAttRepo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);
      final graceAttRepo = FirebaseAttendanceRepository(fakeFirestore, facultyGrace);

      // Step 1: Initial publish v2 (Alan takes morning DBMS)
      await ttRepo.createTimetableContainer(testContainer);
      await ttRepo.savePeriodsBatch(testContainer.id, testPeriods);
      await ttRepo.saveBreaksBatch(testContainer.id, testBreaks);
      await ttRepo.saveGridEntriesBatch(testContainer.id, testEntries);
      await ttRepo.publishTimetable(testContainer.id, publishedBy: hodCse.id);

      final monday = DateTime(2026, 8, 17);

      // Alan marks attendance for Monday morning
      final alanRoster = await alanAttRepo.getStudentsForSection('sec-4a', 'sub-dbms', monday, timetableEntryId: 'pub_tt-cs4-a_e-dbms');
      final pastSession = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260817_e-dbms',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: facultyAlan.id,
        subjectId: 'sub-dbms',
        subjectName: 'Database Management Systems',
        sectionId: 'sec-4a',
        sectionName: 'Section 4-A',
        timeSlot: '09:00 - 10:00',
        date: monday,
        records: [
          alanRoster[0].copyWith(status: AttendanceStatus.present),
          alanRoster[1].copyWith(status: AttendanceStatus.present),
        ],
      );
      await alanAttRepo.saveSession(pastSession);

      // Step 2: HOD reassigns Monday P1 to Grace in draft and republishes (v3)
      final updatedEntry = TimetableGridEntryModel(
        id: 'e-dbms',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'sub-dbms',
        facultyId: 'fac-grace', // Reassigned to Grace
        roomNumber: 'LH-101',
        building: 'CS Block',
        sessionType: TimetableSessionType.lecture,
      );
      await ttRepo.saveGridEntry(testContainer.id, updatedEntry);
      await ttRepo.publishTimetable(testContainer.id, publishedBy: hodCse.id);

      // Step 3: Verify future schedule belongs to Grace
      final futureMonday = DateTime(2026, 8, 24);
      final graceFutureClasses = await graceAttRepo.getAssignedClasses(facultyGrace.id, futureMonday);
      expect(graceFutureClasses.any((c) => c.subjectId == 'sub-dbms' && c.timeSlot == '09:00 - 10:00'), isTrue);

      // Step 4: Verify Alan's historical session from Aug 17 is 100% intact!
      final historicalRecord = await fakeFirestore.getDocument('attendanceSessions', 'sec-4a_sub-dbms_20260817_e-dbms');
      expect(historicalRecord, isNotNull);
      expect(historicalRecord!['facultyId'], equals(facultyAlan.id));
      expect(historicalRecord['isSubmitted'], isTrue);
    });

    // =========================================================================
    // 7. UNPUBLISH TIMETABLE
    // =========================================================================
    test('7. Unpublishing removes future attendance classes while preserving historical sessions', () async {
      final ttRepo = FirebaseTimetableRepository(fakeFirestore, currentUser: hodCse);
      final alanAttRepo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);

      await ttRepo.createTimetableContainer(testContainer);
      await ttRepo.savePeriodsBatch(testContainer.id, testPeriods);
      await ttRepo.saveBreaksBatch(testContainer.id, testBreaks);
      await ttRepo.saveGridEntriesBatch(testContainer.id, testEntries);
      await ttRepo.publishTimetable(testContainer.id, publishedBy: hodCse.id);

      final monday = DateTime(2026, 8, 17);

      // Save historical session
      final session = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260817_e-dbms',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: facultyAlan.id,
        subjectId: 'sub-dbms',
        subjectName: 'Database Management Systems',
        sectionId: 'sec-4a',
        sectionName: 'Section 4-A',
        timeSlot: '09:00 - 10:00',
        date: monday,
        records: [
          AttendanceRecord(id: 'r1', studentId: 'std-1', studentName: 'John', rollNumber: '001', sectionId: 'sec-4a', status: AttendanceStatus.present),
        ],
      );
      await alanAttRepo.saveSession(session);

      // Unpublish timetable
      await ttRepo.unpublishTimetable(testContainer.id);

      // Future attendance query returns empty
      final classes = await alanAttRepo.getAssignedClasses(facultyAlan.id, monday);
      expect(classes.isEmpty, isTrue);

      // Historical session remains in database
      final historicalDoc = await fakeFirestore.getDocument('attendanceSessions', 'sec-4a_sub-dbms_20260817_e-dbms');
      expect(historicalDoc, isNotNull);
    });

    // =========================================================================
    // 8. CROSS-COLLEGE TENANT ISOLATION
    // =========================================================================
    test('8. Cross-college faculty receives 0 classes from another college', () async {
      final ttRepo = FirebaseTimetableRepository(fakeFirestore, currentUser: hodCse);
      
      final otherCollegeFaculty = UserModel(
        id: 'fac-other',
        name: 'Other College Prof',
        email: 'other@mit.edu',
        role: AppRole.faculty,
        collegeId: 'col-2', // Different college
        departmentId: 'dept-cse',
      );
      final otherAttRepo = FirebaseAttendanceRepository(fakeFirestore, otherCollegeFaculty);

      await ttRepo.createTimetableContainer(testContainer);
      await ttRepo.savePeriodsBatch(testContainer.id, testPeriods);
      await ttRepo.saveGridEntriesBatch(testContainer.id, testEntries);
      await ttRepo.publishTimetable(testContainer.id, publishedBy: hodCse.id);

      final monday = DateTime(2026, 8, 17);
      final classes = await otherAttRepo.getAssignedClasses(otherCollegeFaculty.id, monday);
      expect(classes.isEmpty, isTrue);
    });

    // =========================================================================
    // 9. MULTIPLE SECTIONS ROSTER ISOLATION
    // =========================================================================
    test('9. Section rosters remain strictly segregated between sections', () async {
      // Seed student in section B
      await fakeFirestore.setDocument('students', 'std-b1', {
        'id': 'std-b1',
        'name': 'Ada Lovelace',
        'rollNumber': 'CS2026050',
        'sectionId': 'sec-4b',
        'collegeId': 'col-1',
        'isActive': true,
      });

      final alanAttRepo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);
      final monday = DateTime(2026, 8, 17);

      final rosterA = await alanAttRepo.getStudentsForSection('sec-4a', 'sub-dbms', monday);
      final rosterB = await alanAttRepo.getStudentsForSection('sec-4b', 'sub-dbms', monday);

      expect(rosterA.length, equals(2));
      expect(rosterA.any((s) => s.studentName == 'John von Neumann'), isTrue);
      expect(rosterA.any((s) => s.studentName == 'Ada Lovelace'), isFalse);

      expect(rosterB.length, equals(1));
      expect(rosterB.first.studentName, equals('Ada Lovelace'));
    });
  });
}
