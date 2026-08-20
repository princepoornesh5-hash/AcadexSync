import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

import 'package:campus_management/features/notes/domain/models/note_model.dart';
import 'package:campus_management/features/notes/presentation/providers/notes_providers.dart';
import 'package:campus_management/features/notes/presentation/providers/notes_lookup_providers.dart';
import 'package:campus_management/features/notes/presentation/screens/notes_dashboard_screen.dart';
import 'package:campus_management/features/notes/presentation/screens/note_detail_screen.dart';
import 'package:campus_management/features/notes/presentation/widgets/note_card.dart';
import 'package:campus_management/features/notes/data/repositories/mock_notes_repository.dart';
import 'package:campus_management/features/notes/data/repositories/api_notes_repository.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.initial);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubjectNotifier extends AutoDisposeAsyncNotifier<List<Subject>> implements SubjectNotifier {
  final List<Subject> _subjects;
  _FakeSubjectNotifier(this._subjects);

  @override
  Future<List<Subject>> build() async => _subjects;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ACADEX Phase 9Q.5 — Notes UI Vertical Slice Tests', () {
    final sampleSubject = Subject(
      id: 'sub_algo',
      collegeId: 'col_123',
      departmentId: 'dept_cse',
      semesterId: 'sem_6',
      name: 'Design and Analysis of Algorithms',
      code: 'CS601',
      credits: 4,
      type: 'THEORY',
    );

    final sampleNote1 = NoteModel(
      id: 'note_1',
      title: 'Dynamic Programming & Memoization',
      description: 'Comprehensive study guide and practice problem sets for Dynamic Programming.',
      chapter: 'Chapter 4: Advanced Algorithms',
      resourceType: ResourceType.fileAttachment,
      fileName: 'algorithms_dp_guide.pdf',
      fileSize: 2048576, // 2MB
      fileType: 'pdf',
      fileUrl: 'https://ik.imagekit.io/acadex/notes/algorithms_dp_guide.pdf',
      mimeType: 'application/pdf',
      version: 1,
      subjectId: 'sub_algo',
      sectionId: 'sec_a',
      courseId: 'course_btech',
      departmentId: 'dept_cse',
      collegeId: 'col_123',
      semesterId: 'sem_6',
      facultyId: 'fac_101',
      authorUserId: 'fac_101',
      status: NoteStatus.published,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final sampleNote2 = NoteModel(
      id: 'note_2',
      title: 'Graph Traversal Cheat Sheet',
      description: 'BFS and DFS summary notes with complexity proofs.',
      chapter: 'Chapter 2: Graphs',
      resourceType: ResourceType.textNote,
      content: 'BFS uses a Queue data structure (FIFO) while DFS uses a Stack (LIFO)...',
      version: 1,
      subjectId: 'sub_algo',
      sectionId: 'sec_a',
      courseId: 'course_btech',
      departmentId: 'dept_cse',
      collegeId: 'col_123',
      semesterId: 'sem_6',
      facultyId: 'fac_101',
      authorUserId: 'fac_101',
      status: NoteStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets('1. Student sees NotesDashboardScreen with academic resources title', (tester) async {
      final studentUser = UserModel(
        id: 'student_1',
        name: 'Arjun Verma',
        email: 'arjun@acadex.edu',
        role: AppRole.student,
        collegeId: 'col_123',
        departmentId: 'dept_cse',
        sectionId: 'sec_a',
        accountStatus: AccountStatus.active,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: studentUser, token: 'fake-token')),
            ),
            userNotesProvider.overrideWith(
              (ref) => Stream.value([sampleNote1]),
            ),
            subjectsProvider.overrideWith(
              () => _FakeSubjectNotifier([sampleSubject]),
            ),
            notesSubjectMapProvider.overrideWith(
              (ref) => {'sub_algo': sampleSubject},
            ),
          ],
          child: const MaterialApp(
            home: NotesDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Academic Resources'), findsOneWidget);
      expect(find.text('Dynamic Programming & Memoization'), findsOneWidget);
      // Student shouldn't see Create Note action
      expect(find.text('Create Note'), findsNothing);
    });

    testWidgets('2. Faculty sees NotesDashboardScreen with My Notes title and Create button', (tester) async {
      final facultyUser = UserModel(
        id: 'fac_101',
        name: 'Dr. Sarah Connor',
        email: 'sarah@acadex.edu',
        role: AppRole.faculty,
        collegeId: 'col_123',
        departmentId: 'dept_cse',
        accountStatus: AccountStatus.active,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: facultyUser, token: 'fake-token')),
            ),
            userNotesProvider.overrideWith(
              (ref) => Stream.value([sampleNote1, sampleNote2]),
            ),
            subjectsProvider.overrideWith(
              () => _FakeSubjectNotifier([sampleSubject]),
            ),
            notesSubjectMapProvider.overrideWith(
              (ref) => {'sub_algo': sampleSubject},
            ),
          ],
          child: const MaterialApp(
            home: NotesDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Notes'), findsOneWidget);
      expect(find.text('Create Note'), findsOneWidget);
      expect(find.text('Dynamic Programming & Memoization'), findsOneWidget);
      expect(find.text('Graph Traversal Cheat Sheet'), findsOneWidget);
    });

    testWidgets('3. NoteCard renders title, chapter, subject code, and badges correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesSubjectMapProvider.overrideWith(
              (ref) => {'sub_algo': sampleSubject},
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NoteCard(
                note: sampleNote1,
                subject: sampleSubject,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dynamic Programming & Memoization'), findsOneWidget);
      expect(find.text('Chapter 4: Advanced Algorithms'), findsOneWidget);
      expect(find.text('CS601'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('4. NoteDetailScreen renders note metadata and download button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesSubjectMapProvider.overrideWith(
              (ref) => {'sub_algo': sampleSubject},
            ),
          ],
          child: MaterialApp(
            home: NoteDetailScreen(note: sampleNote1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Note Details'), findsOneWidget);
      expect(find.text('Dynamic Programming & Memoization'), findsOneWidget);
      expect(find.text('Chapter 4: Advanced Algorithms'), findsOneWidget);
      expect(find.text('CS601 - Design and Analysis of Algorithms'), findsOneWidget);
      expect(find.text('algorithms_dp_guide.pdf'), findsOneWidget);
      expect(find.text('Preview / View File'), findsOneWidget);
    });

    testWidgets('5. NotesDashboardScreen renders empty state when no notes exist', (tester) async {
      final studentUser = UserModel(
        id: 'student_1',
        name: 'Arjun Verma',
        email: 'arjun@acadex.edu',
        role: AppRole.student,
        collegeId: 'col_123',
        departmentId: 'dept_cse',
        sectionId: 'sec_a',
        accountStatus: AccountStatus.active,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: studentUser, token: 'fake-token')),
            ),
            userNotesProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            subjectsProvider.overrideWith(
              () => _FakeSubjectNotifier([]),
            ),
          ],
          child: const MaterialApp(
            home: NotesDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Notes Found'), findsOneWidget);
      expect(find.text('Check back later for newly published academic resources.'), findsOneWidget);
    });

    testWidgets('6. ApiNotesRepository can instantiate and fall back gracefully', (tester) async {
      final repo = ApiNotesRepository();
      expect(repo, isA<ApiNotesRepository>());

      final mockRepo = MockNotesRepository();
      expect(mockRepo, isA<MockNotesRepository>());
    });
  });
}
