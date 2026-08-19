import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../storage/presentation/providers/storage_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../domain/models/note_model.dart';
import '../../data/repositories/notes_repository.dart';
import '../../data/repositories/mock_notes_repository.dart';
import '../../data/repositories/firebase_notes_repository.dart';

final mockNotesRepositoryProvider = Provider<NotesRepository>((ref) {
  return MockNotesRepository();
});

final firebaseNotesRepositoryProvider = Provider<NotesRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final storageRepository = ref.watch(fileStorageRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return FirebaseNotesRepository(
    firestoreService,
    storageRepository: storageRepository,
    notificationService: notificationService,
  );
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return ref.watch(mockNotesRepositoryProvider);
  }
  return ref.watch(firebaseNotesRepositoryProvider);
});

final userNotesProvider = StreamProvider<List<NoteModel>>((ref) async* {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    yield [];
    return;
  }

  final user = authState.user;
  // Readiness safety guard: Prevent querying with uninitialized/empty user
  if (user.id.isEmpty) {
    yield [];
    return;
  }

  if (user.role != AppRole.superAdmin && (user.collegeId == null || user.collegeId!.isEmpty)) {
    yield [];
    return;
  }

  final repository = ref.watch(notesRepositoryProvider);

  // Direct O(1) section & semester resolution directly from UserModel
  final sectionId = user.sectionId;
  final semesterId = user.semesterId;

  final stream = repository.watchNotes(
    role: user.role,
    userId: user.id,
    collegeId: user.collegeId,
    departmentId: user.departmentId,
    semesterId: semesterId,
    sectionId: sectionId,
  );

  await for (final notes in stream) {
    yield notes;
  }
});

class NotesFilterState {
  final String? subjectId;
  final String? facultyId;
  final String? sectionId;
  final String? semesterId;
  final String? courseId;
  final NoteStatus? status;
  final ResourceType? resourceType;
  final String searchQuery;

  NotesFilterState({
    this.subjectId,
    this.facultyId,
    this.sectionId,
    this.semesterId,
    this.courseId,
    this.status,
    this.resourceType,
    this.searchQuery = '',
  });

  NotesFilterState copyWith({
    String? subjectId,
    String? facultyId,
    String? sectionId,
    String? semesterId,
    String? courseId,
    NoteStatus? status,
    ResourceType? resourceType,
    String? searchQuery,
    bool clearSubject = false,
    bool clearFaculty = false,
    bool clearSection = false,
    bool clearSemester = false,
    bool clearCourse = false,
    bool clearStatus = false,
    bool clearResourceType = false,
  }) {
    return NotesFilterState(
      subjectId: clearSubject ? null : (subjectId ?? this.subjectId),
      facultyId: clearFaculty ? null : (facultyId ?? this.facultyId),
      sectionId: clearSection ? null : (sectionId ?? this.sectionId),
      semesterId: clearSemester ? null : (semesterId ?? this.semesterId),
      courseId: clearCourse ? null : (courseId ?? this.courseId),
      status: clearStatus ? null : (status ?? this.status),
      resourceType: clearResourceType ? null : (resourceType ?? this.resourceType),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final notesFilterProvider = StateProvider<NotesFilterState>((ref) => NotesFilterState());

final filteredNotesProvider = Provider<AsyncValue<List<NoteModel>>>((ref) {
  final asyncNotes = ref.watch(userNotesProvider);
  final filters = ref.watch(notesFilterProvider);

  return asyncNotes.whenData((notes) {
    return notes.where((note) {
      if (filters.subjectId != null && note.subjectId != filters.subjectId) return false;
      if (filters.facultyId != null && note.facultyId != filters.facultyId) return false;
      if (filters.sectionId != null && note.sectionId != filters.sectionId) return false;
      if (filters.semesterId != null && note.semesterId != filters.semesterId) return false;
      if (filters.courseId != null && note.courseId != filters.courseId) return false;
      if (filters.status != null && note.status != filters.status) return false;
      if (filters.resourceType != null && note.resourceType != filters.resourceType) return false;
      
      if (filters.searchQuery.isNotEmpty) {
        final query = filters.searchQuery.toLowerCase();
        if (!note.title.toLowerCase().contains(query) &&
            !note.description.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  });
});

class NoteManagementNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createNote(NoteModel note) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(notesRepositoryProvider);
      await repository.createNote(note);
    });
  }

  Future<void> updateNote(NoteModel note) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(notesRepositoryProvider);
      await repository.updateNote(note);
    });
  }

  Future<void> deleteNote(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(notesRepositoryProvider);
      await repository.deleteNote(id);
    });
  }
}

final noteManagementProvider = AsyncNotifierProvider<NoteManagementNotifier, void>(() {
  return NoteManagementNotifier();
});
