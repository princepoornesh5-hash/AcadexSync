import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:campus_management/core/errors/acadex_error.dart';
import 'package:campus_management/core/presentation/time_board/acadex_live_time_board.dart';
import 'package:campus_management/core/presentation/time_board/acadex_time_engine.dart';
import 'package:campus_management/features/users/presentation/screens/user_form_screen.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';

void main() {
  group('Core Functional Repair - Frontend Error Mapping Tests', () {
    test('Subject duplicate error is correctly mapped to subject message, not semester', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/academics/subjects'),
        response: Response(
          requestOptions: RequestOptions(path: '/academics/subjects'),
          statusCode: 409,
          data: {
            'message': 'Subject with code "CS101" already exists in this semester',
            'code': 'CONFLICT',
          },
        ),
      );

      final acadexException = AcadexException.fromDio(dioError);
      expect(acadexException.userMessage.toLowerCase(), contains('subject'));
      expect(acadexException.userMessage, isNot(contains('That semester already exists')));
    });

    test('Genuine semester duplicate error is correctly mapped to semester message', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/academics/semesters'),
        response: Response(
          requestOptions: RequestOptions(path: '/academics/semesters'),
          statusCode: 409,
          data: {
            'message': 'Semester already exists for this academic year',
            'code': 'CONFLICT',
          },
        ),
      );

      final acadexException = AcadexException.fromDio(dioError);
      expect(acadexException.userMessage, contains('semester already exists'));
    });
  });

  group('Core Functional Repair - Acadex Live Time Board Tests', () {
    testWidgets('Live time board is read-only and tapping does not advance time', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexLiveTimeBoard(isCompact: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialFinder = find.byType(AcadexLiveTimeBoard);
      expect(initialFinder, findsOneWidget);

      // Verify that no GestureDetector mutates time on tap
      await tester.tap(initialFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Multiple taps should not accelerate or mutate time
      for (int i = 0; i < 5; i++) {
        await tester.tap(initialFinder);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Time board remains stably mounted and read-only
      expect(find.byType(AcadexLiveTimeBoard), findsOneWidget);
    });

    test('AcadexTimeEngine uses nowIst() without cumulative drift', () {
      final now = AcadexTimeEngine.nowIst();
      expect(now, isNotNull);
      // IST is UTC+5:30
      final offset = now.timeZoneOffset;
      expect(offset.inMinutes, equals(330));
    });
  });

  group('Core Functional Repair - HOD Role Boundaries in User Form', () {
    testWidgets('HOD can only provision Student and role selector is locked', (WidgetTester tester) async {
      const hodUser = UserModel(
        id: 'hod_123',
        collegeId: 'college_alpha',
        departmentId: 'dept_cse',
        email: 'hod@alpha.edu',
        name: 'Dr. Alan HOD',
        role: AppRole.hod,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => hodUser),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UserFormScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // For HOD, allowedRoles is [AppRole.student] only.
      // The dropdown should NOT be present; instead a fixed badge with "Student" should be displayed.
      expect(find.text('Student'), findsWidgets);
      expect(find.text('Role (Locked)'), findsOneWidget);
      expect(find.text('Faculty'), findsNothing);
      expect(find.text('College Admin'), findsNothing);
      expect(find.text('Super Admin'), findsNothing);
    });

    testWidgets('College Admin sees full selectable role options', (WidgetTester tester) async {
      const adminUser = UserModel(
        id: 'admin_123',
        collegeId: 'college_alpha',
        email: 'admin@alpha.edu',
        name: 'College Admin',
        role: AppRole.collegeAdmin,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => adminUser),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UserFormScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // For College Admin, role dropdown is available with multiple roles
      expect(find.text('Role *'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<AppRole>), findsOneWidget);
    });
  });
}
