import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/ai_assistant/domain/models/ai_message.dart';
import 'package:campus_management/features/ai_assistant/presentation/widgets/ai_proposal_card.dart';
import 'package:campus_management/features/ai_assistant/presentation/providers/ai_providers.dart';
import 'package:campus_management/features/ai_assistant/data/repositories/mock_ai_repository.dart';
import 'package:campus_management/features/auth/presentation/screens/startup_loading_view.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/app/router/app_router.dart';
import 'package:campus_management/features/auth/presentation/screens/login_screen.dart';

class _DirectAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _DirectAuthNotifier(super.initial);

  @override
  Future<void> login(String identifier, String password) async {}
  @override
  Future<void> loginAsDevelopmentRole(AppRole role) async {}
  @override
  Future<void> logout() async {
    state = const AuthUnauthenticated();
  }
  @override
  Future<void> logoutAll() async {
    state = const AuthUnauthenticated();
  }
  @override
  Future<void> resetPassword(String email) async {}
  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {}
  @override
  void updateCurrentUser(UserModel updatedUser) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Startup & Splash Removal Tests', () {
    testWidgets('StartupLoadingView renders clean minimal progress indicator without splash timers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StartupLoadingView(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Verify no artificial splash text or branding screens
      expect(find.text('Campus Operating System'), findsNothing);
      expect(find.text('Empowering Education'), findsNothing);
    });

    testWidgets('Router routes directly to /login when unauthenticated with no splash delay', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _DirectAuthNotifier(const AuthUnauthenticated())),
        ],
      );

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Directly on LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(StartupLoadingView), findsNothing);
    });
  });

  group('AI Proposal Card & Confirmation Workflow Tests', () {
    testWidgets('Renders Assignment Proposal Preview Card with structured details', (tester) async {
      bool confirmCalled = false;
      bool cancelCalled = false;

      final message = AiMessage(
        text: 'I have prepared a draft for the IoT assignment.',
        isAi: true,
        actionStatus: 'PENDING',
        proposal: {
          'actionId': 'asgn-test-123',
          'actionType': 'CREATE_ASSIGNMENT',
          'summary': 'Create IoT Assignment for Section A',
          'preview': {
            'title': 'Smart Sensors Project',
            'subject': 'Internet of Things',
            'section': 'Section A',
            'dueDate': '2026-11-25',
            'dueTime': '05:00 PM',
            'maximumMarks': 50,
            'description': 'Analyze packet traces from sensors.',
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiProposalCard(
                message: message,
                onConfirm: () => confirmCalled = true,
                onCancel: () => cancelCalled = true,
              ),
            ),
          ),
        ),
      );

      // Verify Title & Type
      expect(find.text('Assignment Draft Proposal'), findsOneWidget);
      expect(find.text('Smart Sensors Project'), findsOneWidget);
      expect(find.text('AWAITING APPROVAL'), findsOneWidget);

      // Verify Metadata
      expect(find.text('Internet of Things'), findsOneWidget);
      expect(find.text('Section A'), findsOneWidget);
      expect(find.text('2026-11-25 at 05:00 PM'), findsOneWidget);
      expect(find.text('50 marks'), findsOneWidget);

      // Verify Buttons
      final confirmBtn = find.byKey(const Key('ai_proposal_confirm_button'));
      final cancelBtn = find.byKey(const Key('ai_proposal_cancel_button'));
      expect(confirmBtn, findsOneWidget);
      expect(cancelBtn, findsOneWidget);

      // Tap Confirm
      await tester.tap(confirmBtn);
      expect(confirmCalled, isTrue);

      // Tap Cancel
      await tester.tap(cancelBtn);
      expect(cancelCalled, isTrue);
    });

    testWidgets('Renders Calendar Event Proposal Preview Card with conflict warning', (tester) async {
      final message = AiMessage(
        text: 'Schedule meeting draft prepared.',
        isAi: true,
        actionStatus: 'PENDING',
        proposal: {
          'actionId': 'cal-test-456',
          'actionType': 'CREATE_CALENDAR_EVENT',
          'summary': 'Schedule Curriculum Meeting',
          'preview': {
            'title': 'Department Curriculum Review Meeting',
            'startDate': '2026-11-20',
            'startTime': '10:00 AM',
            'endTime': '11:30 AM',
            'location': 'Seminar Hall 1',
            'eventType': 'EVENT',
            'conflictWarning': 'Note: Room is booked for another seminar at 11:00 AM.',
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiProposalCard(
                message: message,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Calendar Event Proposal'), findsOneWidget);
      expect(find.text('Department Curriculum Review Meeting'), findsOneWidget);
      expect(find.text('2026-11-20'), findsOneWidget);
      expect(find.text('10:00 AM - 11:30 AM'), findsOneWidget);
      expect(find.text('Seminar Hall 1'), findsOneWidget);
      expect(find.text('Note: Room is booked for another seminar at 11:00 AM.'), findsOneWidget);
    });

    testWidgets('Renders EXECUTED state with success badge and summary', (tester) async {
      final message = AiMessage(
        text: 'Assignment created successfully.',
        isAi: true,
        actionStatus: 'EXECUTED',
        executionResultSummary: 'Assignment created and published successfully to student coursework.',
        proposal: {
          'actionId': 'asgn-test-exec',
          'actionType': 'CREATE_ASSIGNMENT',
          'preview': {
            'title': 'Embedded Systems Lab 3',
            'subject': 'Microcontrollers',
            'section': 'Section B',
            'dueDate': '2026-12-01',
            'dueTime': '11:59 PM',
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiProposalCard(
                message: message,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('Official record committed'), findsOneWidget);
      expect(find.text('Assignment created and published successfully to student coursework.'), findsOneWidget);
      // Confirm & Cancel buttons must be gone
      expect(find.byKey(const Key('ai_proposal_confirm_button')), findsNothing);
      expect(find.byKey(const Key('ai_proposal_cancel_button')), findsNothing);
    });

    testWidgets('Renders CANCELLED state with cancelled badge', (tester) async {
      final message = AiMessage(
        text: 'Proposal cancelled.',
        isAi: true,
        actionStatus: 'CANCELLED',
        proposal: {
          'actionId': 'cal-test-canc',
          'actionType': 'CREATE_CALENDAR_EVENT',
          'preview': {
            'title': 'Cancelled Workshop',
            'startDate': '2026-12-10',
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiProposalCard(
                message: message,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('CANCELLED'), findsOneWidget);
      expect(find.text('Proposal was cancelled without changes'), findsOneWidget);
      expect(find.byKey(const Key('ai_proposal_confirm_button')), findsNothing);
    });

    testWidgets('Renders FAILED state with Retry Confirm button', (tester) async {
      bool retryCalled = false;

      final message = AiMessage(
        text: 'Confirmation failed due to server error.',
        isAi: true,
        actionStatus: 'FAILED',
        proposal: {
          'actionId': 'asgn-test-failed',
          'actionType': 'CREATE_ASSIGNMENT',
          'preview': {
            'title': 'Failed Network Assignment',
            'subject': 'Computer Networks',
            'section': 'Section A',
            'dueDate': '2026-12-15',
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiProposalCard(
                message: message,
                onConfirm: () => retryCalled = true,
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('FAILED'), findsOneWidget);
      expect(find.text('Retry Confirm'), findsOneWidget);

      await tester.tap(find.text('Retry Confirm'));
      expect(retryCalled, isTrue);
    });

    testWidgets('Renders EXPIRED state with expired badge and disabled action', (tester) async {
      final message = AiMessage(
        text: 'Proposal has expired.',
        isAi: true,
        actionStatus: 'EXPIRED',
        proposal: {
          'actionId': 'asgn-test-expired',
          'actionType': 'CREATE_ASSIGNMENT',
          'preview': {
            'title': 'Expired Network Assignment',
            'subject': 'Computer Networks',
            'section': 'Section A',
            'dueDate': '2026-10-01',
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiProposalCard(
                message: message,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('EXPIRED'), findsOneWidget);
      expect(find.text('Proposal expired. Please request a fresh preview.'), findsOneWidget);
      expect(find.byKey(const Key('ai_proposal_confirm_button')), findsNothing);
      expect(find.byKey(const Key('ai_proposal_cancel_button')), findsNothing);
    });

    testWidgets('Renders UNCERTAIN state with Reconcile Status button and invokes callback', (tester) async {
      bool reconcileCalled = false;

      final message = AiMessage(
        text: 'Confirmation status timed out.',
        isAi: true,
        actionStatus: 'UNCERTAIN',
        proposal: {
          'actionId': 'asgn-test-uncertain',
          'actionType': 'CREATE_ASSIGNMENT',
          'preview': {
            'title': 'Distributed Computing Project',
            'subject': 'Cloud Computing',
            'section': 'Section C',
            'dueDate': '2026-12-20',
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiProposalCard(
                message: message,
                onConfirm: () {},
                onCancel: () {},
                onReconcile: () => reconcileCalled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('OUTCOME UNCERTAIN'), findsOneWidget);
      final reconcileBtn = find.text('Reconcile Status');
      expect(reconcileBtn, findsOneWidget);

      await tester.tap(reconcileBtn);
      expect(reconcileCalled, isTrue);
    });

    testWidgets('Renders RECONCILING state with progress indicator', (tester) async {
      final message = AiMessage(
        text: 'Reconciling status...',
        isAi: true,
        actionStatus: 'RECONCILING',
        proposal: {
          'actionId': 'asgn-test-reconciling',
          'actionType': 'CREATE_ASSIGNMENT',
          'preview': {
            'title': 'Distributed Computing Project',
            'subject': 'Cloud Computing',
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiProposalCard(
                message: message,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('RECONCILING...'), findsOneWidget);
      expect(find.text('Reconciling persistence state with server...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    test('AiChatNotifier executes full confirmed write workflow via MockAiRepository', () async {
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWithValue(MockAiRepository()),
          authProvider.overrideWith((ref) => _DirectAuthNotifier(
            AuthAuthenticated(
              user: UserModel(
                id: 'fac_123',
                name: 'Prof. Test Turing',
                email: 'turing@ait.edu',
                role: AppRole.faculty,
                accountStatus: AccountStatus.active,
                collegeId: 'col_123',
                departmentId: 'dept_123',
              ),
              token: 'mock-jwt-token',
            ),
          )),
        ],
      );

      final notifier = container.read(aiChatProvider.notifier);

      // 1. Send query proposing an assignment
      await notifier.sendMessage('Create an IoT assignment for Section A');

      var state = container.read(aiChatProvider);
      expect(state.messages.length, 3); // Welcome + User + AI Proposal
      final proposalMsg = state.messages.last;
      expect(proposalMsg.proposal, isNotNull);
      expect(proposalMsg.actionStatus, 'PENDING');
      expect(proposalMsg.proposal!['actionId'], 'mock-action-asgn-1');

      // 2. Confirm the pending action
      await notifier.confirmAction(proposalMsg.proposal!['actionId'], proposalMsg.id);

      state = container.read(aiChatProvider);
      final confirmedMsg = state.messages.last;
      expect(confirmedMsg.actionStatus, 'EXECUTED');
      expect(confirmedMsg.executionResultSummary, contains('Assignment created and published successfully'));
    });

    test('AiChatNotifier reconciles action status from UNCERTAIN to EXECUTED when server committed', () async {
      final repo = _ExecutedMockAiRepository();
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWithValue(repo),
          authProvider.overrideWith((ref) => _DirectAuthNotifier(
            AuthAuthenticated(
              user: UserModel(
                id: 'fac_123',
                name: 'Prof. Test Turing',
                email: 'turing@ait.edu',
                role: AppRole.faculty,
                accountStatus: AccountStatus.active,
                collegeId: 'col_123',
                departmentId: 'dept_123',
              ),
              token: 'mock-jwt-token',
            ),
          )),
        ],
      );

      final notifier = container.read(aiChatProvider.notifier);

      // Propose assignment
      await notifier.sendMessage('Create an IoT assignment for Section A');
      var state = container.read(aiChatProvider);
      final proposalMsg = state.messages.last;

      // Manually set message status to UNCERTAIN to simulate post-timeout condition
      notifier.state = state.copyWith(
        messages: state.messages.map((m) => m.id == proposalMsg.id ? m.copyWith(actionStatus: 'UNCERTAIN') : m).toList(),
      );

      expect(container.read(aiChatProvider).messages.last.actionStatus, 'UNCERTAIN');

      // Reconcile status
      await notifier.reconcileActionStatus(proposalMsg.proposal!['actionId'], proposalMsg.id);

      // Successfully reconciled to EXECUTED
      final finalMsg = container.read(aiChatProvider).messages.last;
      expect(finalMsg.actionStatus, 'EXECUTED');
      expect(finalMsg.executionResultSummary, contains('verified as successfully created'));
    });

    test('AiChatNotifier reconciles action status from UNCERTAIN to FAILED (safe retry) when server is still PENDING', () async {
      final repo = MockAiRepository(); // returns status: PENDING
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWithValue(repo),
          authProvider.overrideWith((ref) => _DirectAuthNotifier(
            AuthAuthenticated(
              user: UserModel(
                id: 'fac_123',
                name: 'Prof. Test Turing',
                email: 'turing@ait.edu',
                role: AppRole.faculty,
                accountStatus: AccountStatus.active,
                collegeId: 'col_123',
                departmentId: 'dept_123',
              ),
              token: 'mock-jwt-token',
            ),
          )),
        ],
      );

      final notifier = container.read(aiChatProvider.notifier);

      // Propose assignment
      await notifier.sendMessage('Create an IoT assignment for Section A');
      var state = container.read(aiChatProvider);
      final proposalMsg = state.messages.last;

      // Manually set message status to UNCERTAIN to simulate post-timeout condition
      notifier.state = state.copyWith(
        messages: state.messages.map((m) => m.id == proposalMsg.id ? m.copyWith(actionStatus: 'UNCERTAIN') : m).toList(),
      );

      expect(container.read(aiChatProvider).messages.last.actionStatus, 'UNCERTAIN');

      // Reconcile status
      await notifier.reconcileActionStatus(proposalMsg.proposal!['actionId'], proposalMsg.id);

      // Reconciles to FAILED with safe retry instruction
      final finalMsg = container.read(aiChatProvider).messages.last;
      expect(finalMsg.actionStatus, 'FAILED');
      expect(container.read(aiChatProvider).error, contains('Operation was not saved on server'));
    });
  });
}

class _ExecutedMockAiRepository extends MockAiRepository {
  @override
  Future<Map<String, dynamic>> getActionStatus({required String actionId}) async {
    return {
      'actionId': actionId,
      'status': 'EXECUTED',
      'summary': 'Confirmed on server',
    };
  }
}
