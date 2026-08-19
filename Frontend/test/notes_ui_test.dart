import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/notes/domain/models/note_model.dart';
import 'package:campus_management/features/notes/presentation/widgets/note_card.dart';
import 'package:campus_management/features/notes/presentation/screens/note_detail_screen.dart';
import 'package:campus_management/features/notes/presentation/screens/notes_dashboard_screen.dart';
import 'package:campus_management/features/notes/presentation/providers/notes_providers.dart';
import 'package:campus_management/features/notes/presentation/providers/notes_lookup_providers.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/notes/data/repositories/mock_notes_repository.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSubjectNotifier extends SubjectNotifier {
  final List<Subject> _subjects;
  MockSubjectNotifier(this._subjects);

  @override
  Future<List<Subject>> build() async => _subjects;
}

void main() {
  final sampleSubject = Subject(
    id: 'sub-dbms',
    code: 'CS301',
    name: 'Database Management Systems',
    departmentId: 'dept-cse',
    semesterId: 'sem-3',
    credits: 4,
    type: 'theory',
    collegeId: 'col-1',
    isActive: true,
  );

  final sampleFacultyUser = UserModel(
    id: 'fac-prof-1',
    email: 'prof@college.edu',
    name: 'Prof. Turing',
    role: AppRole.faculty,
    collegeId: 'col-1',
    departmentId: 'dept-cse',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final samplePdfNote = NoteModel(
    id: 'note-pdf-1',
    title: 'Relational Algebra Notes',
    description: 'Detailed lecture notes on Select, Project, Join operations',
    chapter: 'Chapter 2: Relational Model',
    resourceType: ResourceType.fileAttachment,
    fileName: 'relational_algebra.pdf',
    fileType: 'pdf',
    fileSize: 2097152, // 2MB
    fileUrl: 'https://storage.example.com/relational_algebra.pdf',
    storagePath: 'colleges/col-1/faculty/fac-prof-1/notes/relational_algebra.pdf',
    subjectId: 'sub-dbms',
    sectionId: 'sec-3a',
    courseId: 'crs-cse',
    departmentId: 'dept-cse',
    collegeId: 'col-1',
    semesterId: 'sem-3',
    facultyId: 'fac-prof-1',
    authorUserId: 'fac-prof-1',
    status: NoteStatus.published,
    publishedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final samplePptxNote = NoteModel(
    id: 'note-pptx-1',
    title: 'Transaction Management Slides',
    description: 'ACID properties and concurrency control slides',
    chapter: 'Chapter 5: Transactions',
    resourceType: ResourceType.fileAttachment,
    fileName: 'transactions.pptx',
    fileType: 'pptx',
    fileSize: 4194304, // 4MB
    fileUrl: 'https://storage.example.com/transactions.pptx',
    storagePath: 'colleges/col-1/faculty/fac-prof-1/notes/transactions.pptx',
    subjectId: 'sub-dbms',
    sectionId: 'sec-3a',
    courseId: 'crs-cse',
    departmentId: 'dept-cse',
    collegeId: 'col-1',
    semesterId: 'sem-3',
    facultyId: 'fac-prof-1',
    authorUserId: 'fac-prof-1',
    status: NoteStatus.published,
    publishedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('Notes UI & Widget Rendering Tests', () {
    testWidgets('NoteCard renders subject badge, preview indicator, and chapter title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesSubjectMapProvider.overrideWithValue({'sub-dbms': sampleSubject}),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NoteCard(
                note: samplePdfNote,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('CS301'), findsOneWidget);
      expect(find.text('Relational Algebra Notes'), findsOneWidget);
      expect(find.text('Chapter 2: Relational Model'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
    });

    testWidgets('NoteCard for PPTX displays Download badge', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesSubjectMapProvider.overrideWithValue({'sub-dbms': sampleSubject}),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NoteCard(
                note: samplePptxNote,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('PPTX'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
    });

    testWidgets('NoteDetailScreen displays file preview button and metadata', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesSubjectMapProvider.overrideWithValue({'sub-dbms': sampleSubject}),
          ],
          child: MaterialApp(
            home: NoteDetailScreen(note: samplePdfNote),
          ),
        ),
      );

      expect(find.text('Note Details'), findsOneWidget);
      expect(find.text('Relational Algebra Notes'), findsOneWidget);
      expect(find.text('CS301 - Database Management Systems'), findsOneWidget);
      expect(find.text('relational_algebra.pdf'), findsOneWidget);
      expect(find.text('Preview Available'), findsOneWidget);
      expect(find.text('Preview / View File'), findsOneWidget);
    });

    testWidgets('NotesDashboardScreen renders search, filter chips, and empty state', (tester) async {
      final mockRepo = MockNotesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: sampleFacultyUser, token: 'token-123'))),
            notesRepositoryProvider.overrideWithValue(mockRepo),
            userNotesProvider.overrideWith((ref) => Stream.value([])),
            subjectsProvider.overrideWith(() => MockSubjectNotifier([sampleSubject])),
            notesSubjectMapProvider.overrideWithValue({'sub-dbms': sampleSubject}),
          ],
          child: const MaterialApp(
            home: NotesDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Notes'), findsOneWidget);
      expect(find.text('Create Note'), findsWidgets);
      expect(find.text('All Types'), findsOneWidget);
      expect(find.text('No Notes Found'), findsOneWidget);
    });
  });
}
