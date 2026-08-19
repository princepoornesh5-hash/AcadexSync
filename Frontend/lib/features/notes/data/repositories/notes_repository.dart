import '../../domain/models/note_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../features/auth/domain/models/role_enum.dart';

abstract class NotesRepository {
  /// Watches notes filtered by the user's role and scopes.
  Stream<List<NoteModel>> watchNotes({
    required AppRole role,
    required String userId,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
  });

  /// Fetches notes for a specific set of parameters, useful for management screens.
  Future<List<NoteModel>> getNotes({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? subjectId,
    String? facultyId,
  });

  Future<PaginatedResponse<NoteModel>> getPaginatedNotes({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? subjectId,
    String? facultyId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  });

  /// Fetches a specific note by ID.
  Future<NoteModel?> getNoteById(String id);

  /// Creates a new note.
  Future<void> createNote(NoteModel note);

  /// Updates an existing note.
  Future<void> updateNote(NoteModel note);

  /// Deletes a note by its ID.
  Future<void> deleteNote(String id);
}
