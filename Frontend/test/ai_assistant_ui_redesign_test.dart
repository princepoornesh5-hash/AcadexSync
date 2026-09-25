import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/ai_assistant/presentation/ai_assistant_screen.dart';
import 'package:campus_management/features/ai_assistant/presentation/widgets/ai_composer.dart';
import 'package:campus_management/features/ai_assistant/presentation/widgets/ai_markdown_view.dart';
import 'package:campus_management/features/ai_assistant/presentation/widgets/ai_chat_sidebar.dart';
import 'package:campus_management/features/ai_assistant/presentation/providers/ai_providers.dart';
import 'package:campus_management/features/ai_assistant/data/repositories/mock_ai_repository.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = UserModel(
    id: 'student_123',
    name: 'Aarav Patel',
    email: 'aarav@college.edu',
    role: AppRole.student,
    collegeId: 'college_abc',
    departmentId: 'dept_cse',
    instituteId: 'INST_01',
    accountStatus: AccountStatus.active,
  );

  Widget createTestWidget({
    Size screenSize = const Size(1280, 800),
    AuthState? customAuth,
  }) {
    final authState = customAuth ?? AuthAuthenticated(user: testUser, token: 'test_token');
    return ProviderScope(
      overrides: [
        aiRepositoryProvider.overrideWithValue(MockAiRepository()),
        authProvider.overrideWith((ref) => _FakeAuthNotifier(authState)),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const AiAssistantScreen(),
        ),
      ),
    );
  }

  group('AI Assistant UI Redesign Tests', () {
    testWidgets('1. Empty state renders with ACADEX AI branding and prompt suggestions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Acadex Assistant'), findsOneWidget);
      expect(find.text('Academic AI'), findsOneWidget);

      // Verify Empty State Title
      expect(find.text('What can I help you with?'), findsOneWidget);

      // Verify 4 student suggestion prompt cards
      expect(find.text('How can I check my attendance?'), findsOneWidget);
      expect(find.text('Explain my attendance percentage.'), findsOneWidget);
      expect(find.text('Where can I find my notes?'), findsOneWidget);
      expect(find.text('Where can I find my timetable?'), findsOneWidget);

      // Verify Composer
      expect(find.byType(AiComposer), findsOneWidget);
      expect(find.text('Ask ACADEX Assistant...'), findsOneWidget);
      expect(find.text('Acadex AI can make mistakes. Verify important academic information.'), findsOneWidget);
    });

    testWidgets('2. Desktop Collapsible Sidebar renders user profile and new chat button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AiChatSidebar), findsOneWidget);
      expect(find.text('New Chat'), findsOneWidget);
      expect(find.text('CHAT HISTORY'), findsOneWidget);
      expect(find.text('No previous chats'), findsOneWidget);
      expect(find.text('Aarav Patel'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
    });

    testWidgets('3. Sidebar toggle button collapses and expands sidebar on desktop', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find toggle button
      final toggleButton = find.byTooltip('Collapse sidebar');
      expect(toggleButton, findsOneWidget);

      // Click to collapse
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Open sidebar'), findsOneWidget);

      // Click to expand again
      await tester.tap(find.byTooltip('Open sidebar'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Collapse sidebar'), findsOneWidget);
    });

    testWidgets('4. Submitting a prompt card executes query and renders user and AI response', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap suggestion card
      final promptCard = find.text('How can I check my attendance?');
      expect(promptCard, findsOneWidget);
      await tester.tap(promptCard);
      await tester.pumpAndSettle();

      // User message rendered
      expect(find.text('How can I check my attendance?'), findsOneWidget);

      // Assistant response rendered via MockAiRepository
      expect(find.byType(AiMarkdownView), findsWidgets);
      expect(find.textContaining('Attendance'), findsWidgets);
      expect(find.text('Copy'), findsWidgets);
    });

    testWidgets('5. Typing and sending via AiComposer works', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter text
      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'Where can I find my timetable?');
      await tester.pump();

      // Click send button
      final sendButton = find.byTooltip('Send message');
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify message displayed
      expect(find.text('Where can I find my timetable?'), findsOneWidget);
      expect(find.byType(AiMarkdownView), findsWidgets);
    });

    testWidgets('6. Markdown view renders headings, bullet points, and code blocks with copy', (tester) async {
      const markdownSample = '''
# Academic Guidelines
## Section Rules
- Rule 1: Always check attendance
- Rule 2: Verify timetable
```python
def check_attendance():
    return True
```
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiMarkdownView(text: markdownSample),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Academic Guidelines'), findsOneWidget);
      expect(find.textContaining('Section Rules'), findsOneWidget);
      expect(find.textContaining('Rule 1: Always check attendance'), findsOneWidget);
      expect(find.text('PYTHON'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.textContaining('def check_attendance():'), findsOneWidget);
    });

    testWidgets('7. Mobile layout renders cleanly at 360x800 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpWidget(createTestWidget(screenSize: const Size(360, 800)));
      await tester.pumpAndSettle();

      // Mobile should show menu drawer icon instead of fixed sidebar
      expect(find.byTooltip('Open chats sidebar'), findsOneWidget);
      expect(find.text('What can I help you with?'), findsOneWidget);
      expect(find.byType(AiComposer), findsOneWidget);

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('8. New Chat button resets the chat back to initial state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Send a query
      await tester.tap(find.text('Where can I find my notes?'));
      await tester.pumpAndSettle();

      expect(find.text('Where can I find my notes?'), findsOneWidget);

      // Click New Chat in header
      await tester.tap(find.byTooltip('New Chat'));
      await tester.pumpAndSettle();

      // Expect return to empty state
      expect(find.text('What can I help you with?'), findsOneWidget);
    });
  });
}
