import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../domain/models/academic_models.dart';
import '../../domain/repositories/academic_repository.dart';
import '../../data/repositories/firebase_academic_repository.dart';
import '../../data/repositories/api_academic_repository.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart' as auth;
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../core/providers/pagination_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final firebaseAcademicRepositoryProvider = Provider<AcademicRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authState = ref.watch(auth.authProvider);
  
  UserModel? currentUser;
  if (authState is AuthAuthenticated) {
    currentUser = authState.user;
  }
  
  return FirebaseAcademicRepository(firestoreService, currentUser);
});

final apiAcademicRepositoryProvider = Provider<ApiAcademicRepository>((ref) {
  return ApiAcademicRepository();
});

final academicRepositoryProvider = Provider<AcademicRepository>((ref) {
  return ref.watch(apiAcademicRepositoryProvider);
});

// Backward compatibility alias
final mockRepoProvider = academicRepositoryProvider;

// --- College Notifier ---
class CollegeNotifier extends AutoDisposeAsyncNotifier<List<College>> {
  @override
  Future<List<College>> build() async {
    return ref.watch(academicRepositoryProvider).getColleges();
  }
  Future<void> addCollege(College college) async {
    await ref.read(academicRepositoryProvider).addCollege(college);
    ref.invalidateSelf();
  }
  Future<void> updateCollege(College college) async {
    await ref.read(academicRepositoryProvider).updateCollege(college);
    ref.invalidateSelf();
  }
  Future<void> deactivateCollege(String id) async {
    await ref.read(academicRepositoryProvider).deactivateCollege(id);
    ref.invalidateSelf();
  }
}
final collegesProvider = AsyncNotifierProvider.autoDispose<CollegeNotifier, List<College>>(CollegeNotifier.new);

// --- Department Notifier ---
class DepartmentNotifier extends AutoDisposeAsyncNotifier<List<Department>> {
  @override
  Future<List<Department>> build() async {
    return ref.watch(academicRepositoryProvider).getDepartments();
  }
  Future<void> addDepartment(Department department) async {
    await ref.read(academicRepositoryProvider).addDepartment(department);
    ref.invalidateSelf();
  }
  Future<void> updateDepartment(Department department) async {
    await ref.read(academicRepositoryProvider).updateDepartment(department);
    ref.invalidateSelf();
  }
  Future<void> deactivateDepartment(String id) async {
    await ref.read(academicRepositoryProvider).deactivateDepartment(id);
    ref.invalidateSelf();
  }
  Future<void> assignHod(String departmentId, String hodUserId) async {
    await ref.read(academicRepositoryProvider).assignHodToDepartment(departmentId, hodUserId);
    ref.invalidateSelf();
  }
}
final departmentsProvider = AsyncNotifierProvider.autoDispose<DepartmentNotifier, List<Department>>(DepartmentNotifier.new);

// --- Course Notifier ---
class CourseNotifier extends AutoDisposeAsyncNotifier<List<Course>> {
  @override
  Future<List<Course>> build() async {
    return ref.watch(academicRepositoryProvider).getCourses();
  }
  Future<void> addCourse(Course course) async {
    await ref.read(academicRepositoryProvider).addCourse(course);
    ref.invalidateSelf();
  }
  Future<void> updateCourse(Course course) async {
    await ref.read(academicRepositoryProvider).updateCourse(course);
    ref.invalidateSelf();
  }
  Future<void> deactivateCourse(String id) async {
    await ref.read(academicRepositoryProvider).deactivateCourse(id);
    ref.invalidateSelf();
  }
}
final coursesProvider = AsyncNotifierProvider.autoDispose<CourseNotifier, List<Course>>(CourseNotifier.new);

// --- AcademicYear Notifier ---
class AcademicYearNotifier extends AutoDisposeAsyncNotifier<List<AcademicYear>> {
  @override
  Future<List<AcademicYear>> build() async {
    return ref.watch(academicRepositoryProvider).getAcademicYears();
  }
  Future<void> addAcademicYear(AcademicYear academicYear) async {
    await ref.read(academicRepositoryProvider).addAcademicYear(academicYear);
    ref.invalidateSelf();
  }
  Future<void> updateAcademicYear(AcademicYear academicYear) async {
    await ref.read(academicRepositoryProvider).updateAcademicYear(academicYear);
    ref.invalidateSelf();
  }
  Future<void> deactivateAcademicYear(String id) async {
    await ref.read(academicRepositoryProvider).deactivateAcademicYear(id);
    ref.invalidateSelf();
  }
  Future<void> activateAcademicYear(String collegeId, String academicYearId) async {
    await ref.read(academicRepositoryProvider).activateAcademicYear(collegeId, academicYearId);
    ref.invalidateSelf();
  }
}
final academicYearsProvider = AsyncNotifierProvider.autoDispose<AcademicYearNotifier, List<AcademicYear>>(AcademicYearNotifier.new);

// --- Semester Notifier ---
class SemesterNotifier extends AutoDisposeAsyncNotifier<List<Semester>> {
  @override
  Future<List<Semester>> build() async {
    return ref.watch(academicRepositoryProvider).getSemesters();
  }
  Future<void> addSemester(Semester semester) async {
    await ref.read(academicRepositoryProvider).addSemester(semester);
    ref.invalidateSelf();
  }
  Future<void> updateSemester(Semester semester) async {
    await ref.read(academicRepositoryProvider).updateSemester(semester);
    ref.invalidateSelf();
  }
  Future<void> deactivateSemester(String id) async {
    await ref.read(academicRepositoryProvider).deactivateSemester(id);
    ref.invalidateSelf();
  }
  Future<void> activateSemester(String collegeId, String courseId, String semesterId) async {
    await ref.read(academicRepositoryProvider).activateSemester(collegeId, courseId, semesterId);
    ref.invalidateSelf();
  }
  Future<void> completeSemester(String semesterId) async {
    await ref.read(academicRepositoryProvider).completeSemester(semesterId);
    ref.invalidateSelf();
  }
}
final semestersProvider = AsyncNotifierProvider.autoDispose<SemesterNotifier, List<Semester>>(SemesterNotifier.new);

// --- Section Notifier ---
class SectionNotifier extends AutoDisposeAsyncNotifier<List<Section>> {
  @override
  Future<List<Section>> build() async {
    return ref.watch(academicRepositoryProvider).getSections();
  }
  Future<void> addSection(Section section) async {
    await ref.read(academicRepositoryProvider).addSection(section);
    ref.invalidateSelf();
  }
  Future<void> updateSection(Section section) async {
    await ref.read(academicRepositoryProvider).updateSection(section);
    ref.invalidateSelf();
  }
  Future<void> updateSectionCapacity(String sectionId, int newCapacity) async {
    await ref.read(academicRepositoryProvider).updateSectionCapacity(sectionId, newCapacity);
    ref.invalidateSelf();
  }
  Future<void> transferStudents(List<String> studentIds, String targetSectionId) async {
    await ref.read(academicRepositoryProvider).transferStudentsSection(studentIds: studentIds, targetSectionId: targetSectionId);
    ref.invalidateSelf();
    ref.invalidate(studentsProvider);
  }
  Future<void> executeBulkTransfer(List<String> studentIds, String targetSectionId) async {
    await ref.read(academicRepositoryProvider).executeBulkSectionTransfer(studentIds: studentIds, targetSectionId: targetSectionId);
    ref.invalidateSelf();
    ref.invalidate(studentsProvider);
  }
  Future<void> deactivateSection(String id) async {
    await ref.read(academicRepositoryProvider).deactivateSection(id);
    ref.invalidateSelf();
  }
}
final sectionsProvider = AsyncNotifierProvider.autoDispose<SectionNotifier, List<Section>>(SectionNotifier.new);

// --- Subject Notifier ---
class SubjectNotifier extends AutoDisposeAsyncNotifier<List<Subject>> {
  @override
  Future<List<Subject>> build() async {
    return ref.watch(academicRepositoryProvider).getSubjects();
  }
  Future<void> addSubject(Subject subject) async {
    await ref.read(academicRepositoryProvider).addSubject(subject);
    ref.invalidateSelf();
  }
  Future<void> updateSubject(Subject subject) async {
    await ref.read(academicRepositoryProvider).updateSubject(subject);
    ref.invalidateSelf();
  }
  Future<void> deactivateSubject(String id) async {
    await ref.read(academicRepositoryProvider).deactivateSubject(id);
    ref.invalidateSelf();
  }
}
final subjectsProvider = AsyncNotifierProvider.autoDispose<SubjectNotifier, List<Subject>>(SubjectNotifier.new);

// --- Faculty Notifier ---
class FacultyNotifier extends PaginationNotifier<Faculty> {
  final Ref ref;
  final String? departmentId;

  FacultyNotifier(this.ref, {this.departmentId});

  @override
  Future<PaginatedResponse<Faculty>> fetchPage({DocumentSnapshot? startAfter}) {
    return ref.read(academicRepositoryProvider).getPaginatedFaculty(
      departmentId: departmentId,
      startAfter: startAfter,
      limit: limit,
    );
  }

  Future<void> bulkAssignSubjects(String facultyId, List<String> subjectIds, List<String> sectionIds) async {
    await ref.read(academicRepositoryProvider).bulkAssignSubjectsToFaculty(facultyId, subjectIds, sectionIds);
    await refresh();
  }

  Future<void> transferDepartment(String facultyId, String newDepartmentId) async {
    await ref.read(academicRepositoryProvider).transferFacultyDepartment(facultyId, newDepartmentId);
    await refresh();
    ref.invalidate(facultyAssignmentsProvider);
  }

  Future<ProvisionFacultyResult> provisionFaculty(ProvisionFacultyRequest request) async {
    final result = await ref.read(academicRepositoryProvider).provisionFaculty(request);
    await refresh();
    ref.invalidate(departmentFacultyCountsProvider);
    return result;
  }
}

final facultyProvider = StateNotifierProvider.autoDispose.family<FacultyNotifier, PaginatedState<Faculty>, String?>((ref, departmentId) {
  // Watch auth to force rebuild on logout
  ref.watch(auth.authProvider);
  return FacultyNotifier(ref, departmentId: departmentId)..loadInitial();
});

class FacultyProvisionNotifier extends StateNotifier<AsyncValue<ProvisionFacultyResult?>> {
  final Ref ref;
  FacultyProvisionNotifier(this.ref) : super(const AsyncData(null));

  Future<ProvisionFacultyResult> provisionFaculty(ProvisionFacultyRequest request) async {
    state = const AsyncLoading();
    try {
      final result = await ref.read(academicRepositoryProvider).provisionFaculty(request);
      ref.invalidate(facultyProvider(null));
      if (request.departmentId.isNotEmpty) {
        ref.invalidate(facultyProvider(request.departmentId));
      }
      ref.invalidate(departmentFacultyCountsProvider);
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final facultyProvisionProvider = StateNotifierProvider.autoDispose<FacultyProvisionNotifier, AsyncValue<ProvisionFacultyResult?>>((ref) {
  return FacultyProvisionNotifier(ref);
});

// --- Student Notifier ---
class StudentNotifier extends PaginationNotifier<Student> {
  final Ref ref;
  final String? sectionId;
  final String? departmentId;

  StudentNotifier(this.ref, {this.sectionId, this.departmentId});

  @override
  Future<PaginatedResponse<Student>> fetchPage({DocumentSnapshot? startAfter}) {
    return ref.read(academicRepositoryProvider).getPaginatedStudents(
      sectionId: sectionId,
      departmentId: departmentId,
      startAfter: startAfter,
      limit: limit,
    );
  }

  Future<void> admitStudent(Student student) async {
    await ref.read(academicRepositoryProvider).admitStudent(student);
    await refresh();
  }

  Future<void> bulkAdmit(List<Student> students) async {
    await ref.read(academicRepositoryProvider).bulkAdmitStudents(students);
    await refresh();
  }

  Future<void> promoteStudents(
    List<String> studentIds,
    String newSemesterId,
    String newSectionId, {
    String? targetAcademicYearId,
  }) async {
    final yearId = targetAcademicYearId ?? '';
    await ref.read(academicRepositoryProvider).promoteStudents(
      studentIds: studentIds,
      targetAcademicYearId: yearId,
      targetSemesterId: newSemesterId,
      targetSectionId: newSectionId,
    );
    await refresh();
  }

  Future<void> transferStudents(List<String> studentIds, String newSectionId) async {
    await ref.read(academicRepositoryProvider).transferStudentsSection(
      studentIds: studentIds,
      targetSectionId: newSectionId,
    );
    await refresh();
  }

  Future<void> transferDepartment({
    required List<String> studentIds,
    required String targetDepartmentId,
    required String targetCourseId,
    required String targetSemesterId,
    required String targetSectionId,
  }) async {
    await ref.read(academicRepositoryProvider).transferStudentsDepartment(
      studentIds: studentIds,
      targetDepartmentId: targetDepartmentId,
      targetCourseId: targetCourseId,
      targetSemesterId: targetSemesterId,
      targetSectionId: targetSectionId,
    );
    await refresh();
  }

  Future<void> updateLifecycleState({
    required String studentId,
    required StudentLifecycleState newState,
    String? remarks,
  }) async {
    await ref.read(academicRepositoryProvider).updateStudentLifecycleState(
      studentId: studentId,
      newState: newState,
      remarks: remarks,
    );
    await refresh();
    ref.invalidate(studentAcademicProfileProvider(studentId));
  }

  Future<void> bulkGraduate({
    required List<String> studentIds,
    String? remarks,
  }) async {
    await ref.read(academicRepositoryProvider).bulkGraduateStudents(
      studentIds: studentIds,
      remarks: remarks,
    );
    await refresh();
  }

  Future<void> bulkArchive({
    required List<String> studentIds,
  }) async {
    await ref.read(academicRepositoryProvider).bulkArchiveAlumni(
      studentIds: studentIds,
    );
    await refresh();
  }
}

final studentsProvider = StateNotifierProvider.autoDispose.family<StudentNotifier, PaginatedState<Student>, ({String? sectionId, String? departmentId})>((ref, args) {
  // Watch auth to force rebuild on logout
  ref.watch(auth.authProvider);
  return StudentNotifier(ref, sectionId: args.sectionId, departmentId: args.departmentId)..loadInitial();
});

final studentAcademicProfileProvider = FutureProvider.autoDispose.family<StudentAcademicProfile, String>((ref, studentId) async {
  return ref.watch(academicRepositoryProvider).getStudentAcademicProfile(studentId);
});

final currentStudentAcademicProfileProvider = FutureProvider.autoDispose<StudentAcademicProfile?>((ref) async {
  final authState = ref.watch(auth.authProvider);
  if (authState is! AuthAuthenticated || authState.user.role != AppRole.student) {
    return null;
  }
  return ref.watch(academicRepositoryProvider).getStudentAcademicProfile(authState.user.id);
});

final studentAcademicHistoryProvider = FutureProvider.autoDispose.family<List<StudentAcademicHistory>, String>((ref, studentId) async {
  return ref.watch(academicRepositoryProvider).getStudentAcademicHistory(studentId);
});

final studentsBySectionProvider = FutureProvider.autoDispose.family<List<Student>, String>((ref, sectionId) async {
  return ref.watch(academicRepositoryProvider).getStudentsBySection(sectionId);
});

final studentsBySemesterProvider = FutureProvider.autoDispose.family<List<Student>, String>((ref, semesterId) async {
  return ref.watch(academicRepositoryProvider).getStudentsBySemester(semesterId);
});

final studentsByCourseProvider = FutureProvider.autoDispose.family<List<Student>, String>((ref, courseId) async {
  return ref.watch(academicRepositoryProvider).getStudentsByCourse(courseId);
});

final studentsByDepartmentProvider = FutureProvider.autoDispose.family<List<Student>, String>((ref, departmentId) async {
  return ref.watch(academicRepositoryProvider).getStudentsByDepartment(departmentId);
});

// --- Faculty Assignments Notifier ---
class FacultyAssignmentsNotifier extends AutoDisposeAsyncNotifier<List<FacultyAssignment>> {
  @override
  Future<List<FacultyAssignment>> build() async {
    return ref.watch(academicRepositoryProvider).getFacultyAssignments();
  }

  Future<void> createAssignment(FacultyAssignment assignment) async {
    await ref.read(academicRepositoryProvider).createFacultyAssignment(assignment);
    ref.invalidateSelf();
    ref.invalidate(facultyProvider(null));
  }

  Future<void> updateAssignment(FacultyAssignment assignment) async {
    await ref.read(academicRepositoryProvider).createFacultyAssignment(assignment);
    ref.invalidateSelf();
    ref.invalidate(facultyProvider(null));
  }

  Future<void> removeAssignment(String assignmentId) async {
    await ref.read(academicRepositoryProvider).removeFacultyAssignment(assignmentId);
    ref.invalidateSelf();
    ref.invalidate(facultyProvider(null));
  }
}

final facultyAssignmentsProvider = AsyncNotifierProvider.autoDispose<FacultyAssignmentsNotifier, List<FacultyAssignment>>(FacultyAssignmentsNotifier.new);

// --- Memoized Lookup Maps ---
final collegeMapProvider = Provider.autoDispose<Map<String, College>>((ref) {
  final colleges = ref.watch(collegesProvider).valueOrNull ?? [];
  return {for (final c in colleges) c.id: c};
});

final departmentMapProvider = Provider.autoDispose<Map<String, Department>>((ref) {
  final depts = ref.watch(departmentsProvider).valueOrNull ?? [];
  return {for (final d in depts) d.id: d};
});

final courseMapProvider = Provider.autoDispose<Map<String, Course>>((ref) {
  final courses = ref.watch(coursesProvider).valueOrNull ?? [];
  return {for (final c in courses) c.id: c};
});

final semesterMapProvider = Provider.autoDispose<Map<String, Semester>>((ref) {
  final sems = ref.watch(semestersProvider).valueOrNull ?? [];
  return {for (final s in sems) s.id: s};
});

final sectionMapProvider = Provider.autoDispose<Map<String, Section>>((ref) {
  final secs = ref.watch(sectionsProvider).valueOrNull ?? [];
  return {for (final s in secs) s.id: s};
});

final subjectMapProvider = Provider.autoDispose<Map<String, Subject>>((ref) {
  final subs = ref.watch(subjectsProvider).valueOrNull ?? [];
  return {for (final s in subs) s.id: s};
});

final academicYearMapProvider = Provider.autoDispose<Map<String, AcademicYear>>((ref) {
  final years = ref.watch(academicYearsProvider).valueOrNull ?? [];
  return {for (final y in years) y.id: y};
});

final facultyMapProvider = Provider.autoDispose<Map<String, Faculty>>((ref) {
  final faculties = ref.watch(facultyProvider(null)).items;
  return {for (final f in faculties) f.id: f};
});

// --- Scoped Selectors for Connected Academic Workflows ---
final assignedFacultyForSubjectSectionProvider = Provider.autoDispose.family<List<Faculty>, ({String subjectId, String sectionId})>((ref, args) {
  final assignments = ref.watch(facultyAssignmentsProvider).valueOrNull ?? [];
  final matchingAssignments = assignments.where((a) => a.subjectId == args.subjectId && a.sectionId == args.sectionId && a.isActive).toList();
  final facultyMap = ref.watch(facultyMapProvider);
  return matchingAssignments
      .map((a) => facultyMap[a.facultyId])
      .whereType<Faculty>()
      .toList();
});

final subjectsForSemesterProvider = Provider.autoDispose.family<List<Subject>, String>((ref, semesterId) {
  final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
  return subjects.where((s) => s.semesterId == semesterId && s.isActive).toList();
});

final facultyAssignedSubjectsProvider = Provider.autoDispose.family<List<Subject>, String>((ref, facultyId) {
  final assignments = ref.watch(facultyAssignmentsProvider).valueOrNull ?? [];
  final myAssignments = assignments.where((a) => a.facultyId == facultyId && a.isActive).toList();
  final subjectMap = ref.watch(subjectMapProvider);
  final Set<String> seenIds = {};
  final List<Subject> result = [];
  for (final a in myAssignments) {
    if (!seenIds.contains(a.subjectId) && subjectMap.containsKey(a.subjectId)) {
      seenIds.add(a.subjectId);
      result.add(subjectMap[a.subjectId]!);
    }
  }
  return result;
});

final facultyAssignedSectionsProvider = Provider.autoDispose.family<List<Section>, ({String facultyId, String? subjectId})>((ref, args) {
  final assignments = ref.watch(facultyAssignmentsProvider).valueOrNull ?? [];
  final myAssignments = assignments.where((a) => a.facultyId == args.facultyId && a.isActive && (args.subjectId == null || a.subjectId == args.subjectId)).toList();
  final sectionMap = ref.watch(sectionMapProvider);
  final Set<String> seenIds = {};
  final List<Section> result = [];
  for (final a in myAssignments) {
    if (!seenIds.contains(a.sectionId) && sectionMap.containsKey(a.sectionId)) {
      seenIds.add(a.sectionId);
      result.add(sectionMap[a.sectionId]!);
    }
  }
  return result;
});

// --- Personal Faculty Assignments Provider ---
final myFacultyAssignmentsProvider = Provider.autoDispose<List<FacultyAssignment>>((ref) {
  final authState = ref.watch(auth.authProvider);
  if (authState is! AuthAuthenticated) return [];
  final assignments = ref.watch(facultyAssignmentsProvider).valueOrNull ?? [];
  final currentUserId = authState.user.id;
  return assignments.where((a) => a.facultyId == currentUserId && a.isActive).toList();
});

// --- Parameterized Faculty Assignments by Faculty ID ---
final facultyAssignmentsByFacultyProvider = Provider.autoDispose.family<List<FacultyAssignment>, String>((ref, facultyId) {
  final assignments = ref.watch(facultyAssignmentsProvider).valueOrNull ?? [];
  return assignments.where((a) => a.facultyId == facultyId && a.isActive).toList();
});

// --- Parameterized Faculty Assignments by Section ID ---
final facultyAssignmentsBySectionProvider = Provider.autoDispose.family<List<FacultyAssignment>, String>((ref, sectionId) {
  final assignments = ref.watch(facultyAssignmentsProvider).valueOrNull ?? [];
  return assignments.where((a) => a.sectionId == sectionId && a.isActive).toList();
});

// --- Parameterized Faculty Assignments by Subject ID ---
final facultyAssignmentsBySubjectProvider = Provider.autoDispose.family<List<FacultyAssignment>, String>((ref, subjectId) {
  final assignments = ref.watch(facultyAssignmentsProvider).valueOrNull ?? [];
  return assignments.where((a) => a.subjectId == subjectId && a.isActive).toList();
});

// --- Parameterized Faculty Assignments by Department ID ---
final facultyAssignmentsByDepartmentProvider = Provider.autoDispose.family<List<FacultyAssignment>, String>((ref, departmentId) {
  final assignments = ref.watch(facultyAssignmentsProvider).valueOrNull ?? [];
  return assignments.where((a) => a.departmentId == departmentId && a.isActive).toList();
});

// --- Faculty Workload Overview Model & Provider ---
class FacultyWorkloadOverviewItem {
  final Faculty faculty;
  final List<FacultyAssignment> assignments;
  final int uniqueSubjectsCount;
  final int uniqueSectionsCount;
  final int totalWeeklyPeriods;

  FacultyWorkloadOverviewItem({
    required this.faculty,
    required this.assignments,
    required this.uniqueSubjectsCount,
    required this.uniqueSectionsCount,
    required this.totalWeeklyPeriods,
  });
}

final facultyWorkloadListProvider = Provider.autoDispose<List<FacultyWorkloadOverviewItem>>((ref) {
  final faculties = ref.watch(facultyProvider(null)).items;
  final assignments = ref.watch(facultyAssignmentsProvider).valueOrNull ?? [];
  final authState = ref.watch(auth.authProvider);
  
  String? scopedDeptId;
  if (authState is AuthAuthenticated && authState.user.role == AppRole.hod) {
    scopedDeptId = authState.user.departmentId;
  }

  return faculties.where((f) {
    if (scopedDeptId != null && scopedDeptId.isNotEmpty && f.departmentId != scopedDeptId) {
      return false;
    }
    return true;
  }).map((faculty) {
    final facAssignments = assignments.where((a) => a.facultyId == faculty.id && a.isActive).toList();
    final uniqueSubjects = facAssignments.map((a) => a.subjectId).toSet().length;
    final uniqueSections = facAssignments.map((a) => a.sectionId).toSet().length;
    // Estimate: each assignment typically corresponds to ~3-4 contact periods/week
    final totalWeeklyPeriods = facAssignments.length * 4;

    return FacultyWorkloadOverviewItem(
      faculty: faculty,
      assignments: facAssignments,
      uniqueSubjectsCount: uniqueSubjects,
      uniqueSectionsCount: uniqueSections,
      totalWeeklyPeriods: totalWeeklyPeriods,
    );
  }).toList();
});

// --- Current Academic Year Provider ---
final currentAcademicYearProvider = Provider.autoDispose<AcademicYear?>((ref) {
  final years = ref.watch(academicYearsProvider).valueOrNull ?? [];
  final authState = ref.watch(auth.authProvider);
  String? collegeId;
  if (authState is AuthAuthenticated) {
    collegeId = authState.user.collegeId;
  }
  return years.where((y) => (collegeId == null || y.collegeId == collegeId) && (y.isCurrent || y.status == 'active')).firstOrNull;
});

// --- Academic Years by College Provider ---
final academicYearsByCollegeProvider = Provider.autoDispose.family<List<AcademicYear>, String>((ref, collegeId) {
  final years = ref.watch(academicYearsProvider).valueOrNull ?? [];
  return years.where((y) => y.collegeId == collegeId).toList();
});

// --- Current Semester Provider by Course ID ---
final currentSemesterProvider = Provider.autoDispose.family<Semester?, String>((ref, courseId) {
  final semesters = ref.watch(semestersProvider).valueOrNull ?? [];
  return semesters.where((s) => s.courseId == courseId && (s.isCurrent || s.status == 'active')).firstOrNull;
});

// --- Semesters by Course ID ---
final semestersByCourseProvider = Provider.autoDispose.family<List<Semester>, String>((ref, courseId) {
  final semesters = ref.watch(semestersProvider).valueOrNull ?? [];
  return semesters.where((s) => s.courseId == courseId).toList();
});

// --- Semesters by Academic Year ID ---
final semestersByAcademicYearProvider = Provider.autoDispose.family<List<Semester>, String>((ref, academicYearId) {
  final semesters = ref.watch(semestersProvider).valueOrNull ?? [];
  return semesters.where((s) => s.academicYearId == academicYearId).toList();
});

// --- Sections by Semester ID ---
final sectionsBySemesterProvider = Provider.autoDispose.family<List<Section>, String>((ref, semesterId) {
  final sections = ref.watch(sectionsProvider).valueOrNull ?? [];
  return sections.where((s) => s.semesterId == semesterId).toList();
});

// --- Sections by Course ID ---
final sectionsByCourseProvider = Provider.autoDispose.family<List<Section>, String>((ref, courseId) {
  final sections = ref.watch(sectionsProvider).valueOrNull ?? [];
  return sections.where((s) => s.courseId == courseId).toList();
});

// --- Section Student Count Provider ---
final sectionStudentCountProvider = FutureProvider.autoDispose.family<int, String>((ref, sectionId) async {
  final repo = ref.watch(academicRepositoryProvider);
  final students = await repo.getStudentsBySection(sectionId);
  return students.where((s) => s.isActive).length;
});

// --- Section Capacity Info Provider ---
final sectionCapacityInfoProvider = FutureProvider.autoDispose.family<SectionCapacityInfo, String>((ref, sectionId) async {
  final repo = ref.watch(academicRepositoryProvider);
  return await repo.getSectionCapacityInfo(sectionId);
});

// --- College Capacity Utilization Model & Provider ---
class CollegeCapacityUtilization {
  final int totalCapacity;
  final int totalEnrolled;
  final double utilizationPercentage;
  final int activeSectionsCount;

  const CollegeCapacityUtilization({
    required this.totalCapacity,
    required this.totalEnrolled,
    required this.utilizationPercentage,
    required this.activeSectionsCount,
  });
}

final collegeCapacityUtilizationProvider = FutureProvider.autoDispose.family<CollegeCapacityUtilization, String>((ref, collegeId) async {
  final repo = ref.watch(academicRepositoryProvider);
  final sections = await repo.getSections();
  final collegeSections = sections.where((s) => s.collegeId == collegeId && s.isActive).toList();

  int totalCapacity = 0;
  int totalEnrolled = 0;

  for (final s in collegeSections) {
    totalCapacity += s.capacity;
    final students = await repo.getStudentsBySection(s.id);
    totalEnrolled += students.where((st) => st.isActive).length;
  }

  final percentage = totalCapacity > 0 ? ((totalEnrolled / totalCapacity) * 100).clamp(0.0, 100.0) : 0.0;

  return CollegeCapacityUtilization(
    totalCapacity: totalCapacity,
    totalEnrolled: totalEnrolled,
    utilizationPercentage: percentage,
    activeSectionsCount: collegeSections.length,
  );
});

final departmentStudentCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  return ref.watch(academicRepositoryProvider).getDepartmentStudentCounts();
});

final departmentFacultyCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  return ref.watch(academicRepositoryProvider).getDepartmentFacultyCounts();
});

final facultyWorkloadSummariesProvider = FutureProvider.autoDispose.family<List<FacultyWorkloadSummary>, String?>((ref, departmentId) async {
  return ref.watch(academicRepositoryProvider).getFacultyWorkloadSummaries(departmentId: departmentId);
});

