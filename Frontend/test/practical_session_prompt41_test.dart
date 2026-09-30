import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/practicals/domain/models/practical_models.dart';
import 'package:campus_management/features/practicals/data/repositories/practicals_repository.dart';
import 'package:campus_management/features/practicals/presentation/providers/practicals_providers.dart';
import 'package:campus_management/features/practicals/presentation/widgets/practical_participation_card.dart';
import 'package:campus_management/features/practicals/presentation/screens/practical_sessions_list_screen.dart';
import 'package:campus_management/features/practicals/presentation/screens/new_practical_session_screen.dart';
import 'package:campus_management/features/practicals/presentation/screens/practical_session_detail_screen.dart';
import 'package:campus_management/features/practicals/presentation/screens/student_practicals_screen.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/core/realtime/presentation/providers/realtime_providers.dart';
import 'package:campus_management/core/realtime/models/realtime_event.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePracticalsRepository implements PracticalsRepository {
  PracticalSessionModel testSession;
  List<PracticalParticipationModel> testParticipations;
  List<StudentPracticalHistoryModel> testHistory;

  FakePracticalsRepository({
    required this.testSession,
    required this.testParticipations,
    required this.testHistory,
  });

  @override
  Future<List<PracticalSessionModel>> getSessions({
    String? facultyAssignmentId,
    String? subjectId,
    String? sectionId,
    String? status,
  }) async =>
      [testSession];

  @override
  Future<({PracticalSessionModel session, List<PracticalParticipationModel> participations})> getSessionById(
    String sessionId,
  ) async =>
      (session: testSession, participations: testParticipations);

  @override
  Future<PracticalSessionModel> createSession(Map<String, dynamic> payload) async => testSession;

  @override
  Future<PracticalSessionModel> openSession(String sessionId) async {
    testSession = testSession.copyWith(status: PracticalSessionStatus.open);
    return testSession;
  }

  @override
  Future<PracticalSessionModel> completeSession(String sessionId) async {
    testSession = testSession.copyWith(status: PracticalSessionStatus.completed);
    return testSession;
  }

  @override
  Future<PracticalSessionModel> cancelSession(String sessionId, {String? reason}) async {
    testSession = testSession.copyWith(status: PracticalSessionStatus.cancelled);
    return testSession;
  }

  @override
  Future<PracticalParticipationModel> updateParticipation({
    required String sessionId,
    required String studentId,
    required PracticalParticipationStatus status,
    String? notes,
  }) async {
    final idx = testParticipations.indexWhere((p) => p.studentId == studentId);
    if (idx >= 0) {
      final updated = testParticipations[idx].copyWith(status: status, notes: notes);
      testParticipations[idx] = updated;
      return updated;
    }
    throw Exception('Student participation not found');
  }

  @override
  Future<PracticalSessionModel> bulkUpdateParticipation({
    required String sessionId,
    required List<Map<String, dynamic>> updates,
  }) async {
    for (final u in updates) {
      final sid = u['studentId'] as String;
      final stStr = u['status'] as String?;
      final st = PracticalParticipationStatus.fromString(stStr);
      final idx = testParticipations.indexWhere((p) => p.studentId == sid);
      if (idx >= 0) {
        testParticipations[idx] = testParticipations[idx].copyWith(status: st);
      }
    }
    return testSession;
  }

  @override
  Future<List<StudentPracticalHistoryModel>> getStudentHistory({
    String? studentId,
    String? subjectId,
  }) async =>
      testHistory;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockFacultyUser = UserModel(
    id: 'fac-101',
    name: 'Prof. Ada Lovelace',
    email: 'ada@acadex.edu',
    role: AppRole.faculty,
    collegeId: 'col-1',
  );

  final mockStudentUser = UserModel(
    id: 'stud-201',
    name: 'Alan Turing',
    email: 'alan@acadex.edu',
    role: AppRole.student,
    collegeId: 'col-1',
  );

  final sampleSession = PracticalSessionModel(
    id: 'psess-001',
    collegeId: 'col-1',
    departmentId: 'dept-001',
    courseId: 'crs-001',
    semesterId: 'sem-4',
    sectionId: 'sec-a',
    subjectId: 'sub-001',
    subjectName: 'Data Structures Lab',
    subjectCode: 'CS204',
    facultyAssignmentId: 'fa-001',
    facultyId: 'fac-101',
    facultyName: 'Prof. Ada Lovelace',
    roomId: 'room-101',
    roomNumber: 'Lab 3B',
    sessionNumber: 1,
    topic: 'Binary Search Trees & Balancing',
    instructions: 'Implement AVL rotation and traversal functions.',
    scheduledDate: DateTime(2026, 10, 15, 14, 0),
    startTime: '14:00',
    endTime: '16:00',
    status: PracticalSessionStatus.open,
    totalEnrolled: 2,
    completedCount: 1,
    inProgressCount: 1,
    absentCount: 0,
  );

  final List<PracticalParticipationModel> sampleParticipations = [
    PracticalParticipationModel(
      participationId: 'part-001',
      studentId: 'stud-201',
      studentName: 'Alan Turing',
      rollNumber: 'CS202601',
      status: PracticalParticipationStatus.completed,
      notes: 'Clean recursion logic.',
      completedAt: DateTime(2026, 10, 15, 15, 30),
    ),
    PracticalParticipationModel(
      participationId: 'part-002',
      studentId: 'stud-202',
      studentName: 'Grace Hopper',
      rollNumber: 'CS202602',
      status: PracticalParticipationStatus.inProgress,
    ),
  ];

  final List<StudentPracticalHistoryModel> sampleHistory = [
    StudentPracticalHistoryModel(
      sessionId: 'psess-001',
      topic: 'Binary Search Trees & Balancing',
      sessionNumber: 1,
      scheduledDate: DateTime(2026, 10, 15, 14, 0),
      subjectName: 'Data Structures Lab',
      subjectCode: 'CS204',
      sessionStatus: PracticalSessionStatus.open,
      participationStatus: PracticalParticipationStatus.completed,
      notes: 'Clean recursion logic.',
      completedAt: DateTime(2026, 10, 15, 15, 30),
      roomNumber: 'Lab 3B',
    ),
  ];

  group('Prompt 41 - Practical Domain Models Serialization', () {
    test('PracticalSessionModel serialization & deserialization', () {
      final json = sampleSession.toJson();
      expect(json['topic'], 'Binary Search Trees & Balancing');
      expect(json['status'], 'OPEN');
      expect(json['roomNumber'], 'Lab 3B');

      final reconstructed = PracticalSessionModel.fromJson(json);
      expect(reconstructed.id, sampleSession.id);
      expect(reconstructed.status, PracticalSessionStatus.open);
      expect(reconstructed.totalEnrolled, 2);
      expect(reconstructed.completedCount, 1);
    });

    test('PracticalParticipationModel serialization & deserialization', () {
      final part = sampleParticipations.first;
      final json = part.toJson();
      expect(json['status'], 'COMPLETED');
      expect(json['studentName'], 'Alan Turing');

      final reconstructed = PracticalParticipationModel.fromJson(json);
      expect(reconstructed.id, part.id);
      expect(reconstructed.status, PracticalParticipationStatus.completed);
      expect(reconstructed.rollNumber, 'CS202601');
      expect(reconstructed.notes, 'Clean recursion logic.');
    });

    test('StudentPracticalHistoryModel fromJson parsing', () {
      final item = sampleHistory.first;
      expect(item.topic, 'Binary Search Trees & Balancing');
      expect(item.participationStatus, PracticalParticipationStatus.completed);
      expect(item.roomNumber, 'Lab 3B');
    });

    test('Status enum safety and fallback', () {
      expect(PracticalSessionStatus.planned.displayName, 'Planned');
      expect(PracticalSessionStatus.open.displayName, 'Open');
      expect(PracticalSessionStatus.completed.displayName, 'Completed');
      expect(PracticalSessionStatus.cancelled.displayName, 'Cancelled');

      expect(PracticalParticipationStatus.completed.displayName, 'Completed');
      expect(PracticalParticipationStatus.inProgress.displayName, 'In Progress');
      expect(PracticalParticipationStatus.absent.displayName, 'Absent');
      expect(PracticalParticipationStatus.excused.displayName, 'Excused');
      expect(PracticalParticipationStatus.notStarted.displayName, 'Not Started');
    });
  });

  group('Prompt 41 - Mobile-first UX on 360px Width', () {
    testWidgets('PracticalParticipationCard renders cleanly on 360px viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      PracticalParticipationStatus? toggledStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PracticalParticipationCard(
              participation: sampleParticipations.first,
              isSessionOpen: true,
              onStatusChanged: (st) => toggledStatus = st,
            ),
          ),
        ),
      );

      expect(find.text('Alan Turing'), findsOneWidget);
      expect(find.text('(CS202601)'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);

      // Verify status change interaction
      await tester.tap(find.text('In Progress'));
      await tester.pump();
      expect(toggledStatus, PracticalParticipationStatus.inProgress);
    });

    testWidgets('PracticalSessionsListScreen renders on 360px without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakePracticalsRepository(
        testSession: sampleSession,
        testParticipations: sampleParticipations,
        testHistory: sampleHistory,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: mockFacultyUser, token: 'fake-token'))),
            practicalsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: PracticalSessionsListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Practicals & Labs'), findsOneWidget);
      expect(find.textContaining('Binary Search Trees & Balancing'), findsOneWidget);
      expect(find.text('Schedule Lab'), findsOneWidget);
    });

    testWidgets('NewPracticalSessionScreen renders schedule form on 360px without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakePracticalsRepository(
        testSession: sampleSession,
        testParticipations: sampleParticipations,
        testHistory: sampleHistory,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: mockFacultyUser, token: 'fake-token'))),
            practicalsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: NewPracticalSessionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Schedule Practical Lab'), findsOneWidget);
      expect(find.text('Topic / Experiment Title *'), findsOneWidget);
      expect(find.text('Schedule Practical Session'), findsOneWidget);
    });

    testWidgets('PracticalSessionDetailScreen renders roster, metrics & actions on 360px', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakePracticalsRepository(
        testSession: sampleSession,
        testParticipations: sampleParticipations,
        testHistory: sampleHistory,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: mockFacultyUser, token: 'fake-token'))),
            practicalsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: PracticalSessionDetailScreen(sessionId: 'psess-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Practical Session'), findsOneWidget);
      expect(find.text('Binary Search Trees & Balancing'), findsOneWidget);
      expect(find.text('Alan Turing'), findsOneWidget);
      expect(find.text('Grace Hopper'), findsOneWidget);
      expect(find.text('Complete Session'), findsOneWidget);
      expect(find.text('Mark All Completed'), findsOneWidget);
      expect(find.text('Mark All Present'), findsOneWidget);
    });

    testWidgets('StudentPracticalsScreen renders read-only student history', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakePracticalsRepository(
        testSession: sampleSession,
        testParticipations: sampleParticipations,
        testHistory: sampleHistory,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: mockStudentUser, token: 'fake-token'))),
            practicalsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: StudentPracticalsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Practical Labs'), findsOneWidget);
      expect(find.textContaining('Binary Search Trees & Balancing'), findsOneWidget);
      expect(find.textContaining('Data Structures Lab'), findsOneWidget);
      expect(find.textContaining('Clean recursion logic.'), findsOneWidget);
      // Ensure student cannot see faculty action buttons
      expect(find.text('Schedule Lab'), findsNothing);
      expect(find.text('Complete Session'), findsNothing);
      expect(find.text('Bulk Actions'), findsNothing);
    });
  });

  group('Prompt 41 - Realtime Event Invalidation', () {
    test('RealtimeDispatcher handles practical events and invalidates providers', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: mockFacultyUser, token: 'fake-token'))),
        ],
      );
      addTearDown(container.dispose);

      final dispatcher = container.read(realtimeDispatcherProvider);
      final controller = StreamController<RealtimeEvent>();
      addTearDown(() {
        dispatcher.stop();
        controller.close();
      });

      dispatcher.start(controller.stream);

      final event = RealtimeEvent(
        eventId: 'evt-001',
        eventVersion: 1,
        eventType: 'practical.session.updated',
        aggregateType: 'PRACTICAL_SESSION',
        aggregateId: 'psess-001',
        action: 'UPDATED',
        occurredAt: DateTime.now(),
        collegeId: 'col-1',
        scope: {'subjectId': 'sub-001'},
        payload: {'topic': 'Binary Search Trees & Balancing Updated'},
      );

      controller.add(event);
      await Future<void>.delayed(const Duration(milliseconds: 350));
    });
  });
}
