import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../domain/models/note_model.dart';
import 'notes_repository.dart';

class MockNotesRepository implements NotesRepository {
  final List<NoteModel> _notes = [];
  bool _initialized = false;
  
  final _controller = StreamController<List<NoteModel>>.broadcast();

  Future<void> _delay() async => await Future.delayed(const Duration(milliseconds: 400));

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.from(_notes));
    }
  }

  void _generateInitialData() {
    final now = DateTime.now();
    _notes.addAll([
      NoteModel(
        id: 'note-1',
        title: 'Introduction to Operating Systems',
        description: 'First lecture notes on OS concepts.',
        content: 'Operating Systems manage computer hardware and software resources...\n\nKey Concepts:\n- Processes\n- Threads\n- Memory Management',
        resourceType: ResourceType.textNote,
        chapter: 'Chapter 1: Basics',
        subjectId: 'sub-os',
        sectionId: 'sec-3a',
        courseId: 'crs-cse',
        departmentId: 'dept-cse',
        collegeId: 'col-1',
        semesterId: 'sem-3',
        facultyId: 'fac-1',
        authorUserId: 'user-fac-1',
        status: NoteStatus.published,
        publishedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      NoteModel(
        id: 'note-2',
        title: 'OS Scheduling Algorithms (External)',
        description: 'Watch this video to understand CPU scheduling.',
        externalUrl: 'https://youtube.com/watch?v=example',
        resourceType: ResourceType.externalLink,
        chapter: 'Chapter 2: Scheduling',
        subjectId: 'sub-os',
        sectionId: 'sec-3a',
        courseId: 'crs-cse',
        departmentId: 'dept-cse',
        collegeId: 'col-1',
        semesterId: 'sem-3',
        facultyId: 'fac-1',
        authorUserId: 'user-fac-1',
        status: NoteStatus.published,
        publishedAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      NoteModel(
        id: 'note-3',
        title: 'DBMS Normalization',
        description: 'Draft notes for the upcoming normalization lecture.',
        content: 'Normalization forms: 1NF, 2NF, 3NF, BCNF.',
        resourceType: ResourceType.textNote,
        chapter: 'Chapter 4: Normalization',
        subjectId: 'sub-dbms',
        sectionId: 'sec-3a',
        courseId: 'crs-cse',
        departmentId: 'dept-cse',
        collegeId: 'col-1',
        semesterId: 'sem-3',
        facultyId: 'fac-1',
        authorUserId: 'user-fac-1',
        status: NoteStatus.draft,
        createdAt: now,
        updatedAt: now,
      ),
      NoteModel(
        id: 'note-4',
        title: 'Computer Networks - OSI Model',
        description: 'Detailed PDF covering all 7 layers of the OSI model.',
        resourceType: ResourceType.fileAttachment,
        chapter: 'Chapter 1: Network Models',
        fileName: 'OSI_Model_Reference.pdf',
        fileType: 'pdf',
        fileSize: 1024 * 1024 * 2, // 2MB
        fileUrl: 'mock://storage/notes/OSI_Model_Reference.pdf',
        subjectId: 'sub-os', // Giving to OS so it shows up for default mock user
        sectionId: 'sec-3a',
        courseId: 'crs-cse',
        departmentId: 'dept-cse',
        collegeId: 'col-1',
        semesterId: 'sem-3',
        facultyId: 'fac-1',
        authorUserId: 'user-fac-1',
        status: NoteStatus.published,
        publishedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  }

  @override
  Stream<List<NoteModel>> watchNotes({
    required AppRole role,
    required String userId,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
  }) {
    if (!_initialized) {
      _generateInitialData();
      _initialized = true;
    }
    
    Future.microtask(() => _emit());

    return _controller.stream.map((allNotes) {
      switch (role) {
        case AppRole.student:
          // Students only see published notes for their specific section/semester
          return allNotes.where((n) {
            return n.status == NoteStatus.published &&
                   n.collegeId == collegeId &&
                   n.departmentId == departmentId &&
                   n.courseId == courseId &&
                   n.semesterId == semesterId &&
                   n.sectionId == sectionId;
          }).toList();
          
        case AppRole.faculty:
          // Faculty sees all their own notes regardless of status
          return allNotes.where((n) => n.authorUserId == userId).toList();
          
        case AppRole.hod:
          // HODs see all notes in their department
          if (departmentId == null) return [];
          return allNotes.where((n) => n.departmentId == departmentId).toList();
          
        case AppRole.collegeAdmin:
          // College Admins see all notes in their college
          if (collegeId == null) return [];
          return allNotes.where((n) => n.collegeId == collegeId).toList();
          
        case AppRole.superAdmin:
          // Super Admins see all notes
          return allNotes;
      }
    });
  }

  @override
  Future<List<NoteModel>> getNotes({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? subjectId,
    String? facultyId,
  }) async {
    await _delay();
    return _notes.where((n) {
      if (n.collegeId != collegeId) return false;
      if (departmentId != null && n.departmentId != departmentId) return false;
      if (courseId != null && n.courseId != courseId) return false;
      if (semesterId != null && n.semesterId != semesterId) return false;
      if (sectionId != null && n.sectionId != sectionId) return false;
      if (subjectId != null && n.subjectId != subjectId) return false;
      if (facultyId != null && n.facultyId != facultyId) return false;
      return true;
    }).toList();
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    await _delay();
    return _notes.where((n) => n.id == id).firstOrNull;
  }

  @override
  Future<void> createNote(NoteModel note) async {
    await _delay();
    final newNote = note.copyWith(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      publishedAt: note.status == NoteStatus.published ? DateTime.now() : null,
    );
    _notes.add(newNote);
    _emit();
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    await _delay();
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index == -1) throw Exception('Note not found');
    
    final existing = _notes[index];
    DateTime? publishedAt = existing.publishedAt;
    
    if (existing.status != NoteStatus.published && note.status == NoteStatus.published) {
      publishedAt = DateTime.now();
    } else if (note.status == NoteStatus.unpublished || note.status == NoteStatus.draft) {
      publishedAt = null; // Maybe keep it? Or reset it. Usually it's reset or kept. Let's reset for now.
    }

    _notes[index] = note.copyWith(
      updatedAt: DateTime.now(),
      publishedAt: publishedAt,
    );
    _emit();
  }

  @override
  Future<void> deleteNote(String id) async {
    await _delay();
    _notes.removeWhere((n) => n.id == id);
    _emit();
  }
}
