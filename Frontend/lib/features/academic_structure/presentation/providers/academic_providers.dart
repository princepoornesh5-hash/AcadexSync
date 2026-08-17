import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../domain/models/academic_models.dart';
import '../../domain/repositories/academic_repository.dart';
import '../../data/repositories/firebase_academic_repository.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart' as auth;
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../data/repositories/mock_academic_repository.dart';

final academicRepositoryProvider = Provider<AcademicRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return mockAcademicRepo;
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authState = ref.watch(auth.authProvider);
  
  UserModel? currentUser;
  if (authState is AuthAuthenticated) {
    currentUser = authState.user;
  }
  
  return FirebaseAcademicRepository(firestoreService, currentUser);
});

// Backward compatibility alias
final mockRepoProvider = academicRepositoryProvider;

// --- Static Providers (Read Only) ---
final collegesProvider = FutureProvider<List<College>>((ref) async {
  return ref.watch(academicRepositoryProvider).getColleges();
});
final departmentsProvider = FutureProvider<List<Department>>((ref) async {
  return ref.watch(academicRepositoryProvider).getDepartments();
});
final coursesProvider = FutureProvider<List<Course>>((ref) async {
  return ref.watch(academicRepositoryProvider).getCourses();
});
final academicYearsProvider = FutureProvider<List<AcademicYear>>((ref) async {
  return ref.watch(academicRepositoryProvider).getAcademicYears();
});
final semestersProvider = FutureProvider<List<Semester>>((ref) async {
  return ref.watch(academicRepositoryProvider).getSemesters();
});
final sectionsProvider = FutureProvider<List<Section>>((ref) async {
  return ref.watch(academicRepositoryProvider).getSections();
});
final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  return ref.watch(academicRepositoryProvider).getSubjects();
});

// --- Dynamic Providers (Read / Write) ---

class FacultyNotifier extends AsyncNotifier<List<Faculty>> {
  @override
  Future<List<Faculty>> build() async {
    return ref.watch(academicRepositoryProvider).getFaculty();
  }

  Future<void> bulkAssignSubjects(String facultyId, List<String> subjectIds, List<String> sectionIds) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(academicRepositoryProvider).bulkAssignSubjectsToFaculty(facultyId, subjectIds, sectionIds);
      return ref.read(academicRepositoryProvider).getFaculty();
    });
  }
}

final facultyProvider = AsyncNotifierProvider<FacultyNotifier, List<Faculty>>(() {
  return FacultyNotifier();
});

class StudentNotifier extends AsyncNotifier<List<Student>> {
  @override
  Future<List<Student>> build() async {
    return ref.watch(academicRepositoryProvider).getStudents();
  }

  Future<void> promoteStudents(List<String> studentIds, String newSemesterId, String newSectionId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(academicRepositoryProvider).bulkPromoteStudents(studentIds, newSemesterId, newSectionId);
      return ref.read(academicRepositoryProvider).getStudents();
    });
  }

  Future<void> transferStudents(List<String> studentIds, String newSectionId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(academicRepositoryProvider).bulkTransferStudents(studentIds, newSectionId);
      return ref.read(academicRepositoryProvider).getStudents();
    });
  }
}

final studentsProvider = AsyncNotifierProvider<StudentNotifier, List<Student>>(() {
  return StudentNotifier();
});
