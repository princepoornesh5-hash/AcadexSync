import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_status.dart';
import 'package:campus_management/features/attendance/domain/models/subject_attendance.dart';
import 'package:campus_management/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:campus_management/features/attendance/data/repositories/firebase_attendance_repository.dart';
import 'package:campus_management/core/firebase/firebase_services.dart';

class FakeFirestoreService implements FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> _db = {};

  @override
  Future<void> setDocument(String collection, String id, Map<String, dynamic> data) async {
    _db.putIfAbsent(collection, () => {})[id] = data;
  }

  @override
  Future<void> batchSetDocuments(Map<String, Map<String, dynamic>> documentPathToDataMap) async {
    for (final entry in documentPathToDataMap.entries) {
      final parts = entry.key.split('/');
      if (parts.length >= 2) {
        final collection = parts[0];
        final docId = parts.sublist(1).join('/');
        _db.putIfAbsent(collection, () => {})[docId] = entry.value;
      }
    }
  }

  @override
  Future<Map<String, dynamic>?> getDocument(String collection, String id) async {
    return _db[collection]?[id];
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Prompt 59: Attendance System — Real Data + Role-Based Workflow', () {
    final mockRepo = MockAttendanceRepository();
    late FakeFirestoreService fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirestoreService();
    });

    test('1. Faculty can load assigned classes and student roster for section', () async {
      final now = DateTime.now();
      final assignedClasses = await mockRepo.getAssignedClasses('faculty1', now);
      expect(assignedClasses.isNotEmpty, isTrue);

      final roster = await mockRepo.getStudentsForSection(
        assignedClasses.first.sectionId,
        assignedClasses.first.subjectId,
        now,
      );
      expect(roster.isNotEmpty, isTrue);
    });

    test('2. Faculty saves session and records marked present/absent', () async {
      final now = DateTime.now();
      final repo = FirebaseAttendanceRepository(fakeFirestore, null);

      final session = AttendanceSession(
        id: 'sec1_sub1_20260812',
        collegeId: 'col-1',
        departmentId: 'dept-1',
        subjectId: 'sub1',
        subjectName: 'Java Programming',
        sectionId: 'sec1',
        sectionName: 'DCME 3-A',
        facultyId: 'faculty1',
        timeSlot: '08:30 - 09:20',
        date: now,
        records: [
          AttendanceRecord(
            id: 'rec_1',
            studentId: 's1',
            studentName: 'Student One',
            rollNumber: 'CS2025001',
            sectionId: 'sec1',
            status: AttendanceStatus.present,
          ),
          AttendanceRecord(
            id: 'rec_2',
            studentId: 's2',
            studentName: 'Student Two',
            rollNumber: 'CS2025002',
            sectionId: 'sec1',
            status: AttendanceStatus.absent,
          ),
        ],
      );

      final success = await repo.saveSession(session);
      expect(success, isTrue);

      // Verify Firestore session record saved
      final savedDoc = await fakeFirestore.getDocument('attendanceSessions', 'sec1_sub1_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}');
      expect(savedDoc, isNotNull);
      expect(savedDoc!['facultyId'], equals('faculty1'));
    });

    test('3. Student attendance percentage calculation accuracy', () async {
      final subjectAttendance = SubjectAttendance(
        subjectId: 'sub1',
        subjectName: 'Java Programming',
        subjectCode: 'CS301',
        facultyName: 'Prof. Turing',
        totalClasses: 40,
        attendedClasses: 30,
        missedClasses: 10,
      );

      final calculatedPercentage = (subjectAttendance.attendedClasses / subjectAttendance.totalClasses) * 100;
      expect(calculatedPercentage, equals(75.0));
      expect(subjectAttendance.percentage, equals(75.0));
    });

    test('4. HOD receives department-scoped attendance summary', () async {
      final deptSummary = await mockRepo.getDepartmentSummary('dept-cse');
      expect(deptSummary.totalStudents, greaterThan(0));
      expect(deptSummary.overallPercentage, greaterThan(0.0));

      final shortages = await mockRepo.getStudentShortages('dept-cse');
      expect(shortages, isNotNull);
    });

    test('5. College Admin receives college-wide attendance metrics', () async {
      final collegeSummary = await mockRepo.getCollegeSummary();
      expect(collegeSummary.todayAttendancePercentage, greaterThan(0.0));

      final comparisons = await mockRepo.getDepartmentComparisons();
      expect(comparisons.isNotEmpty, isTrue);
    });

    test('6. Super Admin receives system-wide health and college comparisons', () async {
      final health = await mockRepo.getSuperAdminSystemHealth();
      expect(health.serverStatus, equals('Healthy'));

      final comparisons = await mockRepo.getCollegeComparisons();
      expect(comparisons.isNotEmpty, isTrue);
    });
  });
}
