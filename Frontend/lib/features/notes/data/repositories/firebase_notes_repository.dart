import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../features/storage/domain/repositories/file_storage_repository.dart';
import '../../domain/models/note_model.dart';
import 'notes_repository.dart';
import '../../../../features/notifications/domain/services/notification_service.dart';

class FirebaseNotesRepository implements NotesRepository {
  final FirestoreService _firestoreService;
  final FileStorageRepository? _storageRepository;
  final NotificationService? _notificationService;

  FirebaseNotesRepository(
    this._firestoreService, {
    FileStorageRepository? storageRepository,
    NotificationService? notificationService,
  })  : _storageRepository = storageRepository,
        _notificationService = notificationService;

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
    final filters = <String, dynamic>{};

    switch (role) {
      case AppRole.student:
        if (collegeId != null) filters['collegeId'] = collegeId;
        if (departmentId != null) filters['departmentId'] = departmentId;
        if (courseId != null) filters['courseId'] = courseId;
        if (semesterId != null) filters['semesterId'] = semesterId;
        if (sectionId != null) filters['sectionId'] = sectionId;
        filters['status'] = NoteStatus.published.value;
        break;
      case AppRole.faculty:
        filters['authorUserId'] = userId;
        if (collegeId != null) filters['collegeId'] = collegeId;
        break;
      case AppRole.hod:
        if (collegeId != null) filters['collegeId'] = collegeId;
        if (departmentId != null) filters['departmentId'] = departmentId;
        break;
      case AppRole.collegeAdmin:
        if (collegeId != null) filters['collegeId'] = collegeId;
        break;
      case AppRole.superAdmin:
        if (collegeId != null) filters['collegeId'] = collegeId;
        break;
    }

    return _firestoreService
        .watchQuery('notes', filters, limit: 50, orderBy: 'updatedAt', descending: true)
        .map((docs) {
      return docs.map((doc) => NoteModel.fromJson(doc)).toList();
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
    final filters = <String, dynamic>{'collegeId': collegeId};

    if (departmentId != null) filters['departmentId'] = departmentId;
    if (courseId != null) filters['courseId'] = courseId;
    if (semesterId != null) filters['semesterId'] = semesterId;
    if (sectionId != null) filters['sectionId'] = sectionId;
    if (subjectId != null) filters['subjectId'] = subjectId;
    if (facultyId != null) filters['facultyId'] = facultyId;

    final docs = await _firestoreService.queryCollection('notes', filters);
    return docs.map((doc) => NoteModel.fromJson(doc)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
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
  }) async {
    final filters = <String, dynamic>{'collegeId': collegeId};

    if (departmentId != null) filters['departmentId'] = departmentId;
    if (courseId != null) filters['courseId'] = courseId;
    if (semesterId != null) filters['semesterId'] = semesterId;
    if (sectionId != null) filters['sectionId'] = sectionId;
    if (subjectId != null) filters['subjectId'] = subjectId;
    if (facultyId != null) filters['authorUserId'] = facultyId;

    final response = await _firestoreService.queryCollectionPaginated(
      'notes',
      filters,
      limit: limit,
      orderBy: 'updatedAt',
      descending: true,
      startAfterDocument: startAfter,
    );

    return PaginatedResponse(
      data: response.data.map((doc) => NoteModel.fromJson(doc)).toList(),
      lastDocument: response.lastDocument,
      hasMore: response.hasMore,
    );
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    final doc = await _firestoreService.getDocument('notes', id);
    if (doc == null) return null;
    return NoteModel.fromJson(doc);
  }

  @override
  Future<void> createNote(NoteModel note) async {
    await _validateNoteAuthorization(note);
    final newId = note.id.isNotEmpty ? note.id : 'note_${DateTime.now().millisecondsSinceEpoch}';
    final newNote = note.copyWith(
      id: newId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      publishedAt: note.status == NoteStatus.published ? DateTime.now() : null,
    );
    await _firestoreService.setDocument('notes', newId, newNote.toJson());

    if (newNote.status == NoteStatus.published && _notificationService != null) {
      try {
        await _notificationService.notifyNotePublished(
          noteId: newNote.id,
          noteTitle: newNote.title,
          sectionId: newNote.sectionId,
        );
      } catch (e) {
        developer.log('Notification dispatch warning for note publication: $e', name: 'Acadex.Notes');
      }
    }
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    await _validateNoteAuthorization(note);

    final existingDoc = await _firestoreService.getDocument('notes', note.id);
    if (existingDoc == null) throw Exception('Note not found');

    final existingNote = NoteModel.fromJson(existingDoc);
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

    await _firestoreService.setDocument('notes', note.id, updatedNote.toJson());

    if (existingNote.status != NoteStatus.published &&
        note.status == NoteStatus.published &&
        _notificationService != null) {
      try {
        await _notificationService.notifyNotePublished(
          noteId: updatedNote.id,
          noteTitle: updatedNote.title,
          sectionId: updatedNote.sectionId,
        );
      } catch (e) {
        developer.log('Notification dispatch warning for note publication: $e', name: 'Acadex.Notes');
      }
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    // 1. Fetch note to clean up physical storage asset if present
    try {
      final doc = await _firestoreService.getDocument('notes', id);
      if (doc != null && _storageRepository != null) {
        final note = NoteModel.fromJson(doc);
        if (note.storagePath != null && note.storagePath!.isNotEmpty) {
          try {
            await _storageRepository.deleteFile(note.storagePath!);
          } catch (e) {
            developer.log('Warning: Failed to delete Storage file ${note.storagePath}: $e', name: 'Acadex.Notes');
          }
        } else if (note.fileName != null &&
            note.fileName!.isNotEmpty &&
            note.collegeId.isNotEmpty &&
            note.authorUserId.isNotEmpty) {
          final inferredPath = 'colleges/${note.collegeId}/faculty/${note.authorUserId}/notes/${note.fileName}';
          try {
            await _storageRepository.deleteFile(inferredPath);
          } catch (_) {}
        }
      }
    } catch (e) {
      developer.log('Pre-delete storage cleanup warning: $e', name: 'Acadex.Notes');
    }

    // 2. Delete Firestore document
    await _firestoreService.deleteDocument('notes', id);
  }

  Future<void> _validateNoteAuthorization(NoteModel note) async {
    final userDoc = await _firestoreService.getDocument('users', note.authorUserId);
    if (userDoc == null) throw Exception('User not found');

    final rawRole = userDoc['role'] as String?;
    if (rawRole == null) throw Exception('User role missing');
    final role = AppRoleExtension.fromValue(rawRole);

    if (role != AppRole.faculty &&
        role != AppRole.superAdmin &&
        role != AppRole.collegeAdmin &&
        role != AppRole.hod) {
      throw Exception('Unauthorized role to manage notes');
    }

    if (role == AppRole.faculty) {
      final subjectIds = List<String>.from(userDoc['subjectIds'] ?? userDoc['assignedSubjects'] ?? []);
      final sectionIds = List<String>.from(userDoc['sectionIds'] ?? userDoc['assignedSections'] ?? []);

      if (subjectIds.isNotEmpty && !subjectIds.contains(note.subjectId)) {
        throw Exception('Unauthorized: Faculty is not assigned to this subject.');
      }
      if (sectionIds.isNotEmpty && !sectionIds.contains(note.sectionId)) {
        throw Exception('Unauthorized: Faculty is not assigned to this section.');
      }
    }
  }
}
