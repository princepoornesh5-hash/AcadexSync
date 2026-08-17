import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/notes/domain/models/note_model.dart';
import 'package:campus_management/features/notes/data/repositories/mock_notes_repository.dart';

void main() {
  group('Notes Workflow & Security Tests', () {
    late MockNotesRepository repository;

    setUp(() {
      repository = MockNotesRepository();
    });

    test('Faculty can create note and metadata is preserved', () async {
      final now = DateTime.now();
      final note = NoteModel(
        id: 'new-note-1',
        title: 'Network Topologies',
        description: 'Ring, Star, Mesh topologies',
        resourceType: ResourceType.fileAttachment,
        chapter: 'Chapter 2',
        fileName: 'topologies.pdf',
        fileType: 'pdf',
        fileSize: 1048576, // 1MB
        fileUrl: 'mock://storage/notes/topologies.pdf',
        subjectId: 'sub-cn',
        sectionId: 'sec-1',
        courseId: 'crs-1',
        departmentId: 'dept-1',
        collegeId: 'col-1',
        semesterId: 'sem-1',
        facultyId: 'fac-1',
        authorUserId: 'user-fac-1',
        status: NoteStatus.published,
        createdAt: now,
        updatedAt: now,
      );

      await repository.createNote(note);

      // Verify creation
      await repository.getNoteById('new-note-1');
      // In MockNotesRepository, ID might be overwritten with Uuid, let's just fetch all and check
      final allNotes = await repository.getNotes(collegeId: 'col-1');
      final created = allNotes.firstWhere((n) => n.title == 'Network Topologies');

      expect(created.fileName, 'topologies.pdf');
      expect(created.fileType, 'pdf');
      expect(created.fileSize, 1048576);
      expect(created.chapter, 'Chapter 2');
      expect(created.status, NoteStatus.published);
    });

    test('Faculty edits own note (Mock allows edit through updateNote)', () async {
      // Trigger initialization
      repository.watchNotes(role: AppRole.superAdmin, userId: 'admin');
      await Future.delayed(const Duration(milliseconds: 50));
      
      final notes = await repository.getNotes(collegeId: 'col-1');
      final myNote = notes.firstWhere((n) => n.authorUserId == 'user-fac-1');
      
      final updatedNote = myNote.copyWith(title: 'Updated Title');
      await repository.updateNote(updatedNote);
      
      final fetched = await repository.getNoteById(myNote.id);
      expect(fetched?.title, 'Updated Title');
    });

    test('Student can see published notes in scope', () async {
      final stream = repository.watchNotes(
        role: AppRole.student,
        userId: 'student-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        semesterId: 'sem-3',
        sectionId: 'sec-3a',
      );

      final notes = await stream.first;
      expect(notes.isNotEmpty, true);
      // All should be published
      expect(notes.every((n) => n.status == NoteStatus.published), true);
    });

    test('Draft not visible to students', () async {
      final stream = repository.watchNotes(
        role: AppRole.student,
        userId: 'student-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        semesterId: 'sem-3',
        sectionId: 'sec-3a',
      );

      final notes = await stream.first;
      final drafts = notes.where((n) => n.status == NoteStatus.draft).toList();
      expect(drafts.isEmpty, true);
    });

    test('Student cannot see unauthorized notes (Out of scope)', () async {
      final stream = repository.watchNotes(
        role: AppRole.student,
        userId: 'student-2',
        collegeId: 'col-2', // Different college
        departmentId: 'dept-ece',
        courseId: 'crs-ece',
        semesterId: 'sem-1',
        sectionId: 'sec-1a',
      );

      final notes = await stream.first;
      expect(notes.isEmpty, true); // Since mock initial data is for col-1
    });
  });
}
