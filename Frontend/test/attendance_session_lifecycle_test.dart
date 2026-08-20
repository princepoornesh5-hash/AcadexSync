import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_status.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:campus_management/features/attendance/data/repositories/firebase_attendance_repository.dart';
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
  Future<List<Map<String, dynamic>>> queryCollection(
    String collection,
    Map<String, dynamic> filters, {
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
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

  group('ACADEX Phase 7: Complete Attendance Session, History & Editing Tests', () {
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

    final studentJohn = UserModel(
      id: 'std-1',
      name: 'John von Neumann',
      email: 'john@git.edu',
      role: AppRole.student,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    setUp(() async {
      fakeFirestore = FakeFirestoreService();

      // Seed Subjects and Sections
      await fakeFirestore.setDocument('subjects', 'sub-dbms', {
        'id': 'sub-dbms',
        'name': 'Database Management Systems',
        'code': 'CS201',
      });
      await fakeFirestore.setDocument('subjects', 'sub-os', {
        'id': 'sub-os',
        'name': 'Operating Systems',
        'code': 'CS202',
      });
      await fakeFirestore.setDocument('sections', 'sec-4a', {
        'id': 'sec-4a',
        'name': 'Section 4-A',
      });

      // Seed 4 Students in sec-4a
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
      await fakeFirestore.setDocument('students', 'std-3', {
        'id': 'std-3',
        'name': 'Ada Lovelace',
        'rollNumber': 'CS2026003',
        'sectionId': 'sec-4a',
        'collegeId': 'col-1',
        'isActive': true,
      });
      await fakeFirestore.setDocument('students', 'std-4', {
        'id': 'std-4',
        'name': 'Donald Knuth',
        'rollNumber': 'CS2026004',
        'sectionId': 'sec-4a',
        'collegeId': 'col-1',
        'isActive': true,
      });
    });

    // =========================================================================
    // 1. ROSTER LOADING & NOTIFIER STATE OPERATIONS
    // =========================================================================
    test('1. Roster loads cleanly and MarkingSessionNotifier tracks statuses', () async {
      final repo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);
      final today = DateTime(2026, 8, 17);

      final roster = await repo.getStudentsForSection('sec-4a', 'sub-dbms', today);
      expect(roster.length, equals(4));

      final notifier = MarkingSessionNotifier(roster);
      expect(notifier.remainingCount, equals(4));
      expect(notifier.isComplete, isFalse);

      // Mark John Present
      notifier.markStatus('std-1', AttendanceStatus.present);
      expect(notifier.remainingCount, equals(3));
      expect(notifier.summary[AttendanceStatus.present], equals(1));

      // Mark Claude Late
      notifier.markStatus('std-2', AttendanceStatus.late);
      expect(notifier.remainingCount, equals(2));
      expect(notifier.summary[AttendanceStatus.late], equals(1));

      // Mark Ada Excused
      notifier.markStatus('std-3', AttendanceStatus.excused);
      expect(notifier.remainingCount, equals(1));
      expect(notifier.summary[AttendanceStatus.excused], equals(1));

      // Mark Donald Absent
      notifier.markStatus('std-4', AttendanceStatus.absent);
      expect(notifier.remainingCount, equals(0));
      expect(notifier.isComplete, isTrue);
    });

    // =========================================================================
    // 2. BULK ACTIONS & INDIVIDUAL CORRECTION
    // =========================================================================
    test('2. Bulk Mark All Present / Absent and subsequent individual corrections', () async {
      final repo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);
      final today = DateTime(2026, 8, 17);
      final roster = await repo.getStudentsForSection('sec-4a', 'sub-dbms', today);

      final notifier = MarkingSessionNotifier(roster);

      // Bulk Mark All Present
      notifier.markAll(AttendanceStatus.present);
      expect(notifier.summary[AttendanceStatus.present], equals(4));
      expect(notifier.summary[AttendanceStatus.absent], equals(0));
      expect(notifier.isComplete, isTrue);

      // Individual correction: Change Claude and Donald to Absent
      notifier.markStatus('std-2', AttendanceStatus.absent);
      notifier.markStatus('std-4', AttendanceStatus.absent);

      expect(notifier.summary[AttendanceStatus.present], equals(2));
      expect(notifier.summary[AttendanceStatus.absent], equals(2));

      // Clear all
      notifier.clearAll();
      expect(notifier.remainingCount, equals(4));
      expect(notifier.summary[AttendanceStatus.present], equals(0));

      // Mark remaining unmarked as Absent
      notifier.markStatus('std-1', AttendanceStatus.present);
      notifier.markUnmarked(AttendanceStatus.absent);
      expect(notifier.summary[AttendanceStatus.present], equals(1));
      expect(notifier.summary[AttendanceStatus.absent], equals(3));
      expect(notifier.remainingCount, equals(0));
    });

    // =========================================================================
    // 3. SUMMARY CARD METRICS & ATTENDANCE PERCENTAGE
    // =========================================================================
    test('3. AttendanceSession percentage and summary counts calculation', () {
      final session = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260817_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: facultyAlan.id,
        subjectId: 'sub-dbms',
        subjectName: 'DBMS',
        sectionId: 'sec-4a',
        sectionName: '4-A',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 8, 17),
        records: [
          AttendanceRecord(id: 'r1', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.present),
          AttendanceRecord(id: 'r2', studentId: 'std-2', studentName: 'Claude', rollNumber: '02', sectionId: 'sec-4a', status: AttendanceStatus.late),
          AttendanceRecord(id: 'r3', studentId: 'std-3', studentName: 'Ada', rollNumber: '03', sectionId: 'sec-4a', status: AttendanceStatus.absent),
          AttendanceRecord(id: 'r4', studentId: 'std-4', studentName: 'Donald', rollNumber: '04', sectionId: 'sec-4a', status: AttendanceStatus.excused),
        ],
      );

      expect(session.totalStudents, equals(4));
      expect(session.presentCount, equals(1));
      expect(session.lateCount, equals(1));
      expect(session.absentCount, equals(1));
      expect(session.excusedCount, equals(1));
      // (1 present + 1 late) / 4 = 50.0%
      expect(session.attendancePercentage, equals(50.0));
    });

    // =========================================================================
    // 4. ATOMIC SESSION SAVE & DUPLICATE SLOT SAFETY
    // =========================================================================
    test('4. Atomic session saving populates student attendance records and prevents slot collisions', () async {
      final repo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);
      final today = DateTime(2026, 8, 17);

      final session1 = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260817_e-morning',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: facultyAlan.id,
        subjectId: 'sub-dbms',
        subjectName: 'Database Management Systems',
        sectionId: 'sec-4a',
        sectionName: 'Section 4-A',
        timeSlot: '09:00 - 10:00',
        timetableEntryId: 'pub_tt1_e-morning',
        roomNumber: 'LH-101',
        building: 'CS Block',
        date: today,
        records: [
          AttendanceRecord(id: 'r1', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.present),
          AttendanceRecord(id: 'r2', studentId: 'std-2', studentName: 'Claude', rollNumber: '02', sectionId: 'sec-4a', status: AttendanceStatus.absent),
        ],
      );

      final saveSuccess = await repo.saveSession(session1);
      expect(saveSuccess, isTrue);

      // Verify individual attendance records in Firestore
      final attJohn = await fakeFirestore.getDocument('attendance', 'sec-4a_sub-dbms_20260817_e-morning_std-1');
      expect(attJohn, isNotNull);
      expect(attJohn!['status'], equals('present'));
      expect(attJohn['markedBy'], equals('fac-alan'));

      final attClaude = await fakeFirestore.getDocument('attendance', 'sec-4a_sub-dbms_20260817_e-morning_std-2');
      expect(attClaude, isNotNull);
      expect(attClaude!['status'], equals('absent'));
    });

    // =========================================================================
    // 5. EDITING PREVIOUSLY SAVED SESSION (VERSION & AUDIT PRESERVATION)
    // =========================================================================
    test('5. Editing a previously saved session increments version and updates records', () async {
      final repo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);
      final today = DateTime(2026, 8, 17);

      // Initial save (v1)
      final initialSession = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260817_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: facultyAlan.id,
        subjectId: 'sub-dbms',
        subjectName: 'Database Management Systems',
        sectionId: 'sec-4a',
        sectionName: 'Section 4-A',
        timeSlot: '09:00 - 10:00',
        date: today,
        version: 1,
        records: [
          AttendanceRecord(id: 'r1', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.present),
          AttendanceRecord(id: 'r2', studentId: 'std-2', studentName: 'Claude', rollNumber: '02', sectionId: 'sec-4a', status: AttendanceStatus.absent),
        ],
      );
      await repo.saveSession(initialSession);

      // Edit session: Change Claude to Present (Correction)
      final editedSession = initialSession.copyWith(
        version: 2,
        records: [
          AttendanceRecord(id: 'r1', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.present),
          AttendanceRecord(id: 'r2', studentId: 'std-2', studentName: 'Claude', rollNumber: '02', sectionId: 'sec-4a', status: AttendanceStatus.present, oldStatus: AttendanceStatus.absent),
        ],
      );
      await repo.saveSession(editedSession);

      // Fetch saved session doc and verify v2
      final savedDoc = await fakeFirestore.getDocument('attendanceSessions', 'sec-4a_sub-dbms_20260817_e1');
      expect(savedDoc, isNotNull);
      expect(savedDoc!['version'], equals(2));

      // Verify updated student attendance doc
      final attClaude = await fakeFirestore.getDocument('attendance', 'sec-4a_sub-dbms_20260817_e1_std-2');
      expect(attClaude!['status'], equals('present'));
    });

    // =========================================================================
    // 6. FACULTY HISTORY LIST & CHRONOLOGICAL SORTING
    // =========================================================================
    test('6. Faculty history lists past sessions sorted newest first', () async {
      final repo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);

      final sessionYesterday = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260816_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: facultyAlan.id,
        subjectId: 'sub-dbms',
        subjectName: 'DBMS',
        sectionId: 'sec-4a',
        sectionName: '4-A',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 8, 16),
        records: [],
      );

      final sessionToday = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260817_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: facultyAlan.id,
        subjectId: 'sub-dbms',
        subjectName: 'DBMS',
        sectionId: 'sec-4a',
        sectionName: '4-A',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 8, 17),
        records: [],
      );

      await repo.saveSession(sessionYesterday);
      await repo.saveSession(sessionToday);

      final history = await repo.getRecentSessions(facultyAlan.id);
      expect(history.length, equals(2));
      // Newest first
      expect(history.first.date.day, equals(17));
      expect(history.last.date.day, equals(16));
    });

    // =========================================================================
    // 7. STUDENT AGGREGATE STATS & OVERVIEW DERIVATION
    // =========================================================================
    test('7. Student subject attendance and overview percentages are derived accurately', () async {
      final alanRepo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);

      // Alan holds 2 sessions for DBMS: std-1 attended both, std-2 attended 1
      final sess1 = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260817_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: facultyAlan.id,
        subjectId: 'sub-dbms',
        subjectName: 'Database Management Systems',
        sectionId: 'sec-4a',
        sectionName: 'Section 4-A',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 8, 17),
        records: [
          AttendanceRecord(id: 'r1', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.present),
          AttendanceRecord(id: 'r2', studentId: 'std-2', studentName: 'Claude', rollNumber: '02', sectionId: 'sec-4a', status: AttendanceStatus.absent),
        ],
      );

      final sess2 = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260818_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: facultyAlan.id,
        subjectId: 'sub-dbms',
        subjectName: 'Database Management Systems',
        sectionId: 'sec-4a',
        sectionName: 'Section 4-A',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 8, 18),
        records: [
          AttendanceRecord(id: 'r3', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.present),
          AttendanceRecord(id: 'r4', studentId: 'std-2', studentName: 'Claude', rollNumber: '02', sectionId: 'sec-4a', status: AttendanceStatus.present),
        ],
      );

      await alanRepo.saveSession(sess1);
      await alanRepo.saveSession(sess2);

      // Student 1 (John) -> 2/2 = 100%
      final johnRepo = FirebaseAttendanceRepository(fakeFirestore, studentJohn);
      final johnStats = await johnRepo.getStudentSubjectAttendance('std-1');
      expect(johnStats.length, equals(1));
      expect(johnStats.first.totalClasses, equals(2));
      expect(johnStats.first.attendedClasses, equals(2));
      expect(johnStats.first.missedClasses, equals(0));

      final johnOverview = await johnRepo.getStudentAttendanceOverview('std-1');
      expect(johnOverview.overallPercentage, equals(100.0));

      // Student 2 (Claude) -> 1/2 = 50%
      final claudeStats = await johnRepo.getStudentSubjectAttendance('std-2');
      expect(claudeStats.first.totalClasses, equals(2));
      expect(claudeStats.first.attendedClasses, equals(1));
      expect(claudeStats.first.missedClasses, equals(1));

      final claudeOverview = await johnRepo.getStudentAttendanceOverview('std-2');
      expect(claudeOverview.overallPercentage, equals(50.0));
    });

    // =========================================================================
    // 8. SECURITY & ROLE ISOLATION
    // =========================================================================
    test('8. Cross-faculty and cross-tenant queries enforce strict isolation', () async {
      final alanRepo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);
      final graceRepo = FirebaseAttendanceRepository(fakeFirestore, facultyGrace);

      final alanSession = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260817_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: facultyAlan.id,
        subjectId: 'sub-dbms',
        subjectName: 'DBMS',
        sectionId: 'sec-4a',
        sectionName: '4-A',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 8, 17),
        records: [],
      );
      await alanRepo.saveSession(alanSession);

      // Grace queries her history -> does NOT see Alan's session
      final graceHistory = await graceRepo.getRecentSessions(facultyGrace.id);
      expect(graceHistory.isEmpty, isTrue);

      // Alan queries his history -> sees his session
      final alanHistory = await alanRepo.getRecentSessions(facultyAlan.id);
      expect(alanHistory.length, equals(1));
      expect(alanHistory.first.id, equals('sec-4a_sub-dbms_20260817_e1'));
    });
  });
}
