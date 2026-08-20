import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_status.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_analytics_models.dart';
import 'package:campus_management/features/attendance/data/repositories/firebase_attendance_repository.dart';
import 'package:campus_management/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:campus_management/core/firebase/firebase_services.dart';

class FakeAnalyticsFirestoreService implements FirestoreService {
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

  group('ACADEX Phase 8A: Attendance Analytics & Aggregation Engine Tests', () {
    late FakeAnalyticsFirestoreService fakeFirestore;

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

    setUp(() async {
      fakeFirestore = FakeAnalyticsFirestoreService();

      // Seed Subjects, Sections, Students
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

      await fakeFirestore.setDocument('users', 'fac-alan', {
        'id': 'fac-alan',
        'name': 'Dr. Alan Turing',
      });

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
    });

    // =========================================================================
    // 1. FORMULA & CALCULATION TESTS
    // =========================================================================
    test('1. Centralized calculation formula excludes unmarked from denominator', () {
      // 70 present, 20 absent, 5 late, 5 excused, 10 unmarked
      // Denominator = 70 + 20 + 5 + 5 = 100
      // Percentage = 70 / 100 * 100 = 70.0%
      final pct = AttendanceAnalyticsConstants.calculatePercentage(
        presentCount: 70,
        absentCount: 20,
        lateCount: 5,
        excusedCount: 5,
        unmarkedCount: 10,
      );
      expect(pct, equals(70.0));
    });

    test('2. Zero denominator safely returns 0.0 without NaN or divide-by-zero', () {
      final pctZero = AttendanceAnalyticsConstants.calculatePercentage(
        presentCount: 0,
        absentCount: 0,
        lateCount: 0,
        excusedCount: 0,
        unmarkedCount: 5,
      );
      expect(pctZero, equals(0.0));
      expect(pctZero.isNaN, isFalse);
    });

    test('3. Decimal percentage calculation precision', () {
      // 28 present, 2 absent, 1 late, 0 excused -> 28 / 31 = 90.32258064516129%
      final pct = AttendanceAnalyticsConstants.calculatePercentage(
        presentCount: 28,
        absentCount: 2,
        lateCount: 1,
        excusedCount: 0,
      );
      expect(pct, closeTo(90.32, 0.01));
    });

    // =========================================================================
    // 2. LOW ATTENDANCE THRESHOLD BOUNDARY TESTS (< 75.0)
    // =========================================================================
    test('4. Threshold boundary evaluations (74%, 74.99%, 75%, 80%)', () {
      expect(AttendanceAnalyticsConstants.isLowAttendance(74.0), isTrue);
      expect(AttendanceAnalyticsConstants.isLowAttendance(74.99), isTrue);
      expect(AttendanceAnalyticsConstants.isLowAttendance(75.0), isFalse);
      expect(AttendanceAnalyticsConstants.isLowAttendance(75.01), isFalse);
      expect(AttendanceAnalyticsConstants.isLowAttendance(80.0), isFalse);
    });

    // =========================================================================
    // 3. DATE RANGE PRESETS & INCLUSIVE BOUNDARY TESTS
    // =========================================================================
    test('5. Date range presets normalize start/end dates and include full day bounds', () {
      final refDate = DateTime(2026, 8, 17, 14, 30); // Monday

      final todayRange = AttendanceDateRange.today(refDate);
      expect(todayRange.startDate, equals(DateTime(2026, 8, 17, 0, 0, 0, 0)));
      expect(todayRange.endDate, equals(DateTime(2026, 8, 17, 23, 59, 59, 999)));
      expect(todayRange.contains(DateTime(2026, 8, 17, 23, 30)), isTrue);
      expect(todayRange.contains(DateTime(2026, 8, 18, 0, 0)), isFalse);

      final weekRange = AttendanceDateRange.thisWeek(refDate);
      expect(weekRange.startDate.day, equals(17)); // Monday Aug 17
      expect(weekRange.endDate.day, equals(23)); // Sunday Aug 23
      expect(weekRange.contains(DateTime(2026, 8, 23, 22, 0)), isTrue);

      final monthRange = AttendanceDateRange.thisMonth(refDate);
      expect(monthRange.startDate, equals(DateTime(2026, 8, 1, 0, 0, 0, 0)));
      expect(monthRange.endDate, equals(DateTime(2026, 8, 31, 23, 59, 59, 999)));
      expect(monthRange.contains(DateTime(2026, 8, 31, 23, 59)), isTrue);
    });

    test('6. Custom date range supports inclusive end dates', () {
      final custom = AttendanceDateRange.custom(
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 15),
      );
      expect(custom.contains(DateTime(2026, 8, 15, 23, 0)), isTrue);
      expect(custom.contains(DateTime(2026, 8, 16, 0, 0)), isFalse);
    });

    // =========================================================================
    // 4. STUDENT ATTENDANCE ANALYTICS AGGREGATION
    // =========================================================================
    test('7. Student analytics aggregates individual attendance records with all 5 statuses', () async {
      final repo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);

      // Session 1 on Aug 10: std-1 present, std-2 absent, std-3 late
      final sess1 = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260810_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'fac-alan',
        subjectId: 'sub-dbms',
        subjectName: 'DBMS',
        sectionId: 'sec-4a',
        sectionName: '4-A',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 8, 10),
        records: [
          AttendanceRecord(id: 'r1', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.present),
          AttendanceRecord(id: 'r2', studentId: 'std-2', studentName: 'Claude', rollNumber: '02', sectionId: 'sec-4a', status: AttendanceStatus.absent),
          AttendanceRecord(id: 'r3', studentId: 'std-3', studentName: 'Ada', rollNumber: '03', sectionId: 'sec-4a', status: AttendanceStatus.late),
        ],
      );

      // Session 2 on Aug 12: std-1 present, std-2 excused, std-3 absent
      final sess2 = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260812_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'fac-alan',
        subjectId: 'sub-dbms',
        subjectName: 'DBMS',
        sectionId: 'sec-4a',
        sectionName: '4-A',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 8, 12),
        records: [
          AttendanceRecord(id: 'r4', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.present),
          AttendanceRecord(id: 'r5', studentId: 'std-2', studentName: 'Claude', rollNumber: '02', sectionId: 'sec-4a', status: AttendanceStatus.excused),
          AttendanceRecord(id: 'r6', studentId: 'std-3', studentName: 'Ada', rollNumber: '03', sectionId: 'sec-4a', status: AttendanceStatus.absent),
        ],
      );

      await repo.saveSession(sess1);
      await repo.saveSession(sess2);

      // Query Student 1 (John): 2 present / 2 total = 100% (Not low)
      final johnAnalytics = await repo.getStudentAttendanceAnalytics('std-1');
      expect(johnAnalytics.totalSessions, equals(2));
      expect(johnAnalytics.presentCount, equals(2));
      expect(johnAnalytics.absentCount, equals(0));
      expect(johnAnalytics.attendancePercentage, equals(100.0));
      expect(johnAnalytics.isLowAttendance, isFalse);

      // Query Student 2 (Claude): 0 present, 1 absent, 1 excused -> 0 / 2 = 0% (Low attendance)
      final claudeAnalytics = await repo.getStudentAttendanceAnalytics('std-2');
      expect(claudeAnalytics.totalSessions, equals(2));
      expect(claudeAnalytics.presentCount, equals(0));
      expect(claudeAnalytics.absentCount, equals(1));
      expect(claudeAnalytics.excusedCount, equals(1));
      expect(claudeAnalytics.attendancePercentage, equals(0.0));
      expect(claudeAnalytics.isLowAttendance, isTrue);

      // Query Student 3 (Ada): 0 present, 1 late, 1 absent -> 0 / 2 = 0% (Low attendance)
      final adaAnalytics = await repo.getStudentAttendanceAnalytics('std-3');
      expect(adaAnalytics.totalSessions, equals(2));
      expect(adaAnalytics.lateCount, equals(1));
      expect(adaAnalytics.absentCount, equals(1));
    });

    // =========================================================================
    // 5. SUBJECT ATTENDANCE ANALYTICS AGGREGATION
    // =========================================================================
    test('8. Subject analytics computes aggregate student records and class percentage', () async {
      final repo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);

      final sess1 = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260810_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'fac-alan',
        subjectId: 'sub-dbms',
        subjectName: 'DBMS',
        sectionId: 'sec-4a',
        sectionName: '4-A',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 8, 10),
        records: [
          AttendanceRecord(id: 'r1', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.present),
          AttendanceRecord(id: 'r2', studentId: 'std-2', studentName: 'Claude', rollNumber: '02', sectionId: 'sec-4a', status: AttendanceStatus.present),
          AttendanceRecord(id: 'r3', studentId: 'std-3', studentName: 'Ada', rollNumber: '03', sectionId: 'sec-4a', status: AttendanceStatus.absent),
        ],
      );
      await repo.saveSession(sess1);

      final subjectAnalytics = await repo.getSubjectAttendanceAnalytics('sub-dbms');
      expect(subjectAnalytics.totalSessions, equals(1));
      expect(subjectAnalytics.totalStudentRecords, equals(3));
      expect(subjectAnalytics.presentCount, equals(2));
      expect(subjectAnalytics.absentCount, equals(1));
      // 2 present / 3 total = 66.67%
      expect(subjectAnalytics.attendancePercentage, closeTo(66.67, 0.01));
    });

    // =========================================================================
    // 6. SECTION ATTENDANCE ANALYTICS & LOW ATTENDANCE COUNT
    // =========================================================================
    test('9. Section analytics calculates overall section rate and identifies students below threshold', () async {
      final repo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);

      final sess1 = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260810_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'fac-alan',
        subjectId: 'sub-dbms',
        subjectName: 'DBMS',
        sectionId: 'sec-4a',
        sectionName: '4-A',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 8, 10),
        records: [
          // John: Present (100%)
          AttendanceRecord(id: 'r1', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.present),
          // Claude: Absent (0%)
          AttendanceRecord(id: 'r2', studentId: 'std-2', studentName: 'Claude', rollNumber: '02', sectionId: 'sec-4a', status: AttendanceStatus.absent),
          // Ada: Absent (0%)
          AttendanceRecord(id: 'r3', studentId: 'std-3', studentName: 'Ada', rollNumber: '03', sectionId: 'sec-4a', status: AttendanceStatus.absent),
        ],
      );
      await repo.saveSession(sess1);

      final secAnalytics = await repo.getSectionAttendanceAnalytics('sec-4a');
      expect(secAnalytics.totalSessions, equals(1));
      expect(secAnalytics.totalStudents, equals(3));
      expect(secAnalytics.presentCount, equals(1));
      expect(secAnalytics.absentCount, equals(2));
      // 2 students (Claude, Ada) are below 75%
      expect(secAnalytics.lowAttendanceStudentCount, equals(2));
      expect(secAnalytics.studentAnalytics.length, equals(3));
    });

    // =========================================================================
    // 7. FACULTY ATTENDANCE ACTIVITY ANALYTICS
    // =========================================================================
    test('10. Faculty analytics aggregates conducted classes and student engagement totals', () async {
      final repo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);

      final sess1 = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260810_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'fac-alan',
        subjectId: 'sub-dbms',
        subjectName: 'DBMS',
        sectionId: 'sec-4a',
        sectionName: '4-A',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 8, 10),
        records: [
          AttendanceRecord(id: 'r1', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.present),
          AttendanceRecord(id: 'r2', studentId: 'std-2', studentName: 'Claude', rollNumber: '02', sectionId: 'sec-4a', status: AttendanceStatus.present),
        ],
      );
      await repo.saveSession(sess1);

      final facAnalytics = await repo.getFacultyAttendanceAnalytics('fac-alan');
      expect(facAnalytics.totalSessionsConducted, equals(1));
      expect(facAnalytics.totalStudentRecords, equals(2));
      expect(facAnalytics.presentCount, equals(2));
      expect(facAnalytics.attendancePercentage, equals(100.0));
    });

    // =========================================================================
    // 8. DATE RANGE FILTERING & OUT-OF-RANGE EXCLUSION
    // =========================================================================
    test('11. Date range filters exclude out-of-range sessions from analytics', () async {
      final repo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);

      // Session in July 2026
      final sessJuly = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260715_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'fac-alan',
        subjectId: 'sub-dbms',
        subjectName: 'DBMS',
        sectionId: 'sec-4a',
        sectionName: '4-A',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 7, 15),
        records: [
          AttendanceRecord(id: 'r1', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.present),
        ],
      );

      // Session in August 2026
      final sessAugust = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260815_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'fac-alan',
        subjectId: 'sub-dbms',
        subjectName: 'DBMS',
        sectionId: 'sec-4a',
        sectionName: '4-A',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 8, 15),
        records: [
          AttendanceRecord(id: 'r2', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.absent),
        ],
      );

      await repo.saveSession(sessJuly);
      await repo.saveSession(sessAugust);

      // Query only August 2026
      final augustRange = AttendanceDateRange.custom(
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
      );

      final augustJohn = await repo.getStudentAttendanceAnalytics('std-1', dateRange: augustRange);
      expect(augustJohn.totalSessions, equals(1));
      expect(augustJohn.presentCount, equals(0));
      expect(augustJohn.absentCount, equals(1));
      expect(augustJohn.attendancePercentage, equals(0.0));

      final augustSummary = await repo.getAttendanceDateRangeSummary(dateRange: augustRange);
      expect(augustSummary.totalSessions, equals(1));
      expect(augustSummary.absentCount, equals(1));
    });

    // =========================================================================
    // 9. VERSIONING DEDUPLICATION (EDIT DOES NOT DOUBLE-COUNT SESSIONS)
    // =========================================================================
    test('12. Edited session revisions update existing document and are not double-counted', () async {
      final repo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);

      // Initial save (v1): John Absent
      final sessV1 = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260810_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'fac-alan',
        subjectId: 'sub-dbms',
        subjectName: 'DBMS',
        sectionId: 'sec-4a',
        sectionName: '4-A',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 8, 10),
        version: 1,
        records: [
          AttendanceRecord(id: 'r1', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.absent),
        ],
      );
      await repo.saveSession(sessV1);

      // Edit save (v2): John corrected to Present
      final sessV2 = sessV1.copyWith(
        version: 2,
        records: [
          AttendanceRecord(id: 'r1', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.present),
        ],
      );
      await repo.saveSession(sessV2);

      // Verify that total sessions conducted is exactly 1 (not 2)
      final facAnalytics = await repo.getFacultyAttendanceAnalytics('fac-alan');
      expect(facAnalytics.totalSessionsConducted, equals(1));
      expect(facAnalytics.presentCount, equals(1));
      expect(facAnalytics.absentCount, equals(0));

      final johnAnalytics = await repo.getStudentAttendanceAnalytics('std-1');
      expect(johnAnalytics.totalSessions, equals(1));
      expect(johnAnalytics.presentCount, equals(1));
      expect(johnAnalytics.attendancePercentage, equals(100.0));
    });

    // =========================================================================
    // 10. TENANT & ROLE SCOPE ISOLATION
    // =========================================================================
    test('13. Cross-faculty queries enforce strict tenant and role isolation', () async {
      final alanRepo = FirebaseAttendanceRepository(fakeFirestore, facultyAlan);
      final graceRepo = FirebaseAttendanceRepository(fakeFirestore, facultyGrace);

      final alanSession = AttendanceSession(
        id: 'sec-4a_sub-dbms_20260810_e1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'fac-alan',
        subjectId: 'sub-dbms',
        subjectName: 'DBMS',
        sectionId: 'sec-4a',
        sectionName: '4-A',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 8, 10),
        records: [
          AttendanceRecord(id: 'r1', studentId: 'std-1', studentName: 'John', rollNumber: '01', sectionId: 'sec-4a', status: AttendanceStatus.present),
        ],
      );
      await alanRepo.saveSession(alanSession);

      // Dr. Grace queries her faculty analytics -> 0 sessions
      final graceAnalytics = await graceRepo.getFacultyAttendanceAnalytics('fac-grace');
      expect(graceAnalytics.totalSessionsConducted, equals(0));
      expect(graceAnalytics.totalStudentRecords, equals(0));

      // Dr. Alan queries his faculty analytics -> 1 session
      final alanAnalytics = await alanRepo.getFacultyAttendanceAnalytics('fac-alan');
      expect(alanAnalytics.totalSessionsConducted, equals(1));
    });

    // =========================================================================
    // 11. MOCK REPOSITORY CONSISTENCY TEST
    // =========================================================================
    test('14. MockAttendanceRepository analytics behaves consistently with formulas and models', () async {
      final mockRepo = MockAttendanceRepository();

      final studentAnalytics = await mockRepo.getStudentAttendanceAnalytics('s1');
      expect(studentAnalytics.studentId, equals('s1'));
      expect(studentAnalytics.totalSessions, greaterThan(0));
      expect(studentAnalytics.attendancePercentage, inInclusiveRange(0.0, 100.0));

      final sectionAnalytics = await mockRepo.getSectionAttendanceAnalytics('sec1');
      expect(sectionAnalytics.sectionId, equals('sec1'));
      expect(sectionAnalytics.totalStudents, greaterThan(0));

      final dateSummary = await mockRepo.getAttendanceDateRangeSummary();
      expect(dateSummary.totalSessions, greaterThanOrEqualTo(0));
    });
  });
}
