import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_management/features/notifications/presentation/screens/create_announcement_screen.dart';
import 'package:campus_management/features/notifications/data/repositories/api_notification_repository.dart';
import 'package:campus_management/core/presentation/screens/not_found_screen.dart';
import 'package:campus_management/core/network/api_client.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/domain/repositories/academic_repository.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockAcademicRepo implements AcademicRepository {
  @override
  Future<List<Department>> getDepartments({String? collegeId, String? search, String? status}) async {
    return [
      Department(
        id: 'dept-cse',
        collegeId: 'col-1',
        name: 'Computer Science',
        code: 'CSE',
        hodId: 'hod-1',
        description: 'CSE Dept',
      ),
    ];
  }

  @override
  Future<List<Course>> getCourses({String? collegeId, String? departmentId, String? search}) async => [];

  @override
  Future<List<AcademicYear>> getAcademicYears({String? collegeId}) async => [];

  @override
  Future<List<Semester>> getSemesters({String? collegeId, String? courseId, String? academicYearId}) async => [];

  @override
  Future<List<Section>> getSections({String? semesterId, String? courseId, String? collegeId}) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testHod = UserModel(
    id: 'hod-1',
    name: 'Dr. Alan Turing',
    email: 'hod.cse@acadex.edu',
    role: AppRole.hod,
    collegeId: 'col-1',
    departmentId: 'dept-cse',
  );

  const testStudent = UserModel(
    id: 'std-1',
    name: 'Alice Student',
    email: 'alice@acadex.edu',
    role: AppRole.student,
    collegeId: 'col-1',
    departmentId: 'dept-cse',
  );

  group('ACADEX Prompt 2 — Announcement Creation & Routing Tests', () {
    testWidgets('1. CreateAnnouncementScreen renders form with title, content, audience & publish controls', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(const AuthAuthenticated(user: testHod, token: 'tok'))),
            academicRepositoryProvider.overrideWithValue(_MockAcademicRepo()),
          ],
          child: const MaterialApp(
            home: CreateAnnouncementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create Announcement'), findsOneWidget);
      expect(find.text('Announcement Title *'), findsOneWidget);
      expect(find.text('Announcement Body *'), findsOneWidget);
      expect(find.text('Save Draft'), findsOneWidget);
      expect(find.text('Publish Now'), findsOneWidget);
    });

    testWidgets('2. Validation prevents submission when required fields are empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(const AuthAuthenticated(user: testHod, token: 'tok'))),
            academicRepositoryProvider.overrideWithValue(_MockAcademicRepo()),
          ],
          child: const MaterialApp(
            home: CreateAnnouncementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to and tap Publish Now without filling in title or content
      final publishBtn = find.text('Publish Now');
      await tester.ensureVisible(publishBtn);
      await tester.pumpAndSettle();
      await tester.tap(publishBtn);
      await tester.pumpAndSettle();

      // Form validation error messages should appear
      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Body is required'), findsOneWidget);
    });

    testWidgets('3. Form submission calls API with publishNow: true and audience scope', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Map<String, dynamic>? capturedPayload;

      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/announcements' && options.method == 'POST') {
            capturedPayload = options.data as Map<String, dynamic>;
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 201,
              data: {
                'success': true,
                'data': {
                  'id': 'ann-123',
                  'collegeId': 'col-1',
                  'departmentId': 'dept-cse',
                  'title': capturedPayload!['title'],
                  'body': capturedPayload!['body'],
                  'audienceScope': capturedPayload!['audienceScope'],
                  'status': 'PUBLISHED',
                  'createdBy': 'hod-1',
                  'createdAt': DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                },
              },
            ));
          }
          return handler.next(options);
        },
      ));

      final client = ApiClient(customDio: dio);
      final repo = ApiNotificationRepository(apiClient: client);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(const AuthAuthenticated(user: testHod, token: 'tok'))),
            academicRepositoryProvider.overrideWithValue(_MockAcademicRepo()),
            apiNotificationRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: CreateAnnouncementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fill in title
      final titleField = find.widgetWithText(TextFormField, 'Announcement Title *');
      await tester.enterText(titleField, 'End of Semester Lab Exam Notice');

      // Fill in message content
      final contentField = find.widgetWithText(TextFormField, 'Announcement Body *');
      await tester.enterText(contentField, 'All students must bring their lab records signed by faculty.');

      // Scroll to and tap Publish Now
      final publishBtn = find.text('Publish Now');
      await tester.ensureVisible(publishBtn);
      await tester.pumpAndSettle();
      await tester.tap(publishBtn);
      await tester.pumpAndSettle();

      expect(capturedPayload, isNotNull);
      expect(capturedPayload!['title'], equals('End of Semester Lab Exam Notice'));
      expect(capturedPayload!['body'], equals('All students must bring their lab records signed by faculty.'));
      expect(capturedPayload!['publishNow'], isTrue);
      expect(capturedPayload!['status'], equals('PUBLISHED'));
      expect(capturedPayload!['audienceScope'], equals('DEPARTMENT'));
      expect(capturedPayload!['departmentId'], equals('dept-cse'));
    });

    testWidgets('4. AcadexNotFoundScreen handles unknown routes without leaking GoException', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(const AuthAuthenticated(user: testHod, token: 'tok'))),
          ],
          child: const MaterialApp(
            home: AcadexNotFoundScreen(
              location: '/unknown/dead/route',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('404 — PAGE NOT FOUND'), findsOneWidget);
      expect(find.text('Page unavailable'), findsOneWidget);
      expect(find.text('/unknown/dead/route'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
      expect(find.text('Go to Dashboard'), findsOneWidget);
      expect(find.textContaining('GoException'), findsNothing);
    });

    testWidgets('5. Direct access to CreateAnnouncementScreen by Student shows permission denied', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(const AuthAuthenticated(user: testStudent, token: 'tok'))),
            academicRepositoryProvider.overrideWithValue(_MockAcademicRepo()),
          ],
          child: const MaterialApp(
            home: CreateAnnouncementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('You do not have permission to create announcements.'), findsOneWidget);
      expect(find.text('Publish Now'), findsNothing);
    });
  });
}
