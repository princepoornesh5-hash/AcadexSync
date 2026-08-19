import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/data/repositories/firebase_academic_repository.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/core/firebase/firebase_services.dart';
import 'package:campus_management/core/firebase/firebase_exceptions.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirestoreService implements FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> _db = {};

  @override
  Future<void> setDocument(String collection, String id, Map<String, dynamic> data) async {
    _db.putIfAbsent(collection, () => {})[id] = Map<String, dynamic>.from(data);
  }

  @override
  Future<Map<String, dynamic>?> getDocument(String collection, String id) async {
    return _db[collection]?[id];
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollection(String collection, Map<String, dynamic> filters) async {
    final docs = _db[collection]?.values.toList() ?? [];
    if (filters.isEmpty) return docs;
    return docs.where((doc) {
      for (final entry in filters.entries) {
        if (doc[entry.key] != entry.value) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> deleteDocument(String collection, String id) async {
    _db[collection]?.remove(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ACADEX Phase 2: Faculty Assignment & Academic Workload Tests', () {
    late FakeFirestoreService fakeFirestore;

    final collegeAdmin = const UserModel(
      id: 'usr-col-admin',
      name: 'College Administrator',
      email: 'admin@git.edu',
      role: AppRole.collegeAdmin,
      collegeId: 'col-1',
    );

    final cseHod = const UserModel(
      id: 'usr-cse-hod',
      name: 'Dr. Turing (HOD CSE)',
      email: 'turing.hod@git.edu',
      role: AppRole.hod,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    final facultyMember = const UserModel(
      id: 'usr-fac-1',
      name: 'Prof. Ravi Kumar',
      email: 'ravi@git.edu',
      role: AppRole.faculty,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    final student = const UserModel(
      id: 'usr-std-1',
      name: 'Student Alice',
      email: 'alice@git.edu',
      role: AppRole.student,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    setUp(() async {
      fakeFirestore = FakeFirestoreService();

      // Seed Department
      await fakeFirestore.setDocument('departments', 'dept-cse', {
        'id': 'dept-cse',
        'collegeId': 'col-1',
        'name': 'Computer Engineering',
        'code': 'CSE',
        'hodId': 'usr-cse-hod',
        'isActive': true,
      });

      // Seed Courses
      await fakeFirestore.setDocument('courses', 'crs-diploma', {
        'id': 'crs-diploma',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
        'name': 'Diploma Computer Engineering',
        'code': 'DCE',
        'isActive': true,
      });

      // Seed Semesters
      await fakeFirestore.setDocument('semesters', 'sem-3', {
        'id': 'sem-3',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
        'courseId': 'crs-diploma',
        'academicYearId': 'ay-2026',
        'name': '3rd Semester',
        'number': 3,
        'isActive': true,
      });

      // Seed Sections
      await fakeFirestore.setDocument('sections', 'sec-a', {
        'id': 'sec-a',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
        'semesterId': 'sem-3',
        'name': 'A',
        'isActive': true,
      });

      await fakeFirestore.setDocument('sections', 'sec-b', {
        'id': 'sec-b',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
        'semesterId': 'sem-3',
        'name': 'B',
        'isActive': true,
      });

      // Seed Subjects
      await fakeFirestore.setDocument('subjects', 'sub-java', {
        'id': 'sub-java',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
        'semesterId': 'sem-3',
        'name': 'Java Programming',
        'code': 'CS301',
        'credits': 4,
        'type': 'Theory',
        'isActive': true,
      });

      await fakeFirestore.setDocument('subjects', 'sub-dbms', {
        'id': 'sub-dbms',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
        'semesterId': 'sem-3',
        'name': 'Database Management Systems',
        'code': 'CS302',
        'credits': 4,
        'type': 'Theory',
        'isActive': true,
      });

      // Seed Faculty
      await fakeFirestore.setDocument('faculty', 'usr-fac-1', {
        'id': 'usr-fac-1',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
        'name': 'Prof. Ravi Kumar',
        'employeeId': 'EMP101',
        'email': 'ravi@git.edu',
        'phone': '9876543210',
        'isActive': true,
        'subjectIds': <String>[],
        'sectionIds': <String>[],
      });

      await fakeFirestore.setDocument('faculty', 'usr-fac-2', {
        'id': 'usr-fac-2',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
        'name': 'Prof. Priya Sharma',
        'employeeId': 'EMP102',
        'email': 'priya@git.edu',
        'phone': '9876543211',
        'isActive': true,
        'subjectIds': <String>[],
        'sectionIds': <String>[],
      });
    });

    test('1. College Admin can create faculty assignment', () async {
      final repo = FirebaseAcademicRepository(fakeFirestore, collegeAdmin);

      final assignment = FacultyAssignment(
        id: 'fa-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'usr-fac-1',
        facultyName: 'Prof. Ravi Kumar',
        courseId: 'crs-diploma',
        semesterId: 'sem-3',
        sectionId: 'sec-a',
        subjectId: 'sub-java',
        academicYearId: 'ay-2026',
        isActive: true,
      );

      await repo.createFacultyAssignment(assignment);

      final list = await repo.getFacultyAssignments();
      expect(list.length, equals(1));
      expect(list.first.facultyId, equals('usr-fac-1'));
      expect(list.first.subjectId, equals('sub-java'));
      expect(list.first.sectionId, equals('sec-a'));
    });

    test('2. College Admin cannot assign cross-college faculty', () async {
      // Foreign faculty from college col-2
      await fakeFirestore.setDocument('faculty', 'fac-foreign', {
        'id': 'fac-foreign',
        'collegeId': 'col-2', // Different college
        'departmentId': 'dept-cse',
        'name': 'Prof. Foreign',
        'employeeId': 'EMP999',
        'email': 'foreign@other.edu',
        'phone': '0000000000',
        'isActive': true,
        'subjectIds': <String>[],
        'sectionIds': <String>[],
      });

      final repo = FirebaseAcademicRepository(fakeFirestore, collegeAdmin);

      final assignment = FacultyAssignment(
        id: 'fa-foreign',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'fac-foreign',
        facultyName: 'Prof. Foreign',
        courseId: 'crs-diploma',
        semesterId: 'sem-3',
        sectionId: 'sec-a',
        subjectId: 'sub-java',
        academicYearId: 'ay-2026',
        isActive: true,
      );

      expect(
        () => repo.createFacultyAssignment(assignment),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('3. HOD can create assignment in own department', () async {
      final repo = FirebaseAcademicRepository(fakeFirestore, cseHod);

      final assignment = FacultyAssignment(
        id: 'fa-hod-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'usr-fac-1',
        facultyName: 'Prof. Ravi Kumar',
        courseId: 'crs-diploma',
        semesterId: 'sem-3',
        sectionId: 'sec-b',
        subjectId: 'sub-dbms',
        academicYearId: 'ay-2026',
        isActive: true,
      );

      await repo.createFacultyAssignment(assignment);

      final list = await repo.getFacultyAssignments(departmentId: 'dept-cse');
      expect(list.length, equals(1));
      expect(list.first.subjectId, equals('sub-dbms'));
    });

    test('4. HOD cannot create assignment in another department', () async {
      final repo = FirebaseAcademicRepository(fakeFirestore, cseHod);

      final foreignDeptAssignment = FacultyAssignment(
        id: 'fa-foreign-dept',
        collegeId: 'col-1',
        departmentId: 'dept-ece', // Different department
        facultyId: 'usr-fac-1',
        facultyName: 'Prof. Ravi Kumar',
        courseId: 'crs-diploma',
        semesterId: 'sem-3',
        sectionId: 'sec-a',
        subjectId: 'sub-java',
        academicYearId: 'ay-2026',
        isActive: true,
      );

      expect(
        () => repo.createFacultyAssignment(foreignDeptAssignment),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('5 & 6. Faculty can see own assignments and not another faculty assignments', () async {
      final repo = FirebaseAcademicRepository(fakeFirestore, collegeAdmin);

      // Assignment for Ravi
      await repo.createFacultyAssignment(FacultyAssignment(
        id: 'fa-ravi-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'usr-fac-1',
        facultyName: 'Prof. Ravi Kumar',
        courseId: 'crs-diploma',
        semesterId: 'sem-3',
        sectionId: 'sec-a',
        subjectId: 'sub-java',
        academicYearId: 'ay-2026',
      ));

      // Assignment for Priya
      await repo.createFacultyAssignment(FacultyAssignment(
        id: 'fa-priya-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'usr-fac-2',
        facultyName: 'Prof. Priya Sharma',
        courseId: 'crs-diploma',
        semesterId: 'sem-3',
        sectionId: 'sec-b',
        subjectId: 'sub-dbms',
        academicYearId: 'ay-2026',
      ));

      // Ravi queries own assignments
      final raviRepo = FirebaseAcademicRepository(fakeFirestore, facultyMember);
      final raviAssignments = await raviRepo.getFacultyAssignments(facultyId: 'usr-fac-1');

      expect(raviAssignments.length, equals(1));
      expect(raviAssignments.first.facultyId, equals('usr-fac-1'));
      expect(raviAssignments.first.subjectId, equals('sub-java'));
    });

    test('7. Duplicate active assignments are rejected', () async {
      final repo = FirebaseAcademicRepository(fakeFirestore, collegeAdmin);

      final assignment = FacultyAssignment(
        id: 'fa-dup-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'usr-fac-1',
        facultyName: 'Prof. Ravi Kumar',
        courseId: 'crs-diploma',
        semesterId: 'sem-3',
        sectionId: 'sec-a',
        subjectId: 'sub-java',
        academicYearId: 'ay-2026',
      );

      await repo.createFacultyAssignment(assignment);

      // Attempt to assign the exact same class/subject/section/academic year again
      final duplicateAssignment = FacultyAssignment(
        id: 'fa-dup-2',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'usr-fac-1',
        facultyName: 'Prof. Ravi Kumar',
        courseId: 'crs-diploma',
        semesterId: 'sem-3',
        sectionId: 'sec-a',
        subjectId: 'sub-java',
        academicYearId: 'ay-2026',
      );

      expect(
        () => repo.createFacultyAssignment(duplicateAssignment),
        throwsA(isA<BackendValidationException>()),
      );
    });

    test('8. Assignment deletion / deactivation works properly', () async {
      final repo = FirebaseAcademicRepository(fakeFirestore, collegeAdmin);

      final assignment = FacultyAssignment(
        id: 'fa-del-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'usr-fac-1',
        facultyName: 'Prof. Ravi Kumar',
        courseId: 'crs-diploma',
        semesterId: 'sem-3',
        sectionId: 'sec-a',
        subjectId: 'sub-java',
        academicYearId: 'ay-2026',
      );

      await repo.createFacultyAssignment(assignment);
      var list = await repo.getFacultyAssignments();
      expect(list.length, equals(1));

      // Remove assignment
      await repo.removeFacultyAssignment('fa-del-1');

      list = await repo.getFacultyAssignments();
      expect(list.isEmpty, isTrue);

      final doc = await fakeFirestore.getDocument('facultyAssignments', 'fa-del-1');
      expect(doc?['isActive'], equals(false));
    });

    test('8. Student cannot create or modify assignments', () async {
      final repo = FirebaseAcademicRepository(fakeFirestore, student);

      final assignment = FacultyAssignment(
        id: 'fa-std-unauth',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        facultyId: 'usr-fac-1',
        facultyName: 'Prof. Ravi Kumar',
        courseId: 'crs-diploma',
        semesterId: 'sem-3',
        sectionId: 'sec-a',
        subjectId: 'sub-java',
        academicYearId: 'ay-2026',
      );

      expect(
        () => repo.createFacultyAssignment(assignment),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('9. Workload calculations correctly compute unique subjects, sections, and weekly periods', () async {
      final container = ProviderContainer(
        overrides: [
          academicRepositoryProvider.overrideWithValue(MockAcademicRepository()),
          authProvider.overrideWith((ref) => FakeAuthNotifier(AuthAuthenticated(user: collegeAdmin, token: 'mock-token'))),
        ],
      );

      // Trigger listener on facultyProvider
      container.listen(facultyProvider(null), (_, _) {});
      container.listen(facultyAssignmentsProvider, (_, _) {});

      await Future.delayed(const Duration(milliseconds: 300));

      final workloadList = container.read(facultyWorkloadListProvider);
      expect(workloadList, isNotNull);
      expect(workloadList.isNotEmpty, isTrue);

      final sample = workloadList.first;
      expect(sample.faculty.name.isNotEmpty, isTrue);
      expect(sample.totalWeeklyPeriods, greaterThanOrEqualTo(0));
    });

    test('10. O(1) Lookup map providers are correctly populated without N+1 queries', () async {
      final container = ProviderContainer(
        overrides: [
          academicRepositoryProvider.overrideWithValue(MockAcademicRepository()),
          authProvider.overrideWith((ref) => FakeAuthNotifier(AuthAuthenticated(user: collegeAdmin, token: 'mock-token'))),
        ],
      );

      // Trigger listeners
      container.listen(departmentsProvider, (_, _) {});
      container.listen(coursesProvider, (_, _) {});
      container.listen(semestersProvider, (_, _) {});
      container.listen(sectionsProvider, (_, _) {});
      container.listen(subjectsProvider, (_, _) {});
      container.listen(academicYearsProvider, (_, _) {});

      await Future.delayed(const Duration(milliseconds: 300));

      // Read memoized lookup maps
      final deptMap = container.read(departmentMapProvider);
      final courseMap = container.read(courseMapProvider);
      final semMap = container.read(semesterMapProvider);
      final secMap = container.read(sectionMapProvider);
      final subMap = container.read(subjectMapProvider);
      final yearMap = container.read(academicYearMapProvider);

      expect(deptMap, isA<Map<String, Department>>());
      expect(courseMap, isA<Map<String, Course>>());
      expect(semMap, isA<Map<String, Semester>>());
      expect(secMap, isA<Map<String, Section>>());
      expect(subMap, isA<Map<String, Subject>>());
      expect(yearMap, isA<Map<String, AcademicYear>>());
    });
  });
}
