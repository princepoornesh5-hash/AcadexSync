import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../domain/models/note_model.dart';
import 'notes_repository.dart';

class FirebaseNotesRepository implements NotesRepository {
  final FirestoreService _firestoreService;

  FirebaseNotesRepository(this._firestoreService);

  CollectionReference get _collection => FirebaseFirestore.instance.collection('notes');

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
    Query query = _collection;

    switch (role) {
      case AppRole.student:
        if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);
        if (departmentId != null) query = query.where('departmentId', isEqualTo: departmentId);
        if (courseId != null) query = query.where('courseId', isEqualTo: courseId);
        if (semesterId != null) query = query.where('semesterId', isEqualTo: semesterId);
        if (sectionId != null) query = query.where('sectionId', isEqualTo: sectionId);
        query = query.where('status', isEqualTo: NoteStatus.published.value);
        break;
      case AppRole.faculty:
        query = query.where('authorUserId', isEqualTo: userId);
        break;
      case AppRole.hod:
        if (departmentId != null) query = query.where('departmentId', isEqualTo: departmentId);
        break;
      case AppRole.collegeAdmin:
        if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);
        break;
      case AppRole.superAdmin:
        break;
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => NoteModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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
    Query query = _collection.where('collegeId', isEqualTo: collegeId);

    if (departmentId != null) query = query.where('departmentId', isEqualTo: departmentId);
    if (courseId != null) query = query.where('courseId', isEqualTo: courseId);
    if (semesterId != null) query = query.where('semesterId', isEqualTo: semesterId);
    if (sectionId != null) query = query.where('sectionId', isEqualTo: sectionId);
    if (subjectId != null) query = query.where('subjectId', isEqualTo: subjectId);
    if (facultyId != null) query = query.where('facultyId', isEqualTo: facultyId);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => NoteModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return NoteModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<void> createNote(NoteModel note) async {
    final docRef = _collection.doc();
    final newNote = note.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      publishedAt: note.status == NoteStatus.published ? DateTime.now() : null,
    );
    await docRef.set(newNote.toJson());
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    final docRef = _collection.doc(note.id);
    
    // We need to fetch the existing note to check if status changed to published
    final existingDoc = await docRef.get();
    if (!existingDoc.exists) throw Exception('Note not found');
    
    final existingNote = NoteModel.fromJson(existingDoc.data() as Map<String, dynamic>);
    DateTime? publishedAt = existingNote.publishedAt;
    
    if (existingNote.status != NoteStatus.published && note.status == NoteStatus.published) {
      publishedAt = DateTime.now();
    } else if (note.status == NoteStatus.unpublished || note.status == NoteStatus.draft) {
      publishedAt = null;
    }

    final updatedNote = note.copyWith(
      updatedAt: DateTime.now(),
      publishedAt: publishedAt,
    );
    
    await docRef.update(updatedNote.toJson());
  }

  @override
  Future<void> deleteNote(String id) async {
    await _collection.doc(id).delete();
  }
}
