import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/notes/domain/models/note_model.dart';
import 'package:campus_management/features/notes/domain/utils/note_mime_helper.dart';
import 'package:campus_management/features/notes/data/repositories/firebase_notes_repository.dart';
import 'package:campus_management/features/notes/presentation/providers/notes_providers.dart';
import 'package:campus_management/features/storage/domain/repositories/file_storage_repository.dart';
import 'package:campus_management/features/storage/domain/models/stored_file.dart';
import 'package:campus_management/features/storage/domain/models/file_category.dart';
import 'package:campus_management/features/notifications/domain/services/notification_service.dart';
import 'package:campus_management/core/firebase/firebase_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

// Fake FirestoreService for testing query generation and operations
class FakeFirestoreService implements FirestoreService {
  final Map<String, Map<String, dynamic>> collections = {};
  Map<String, dynamic>? lastWatchFilters;
  Map<String, dynamic>? lastQueryFilters;

  @override
  Stream<List<Map<String, dynamic>>> watchQuery(
    String collection,
    Map<String, dynamic> filters, {
    int? limit = 50,
    String? orderBy,
    bool descending = false,
  }) {
    lastWatchFilters = Map.from(filters);
    final results = collections.entries
        .where((e) => e.key.startsWith('$collection/'))
        .map((e) => e.value)
        .where((doc) {
          for (final entry in filters.entries) {
            if (doc[entry.key] != entry.value) return false;
          }
          return true;
        })
        .toList();
    return Stream.value(results);
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollection(
    String collection,
    Map<String, dynamic> filters, {
    int? limit = 100,
    String? orderBy,
    bool descending = false,
  }) async {
    lastQueryFilters = Map.from(filters);
    return collections.entries
        .where((e) => e.key.startsWith('$collection/'))
        .map((e) => e.value)
        .where((doc) {
          for (final entry in filters.entries) {
            if (doc[entry.key] != entry.value) return false;
          }
          return true;
        })
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getDocument(String collection, String docId) async {
    return collections['$collection/$docId'];
  }

  @override
  Future<void> setDocument(String collection, String docId, Map<String, dynamic> data) async {
    collections['$collection/$docId'] = data;
  }

  @override
  Future<void> deleteDocument(String collection, String docId) async {
    collections.remove('$collection/$docId');
  }

  @override
  Future<PaginatedResponse<Map<String, dynamic>>> queryCollectionPaginated(
    String collection,
    Map<String, dynamic> filters, {
    int limit = 20,
    String? orderBy,
    bool descending = false,
    DocumentSnapshot? startAfterDocument,
  }) async {
    lastQueryFilters = Map.from(filters);
    final list = collections.entries
        .where((e) => e.key.startsWith('$collection/'))
        .map((e) => e.value)
        .toList();
    return PaginatedResponse(data: list, hasMore: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake FileStorageRepository for verifying cleanup
class FakeFileStorageRepository implements FileStorageRepository {
  final List<String> deletedPaths = [];
  final List<String> uploadedFiles = [];

  @override
  Future<StoredFile> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required FileCategory category,
    required String ownerUid,
    String? collegeId,
    String? departmentId,
    String? studentId,
    String? facultyUid,
    Map<String, String>? customMetadata,
  }) async {
    final path = 'colleges/$collegeId/faculty/$ownerUid/notes/$fileName';
    uploadedFiles.add(path);
    return StoredFile(
      id: 'file-123',
      fileName: fileName,
      downloadUrl: 'https://storage.googleapis.com/$path',
      storagePath: path,
      sizeBytes: bytes.length,
      contentType: contentType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      ownerUid: ownerUid,
      category: category,
      collegeId: collegeId,
      departmentId: departmentId,
    );
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    deletedPaths.add(storagePath);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake NotificationService that throws to test isolation
class ThrowingNotificationService implements NotificationService {
  @override
  Future<void> notifyNotePublished({
    required String noteId,
    required String noteTitle,
    required String sectionId,
  }) async {
    throw Exception('Simulated push notification network timeout');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Notes Module Firebase & Auth Repair Tests', () {
    late FakeFirestoreService firestoreService;
    late FakeFileStorageRepository storageRepo;
    late FirebaseNotesRepository repository;

    setUp(() {
      firestoreService = FakeFirestoreService();
      storageRepo = FakeFileStorageRepository();
      repository = FirebaseNotesRepository(
        firestoreService,
        storageRepository: storageRepo,
      );
    });

    test('Student query strictly scopes by collegeId, departmentId, and published status', () async {
      repository.watchNotes(
        role: AppRole.student,
        userId: 'student-uid-1',
        collegeId: 'college-alpha',
        departmentId: 'dept-cse',
        sectionId: 'sec-a',
        semesterId: 'sem-3',
      ).listen((_) {});

      expect(firestoreService.lastWatchFilters, isNotNull);
      expect(firestoreService.lastWatchFilters!['collegeId'], 'college-alpha');
      expect(firestoreService.lastWatchFilters!['departmentId'], 'dept-cse');
      expect(firestoreService.lastWatchFilters!['sectionId'], 'sec-a');
      expect(firestoreService.lastWatchFilters!['semesterId'], 'sem-3');
      expect(firestoreService.lastWatchFilters!['status'], NoteStatus.published.value);
    });

    test('Faculty query scopes by authorUserId and collegeId', () async {
      repository.watchNotes(
        role: AppRole.faculty,
        userId: 'faculty-uid-1',
        collegeId: 'college-alpha',
      ).listen((_) {});

      expect(firestoreService.lastWatchFilters, isNotNull);
      expect(firestoreService.lastWatchFilters!['authorUserId'], 'faculty-uid-1');
      expect(firestoreService.lastWatchFilters!['collegeId'], 'college-alpha');
      expect(firestoreService.lastWatchFilters!.containsKey('status'), false); // Faculty sees drafts too
    });

    test('HOD query scopes by collegeId and departmentId', () async {
      repository.watchNotes(
        role: AppRole.hod,
        userId: 'hod-uid-1',
        collegeId: 'college-alpha',
        departmentId: 'dept-ece',
      ).listen((_) {});

      expect(firestoreService.lastWatchFilters, isNotNull);
      expect(firestoreService.lastWatchFilters!['collegeId'], 'college-alpha');
      expect(firestoreService.lastWatchFilters!['departmentId'], 'dept-ece');
    });

    test('College Admin query scopes by collegeId', () async {
      repository.watchNotes(
        role: AppRole.collegeAdmin,
        userId: 'admin-uid-1',
        collegeId: 'college-alpha',
      ).listen((_) {});

      expect(firestoreService.lastWatchFilters, isNotNull);
      expect(firestoreService.lastWatchFilters!['collegeId'], 'college-alpha');
    });

    test('Deleting a note deletes physical file from Storage repository', () async {
      final note = NoteModel(
        id: 'note-to-delete',
        title: 'Algorithms Chapter 1',
        description: 'Sorting algorithms notes',
        resourceType: ResourceType.fileAttachment,
        fileName: 'sorting.pdf',
        fileType: 'pdf',
        fileSize: 524288,
        fileUrl: 'https://storage.googleapis.com/colleges/col-1/faculty/fac-1/notes/sorting.pdf',
        storagePath: 'colleges/col-1/faculty/fac-1/notes/sorting.pdf',
        subjectId: 'sub-algo',
        sectionId: 'sec-1',
        courseId: 'crs-1',
        departmentId: 'dept-1',
        collegeId: 'col-1',
        semesterId: 'sem-1',
        facultyId: 'fac-1',
        authorUserId: 'fac-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await firestoreService.setDocument('notes', note.id, note.toJson());
      expect(firestoreService.collections.containsKey('notes/${note.id}'), true);

      await repository.deleteNote(note.id);

      expect(firestoreService.collections.containsKey('notes/${note.id}'), false);
      expect(storageRepo.deletedPaths.contains('colleges/col-1/faculty/fac-1/notes/sorting.pdf'), true);
    });

    test('Notification failures do not block or revert note creation', () async {
      final throwingRepo = FirebaseNotesRepository(
        firestoreService,
        storageRepository: storageRepo,
        notificationService: ThrowingNotificationService(),
      );

      // Pre-populate author user doc so role validation passes
      await firestoreService.setDocument('users', 'fac-1', {
        'id': 'fac-1',
        'role': 'faculty',
        'subjectIds': ['sub-algo'],
        'sectionIds': ['sec-1'],
      });

      final note = NoteModel(
        id: 'note-notification-test',
        title: 'Operating Systems Virtual Memory',
        description: 'Paging and segmentation notes',
        resourceType: ResourceType.textNote,
        content: 'Virtual memory allows processes to execute without being wholly in memory.',
        subjectId: 'sub-algo',
        sectionId: 'sec-1',
        courseId: 'crs-1',
        departmentId: 'dept-1',
        collegeId: 'col-1',
        semesterId: 'sem-1',
        facultyId: 'fac-1',
        authorUserId: 'fac-1',
        status: NoteStatus.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Should complete successfully without throwing
      await throwingRepo.createNote(note);

      final createdDoc = await firestoreService.getDocument('notes', note.id);
      expect(createdDoc, isNotNull);
      expect(createdDoc!['title'], 'Operating Systems Virtual Memory');
    });

    test('NoteMimeHelper resolves all 8 required formats correctly', () {
      expect(NoteMimeHelper.resolveMimeType('lecture.pdf'), 'application/pdf');
      expect(NoteMimeHelper.resolveMimeType('photo.jpg'), 'image/jpeg');
      expect(NoteMimeHelper.resolveMimeType('diagram.jpeg'), 'image/jpeg');
      expect(NoteMimeHelper.resolveMimeType('chart.png'), 'image/png');
      expect(NoteMimeHelper.resolveMimeType('slides.ppt'), 'application/vnd.ms-powerpoint');
      expect(NoteMimeHelper.resolveMimeType('deck.pptx'), 'application/vnd.openxmlformats-officedocument.presentationml.presentation');
      expect(NoteMimeHelper.resolveMimeType('assignment.doc'), 'application/msword');
      expect(NoteMimeHelper.resolveMimeType('notes.docx'), 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');

      for (final ext in ['jpg', 'jpeg', 'png', 'pdf', 'ppt', 'pptx', 'doc', 'docx']) {
        expect(NoteMimeHelper.isExtensionSupported(ext), true);
        expect(NoteMimeHelper.isExtensionSupported('file.$ext'), true);
      }

      expect(NoteMimeHelper.isExtensionSupported('exe'), false);
      expect(NoteMimeHelper.isExtensionSupported('mp4'), false);
    });

    test('NoteMimeHelper previewable checks', () {
      expect(NoteMimeHelper.isPreviewableFormat('pdf'), true);
      expect(NoteMimeHelper.isPreviewableFormat('lecture.PDF'), true);
      expect(NoteMimeHelper.isPreviewableFormat('jpg'), true);
      expect(NoteMimeHelper.isPreviewableFormat('image.png'), true);
      expect(NoteMimeHelper.isPreviewableFormat('pptx'), false);
      expect(NoteMimeHelper.isPreviewableFormat('doc'), false);
      expect(NoteMimeHelper.isPreviewableFormat('docx'), false);
    });

    test('NoteMimeHelper file size validation (25MB limit)', () {
      expect(NoteMimeHelper.isFileSizeValid(1024), true); // 1 KB
      expect(NoteMimeHelper.isFileSizeValid(25 * 1024 * 1024), true); // 25 MB exact
      expect(NoteMimeHelper.isFileSizeValid(25 * 1024 * 1024 + 1), false); // 25MB + 1 byte
      expect(NoteMimeHelper.isFileSizeValid(0), false);
      expect(NoteMimeHelper.isFileSizeValid(-100), false);
    });

    test('userNotesProvider performs direct O(1) resolution from UserModel sectionId', () async {
      final studentUser = UserModel(
        id: 'student-alice',
        email: 'alice@college.edu',
        name: 'Alice Student',
        role: AppRole.student,
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        sectionId: 'sec-3b',
        semesterId: 'sem-3',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: studentUser, token: 'mock-token'))),
          notesRepositoryProvider.overrideWithValue(repository),
        ],
      );

      // Listen to userNotesProvider
      final notesStream = container.read(userNotesProvider.future);
      await notesStream;

      expect(firestoreService.lastWatchFilters, isNotNull);
      expect(firestoreService.lastWatchFilters!['collegeId'], 'col-1');
      expect(firestoreService.lastWatchFilters!['departmentId'], 'dept-cse');
      expect(firestoreService.lastWatchFilters!['sectionId'], 'sec-3b');
      expect(firestoreService.lastWatchFilters!['semesterId'], 'sem-3');
    });
  });
}
