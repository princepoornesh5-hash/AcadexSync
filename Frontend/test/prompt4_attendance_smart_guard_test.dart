import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:campus_management/features/attendance/domain/models/assigned_class.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_status.dart';
import 'package:campus_management/features/attendance/presentation/widgets/acadex_attendance_guard_card.dart';
import 'package:campus_management/features/attendance/presentation/widgets/student_attendance_card.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:campus_management/features/attendance/presentation/screens/mark_attendance_screen.dart';

void main() {
  final sampleClass = AssignedClass(
    id: 'entry_cs501_secA',
    timetableId: 'tt_sem5',
    timetableEntryId: 'tt_entry_101',
    facultyId: 'fac_999',
    facultyAssignmentId: 'fa_456',
    subjectId: 'sub_cn101',
    subjectName: 'Computer Networks',
    sectionId: 'sec_5a',
    sectionName: 'Section A',
    semester: 'Semester 5',
    timeSlot: '09:00 - 10:00',
    date: DateTime(2026, 9, 30),
    isAttendanceMarked: false,
    cohort: '2024-28',
    academicStage: 'Undergraduate',
  );

  group('AcadexAttendanceGuardCard - Authoritative Context & Smart Guard', () {
    testWidgets('renders authoritative subject, section breadcrumb, time slot, and ready status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcadexAttendanceGuardCard(
              activeClass: sampleClass,
              totalStudents: 42,
              isMarked: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ATTENDANCE GUARD'), findsOneWidget);
      expect(find.text('Computer Networks'), findsOneWidget);
      expect(find.text('09:00 - 10:00'), findsOneWidget);
      expect(find.text('42 Enrolled'), findsOneWidget);
      expect(find.text('Ready to Mark'), findsOneWidget);
    });

    testWidgets('renders correct badge when attendance is already submitted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcadexAttendanceGuardCard(
              activeClass: sampleClass,
              totalStudents: 40,
              isMarked: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Submitted (Editable)'), findsOneWidget);
    });

    testWidgets('renders locked status badge when session is locked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcadexAttendanceGuardCard(
              activeClass: sampleClass,
              totalStudents: 38,
              isLocked: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session Locked'), findsOneWidget);
    });

    testWidgets('renders closed status badge when session is closed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcadexAttendanceGuardCard(
              activeClass: sampleClass,
              totalStudents: 38,
              isClosed: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session Closed'), findsOneWidget);
    });

    testWidgets('adapts layout cleanly across mobile, tablet, and desktop constraints', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      for (final width in [320.0, 390.0, 480.0, 768.0, 1200.0]) {
        tester.view.physicalSize = Size(width, 800.0);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AcadexAttendanceGuardCard(
                activeClass: sampleClass,
                totalStudents: 42,
                isMarked: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Computer Networks'), findsOneWidget);
        expect(find.text('ATTENDANCE GUARD'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('StudentAttendanceCard - Compact, Accessible & Theme Adaptive', () {
    final sampleRecord = AttendanceRecord(
      id: 'rec_1',
      studentId: 'stud_101',
      studentName: 'Aarav Kumar',
      rollNumber: 'CS-2024-001',
      sectionId: 'sec_5a',
      status: null,
    );

    testWidgets('renders student name, roll number, unmarked state, and all 4 segment buttons', (tester) async {
      AttendanceStatus? selectedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentAttendanceCard(
              record: sampleRecord,
              onStatusChanged: (status) => selectedStatus = status,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aarav Kumar'), findsOneWidget);
      expect(find.text('CS-2024-001'), findsOneWidget);
      expect(find.text('UNMARKED'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Late'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(find.text('Excused'), findsOneWidget);

      // Tap Present
      await tester.tap(find.text('Present'));
      await tester.pumpAndSettle();
      expect(selectedStatus, equals(AttendanceStatus.present));

      // Tap Absent
      await tester.tap(find.text('Absent'));
      await tester.pumpAndSettle();
      expect(selectedStatus, equals(AttendanceStatus.absent));
    });

    testWidgets('accessible semantics labels are present for assistive screen-readers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentAttendanceCard(
              record: sampleRecord.copyWith(status: AttendanceStatus.present),
              onStatusChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Mark Aarav Kumar as Present'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Mark Aarav Kumar as Absent'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Status: present'),
        findsOneWidget,
      );
    });

    testWidgets('resilient to 1.25 text scaling without clipping or overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.25)),
            child: Scaffold(
              body: StudentAttendanceCard(
                record: sampleRecord,
                onStatusChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aarav Kumar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('adapts smoothly across narrow and wide constraints', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      for (final width in [320.0, 400.0, 600.0, 1024.0]) {
        tester.view.physicalSize = Size(width, 400.0);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StudentAttendanceCard(
                record: sampleRecord,
                onStatusChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Aarav Kumar'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('MarkAttendanceScreen - Smart Guard Flow & Unsaved Changes Protection', () {
    testWidgets('shows No Class Selected empty state when activeClass is null', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MarkAttendanceScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Class Selected'), findsOneWidget);
      expect(find.text('View Schedule'), findsOneWidget);
    });

    testWidgets('renders Smart Guard card and student roster when active class is set', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final records = [
        AttendanceRecord(
          id: 'rec_1',
          studentId: 'stud_1',
          studentName: 'Aarav Kumar',
          rollNumber: 'CS-001',
          sectionId: 'sec_5a',
          status: null,
        ),
        AttendanceRecord(
          id: 'rec_2',
          studentId: 'stud_2',
          studentName: 'Ananya Sharma',
          rollNumber: 'CS-002',
          sectionId: 'sec_5a',
          status: null,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeClassProvider.overrideWith((ref) => sampleClass),
            activeStudentListProvider.overrideWith((ref) => Future.value(records)),
          ],
          child: const MaterialApp(
            home: MarkAttendanceScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ATTENDANCE GUARD'), findsOneWidget);
      expect(find.text('Computer Networks'), findsWidgets);
      expect(find.text('Aarav Kumar'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Ananya Sharma'), 150, scrollable: find.byType(Scrollable).first);
      expect(find.text('Ananya Sharma'), findsOneWidget);
      expect(find.text('All Present'), findsOneWidget);
      expect(find.text('All Absent'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);
    });

    testWidgets('bulk action All Present marks all students as Present and updates summary', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final records = [
        AttendanceRecord(
          id: 'rec_1',
          studentId: 'stud_1',
          studentName: 'Aarav Kumar',
          rollNumber: 'CS-001',
          sectionId: 'sec_5a',
          status: null,
        ),
        AttendanceRecord(
          id: 'rec_2',
          studentId: 'stud_2',
          studentName: 'Ananya Sharma',
          rollNumber: 'CS-002',
          sectionId: 'sec_5a',
          status: null,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeClassProvider.overrideWith((ref) => sampleClass),
            activeStudentListProvider.overrideWith((ref) => Future.value(records)),
          ],
          child: const MaterialApp(
            home: MarkAttendanceScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap All Present button
      await tester.tap(find.text('All Present'));
      await tester.pumpAndSettle();

      // Tap Save Attendance button to trigger review dialog
      final saveButton = find.text('Save Attendance');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify explicit review dialog shows totals
      expect(find.text('Review & Submit Attendance'), findsOneWidget);
      expect(find.text('• Total Students: 2'), findsOneWidget);
      expect(find.text('• Present: 2'), findsOneWidget);
      expect(find.text('• Absent: 0'), findsOneWidget);
      expect(find.text('Confirm & Submit'), findsOneWidget);
    });

    testWidgets('triggers unsaved changes protection dialog when back button is pressed with changes', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final records = [
        AttendanceRecord(
          id: 'rec_1',
          studentId: 'stud_1',
          studentName: 'Aarav Kumar',
          rollNumber: 'CS-001',
          sectionId: 'sec_5a',
          status: null,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeClassProvider.overrideWith((ref) => sampleClass),
            activeStudentListProvider.overrideWith((ref) => Future.value(records)),
          ],
          child: const MaterialApp(
            home: MarkAttendanceScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mark student as present using card segment button
      final studentCardPresent = find.descendant(
        of: find.byType(StudentAttendanceCard),
        matching: find.text('Present'),
      );
      await tester.tap(studentCardPresent);
      await tester.pumpAndSettle();

      // Tap Back button in AppBar
      final backButton = find.byIcon(LucideIcons.arrowLeft);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify unsaved changes confirmation dialog is displayed
      expect(find.text('Unsaved Attendance Changes'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Discard Changes'), findsOneWidget);

      // Tap Keep Editing -> dialog dismisses, screen remains
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved Attendance Changes'), findsNothing);
      expect(find.text('Aarav Kumar'), findsOneWidget);
    });
  });
}
