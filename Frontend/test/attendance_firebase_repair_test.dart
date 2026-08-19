import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_status.dart';
import 'package:campus_management/features/attendance/data/repositories/firebase_attendance_repository.dart';
import 'package:campus_management/features/attendance/presentation/providers/student_attendance_providers.dart';
import 'package:campus_management/features/attendance/presentation/providers/faculty_history_providers.dart';
import 'package:campus_management/features/attendance/presentation/providers/hod_attendance_providers.dart';
import 'package:campus_management/core/firebase/firebase_services.dart';

class TestFirestoreService implements FirestoreService {
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
        final collection = parts[0];
        final docId = parts.sublist(1).join('/');
        db.putIfAbsent(collection, () => {})[docId] = entry.value;
      }
    }
  }

  @override
  Future<Map<String, dynamic>?> getDocument(String collection, String id) async {
    return db[collection]?[id];
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollection(String collection, Map<String, dynamic> filters) async {
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ACADEX Prompt 90: Attendance Firebase & Identity Repair Tests', () {
    late TestFirestoreService testFirestore;

    final mockFacultyUser = UserModel(
      id: 'fac-999',
      email: 'faculty999@univ.edu',
      name: 'Dr. Ada Lovelace',
      role: AppRole.faculty,
      collegeId: 'col-alpha',
      departmentId: 'dept-cse',
      accountStatus: AccountStatus.active,
      createdAt: DateTime.now(),
    );

    final mockStudentUser = UserModel(
      id: 'stu-777',
      email: 'student777@univ.edu',
      name: 'Grace Student',
      role: AppRole.student,
      collegeId: 'col-alpha',
      departmentId: 'dept-cse',
      accountStatus: AccountStatus.active,
      createdAt: DateTime.now(),
    );

    setUp(() {
      testFirestore = TestFirestoreService();
    });

    test('1. Identity Providers dynamically resolve authenticated UID', () {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(mockFacultyUser),
        ],
      );

      final resolvedFacultyId = container.read(currentFacultyIdProvider);
      expect(resolvedFacultyId, equals('fac-999'));

      final resolvedDeptId = container.read(currentDepartmentIdProvider);
      expect(resolvedDeptId, equals('dept-cse'));

      final studentContainer = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(mockStudentUser),
        ],
      );

      final resolvedStudentId = studentContainer.read(currentStudentIdProvider);
      expect(resolvedStudentId, equals('stu-777'));
    });

    test('2. Atomic Batch Save writes Session and Attendance records with matching tenant IDs', () async {
      final repo = FirebaseAttendanceRepository(testFirestore, mockFacultyUser);
      final now = DateTime.now();

      final session = AttendanceSession(
        id: 'sec-101_sub-cs1_20260814',
        collegeId: 'col-alpha',
        departmentId: 'dept-cse',
        facultyId: 'fac-999',
        subjectId: 'sub-cs1',
        subjectName: 'Compiler Design',
        sectionId: 'sec-101',
        sectionName: 'DCME 5-A',
        timeSlot: '09:00 - 10:00',
        date: now,
        records: [
          AttendanceRecord(
            id: 'rec-1',
            studentId: 'stu-777',
            studentName: 'Grace Student',
            rollNumber: 'CS5001',
            sectionId: 'sec-101',
            status: AttendanceStatus.present,
          ),
          AttendanceRecord(
            id: 'rec-2',
            studentId: 'stu-888',
            studentName: 'Bob Student',
            rollNumber: 'CS5002',
            sectionId: 'sec-101',
            status: AttendanceStatus.absent,
          ),
        ],
      );

      final result = await repo.saveSession(session);
      expect(result, isTrue);

      final sessionId = 'sec-101_sub-cs1_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final sessionDoc = await testFirestore.getDocument('attendanceSessions', sessionId);
      expect(sessionDoc, isNotNull);
      expect(sessionDoc!['facultyId'], equals('fac-999'));
      expect(sessionDoc['collegeId'], equals('col-alpha'));
      expect(sessionDoc['departmentId'], equals('dept-cse'));

      final record1 = await testFirestore.getDocument('attendance', '${sessionId}_stu-777');
      expect(record1, isNotNull);
      expect(record1!['facultyId'], equals('fac-999'));
      expect(record1['collegeId'], equals('col-alpha'));
      expect(record1['status'], equals('present'));

      final record2 = await testFirestore.getDocument('attendance', '${sessionId}_stu-888');
      expect(record2, isNotNull);
      expect(record2!['status'], equals('absent'));
    });

    test('3. Faculty History queries actual sessions filtered by facultyId and collegeId', () async {
      final repo = FirebaseAttendanceRepository(testFirestore, mockFacultyUser);

      // Seed sessions
      await testFirestore.setDocument('attendanceSessions', 'sess-1', {
        'id': 'sess-1',
        'facultyId': 'fac-999',
        'collegeId': 'col-alpha',
        'departmentId': 'dept-cse',
        'subjectId': 'sub-cs1',
        'subjectName': 'Compiler Design',
        'sectionId': 'sec-101',
        'sectionName': 'DCME 5-A',
        'timeSlot': '09:00 - 10:00',
        'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'records': [],
      });

      await testFirestore.setDocument('attendanceSessions', 'sess-foreign', {
        'id': 'sess-foreign',
        'facultyId': 'fac-other',
        'collegeId': 'col-alpha',
        'departmentId': 'dept-cse',
        'subjectId': 'sub-cs1',
        'subjectName': 'Compiler Design',
        'sectionId': 'sec-101',
        'sectionName': 'DCME 5-A',
        'timeSlot': '09:00 - 10:00',
        'date': DateTime.now().toIso8601String(),
        'records': [],
      });

      final sessions = await repo.getRecentSessions('fac-999');
      expect(sessions.length, equals(1));
      expect(sessions.first.id, equals('sess-1'));
      expect(sessions.first.facultyId, equals('fac-999'));
    });

    test('4. Student Subject Attendance calculates statistics with real tenant records', () async {
      final repo = FirebaseAttendanceRepository(testFirestore, mockStudentUser);

      // Seed subjects
      await testFirestore.setDocument('subjects', 'sub-101', {
        'id': 'sub-101',
        'name': 'Data Structures',
        'code': 'CS201',
      });

      // Seed attendance records for student
      await testFirestore.setDocument('attendance', 'rec-1', {
        'attendanceId': 'rec-1',
        'studentId': 'stu-777',
        'collegeId': 'col-alpha',
        'subjectId': 'sub-101',
        'status': 'present',
        'date': '2026-08-10',
      });
      await testFirestore.setDocument('attendance', 'rec-2', {
        'attendanceId': 'rec-2',
        'studentId': 'stu-777',
        'collegeId': 'col-alpha',
        'subjectId': 'sub-101',
        'status': 'late',
        'date': '2026-08-11',
      });
      await testFirestore.setDocument('attendance', 'rec-3', {
        'attendanceId': 'rec-3',
        'studentId': 'stu-777',
        'collegeId': 'col-alpha',
        'subjectId': 'sub-101',
        'status': 'absent',
        'date': '2026-08-12',
      });

      final subjectStats = await repo.getStudentSubjectAttendance('stu-777');
      expect(subjectStats.length, equals(1));
      expect(subjectStats.first.totalClasses, equals(3));
      expect(subjectStats.first.attendedClasses, equals(2)); // Present + Late
      expect(subjectStats.first.missedClasses, equals(1));
      expect(subjectStats.first.percentage.toStringAsFixed(1), equals('66.7'));
    });
  });
}
