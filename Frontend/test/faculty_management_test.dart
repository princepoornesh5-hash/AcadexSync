import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/data/repositories/firebase_academic_repository.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
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
  group('Prompt 58: Faculty Management & Academic Assignment Tests', () {
    late FakeFirestoreService fakeFirestore;

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

    test('1. HOD can create faculty record within authorized department', () async {
      final repo = FirebaseAcademicRepository(fakeFirestore, hodUser);

      final faculty = Faculty(
        id: 'fac-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        name: 'Dr. Alan Turing',
        employeeId: 'EMP001',
        email: 'turing@acadex.com',
        phone: '1234567890',
        isActive: true,
      );

      await repo.addFaculty(faculty);
      final facultyList = await repo.getFaculty();

      expect(facultyList.length, equals(1));
      expect(facultyList.first.name, equals('Dr. Alan Turing'));
      expect(facultyList.first.employeeId, equals('EMP001'));
    });

    test('2. HOD cannot create faculty record in another department (Tenant Isolation)', () async {
      final repo = FirebaseAcademicRepository(fakeFirestore, hodUser);

      final foreignFaculty = Faculty(
        id: 'fac-foreign',
        collegeId: 'col-1',
        departmentId: 'dept-ece', // Foreign department
        name: 'Dr. Foreign Professor',
        employeeId: 'EMP999',
        email: 'foreign@acadex.com',
        phone: '9999999999',
        isActive: true,
      );

      expect(
        () => repo.addFaculty(foreignFaculty),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('3. Bulk assignment connects Faculty to Subjects and Sections', () async {
      final repo = FirebaseAcademicRepository(fakeFirestore, collegeAdminUser);

      final faculty = Faculty(
        id: 'fac-2',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        name: 'Dr. Grace Hopper',
        employeeId: 'EMP002',
        email: 'hopper@acadex.com',
        phone: '9876543210',
        isActive: true,
      );

      await repo.addFaculty(faculty);
      await repo.bulkAssignSubjectsToFaculty('fac-2', ['sub-algo-101'], ['sec-3a']);

      final doc = await fakeFirestore.getDocument('faculty', 'fac-2');
      final updatedFaculty = Faculty.fromJson(doc!);

      expect(updatedFaculty.subjectIds, contains('sub-algo-101'));
      expect(updatedFaculty.sectionIds, contains('sec-3a'));
    });

    test('4. Cross-department assignment attempt by unauthorized HOD is rejected', () async {
      // Pre-seed faculty in ECE department
      await fakeFirestore.setDocument('faculty', 'fac-ece-1', {
        'id': 'fac-ece-1',
        'departmentId': 'dept-ece',
        'name': 'ECE Professor',
        'employeeId': 'EMP003',
        'email': 'ece@acadex.com',
        'phone': '1112223333',
        'isActive': true,
        'subjectIds': [],
        'sectionIds': [],
      });

      // CSE HOD attempts to assign subjects to ECE Faculty
      final cseHodRepo = FirebaseAcademicRepository(fakeFirestore, hodUser);

      expect(
        () => cseHodRepo.bulkAssignSubjectsToFaculty('fac-ece-1', ['sub-cse-1'], ['sec-1']),
        throwsA(isA<BackendPermissionException>()),
      );
    });

    test('5. Development Test Mode contains realistic mock faculty assignments', () async {
      final mockRepo = MockAcademicRepository();
      final facultyList = await mockRepo.getFaculty();

      expect(facultyList.isNotEmpty, isTrue);
      final facultySample = facultyList.first;
      expect(facultySample.departmentId.isNotEmpty, isTrue);
      expect(facultySample.employeeId.isNotEmpty, isTrue);
    });
  });
}
