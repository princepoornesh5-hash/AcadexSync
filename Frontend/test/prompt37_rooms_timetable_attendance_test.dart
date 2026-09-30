import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/attendance/domain/models/assigned_class.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';

class TestFacultyAssignmentNotifier extends FacultyAssignmentsNotifier {
  final List<FacultyAssignment> initialAssignments;
  TestFacultyAssignmentNotifier(this.initialAssignments);
  @override
  Future<List<FacultyAssignment>> build() async => initialAssignments;
}

void main() {
  group('PROMPT 37 — Frontend Rooms, Timetable & Attendance Hardening Tests', () {
    test('Room model handles retirement and active status serialization', () {
      final activeRoomJson = {
        'id': 'room_101',
        'collegeId': 'col_01',
        'departmentId': 'dept_cse',
        'name': 'Lecture Hall 101',
        'code': 'LH101',
        'capacity': 80,
        'type': 'lecture',
        'status': 'active',
        'isActive': true,
      };

      final room = Room.fromJson(activeRoomJson);
      expect(room.id, 'room_101');
      expect(room.name, 'Lecture Hall 101');
      expect(room.code, 'LH101');
      expect(room.capacity, 80);
      expect(room.isActive, true);

      // Retired room model
      final retiredRoomJson = {
        'id': 'room_102',
        'collegeId': 'col_01',
        'name': 'Old Shed',
        'code': 'SHED',
        'capacity': 30,
        'type': 'lecture',
        'status': 'retired',
        'isActive': false,
      };

      final retiredRoom = Room.fromJson(retiredRoomJson);
      expect(retiredRoom.id, 'room_102');
      expect(retiredRoom.status, 'retired');
      expect(retiredRoom.isActive, false);
    });

    test('AssignedClass handles section optionality and formatting without artifacts', () {
      // 1. With section
      final assignedWithSection = AssignedClass(
        id: 'cls_01',
        subjectId: 'sub_dbms',
        subjectName: 'Database Management Systems',
        sectionId: 'sec_a',
        sectionName: 'A',
        semester: '5',
        timeSlot: '09:00 - 10:00',
        date: DateTime(2026, 9, 1),
      );

      expect(assignedWithSection.sectionId, 'sec_a');
      expect(assignedWithSection.contextualDescription, contains('Class A'));

      // 2. Without section (section-disabled institution)
      final assignedWithoutSection = AssignedClass(
        id: 'cls_02',
        subjectId: 'sub_algo',
        subjectName: 'Algorithms',
        sectionId: '',
        sectionName: '',
        semester: '5',
        timeSlot: '10:00 - 11:00',
        date: DateTime(2026, 9, 1),
      );

      expect(assignedWithoutSection.sectionId, isEmpty);
      expect(assignedWithoutSection.sectionName, isEmpty);
      // Contextual description should not contain "Class " or trailing empty strings
      expect(assignedWithoutSection.contextualDescription, isNot(contains('Class ')));
      expect(assignedWithoutSection.contextualDescription, 'Semester 5');
    });

    test('AttendanceSession handles null sectionId and sectionName gracefully', () {
      final json = {
        'id': 'sess_01',
        'collegeId': 'col_01',
        'departmentId': 'dept_01',
        'facultyId': 'fac_01',
        'subjectId': 'sub_01',
        'subjectName': 'Operating Systems',
        'sectionId': null,
        'sectionName': null,
        'timeSlot': '11:00 - 12:00',
        'date': '2026-09-02T00:00:00.000Z',
        'status': 'open',
        'isLocked': false,
        'records': [],
      };

      final session = AttendanceSession.fromJson(json);
      expect(session.id, 'sess_01');
      expect(session.sectionId, '');
      expect(session.sectionName, '');
      expect(session.isOpen, true);
      expect(session.isLockedState, false);
    });

    test('facultyAssignmentsBySemesterProvider filters assignments correctly for section-disabled context', () async {
      final testAssignments = [
        FacultyAssignment(
          id: 'fa_1',
          collegeId: 'col_1',
          departmentId: 'dept_1',
          facultyId: 'fac_1',
          facultyName: 'Dr. Turing',
          courseId: 'crs_1',
          academicYearId: 'ay_1',
          semesterId: 'sem_1',
          sectionId: null,
          subjectId: 'sub_1',
          isActive: true,
          status: 'active',
          assignedAt: DateTime.now(),
        ),
        FacultyAssignment(
          id: 'fa_2',
          collegeId: 'col_1',
          departmentId: 'dept_1',
          facultyId: 'fac_2',
          facultyName: 'Dr. Lovelace',
          courseId: 'crs_1',
          academicYearId: 'ay_1',
          semesterId: 'sem_2', // Different semester
          sectionId: null,
          subjectId: 'sub_2',
          isActive: true,
          status: 'active',
          assignedAt: DateTime.now(),
        ),
        FacultyAssignment(
          id: 'fa_3',
          collegeId: 'col_1',
          departmentId: 'dept_1',
          facultyId: 'fac_3',
          facultyName: 'Dr. Knuth',
          courseId: 'crs_1',
          academicYearId: 'ay_1',
          semesterId: 'sem_1',
          sectionId: null,
          subjectId: 'sub_3',
          isActive: false, // Inactive
          status: 'inactive',
          assignedAt: DateTime.now(),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          facultyAssignmentsProvider.overrideWith(
            () => TestFacultyAssignmentNotifier(testAssignments),
          ),
        ],
      );

      // Await build completion
      await container.read(facultyAssignmentsProvider.future);

      final sem1Assignments = container.read(facultyAssignmentsBySemesterProvider('sem_1'));
      expect(sem1Assignments.length, 1);
      expect(sem1Assignments[0].id, 'fa_1');
      expect(sem1Assignments[0].facultyName, 'Dr. Turing');

      final sem2Assignments = container.read(facultyAssignmentsBySemesterProvider('sem_2'));
      expect(sem2Assignments.length, 1);
      expect(sem2Assignments[0].id, 'fa_2');
      expect(sem2Assignments[0].facultyName, 'Dr. Lovelace');

      final sem3Assignments = container.read(facultyAssignmentsBySemesterProvider('sem_3'));
      expect(sem3Assignments, isEmpty);
    });
  });
}
