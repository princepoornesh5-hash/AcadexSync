import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/teaching_handover_dialog.dart';

void main() {
  group('ACADEX PROMPT 4: Flutter Models & Handover Test Suite', () {
    test('1. TeachingHandover model serializes and deserializes correctly', () {
      final now = DateTime.now();
      final handover = TeachingHandover(
        id: 'ho-101',
        collegeId: 'col-A',
        departmentId: 'dept-CS',
        subjectId: 'sub-MATH',
        sectionId: 'sec-A',
        sourceAssignmentId: 'asg-old',
        targetAssignmentId: 'asg-new',
        previousFacultyId: 'fac-1',
        successorFacultyId: 'fac-2',
        reassignedPendingWork: true,
        reassignedCounts: {'assignments': 2, 'attendanceSessions': 0},
        handedOverBy: 'admin-1',
        status: 'COMPLETED',
        handoverDate: now,
        notes: 'Handover due to faculty transfer',
      );

      final json = handover.toJson();
      expect(json['id'], 'ho-101');
      expect(json['status'], 'COMPLETED');
      expect(json['reassignedPendingWork'], true);

      final fromJson = TeachingHandover.fromJson(json);
      expect(fromJson.id, 'ho-101');
      expect(fromJson.previousFacultyId, 'fac-1');
      expect(fromJson.successorFacultyId, 'fac-2');
      expect(fromJson.reassignedPendingWork, true);
    });

    test('2. DepartmentTenure model maintains active status and immutable attribution', () {
      final now = DateTime.now();
      final tenure = DepartmentTenure(
        id: 'ten-201',
        collegeId: 'col-A',
        departmentId: 'dept-CS',
        userId: 'usr-hod',
        userName: 'Dr. Turing',
        userEmail: 'turing@col-a.edu',
        startDate: now.subtract(const Duration(days: 100)),
        status: 'ACTIVE',
      );

      expect(tenure.isActive, isTrue);

      final json = tenure.toJson();
      final fromJson = DepartmentTenure.fromJson(json);
      expect(fromJson.userName, 'Dr. Turing');
      expect(fromJson.isActive, isTrue);
    });

    test('3. StudentTransfer model isolates source and destination PIN numbers', () {
      final now = DateTime.now();
      final transfer = StudentTransfer(
        id: 'st-301',
        globalUserId: 'usr-global-1',
        sourceCollegeId: 'col-A',
        destinationCollegeId: 'col-B',
        sourcePin: 'COLA-2024-001',
        destinationPin: 'COLB-2026-099',
        status: 'APPROVED',
        effectiveDate: now,
        reason: 'Relocated family to new state',
      );

      expect(transfer.isApproved, isTrue);
      expect(transfer.sourcePin, 'COLA-2024-001');
      expect(transfer.destinationPin, 'COLB-2026-099');

      final fromJson = StudentTransfer.fromJson(transfer.toJson());
      expect(fromJson.sourcePin, 'COLA-2024-001');
      expect(fromJson.destinationPin, 'COLB-2026-099');
      expect(fromJson.isApproved, isTrue);
    });

    test('4. TransferCredit preserves source college name and subject code', () {
      final credit = TransferCredit(
        id: 'tc-401',
        collegeId: 'col-B',
        studentId: 'stu-1',
        sourceCollegeName: 'Institute of Technology A',
        sourceSubjectCode: 'CS101',
        sourceSubjectName: 'Intro to Computer Science',
        creditsEarned: 4,
        gradeObtained: 'A',
        status: 'APPROVED',
        verificationRemarks: 'Syllabus mapped and approved by Academic Council',
      );

      expect(credit.isApproved, isTrue);
      expect(credit.creditsEarned, 4);
      expect(credit.sourceCollegeName, 'Institute of Technology A');

      final fromJson = TransferCredit.fromJson(credit.toJson());
      expect(fromJson.sourceSubjectCode, 'CS101');
      expect(fromJson.sourceCollegeName, 'Institute of Technology A');
      expect(fromJson.isApproved, isTrue);
    });

    test('5. MockAcademicRepository executes handover without throwing', () async {
      final repo = MockAcademicRepository();
      final handover = await repo.handoverFacultyAssignment(
        assignmentId: 'asg-test-1',
        successorFacultyId: 'fac-succ-1',
        handoverNotes: 'Semester transition handover',
        reassignPendingWork: true,
      );

      expect(handover.sourceAssignmentId, 'asg-test-1');
      expect(handover.successorFacultyId, 'fac-succ-1');
      expect(handover.status, 'COMPLETED');

      final tenures = await repo.getDepartmentTenureHistory('d1');
      expect(tenures.isNotEmpty, isTrue);
      expect(tenures.first.isActive, isTrue);
    });

    testWidgets('6. TeachingHandoverDialog displays form and current teacher context', (tester) async {
      final mockAssignment = FacultyAssignment(
        id: 'asg-99',
        collegeId: 'c1',
        departmentId: 'd1',
        facultyId: 'f1',
        facultyName: 'Prof. Alice',
        courseId: 'crs1',
        semesterId: 'sem1',
        sectionId: 'sec1',
        subjectId: 'sub1',
        academicYearId: 'ay1',
        isActive: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            academicRepositoryProvider.overrideWithValue(MockAcademicRepository()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TeachingHandoverDialog(assignment: mockAssignment),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Teaching Handover'), findsOneWidget);
      expect(find.textContaining('Prof. Alice'), findsOneWidget);
      expect(find.text('Reassign Pending Assignments & Attendance'), findsOneWidget);
      expect(find.text('Execute Handover'), findsOneWidget);
    });
  });
}
