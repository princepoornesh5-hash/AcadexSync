import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/data/repositories/firebase_academic_repository.dart';
import 'package:campus_management/core/firebase/firebase_services.dart';
import 'package:campus_management/core/firebase/firebase_exceptions.dart';

class FakeFirestoreService implements FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> _db = {};

  @override
  Future<void> setDocument(String collection, String id, Map<String, dynamic> data) async {
    _db.putIfAbsent(collection, () => {})[id] = data;
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('FirebaseAcademicRepository Unit & Tenant Security Tests', () {
    late FakeFirestoreService fakeFirestore;

    final superAdminUser = const UserModel(
      id: 'usr-super',
      name: 'Super Admin',
      email: 'admin@acadex.com',
      role: AppRole.superAdmin,
    );

    final collegeAdminUser = const UserModel(
      id: 'usr-col-admin',
      name: 'College Admin',
      email: 'college@acadex.com',
      role: AppRole.collegeAdmin,
      collegeId: 'col-1',
    );

    final hodUser = const UserModel(
      id: 'usr-hod',
      name: 'HOD CSE',
      email: 'hod@acadex.com',
      role: AppRole.hod,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    setUp(() {
      fakeFirestore = FakeFirestoreService();
    });

    test('1. Super Admin can add and fetch colleges across platforms', () async {
      final repo = FirebaseAcademicRepository(fakeFirestore, superAdminUser);

      final college = College(
        id: 'col-1',
        name: 'Acadex Engineering College',
        code: 'AEC',
        address: '123 Tech Park',
        email: 'info@aec.edu',
        phone: '1234567890',
        principal: 'Dr. Smith',
      );

      await repo.addCollege(college);
      final colleges = await repo.getColleges();

      expect(colleges.length, 1);
      expect(colleges.first.name, 'Acadex Engineering College');
    });

    test('2. College Admin is scoped to their authorized college', () async {
      // Pre-seed two colleges
      await fakeFirestore.setDocument('colleges', 'col-1', {
        'id': 'col-1',
        'name': 'College One',
        'code': 'C1',
        'address': 'Addr 1',
        'email': 'c1@test.com',
        'phone': '111',
        'principal': 'P1',
        'isActive': true,
      });

      await fakeFirestore.setDocument('colleges', 'col-2', {
        'id': 'col-2',
        'name': 'College Two',
        'code': 'C2',
        'address': 'Addr 2',
        'email': 'c2@test.com',
        'phone': '222',
        'principal': 'P2',
        'isActive': true,
      });

      final colAdminRepo = FirebaseAcademicRepository(fakeFirestore, collegeAdminUser);
      final visibleColleges = await colAdminRepo.getColleges();

      // Should only return col-1
      expect(visibleColleges.length, 1);
      expect(visibleColleges.first.id, 'col-1');
    });

    test('3. College Admin cannot add department to another college', () async {
      final colAdminRepo = FirebaseAcademicRepository(fakeFirestore, collegeAdminUser);

      final unauthorizedDept = Department(
        id: 'dept-foreign',
        collegeId: 'col-2', // Unauthorized foreign college
        name: 'Foreign Dept',
        code: 'FOR',
        hodId: 'usr-hod-2',
        description: 'Foreign department',
      );

      expect(
        () => colAdminRepo.addDepartment(unauthorizedDept),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('4. HOD is restricted to their assigned department', () async {
      final hodRepo = FirebaseAcademicRepository(fakeFirestore, hodUser);

      // Pre-seed the department since addCourse validates it exists
      await fakeFirestore.setDocument('departments', 'dept-cse', {
        'id': 'dept-cse',
        'collegeId': 'col-1',
        'name': 'Computer Science',
        'code': 'CSE',
        'hodId': 'usr-hod-1',
        'description': 'CSE Dept',
        'isActive': true,
      });

      final validDeptCourse = Course(
        id: 'crs-cse-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        name: 'B.Tech CSE',
        code: 'CSE101',
      );

      await hodRepo.addCourse(validDeptCourse);
      final courses = await hodRepo.getCourses();

      expect(courses.length, 1);
      expect(courses.first.departmentId, 'dept-cse');
    });

    test('5. Bulk student promotion and transfer updates section history', () async {
      await fakeFirestore.setDocument('semesters', 'sem-4', {
        'id': 'sem-4',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
        'courseId': 'crs-cse',
        'academicYearId': 'ay-2026',
        'name': 'Semester 4',
        'number': 4,
        'isActive': true,
      });

      await fakeFirestore.setDocument('sections', 'sec-4a', {
        'id': 'sec-4a',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
        'semesterId': 'sem-4',
        'name': 'Section 4A',
        'isActive': true,
      });

      await fakeFirestore.setDocument('students', 'std-1', {
        'id': 'std-1',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
        'courseId': 'crs-cse',
        'sectionId': 'sec-3a',
        'semesterId': 'sem-3',
        'rollNumber': 'R001',
        'usn': 'USN001',
        'name': 'Student One',
        'email': 'student1@acadex.com',
        'phone': '9999999999',
        'academicYearId': 'ay-2026',
        'status': 'active',
        'history': [],
        'isActive': true,
      });

      final repo = FirebaseAcademicRepository(fakeFirestore, superAdminUser);
      await repo.bulkPromoteStudents(['std-1'], 'sem-4', 'sec-4a');

      final updatedDoc = await fakeFirestore.getDocument('students', 'std-1');
      final updatedStudent = Student.fromJson(updatedDoc!);

      expect(updatedStudent.semesterId, 'sem-4');
      expect(updatedStudent.sectionId, 'sec-4a');
      expect(updatedStudent.history.length, 1);
      expect(updatedStudent.history.first.semesterId, 'sem-3');
    });
  });
}
