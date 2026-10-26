import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_status.dart';
import 'package:campus_management/features/attendance/presentation/widgets/faculty/attendance_record_card.dart';

void main() {
  group('Attendance Count Integrity & Summary Invariant Tests', () {
    test('AttendanceSession parses unicode en-dash and em-dash to canonical hyphen', () {
      final jsonWithEnDash = {
        'id': '6acdc9475b7b19115fef9db4',
        'collegeId': 'coll_1',
        'departmentId': 'dept_1',
        'facultyId': 'fac_1',
        'subjectId': 'sub_1',
        'subjectName': 'IOT',
        'sectionId': 'sec_1',
        'sectionName': 'A',
        'date': '2026-10-12T00:00:00.000Z',
        'timeSlot': '10:00 – 12:00', // Unicode EN-DASH \u2013
        'status': 'open',
        'records': [],
      };

      final session1 = AttendanceSession.fromJson(jsonWithEnDash);
      expect(session1.timeSlot, equals('10:00 - 12:00'));

      final jsonWithEmDash = {
        'id': '6acc69819601297d3dff5924',
        'collegeId': 'coll_1',
        'departmentId': 'dept_1',
        'facultyId': 'fac_1',
        'subjectId': 'sub_1',
        'subjectName': 'IOT',
        'sectionId': 'sec_1',
        'sectionName': 'A',
        'date': '2026-10-12T00:00:00.000Z',
        'timeSlot': '10:00 — 12:00', // Unicode EM-DASH \u2014
        'status': 'open',
        'records': [],
      };

      final session2 = AttendanceSession.fromJson(jsonWithEmDash);
      expect(session2.timeSlot, equals('10:00 - 12:00'));
    });

    test('AttendanceSession status counts satisfy invariant: present + late + absent + excused + unmarked == total', () {
      final records = [
        AttendanceRecord(
          id: 'r1',
          studentId: 'st1',
          studentName: 'Harsha',
          rollNumber: 'IOT001',
          sectionId: 'sec_1',
          status: AttendanceStatus.present,
        ),
        AttendanceRecord(
          id: 'r2',
          studentId: 'st2',
          studentName: 'Naga Rasagna',
          rollNumber: 'IOT002',
          sectionId: 'sec_1',
          status: AttendanceStatus.late,
        ),
        AttendanceRecord(
          id: 'r3',
          studentId: 'st3',
          studentName: 'R Poornesh',
          rollNumber: 'IOT003',
          sectionId: 'sec_1',
          status: AttendanceStatus.present,
        ),
        AttendanceRecord(
          id: 'r4',
          studentId: 'st4',
          studentName: 'Santosh',
          rollNumber: 'IOT004',
          sectionId: 'sec_1',
          status: AttendanceStatus.excused,
        ),
        AttendanceRecord(
          id: 'r5',
          studentId: 'st5',
          studentName: 'k Uday Kumar',
          rollNumber: 'IOT005',
          sectionId: 'sec_1',
          status: AttendanceStatus.excused,
        ),
      ];

      final session = AttendanceSession(
        id: '6acdc9475b7b19115fef9db4',
        collegeId: 'coll_1',
        departmentId: 'dept_1',
        facultyId: 'fac_1',
        subjectId: 'sub_1',
        subjectName: 'IOT',
        sectionId: 'sec_1',
        sectionName: 'A',
        timeSlot: '10:00 - 12:00',
        date: DateTime(2026, 10, 12),
        records: records,
        status: 'open',
      );

      expect(session.presentCount, equals(2));
      expect(session.lateCount, equals(1));
      expect(session.absentCount, equals(0));
      expect(session.excusedCount, equals(2));
      expect(session.unmarkedCount, equals(0));
      expect(session.totalStudents, equals(5));

      // Verifying strict invariant equality
      final sum = session.presentCount +
          session.lateCount +
          session.absentCount +
          session.excusedCount +
          session.unmarkedCount;
      expect(sum, equals(session.totalStudents));
    });

    testWidgets('AttendanceRecordCard renders Excused count and short reference for Session 1 (#ef9db4)', (tester) async {
      final records = [
        AttendanceRecord(
          id: 'r1',
          studentId: 'st1',
          studentName: 'Harsha',
          rollNumber: 'IOT001',
          sectionId: 'sec_1',
          status: AttendanceStatus.present,
        ),
        AttendanceRecord(
          id: 'r2',
          studentId: 'st2',
          studentName: 'Naga Rasagna',
          rollNumber: 'IOT002',
          sectionId: 'sec_1',
          status: AttendanceStatus.late,
        ),
        AttendanceRecord(
          id: 'r3',
          studentId: 'st3',
          studentName: 'R Poornesh',
          rollNumber: 'IOT003',
          sectionId: 'sec_1',
          status: AttendanceStatus.present,
        ),
        AttendanceRecord(
          id: 'r4',
          studentId: 'st4',
          studentName: 'Santosh',
          rollNumber: 'IOT004',
          sectionId: 'sec_1',
          status: AttendanceStatus.excused,
        ),
        AttendanceRecord(
          id: 'r5',
          studentId: 'st5',
          studentName: 'k Uday Kumar',
          rollNumber: 'IOT005',
          sectionId: 'sec_1',
          status: AttendanceStatus.excused,
        ),
      ];

      final session1 = AttendanceSession(
        id: '6acdc9475b7b19115fef9db4',
        collegeId: 'coll_1',
        departmentId: 'dept_1',
        facultyId: 'fac_1',
        subjectId: 'sub_1',
        subjectName: 'IOT',
        sectionId: 'sec_1',
        sectionName: 'A',
        timeSlot: '10:00 - 12:00',
        date: DateTime(2026, 10, 12),
        records: records,
        status: 'open',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttendanceRecordCard(
              session: session1,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify stats badges
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // present (2) and excused (2)
      expect(find.text('Late'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Excused'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Verify short reference and normalized time slot
      expect(find.textContaining('#ef9db4'), findsOneWidget);
      expect(find.textContaining('10:00 - 12:00'), findsOneWidget);
    });

    testWidgets('AttendanceRecordCard renders Unmarked count when unrecorded students exist', (tester) async {
      final records = [
        AttendanceRecord(
          id: 'r1',
          studentId: 'st1',
          studentName: 'Harsha',
          rollNumber: 'IOT001',
          sectionId: 'sec_1',
          status: AttendanceStatus.present,
        ),
        AttendanceRecord(
          id: 'r2',
          studentId: 'st2',
          studentName: 'Naga Rasagna',
          rollNumber: 'IOT002',
          sectionId: 'sec_1',
          status: null, // Unmarked
        ),
        AttendanceRecord(
          id: 'r3',
          studentId: 'st3',
          studentName: 'R Poornesh',
          rollNumber: 'IOT003',
          sectionId: 'sec_1',
          status: null, // Unmarked
        ),
      ];

      final sessionWithUnmarked = AttendanceSession(
        id: 'sess_unmarked_01',
        collegeId: 'coll_1',
        departmentId: 'dept_1',
        facultyId: 'fac_1',
        subjectId: 'sub_1',
        subjectName: 'IOT',
        sectionId: 'sec_1',
        sectionName: 'A',
        timeSlot: '10:00 - 12:00',
        date: DateTime(2026, 10, 12),
        records: records,
        status: 'open',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttendanceRecordCard(
              session: sessionWithUnmarked,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Unmarked'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2 unmarked
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // 3 total
    });
  });
}
