import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../core/firebase/firebase_exceptions.dart';
import '../../domain/models/academic_models.dart';
import '../../domain/repositories/academic_repository.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../../../features/auth/domain/models/role_enum.dart';

class FirebaseAcademicRepository implements AcademicRepository {
  final FirestoreService _firestoreService;
  final UserModel? _currentUser;

  FirebaseAcademicRepository(this._firestoreService, this._currentUser);

  void _validateScope(String? collegeId, [String? departmentId]) {
    if (_currentUser == null) throw const BackendPermissionException('Unauthenticated');
    if (_currentUser.role == AppRole.superAdmin) return;
    
    if (collegeId != null && collegeId != _currentUser.collegeId) {
       throw const BackendPermissionException('Unauthorized access to college data');
    }
    
    if (_currentUser.role == AppRole.hod) {
       if (departmentId != null && departmentId != _currentUser.departmentId) {
         throw const BackendPermissionException('Unauthorized access to department data');
       }
    }
  }

  Map<String, dynamic> _getScopeFilters({bool isCollege = false, bool hasCollegeId = true}) {
    if (_currentUser == null) return {};
    if (_currentUser.role == AppRole.superAdmin) return {};
    
    final filters = <String, dynamic>{};
    
    if (isCollege) {
      filters['id'] = _currentUser.collegeId;
      return filters;
    }
    
    if (hasCollegeId && _currentUser.collegeId?.isNotEmpty == true) {
      filters['collegeId'] = _currentUser.collegeId;
    }
    
    if (_currentUser.role == AppRole.hod && _currentUser.departmentId?.isNotEmpty == true) {
      filters['departmentId'] = _currentUser.departmentId;
    }
    
    return filters;
  }

  // --- Read Operations ---

  @override
  Future<List<College>> getColleges() async {
    final filters = _getScopeFilters(isCollege: true);
    final docs = await _firestoreService.queryCollection('colleges', filters);
    return docs.map((d) => College.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<List<Department>> getDepartments({String? collegeId, String? search, String? status}) async {
    final filters = _getScopeFilters(hasCollegeId: true);
    final docs = await _firestoreService.queryCollection('departments', filters);
    return docs.map((d) => Department.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<Department> getDepartmentById(String id) async {
    final doc = await _firestoreService.getDocument('departments', id);
    if (doc == null) throw Exception('Department not found');
    return Department.fromJson(doc);
  }

  @override
  Future<Map<String, dynamic>> getDepartmentSummary(String id) async {
    return {};
  }

  @override
  Future<Map<String, dynamic>?> getDepartmentHod(String departmentId) async {
    return null;
  }

  @override
  Future<void> updateDepartmentStatus(String id, String status) async {
    final doc = await _firestoreService.getDocument('departments', id);
    if (doc != null) {
      final updated = Department.fromJson(doc).copyWith(isActive: status == 'active');
      await _firestoreService.setDocument('departments', id, updated.toJson());
    }
  }

  @override
  Future<List<Course>> getCourses({String? collegeId, String? departmentId, String? search}) async {
    final filters = _getScopeFilters(hasCollegeId: true);
    final docs = await _firestoreService.queryCollection('courses', filters);
    return docs.map((d) => Course.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<Course> getCourseById(String id) async {
    final doc = await _firestoreService.getDocument('courses', id);
    if (doc == null) throw Exception('Course not found');
    return Course.fromJson(doc);
  }

  @override
  Future<void> updateCourseStatus(String id, bool isActive) async {
    final doc = await _firestoreService.getDocument('courses', id);
    if (doc != null) {
      final updated = Course.fromJson(doc).copyWith(isActive: isActive);
      await _firestoreService.setDocument('courses', id, updated.toJson());
    }
  }

  @override
  Future<List<AcademicYear>> getAcademicYears({String? collegeId}) async {
    final filters = _getScopeFilters(hasCollegeId: true);
    final docs = await _firestoreService.queryCollection('academicYears', filters);
    return docs.map((d) => AcademicYear.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<AcademicYear> getAcademicYearById(String id) async {
    final doc = await _firestoreService.getDocument('academicYears', id);
    if (doc == null) throw Exception('Academic Year not found');
    return AcademicYear.fromJson(doc);
  }

  @override
  Future<void> setCurrentAcademicYear(String id) async {
    final doc = await _firestoreService.getDocument('academicYears', id);
    if (doc != null) {
      final updated = AcademicYear.fromJson(doc).copyWith(isCurrent: true);
      await _firestoreService.setDocument('academicYears', id, updated.toJson());
    }
  }

  @override
  Future<void> updateAcademicYearStatus(String id, bool isActive) async {
    final doc = await _firestoreService.getDocument('academicYears', id);
    if (doc != null) {
      final updated = AcademicYear.fromJson(doc).copyWith(isActive: isActive);
      await _firestoreService.setDocument('academicYears', id, updated.toJson());
    }
  }

  @override
  Future<List<Semester>> getSemesters({String? courseId, String? academicYearId, String? collegeId}) async {
    final filters = _getScopeFilters(hasCollegeId: true);
    if (courseId != null) filters['courseId'] = courseId;
    if (academicYearId != null) filters['academicYearId'] = academicYearId;
    final docs = await _firestoreService.queryCollection('semesters', filters);
    return docs.map((d) => Semester.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<Semester> getSemesterById(String id) async {
    final doc = await _firestoreService.getDocument('semesters', id);
    if (doc == null) throw Exception('Semester not found');
    return Semester.fromJson(doc);
  }

  @override
  Future<void> updateSemesterStatus(String id, bool isActive) async {
    final doc = await _firestoreService.getDocument('semesters', id);
    if (doc != null) {
      final updated = Semester.fromJson(doc).copyWith(isActive: isActive);
      await _firestoreService.setDocument('semesters', id, updated.toJson());
    }
  }

  @override
  Future<void> toggleSemesterCurrent(String id, bool isCurrent) async {
    final doc = await _firestoreService.getDocument('semesters', id);
    if (doc != null) {
      final updated = Semester.fromJson(doc).copyWith(isCurrent: isCurrent);
      await _firestoreService.setDocument('semesters', id, updated.toJson());
    }
  }

  @override
  Future<List<Section>> getSections({String? semesterId, String? courseId, String? collegeId}) async {
    final filters = _getScopeFilters(hasCollegeId: true);
    if (semesterId != null) filters['semesterId'] = semesterId;
    if (courseId != null) filters['courseId'] = courseId;
    final docs = await _firestoreService.queryCollection('sections', filters);
    return docs.map((d) => Section.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<Section> getSectionById(String id) async {
    final doc = await _firestoreService.getDocument('sections', id);
    if (doc == null) throw Exception('Section not found');
    return Section.fromJson(doc);
  }

  @override
  Future<void> updateSectionStatus(String id, bool isActive) async {
    final doc = await _firestoreService.getDocument('sections', id);
    if (doc != null) {
      final updated = Section.fromJson(doc).copyWith(isActive: isActive);
      await _firestoreService.setDocument('sections', id, updated.toJson());
    }
  }

  @override
  Future<ProvisionHodResult> provisionHod({
    required String departmentId,
    required String name,
    required String instituteId,
    required String email,
    String? phone,
  }) async {
    throw UnimplementedError('HOD provisioning via Firebase not supported');
  }

  @override
  Future<List<UserModel>> getHods({String? departmentId, String? search, String? status}) async {
    return [];
  }

  @override
  Future<UserModel> getHodById(String id) async {
    throw UnimplementedError('getHodById not implemented');
  }

  @override
  Future<void> updateHodProfile(String id, {String? name, String? email, String? phone}) async {}

  @override
  Future<void> transferHodDepartment(String id, String targetDepartmentId) async {}

  @override
  Future<Map<String, dynamic>> getHodSummary(String id) async {
    return {};
  }

  @override
  Future<List<Subject>> getSubjects({String? semesterId, String? courseId, String? collegeId}) async {
    final filters = _getScopeFilters(hasCollegeId: true);
    if (semesterId != null) filters['semesterId'] = semesterId;
    if (courseId != null) filters['courseId'] = courseId;
    final docs = await _firestoreService.queryCollection('subjects', filters);
    return docs.map((d) => Subject.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<Subject> getSubjectById(String id) async {
    final doc = await _firestoreService.getDocument('subjects', id);
    if (doc == null) throw Exception('Subject not found');
    return Subject.fromJson(doc);
  }

  @override
  Future<void> updateSubjectStatus(String id, bool isActive) async {
    final doc = await _firestoreService.getDocument('subjects', id);
    if (doc != null) {
      final updated = Subject.fromJson(doc).copyWith(isActive: isActive);
      await _firestoreService.setDocument('subjects', id, updated.toJson());
    }
  }

  @override
  Future<List<Faculty>> getFaculty({String? departmentId, String? search, String? status}) async {
    final filters = _getScopeFilters(hasCollegeId: true);
    if (departmentId != null) filters['departmentId'] = departmentId;
    final docs = await _firestoreService.queryCollection('faculty', filters);
    return docs.map((d) => Faculty.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<Map<String, dynamic>> getFacultySummary(String id) async {
    return {};
  }

  @override
  Future<PaginatedResponse<Faculty>> getPaginatedFaculty({String? departmentId, int limit = 20, DocumentSnapshot? startAfter}) async {
    final filters = _getScopeFilters(hasCollegeId: true);
    if (departmentId != null) filters['departmentId'] = departmentId;
    filters['isActive'] = true;
    
    final response = await _firestoreService.queryCollectionPaginated(
      'faculty', 
      filters, 
      limit: limit, 
      orderBy: 'name', 
      startAfterDocument: startAfter,
    );
    
    return PaginatedResponse<Faculty>(
      data: response.data.map((d) => Faculty.fromJson(d)).toList(),
      lastDocument: response.lastDocument,
      hasMore: response.hasMore,
    );
  }

  @override
  Future<List<Student>> getStudents({String? sectionId, String? departmentId}) async {
    final filters = _getScopeFilters();
    if (sectionId != null) filters['sectionId'] = sectionId;
    if (departmentId != null) filters['departmentId'] = departmentId;
    final docs = await _firestoreService.queryCollection('students', filters);
    return docs.map((d) => Student.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<PaginatedResponse<Student>> getPaginatedStudents({String? sectionId, String? departmentId, int limit = 20, DocumentSnapshot? startAfter}) async {
    final filters = _getScopeFilters();
    if (sectionId != null) filters['sectionId'] = sectionId;
    if (departmentId != null) filters['departmentId'] = departmentId;
    filters['isActive'] = true;
    
    final response = await _firestoreService.queryCollectionPaginated(
      'students', 
      filters, 
      limit: limit, 
      orderBy: 'name', 
      startAfterDocument: startAfter,
    );
    
    return PaginatedResponse<Student>(
      data: response.data.map((d) => Student.fromJson(d)).toList(),
      lastDocument: response.lastDocument,
      hasMore: response.hasMore,
    );
  }

  @override
  Future<Faculty?> getFacultyById(String id) async {
    final doc = await _firestoreService.getDocument('faculty', id);
    return doc != null ? Faculty.fromJson(doc) : null;
  }

  @override
  Future<Student?> getStudentById(String id) async {
    final doc = await _firestoreService.getDocument('students', id);
    return doc != null ? Student.fromJson(doc) : null;
  }

  @override
  Future<bool> checkStudentExists(String rollNumber, String email) async {
    final docsByRoll = await _firestoreService.queryCollectionPaginated('students', {'rollNumber': rollNumber}, limit: 1);
    if (docsByRoll.data.isNotEmpty) return true;
    final docsByEmail = await _firestoreService.queryCollectionPaginated('students', {'email': email}, limit: 1);
    return docsByEmail.data.isNotEmpty;
  }

  @override
  Future<bool> checkFacultyExists(String employeeId, String email) async {
    final docsById = await _firestoreService.queryCollectionPaginated('faculty', {'employeeId': employeeId}, limit: 1);
    if (docsById.data.isNotEmpty) return true;
    final docsByEmail = await _firestoreService.queryCollectionPaginated('faculty', {'email': email}, limit: 1);
    return docsByEmail.data.isNotEmpty;
  }

  // --- College Mutations (Super Admin only) ---

  @override
  Future<void> addCollege(College college) async {
    if (_currentUser != null && _currentUser.role != AppRole.superAdmin) {
      throw const BackendPermissionException("Only Super Admin can create colleges");
    }
    await _firestoreService.setDocument('colleges', college.id, college.toJson());
  }

  @override
  Future<void> updateCollege(College college) async {
    if (_currentUser != null && _currentUser.role != AppRole.superAdmin) {
      throw const BackendPermissionException("Only Super Admin can update colleges");
    }
    await _firestoreService.setDocument('colleges', college.id, college.toJson());
  }

  @override
  Future<void> deactivateCollege(String id) async {
    if (_currentUser != null && _currentUser.role != AppRole.superAdmin) {
      throw const BackendPermissionException("Only Super Admin can deactivate colleges");
    }
    final doc = await _firestoreService.getDocument('colleges', id);
    if (doc != null) {
      final updated = College.fromJson(doc).copyWith(isActive: false);
      await _firestoreService.setDocument('colleges', id, updated.toJson());
    }
  }

  @override
  Future<void> deleteCollegePermanently(String id) async {
    if (_currentUser != null && _currentUser.role != AppRole.superAdmin) {
      throw const BackendPermissionException("Only Super Admin can delete colleges");
    }
    await _firestoreService.deleteDocument('colleges', id);
  }

  @override
  Future<College> getCollegeById(String id) async {
    final doc = await _firestoreService.getDocument('colleges', id);
    if (doc == null) throw Exception('College not found');
    return College.fromJson(doc);
  }

  @override
  Future<Map<String, dynamic>> getCollegeSummary(String id) async {
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> getCollegeAdmins(String id) async {
    // Firebase repo delegates to API for college admin listing
    return [];
  }

  @override
  Future<void> updateCollegeStatus(String id, String status) async {
    final doc = await _firestoreService.getDocument('colleges', id);
    if (doc != null) {
      final updated = College.fromJson(doc).copyWith(isActive: status == 'active');
      await _firestoreService.setDocument('colleges', id, updated.toJson());
    }
  }

  @override
  Future<ProvisionAdminResult> provisionCollegeAdmin(String collegeId, Map<String, dynamic> data) async {
    throw UnimplementedError('provisionCollegeAdmin not supported in Firebase repo. Use API repo.');
  }


  @override
  Future<void> addDepartment(Department department) async {
    _validateScope(department.collegeId, department.id);
    await _firestoreService.setDocument('departments', department.id, department.toJson());
  }

  @override
  Future<void> updateDepartment(Department department) async {
    _validateScope(department.collegeId, department.id);
    await _firestoreService.setDocument('departments', department.id, department.toJson());
  }

  @override
  Future<void> deactivateDepartment(String id) async {
    final doc = await _firestoreService.getDocument('departments', id);
    if (doc != null) {
      final department = Department.fromJson(doc);
      _validateScope(department.collegeId, department.id);

      final activeAssignments = await _firestoreService.queryCollection('facultyAssignments', {
        'departmentId': id,
        'isActive': true,
      });
      if (activeAssignments.isNotEmpty) {
        throw const BackendValidationException("Cannot deactivate department with active faculty assignments. Reassign or remove them first.");
      }

      final activeStudents = await _firestoreService.queryCollection('students', {
        'departmentId': id,
        'isActive': true,
      });
      if (activeStudents.isNotEmpty) {
        throw const BackendValidationException("Cannot deactivate department with enrolled students. Transfer them first.");
      }

      final updated = department.copyWith(isActive: false);
      await _firestoreService.setDocument('departments', id, updated.toJson());
    }
  }

  // --- Course Mutations ---

  @override
  Future<void> addCourse(Course course) async {
    final deptDoc = await _firestoreService.getDocument('departments', course.departmentId);
    if (deptDoc == null) throw Exception("Invalid Department");
    final collegeId = deptDoc['collegeId'] as String?;
    
    _validateScope(collegeId, course.departmentId);
    await _firestoreService.setDocument('courses', course.id, course.toJson());
  }

  @override
  Future<void> updateCourse(Course course) async {
    final deptDoc = await _firestoreService.getDocument('departments', course.departmentId);
    if (deptDoc == null) throw Exception("Invalid Department");
    final collegeId = deptDoc['collegeId'] as String?;
    
    _validateScope(collegeId, course.departmentId);
    await _firestoreService.setDocument('courses', course.id, course.toJson());
  }

  @override
  Future<void> deactivateCourse(String id) async {
    final doc = await _firestoreService.getDocument('courses', id);
    if (doc != null) {
      final course = Course.fromJson(doc);
      final deptDoc = await _firestoreService.getDocument('departments', course.departmentId);
      final collegeId = deptDoc?['collegeId'] as String?;
      
      _validateScope(collegeId, course.departmentId);

      // Safety Check: Check if active semesters depend on this
      final activeSemesters = await _firestoreService.queryCollection('semesters', {'courseId': id, 'isActive': true});
      if (activeSemesters.isNotEmpty) {
        throw Exception("Cannot deactivate course with active semesters. Deactivate them first.");
      }

      final updated = course.copyWith(isActive: false);
      await _firestoreService.setDocument('courses', id, updated.toJson());
    }
  }

  // --- Academic Year Mutations ---

  @override
  Future<void> addAcademicYear(AcademicYear academicYear) async {
    _validateScope(academicYear.collegeId);
    if (!academicYear.endDate.isAfter(academicYear.startDate)) {
      throw const BackendValidationException("End date must be after start date");
    }

    if (academicYear.isCurrent || academicYear.status == 'active') {
      final existing = await _firestoreService.queryCollection('academicYears', {'collegeId': academicYear.collegeId});
      for (final doc in existing) {
        if (doc['isCurrent'] == true || doc['status'] == 'active') {
          await _firestoreService.setDocument('academicYears', doc['id'] as String, {
            'status': 'completed',
            'isCurrent': false,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }
    }

    await _firestoreService.setDocument('academicYears', academicYear.id, academicYear.toJson());
  }

  @override
  Future<void> updateAcademicYear(AcademicYear academicYear) async {
    _validateScope(academicYear.collegeId);
    if (!academicYear.endDate.isAfter(academicYear.startDate)) {
      throw const BackendValidationException("End date must be after start date");
    }

    if (academicYear.isCurrent || academicYear.status == 'active') {
      final existing = await _firestoreService.queryCollection('academicYears', {'collegeId': academicYear.collegeId});
      for (final doc in existing) {
        if (doc['id'] != academicYear.id && (doc['isCurrent'] == true || doc['status'] == 'active')) {
          await _firestoreService.setDocument('academicYears', doc['id'] as String, {
            'status': 'completed',
            'isCurrent': false,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }
    }

    await _firestoreService.setDocument('academicYears', academicYear.id, academicYear.toJson());
  }

  @override
  Future<void> deactivateAcademicYear(String id) async {
    final doc = await _firestoreService.getDocument('academicYears', id);
    if (doc != null) {
      final academicYear = AcademicYear.fromJson(doc);
      _validateScope(academicYear.collegeId);
      final updated = academicYear.copyWith(isActive: false, status: 'archived', isCurrent: false, updatedAt: DateTime.now());
      await _firestoreService.setDocument('academicYears', id, updated.toJson());
    }
  }

  @override
  Future<void> activateAcademicYear(String collegeId, String academicYearId) async {
    _validateScope(collegeId);
    final target = await _firestoreService.getDocument('academicYears', academicYearId);
    if (target == null || target['collegeId'] != collegeId) {
      throw const BackendValidationException("Academic year not found");
    }

    final allYears = await _firestoreService.queryCollection('academicYears', {'collegeId': collegeId});
    for (final doc in allYears) {
      final yId = doc['id'] as String;
      if (yId == academicYearId) {
        await _firestoreService.setDocument('academicYears', yId, {
          'status': 'active',
          'isCurrent': true,
          'isActive': true,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else if (doc['isCurrent'] == true || doc['status'] == 'active') {
        await _firestoreService.setDocument('academicYears', yId, {
          'status': 'completed',
          'isCurrent': false,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  // --- Semester Mutations ---

  @override
  Future<void> addSemester(Semester semester) async {
    final courseDoc = await _firestoreService.getDocument('courses', semester.courseId);
    if (courseDoc == null) throw const BackendValidationException("Invalid Course");
    final departmentId = courseDoc['departmentId'] as String?;
    
    final deptDoc = await _firestoreService.getDocument('departments', departmentId!);
    final collegeId = deptDoc?['collegeId'] as String?;
    
    _validateScope(collegeId, departmentId);
    
    // Validate Academic Year belongs to College
    final ayDoc = await _firestoreService.getDocument('academicYears', semester.academicYearId);
    if (ayDoc == null || ayDoc['collegeId'] != collegeId) throw const BackendValidationException("Invalid Academic Year for this College");

    if (semester.startDate != null && semester.endDate != null && !semester.endDate!.isAfter(semester.startDate!)) {
      throw const BackendValidationException("End date must be after start date");
    }

    // Prevent duplicate semester number inside same course and academic year
    final existingSemesters = await _firestoreService.queryCollection('semesters', {
      'courseId': semester.courseId,
      'academicYearId': semester.academicYearId,
      'number': semester.number,
      'isActive': true,
    });
    if (existingSemesters.isNotEmpty) {
      throw const BackendValidationException("Duplicate semester number inside same course and academic year");
    }

    // Single active semester per course & academic year
    if (semester.isCurrent || semester.status == 'active') {
      final activeInCourse = await _firestoreService.queryCollection('semesters', {
        'courseId': semester.courseId,
        'academicYearId': semester.academicYearId,
      });
      for (final doc in activeInCourse) {
        if (doc['isCurrent'] == true || doc['status'] == 'active') {
          await _firestoreService.setDocument('semesters', doc['id'] as String, {
            'status': 'completed',
            'isCurrent': false,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }
    }

    await _firestoreService.setDocument('semesters', semester.id, semester.copyWith(
      collegeId: collegeId ?? '',
      departmentId: departmentId,
      createdAt: semester.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    ).toJson());
  }

  @override
  Future<void> updateSemester(Semester semester) async {
    final courseDoc = await _firestoreService.getDocument('courses', semester.courseId);
    if (courseDoc == null) throw const BackendValidationException("Invalid Course");
    final departmentId = courseDoc['departmentId'] as String?;
    
    final deptDoc = await _firestoreService.getDocument('departments', departmentId!);
    final collegeId = deptDoc?['collegeId'] as String?;
    
    _validateScope(collegeId, departmentId);

    if (semester.isCurrent || semester.status == 'active') {
      final activeInCourse = await _firestoreService.queryCollection('semesters', {
        'courseId': semester.courseId,
        'academicYearId': semester.academicYearId,
      });
      for (final doc in activeInCourse) {
        if (doc['id'] != semester.id && (doc['isCurrent'] == true || doc['status'] == 'active')) {
          await _firestoreService.setDocument('semesters', doc['id'] as String, {
            'status': 'completed',
            'isCurrent': false,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }
    }

    await _firestoreService.setDocument('semesters', semester.id, semester.copyWith(updatedAt: DateTime.now()).toJson());
  }

  @override
  Future<void> deactivateSemester(String id) async {
    final doc = await _firestoreService.getDocument('semesters', id);
    if (doc != null) {
      final sem = Semester.fromJson(doc);
      final courseDoc = await _firestoreService.getDocument('courses', sem.courseId);
      final departmentId = courseDoc?['departmentId'] as String?;
      final deptDoc = await _firestoreService.getDocument('departments', departmentId!);
      final collegeId = deptDoc?['collegeId'] as String?;
      
      _validateScope(collegeId, departmentId);

      // Safety Check
      final activeSections = await _firestoreService.queryCollection('sections', {'semesterId': id, 'isActive': true});
      if (activeSections.isNotEmpty) {
        throw const BackendValidationException("Cannot deactivate semester with active sections.");
      }

      final updated = sem.copyWith(isActive: false, status: 'archived', isCurrent: false, updatedAt: DateTime.now());
      await _firestoreService.setDocument('semesters', id, updated.toJson());
    }
  }

  @override
  Future<void> activateSemester(String collegeId, String courseId, String semesterId) async {
    final doc = await _firestoreService.getDocument('semesters', semesterId);
    if (doc == null) throw const BackendValidationException("Semester not found");
    final targetSem = Semester.fromJson(doc);
    _validateScope(collegeId, targetSem.departmentId);

    final allInCourse = await _firestoreService.queryCollection('semesters', {
      'courseId': courseId,
      'academicYearId': targetSem.academicYearId,
    });

    for (final sDoc in allInCourse) {
      final sId = sDoc['id'] as String;
      if (sId == semesterId) {
        await _firestoreService.setDocument('semesters', sId, {
          'status': 'active',
          'isCurrent': true,
          'isActive': true,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else if (sDoc['isCurrent'] == true || sDoc['status'] == 'active') {
        await _firestoreService.setDocument('semesters', sId, {
          'status': 'completed',
          'isCurrent': false,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  @override
  Future<void> completeSemester(String semesterId) async {
    final doc = await _firestoreService.getDocument('semesters', semesterId);
    if (doc == null) throw const BackendValidationException("Semester not found");
    final sem = Semester.fromJson(doc);
    _validateScope(sem.collegeId, sem.departmentId);

    await _firestoreService.setDocument('semesters', semesterId, {
      'status': 'completed',
      'isCurrent': false,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // --- Section Mutations & Capacity ---

  @override
  Future<void> addSection(Section section) async {
    final semDoc = await _firestoreService.getDocument('semesters', section.semesterId);
    if (semDoc == null) throw const BackendValidationException("Invalid Semester");
    final courseDoc = await _firestoreService.getDocument('courses', semDoc['courseId']);
    final deptDoc = await _firestoreService.getDocument('departments', courseDoc?['departmentId']);
    
    _validateScope(deptDoc?['collegeId'] as String?, courseDoc?['departmentId'] as String?);

    if (section.capacity <= 0) {
      throw const BackendValidationException("Section capacity must be greater than 0");
    }

    await _firestoreService.setDocument('sections', section.id, section.copyWith(
      collegeId: deptDoc?['collegeId'] as String? ?? '',
      departmentId: courseDoc?['departmentId'] as String? ?? '',
      courseId: semDoc['courseId'] as String? ?? '',
      academicYearId: semDoc['academicYearId'] as String? ?? '',
      createdAt: section.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    ).toJson());
  }

  @override
  Future<void> updateSection(Section section) async {
    final semDoc = await _firestoreService.getDocument('semesters', section.semesterId);
    if (semDoc == null) throw const BackendValidationException("Invalid Semester");
    final courseDoc = await _firestoreService.getDocument('courses', semDoc['courseId']);
    final deptDoc = await _firestoreService.getDocument('departments', courseDoc?['departmentId']);
    
    _validateScope(deptDoc?['collegeId'] as String?, courseDoc?['departmentId'] as String?);
    await _firestoreService.setDocument('sections', section.id, section.copyWith(updatedAt: DateTime.now()).toJson());
  }

  @override
  Future<void> updateSectionCapacity(String sectionId, int newCapacity) async {
    if (newCapacity <= 0) {
      throw const BackendValidationException("Section capacity must be greater than 0");
    }
    final doc = await _firestoreService.getDocument('sections', sectionId);
    if (doc == null) throw const BackendValidationException("Section not found");
    final section = Section.fromJson(doc);
    _validateScope(section.collegeId, section.departmentId);

    await _firestoreService.setDocument('sections', sectionId, {
      'capacity': newCapacity,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<SectionCapacityInfo> getSectionCapacityInfo(String sectionId) async {
    final doc = await _firestoreService.getDocument('sections', sectionId);
    if (doc == null) throw const BackendValidationException("Section not found");
    final section = Section.fromJson(doc);

    final activeStudents = await _firestoreService.queryCollection('students', {
      'sectionId': sectionId,
      'isActive': true,
    });

    return SectionCapacityInfo(
      sectionId: section.id,
      sectionName: section.name,
      enrolledCount: activeStudents.length,
      capacity: section.capacity,
    );
  }

  @override
  Future<List<SectionTransferValidationResult>> validateBulkSectionTransfer(List<String> studentIds, String targetSectionId) async {
    final doc = await _firestoreService.getDocument('sections', targetSectionId);
    if (doc == null) throw const BackendValidationException("Target section does not exist");
    final targetSection = Section.fromJson(doc);

    final currentStudents = await _firestoreService.queryCollection('students', {
      'sectionId': targetSectionId,
      'isActive': true,
    });
    final availableSeats = targetSection.capacity - currentStudents.length;
    int eligibleAssigned = 0;
    final List<SectionTransferValidationResult> results = [];

    for (final id in studentIds) {
      final sDoc = await _firestoreService.getDocument('students', id);
      if (sDoc == null) {
        results.add(SectionTransferValidationResult(studentId: id, studentName: 'Unknown', rollNumber: 'N/A', canMove: false, reason: 'Student not found'));
        continue;
      }
      final student = Student.fromJson(sDoc);
      if (student.collegeId != targetSection.collegeId) {
        results.add(SectionTransferValidationResult(studentId: student.id, studentName: student.name, rollNumber: student.rollNumber, canMove: false, reason: 'Cross-college transfer is strictly prohibited'));
        continue;
      }
      if (targetSection.departmentId.isNotEmpty && student.departmentId.isNotEmpty && student.departmentId != targetSection.departmentId) {
        results.add(SectionTransferValidationResult(studentId: student.id, studentName: student.name, rollNumber: student.rollNumber, canMove: false, reason: 'Cross-department transfer is not allowed. Use department transfer'));
        continue;
      }
      if (targetSection.semesterId.isNotEmpty && student.semesterId.isNotEmpty && student.semesterId != targetSection.semesterId) {
        results.add(SectionTransferValidationResult(studentId: student.id, studentName: student.name, rollNumber: student.rollNumber, canMove: false, reason: 'Student semester does not match target section semester'));
        continue;
      }
      if (student.sectionId == targetSectionId) {
        results.add(SectionTransferValidationResult(studentId: student.id, studentName: student.name, rollNumber: student.rollNumber, canMove: false, reason: 'Student is already enrolled in this section'));
        continue;
      }
      if (eligibleAssigned >= availableSeats) {
        results.add(SectionTransferValidationResult(studentId: student.id, studentName: student.name, rollNumber: student.rollNumber, canMove: false, reason: 'Target section is full (Available seats: $availableSeats)'));
        continue;
      }

      eligibleAssigned++;
      results.add(SectionTransferValidationResult(studentId: student.id, studentName: student.name, rollNumber: student.rollNumber, canMove: true));
    }
    return results;
  }

  @override
  Future<void> executeBulkSectionTransfer({required List<String> studentIds, required String targetSectionId}) async {
    final validations = await validateBulkSectionTransfer(studentIds, targetSectionId);
    final eligible = validations.where((v) => v.canMove).map((v) => v.studentId).toList();
    if (eligible.isEmpty) {
      throw const BackendValidationException("No eligible students can be transferred");
    }
    await transferStudentsSection(studentIds: eligible, targetSectionId: targetSectionId);
  }

  @override
  Future<void> deactivateSection(String id) async {
    final doc = await _firestoreService.getDocument('sections', id);
    if (doc != null) {
      final section = Section.fromJson(doc);
      final semDoc = await _firestoreService.getDocument('semesters', section.semesterId);
      final courseDoc = await _firestoreService.getDocument('courses', semDoc?['courseId']);
      final deptDoc = await _firestoreService.getDocument('departments', courseDoc?['departmentId']);
      
      _validateScope(deptDoc?['collegeId'] as String?, courseDoc?['departmentId'] as String?);

      // Safety check: Cannot deactivate if students are in it
      final activeStudents = await _firestoreService.queryCollection('students', {'sectionId': id, 'isActive': true});
      if (activeStudents.isNotEmpty) {
        throw const BackendValidationException("Cannot deactivate section with active students.");
      }

      final updated = section.copyWith(isActive: false, status: 'archived', updatedAt: DateTime.now());
      await _firestoreService.setDocument('sections', id, updated.toJson());
    }
  }

  // --- Subject Mutations ---

  @override
  Future<void> addSubject(Subject subject) async {
    final deptDoc = await _firestoreService.getDocument('departments', subject.departmentId);
    if (deptDoc == null) throw Exception("Invalid Department");
    
    final semDoc = await _firestoreService.getDocument('semesters', subject.semesterId);
    if (semDoc == null) throw Exception("Invalid Semester");
    
    _validateScope(deptDoc['collegeId'] as String?, subject.departmentId);
    await _firestoreService.setDocument('subjects', subject.id, subject.toJson());
  }

  @override
  Future<void> updateSubject(Subject subject) async {
    final deptDoc = await _firestoreService.getDocument('departments', subject.departmentId);
    if (deptDoc == null) throw Exception("Invalid Department");
    
    final semDoc = await _firestoreService.getDocument('semesters', subject.semesterId);
    if (semDoc == null) throw Exception("Invalid Semester");
    
    _validateScope(deptDoc['collegeId'] as String?, subject.departmentId);
    await _firestoreService.setDocument('subjects', subject.id, subject.toJson());
  }

  @override
  Future<void> deactivateSubject(String id) async {
    final doc = await _firestoreService.getDocument('subjects', id);
    if (doc != null) {
      final subject = Subject.fromJson(doc);
      final deptDoc = await _firestoreService.getDocument('departments', subject.departmentId);
      _validateScope(deptDoc?['collegeId'] as String?, subject.departmentId);
      final updated = subject.copyWith(isActive: false);
      await _firestoreService.setDocument('subjects', id, updated.toJson());
    }
  }

  // --- Faculty Mutations ---

  @override
  Future<void> addFaculty(Faculty faculty) async {
    _validateScope(faculty.collegeId, faculty.departmentId);
    await _firestoreService.setDocument('faculty', faculty.id, faculty.toJson());
  }

  @override
  Future<ProvisionFacultyResult> provisionFaculty(ProvisionFacultyRequest request) async {
    throw UnimplementedError('Faculty provisioning is only handled via ApiAcademicRepository in production');
  }

  @override
  Future<void> updateFaculty(Faculty faculty) async {
    _validateScope(faculty.collegeId, faculty.departmentId);
    final doc = await _firestoreService.getDocument('faculty', faculty.id);
    if (doc != null) {
      final existing = Faculty.fromJson(doc);
      if (existing.departmentId.isNotEmpty && existing.departmentId != faculty.departmentId) {
        // Invalidate old assignments
        final oldAssignments = await _firestoreService.queryCollection('facultyAssignments', {
          'facultyId': faculty.id,
          'departmentId': existing.departmentId,
          'isActive': true,
        });
        for (final a in oldAssignments) {
          final assignment = FacultyAssignment.fromJson(a);
          final updated = assignment.copyWith(isActive: false, updatedAt: DateTime.now());
          await _firestoreService.setDocument('facultyAssignments', assignment.id, updated.toJson());
        }
        final updatedFaculty = faculty.copyWith(subjectIds: [], sectionIds: []);
        await _firestoreService.setDocument('faculty', faculty.id, updatedFaculty.toJson());
        return;
      }
    }
    await _firestoreService.setDocument('faculty', faculty.id, faculty.toJson());
  }

  @override
  Future<void> transferFacultyDepartment(String facultyId, String newDepartmentId) async {
    final doc = await _firestoreService.getDocument('faculty', facultyId);
    if (doc == null) throw Exception("Faculty not found");
    final faculty = Faculty.fromJson(doc);
    _validateScope(faculty.collegeId);

    final targetDeptDoc = await _firestoreService.getDocument('departments', newDepartmentId);
    if (targetDeptDoc == null) throw Exception("Target department not found");
    final targetDept = Department.fromJson(targetDeptDoc);

    if (faculty.collegeId != targetDept.collegeId) {
      throw const BackendPermissionException("Cannot transfer faculty to a different college");
    }

    final oldDeptId = faculty.departmentId;
    if (oldDeptId != newDepartmentId) {
      // Invalidate old assignments
      final oldAssignments = await _firestoreService.queryCollection('facultyAssignments', {
        'facultyId': facultyId,
        'departmentId': oldDeptId,
        'isActive': true,
      });
      for (final a in oldAssignments) {
        final assignment = FacultyAssignment.fromJson(a);
        final updated = assignment.copyWith(isActive: false, updatedAt: DateTime.now());
        await _firestoreService.setDocument('facultyAssignments', assignment.id, updated.toJson());
      }

      // Update faculty document
      final updatedFaculty = faculty.copyWith(
        departmentId: newDepartmentId,
        subjectIds: [],
        sectionIds: [],
      );
      await _firestoreService.setDocument('faculty', facultyId, updatedFaculty.toJson());

      // Update user document if present
      final userDoc = await _firestoreService.getDocument('users', facultyId);
      if (userDoc != null) {
        final user = UserModel.fromJson(userDoc);
        final updatedUser = user.copyWith(departmentId: newDepartmentId);
        await _firestoreService.setDocument('users', facultyId, updatedUser.toJson());
      }
    }
  }

  @override
  Future<void> deactivateFaculty(String id) async {
    final doc = await _firestoreService.getDocument('faculty', id);
    if (doc != null) {
      final faculty = Faculty.fromJson(doc);
      _validateScope(faculty.collegeId, faculty.departmentId);
      final updated = faculty.copyWith(isActive: false);
      await _firestoreService.setDocument('faculty', id, updated.toJson());
    }
  }

  @override
  Future<void> bulkAssignSubjectsToFaculty(String facultyId, List<String> subjectIds, List<String> sectionIds) async {
    final doc = await _firestoreService.getDocument('faculty', facultyId);
    if (doc != null) {
      final faculty = Faculty.fromJson(doc);
      _validateScope(faculty.collegeId, faculty.departmentId);
      final updated = faculty.copyWith(subjectIds: subjectIds, sectionIds: sectionIds);
      await _firestoreService.setDocument('faculty', facultyId, updated.toJson());
    }
  }

  // --- Student Mutations & Lifecycle Engine (Phase 3) ---

  @override
  Future<void> addStudent(Student student) async {
    await admitStudent(student);
  }

  @override
  Future<ProvisionStudentResult> provisionStudent(ProvisionStudentRequest request) async {
    final student = Student(
      id: 'stu_${DateTime.now().millisecondsSinceEpoch}',
      collegeId: 'c1',
      departmentId: request.departmentId,
      courseId: request.courseId ?? '',
      academicYearId: request.academicYearId ?? '',
      semesterId: request.semesterId ?? '',
      sectionId: request.sectionId ?? '',
      name: request.name,
      rollNumber: request.rollNumber ?? '',
      instituteId: request.instituteId,
      admissionNumber: request.admissionNumber,
      email: request.email ?? '',
      phone: request.phone ?? '',
      parentName: request.parentName,
      parentPhone: request.parentPhone,
      bloodGroup: request.bloodGroup,
      address: request.address,
      dateOfBirth: request.dateOfBirth != null ? DateTime.tryParse(request.dateOfBirth!) : null,
      admissionDate: request.admissionDate != null ? DateTime.tryParse(request.admissionDate!) : null,
      isActive: true,
      accountStatus: AccountStatus.pendingActivation,
    );
    await addStudent(student);
    return ProvisionStudentResult(
      user: UserModel(
        id: student.id,
        name: student.name,
        email: student.email,
        phone: student.phone,
        role: AppRole.student,
        collegeId: student.collegeId,
        departmentId: student.departmentId,
        instituteId: student.instituteId,
        accountStatus: AccountStatus.pendingActivation,
      ),
      student: student,
      invitation: InvitationInfo(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        status: 'pending',
      ),
      activationCode: 'FB-STU1-CODE',
    );
  }

  @override
  Future<void> transferStudentDepartment(String studentId, String newDepartmentId) async {
    final doc = await _firestoreService.getDocument('students', studentId);
    if (doc != null) {
      final updated = Student.fromJson(doc).copyWith(departmentId: newDepartmentId);
      await _firestoreService.setDocument('students', studentId, updated.toJson());
    }
  }

  @override
  Future<Map<String, dynamic>> getStudentSummary(String studentId) async {
    return {'enrollmentCount': 1};
  }

  @override
  Future<void> enrollStudent({
    required String studentId,
    required String courseId,
    required String academicYearId,
    required String semesterId,
    required String sectionId,
    String? enrollmentDate,
  }) async {
    final doc = await _firestoreService.getDocument('students', studentId);
    if (doc != null) {
      final updated = Student.fromJson(doc).copyWith(
        courseId: courseId,
        academicYearId: academicYearId,
        semesterId: semesterId,
        sectionId: sectionId,
      );
      await _firestoreService.setDocument('students', studentId, updated.toJson());
    }
  }

  @override
  Future<void> updateStudent(Student student) async {
    _validateScope(student.collegeId, student.departmentId);
    await _firestoreService.setDocument('students', student.id, student.toJson());
  }

  @override
  Future<void> deactivateStudent(String id) async {
    await updateStudentLifecycleState(
      studentId: id,
      newState: StudentLifecycleState.suspended,
      remarks: 'Deactivated student profile',
    );
  }

  @override
  Future<void> bulkPromoteStudents(List<String> studentIds, String newSemesterId, String newSectionId) async {
    final semDoc = await _firestoreService.getDocument('semesters', newSemesterId);
    final targetAcademicYearId = semDoc?['academicYearId'] as String? ?? '';
    await promoteStudents(
      studentIds: studentIds,
      targetAcademicYearId: targetAcademicYearId,
      targetSemesterId: newSemesterId,
      targetSectionId: newSectionId,
    );
  }

  @override
  Future<void> bulkTransferStudents(List<String> studentIds, String newSectionId) async {
    await transferStudentsSection(studentIds: studentIds, targetSectionId: newSectionId);
  }

  @override
  Future<String> generateRollNumber(String collegeId, String courseId, String academicYearId) async {
    _validateScope(collegeId);
    String courseCode = 'STU';
    if (courseId.isNotEmpty) {
      final courseDoc = await _firestoreService.getDocument('courses', courseId);
      if (courseDoc != null) {
        final code = courseDoc['code'] as String?;
        if (code != null && code.isNotEmpty) {
          courseCode = code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
        }
      }
    }

    String yearStr = DateTime.now().year.toString();
    if (academicYearId.isNotEmpty) {
      final yearDoc = await _firestoreService.getDocument('academicYears', academicYearId);
      if (yearDoc != null) {
        final yName = yearDoc['name'] as String? ?? '';
        final match = RegExp(r'\d{4}').firstMatch(yName);
        if (match != null) {
          yearStr = match.group(0)!;
        }
      }
    }

    final prefix = '$courseCode-$yearStr-';
    final existingStudents = await _firestoreService.queryCollection('students', {
      'collegeId': collegeId,
    });

    int maxSeq = 0;
    for (final doc in existingStudents) {
      final rNo = doc['rollNumber'] as String? ?? '';
      if (rNo.startsWith(prefix)) {
        final seqPart = rNo.substring(prefix.length);
        final parsed = int.tryParse(seqPart);
        if (parsed != null && parsed > maxSeq) {
          maxSeq = parsed;
        }
      }
    }

    final nextSeq = (maxSeq + 1).toString().padLeft(3, '0');
    return '$prefix$nextSeq';
  }

  @override
  Future<void> admitStudent(Student student) async {
    _validateScope(student.collegeId, student.departmentId);

    if (_currentUser != null) {
      if (_currentUser.role != AppRole.superAdmin &&
          _currentUser.role != AppRole.collegeAdmin &&
          _currentUser.role != AppRole.hod) {
        throw const BackendPermissionException('Only Super Admin, College Admin, or HOD can admit students');
      }

      if (_currentUser.role == AppRole.hod && _currentUser.departmentId != student.departmentId) {
        throw const BackendPermissionException('HOD can only admit students to their own department');
      }
    }

    // Validation: Department, Course, Semester, Section existence
    if (student.departmentId.isNotEmpty) {
      final deptDoc = await _firestoreService.getDocument('departments', student.departmentId);
      if (deptDoc == null) throw const BackendValidationException('Department does not exist');
    }
    if (student.courseId.isNotEmpty) {
      final courseDoc = await _firestoreService.getDocument('courses', student.courseId);
      if (courseDoc == null) throw const BackendValidationException('Course does not exist');
      if (student.departmentId.isNotEmpty && courseDoc['departmentId'] != student.departmentId) {
        throw const BackendValidationException('Selected course does not belong to the selected department');
      }
    }
    if (student.semesterId.isNotEmpty) {
      final semDoc = await _firestoreService.getDocument('semesters', student.semesterId);
      if (semDoc == null) throw const BackendValidationException('Semester does not exist');
      if (student.courseId.isNotEmpty && semDoc['courseId'] != student.courseId) {
        throw const BackendValidationException('Selected semester does not belong to the selected course');
      }
    }
    if (student.sectionId.isNotEmpty) {
      final secDoc = await _firestoreService.getDocument('sections', student.sectionId);
      if (secDoc == null) throw const BackendValidationException('Section does not exist');
      if (student.semesterId.isNotEmpty && secDoc['semesterId'] != student.semesterId) {
        throw const BackendValidationException('Selected section does not belong to the selected semester');
      }
      final sec = Section.fromJson(secDoc);
      final activeInSec = await _firestoreService.queryCollection('students', {
        'sectionId': student.sectionId,
        'isActive': true,
      });
      if (activeInSec.where((d) => d['id'] != student.id).length >= sec.capacity) {
        throw BackendValidationException('Section ${sec.name} is full (Capacity: ${sec.capacity})');
      }
    }

    // Check duplicate roll number
    if (student.rollNumber.isNotEmpty) {
      final existingRoll = await _firestoreService.queryCollection('students', {
        'collegeId': student.collegeId,
        'rollNumber': student.rollNumber,
      });
      if (existingRoll.any((d) => d['id'] != student.id)) {
        throw const BackendValidationException('Roll number already exists in this college');
      }
    }

    final initialTimeline = AcademicTimelineRecord(
      id: 'hist_${DateTime.now().millisecondsSinceEpoch}_${student.id}',
      academicYearId: student.academicYearId,
      academicYearName: '',
      semesterId: student.semesterId,
      semesterName: '',
      sectionId: student.sectionId,
      sectionName: '',
      departmentId: student.departmentId,
      courseId: student.courseId,
      status: 'Admitted',
      termStartDate: student.admissionDate ?? DateTime.now(),
      remarks: 'Student admitted into academic lifecycle',
    );

    final enrichedStudent = student.copyWith(
      admissionDate: student.admissionDate ?? DateTime.now(),
      lifecycleState: student.lifecycleState == StudentLifecycleState.applicant
          ? StudentLifecycleState.admitted
          : student.lifecycleState,
      isActive: true,
      history: student.history.isNotEmpty ? student.history : [initialTimeline],
    );

    await _firestoreService.setDocument('students', enrichedStudent.id, enrichedStudent.toJson());

    // Sync student user account if it exists or create one
    final userDoc = await _firestoreService.getDocument('users', enrichedStudent.id);
    if (userDoc == null) {
      final newUser = UserModel(
        id: enrichedStudent.id,
        name: enrichedStudent.name,
        email: enrichedStudent.email,
        role: AppRole.student,
        collegeId: enrichedStudent.collegeId,
        departmentId: enrichedStudent.departmentId,
        accountStatus: AccountStatus.active,
        createdAt: DateTime.now(),
      );
      await _firestoreService.setDocument('users', enrichedStudent.id, newUser.toJson());
    }
  }

  @override
  Future<void> bulkAdmitStudents(List<Student> students) async {
    for (final s in students) {
      await admitStudent(s);
    }
  }

  @override
  Future<void> promoteStudents({
    required List<String> studentIds,
    required String targetAcademicYearId,
    required String targetSemesterId,
    required String targetSectionId,
  }) async {
    final semDoc = await _firestoreService.getDocument('semesters', targetSemesterId);
    if (semDoc == null) throw const BackendValidationException('Target semester does not exist');
    final secDoc = await _firestoreService.getDocument('sections', targetSectionId);
    if (secDoc == null) throw const BackendValidationException('Target section does not exist');
    if (secDoc['semesterId'] != targetSemesterId) {
      throw const BackendValidationException('Target section does not belong to target semester');
    }

    final targetCourseId = semDoc['courseId'] as String? ?? '';
    final targetDeptId = semDoc['departmentId'] as String? ?? '';

    for (final id in studentIds) {
      final doc = await _firestoreService.getDocument('students', id);
      if (doc != null) {
        final current = Student.fromJson(doc);
        _validateScope(current.collegeId, current.departmentId);

        // Security check: cannot promote cross-department
        if (targetDeptId.isNotEmpty && current.departmentId.isNotEmpty && targetDeptId != current.departmentId) {
          throw const BackendValidationException('Cross-department promotion is strictly prohibited');
        }
        if (targetCourseId.isNotEmpty && current.courseId.isNotEmpty && targetCourseId != current.courseId) {
          throw const BackendValidationException('Cross-course promotion is not allowed. Use department transfer instead');
        }

        // Snapshot current state in timeline
        final currentSemDoc = await _firestoreService.getDocument('semesters', current.semesterId);
        final currentSecDoc = await _firestoreService.getDocument('sections', current.sectionId);

        final timelineRecord = AcademicTimelineRecord(
          id: 'hist_${DateTime.now().millisecondsSinceEpoch}_$id',
          academicYearId: current.academicYearId,
          semesterId: current.semesterId,
          semesterName: currentSemDoc?['name'] as String? ?? current.semesterId,
          sectionId: current.sectionId,
          sectionName: currentSecDoc?['name'] as String? ?? current.sectionId,
          departmentId: current.departmentId,
          courseId: current.courseId,
          status: 'Promoted',
          termEndDate: DateTime.now(),
          remarks: 'Promoted to ${semDoc['name']} (Section ${secDoc['name']})',
        );

        final newHistory = List<AcademicTimelineRecord>.from(current.history)..add(timelineRecord);

        // Record history document in /studentAcademicHistory
        final historyEntry = StudentAcademicHistory(
          id: 'hist_${DateTime.now().millisecondsSinceEpoch}_${id}_new',
          studentUid: id,
          collegeId: current.collegeId,
          departmentId: current.departmentId,
          courseId: current.courseId,
          academicYearId: targetAcademicYearId,
          semesterId: targetSemesterId,
          sectionId: targetSectionId,
          startDate: DateTime.now(),
          status: 'active',
          createdAt: DateTime.now(),
        );
        await recordAcademicHistory(historyEntry);

        final updated = current.copyWith(
          academicYearId: targetAcademicYearId,
          semesterId: targetSemesterId,
          sectionId: targetSectionId,
          lifecycleState: StudentLifecycleState.active,
          isActive: true,
          history: newHistory,
        );

        await _firestoreService.setDocument('students', id, updated.toJson());
      }
    }
  }

  @override
  Future<void> transferStudentsSection({
    required List<String> studentIds,
    required String targetSectionId,
  }) async {
    final secDoc = await _firestoreService.getDocument('sections', targetSectionId);
    if (secDoc == null) throw const BackendValidationException('Target section does not exist');
    final targetSemId = secDoc['semesterId'] as String? ?? '';

    for (final id in studentIds) {
      final doc = await _firestoreService.getDocument('students', id);
      if (doc != null) {
        final current = Student.fromJson(doc);
        _validateScope(current.collegeId, current.departmentId);

        final currentSecDoc = await _firestoreService.getDocument('sections', current.sectionId);

        final timelineRecord = AcademicTimelineRecord(
          id: 'hist_${DateTime.now().millisecondsSinceEpoch}_$id',
          academicYearId: current.academicYearId,
          semesterId: current.semesterId,
          sectionId: current.sectionId,
          sectionName: currentSecDoc?['name'] as String? ?? current.sectionId,
          departmentId: current.departmentId,
          courseId: current.courseId,
          status: 'Transferred',
          termEndDate: DateTime.now(),
          remarks: 'Transferred to Section ${secDoc['name']}',
        );

        final newHistory = List<AcademicTimelineRecord>.from(current.history)..add(timelineRecord);

        final updated = current.copyWith(
          sectionId: targetSectionId,
          semesterId: targetSemId.isNotEmpty ? targetSemId : current.semesterId,
          history: newHistory,
        );

        await _firestoreService.setDocument('students', id, updated.toJson());
      }
    }
  }

  @override
  Future<void> transferStudentsDepartment({
    required List<String> studentIds,
    required String targetDepartmentId,
    required String targetCourseId,
    required String targetSemesterId,
    required String targetSectionId,
  }) async {
    for (final id in studentIds) {
      final doc = await _firestoreService.getDocument('students', id);
      if (doc != null) {
        final current = Student.fromJson(doc);
        _validateScope(current.collegeId, current.departmentId);

        final timelineRecord = AcademicTimelineRecord(
          id: 'hist_${DateTime.now().millisecondsSinceEpoch}_$id',
          academicYearId: current.academicYearId,
          semesterId: current.semesterId,
          sectionId: current.sectionId,
          departmentId: current.departmentId,
          courseId: current.courseId,
          status: 'Department Transferred',
          termEndDate: DateTime.now(),
          remarks: 'Transferred to department $targetDepartmentId',
        );

        final newHistory = List<AcademicTimelineRecord>.from(current.history)..add(timelineRecord);

        final updated = current.copyWith(
          departmentId: targetDepartmentId,
          courseId: targetCourseId,
          semesterId: targetSemesterId,
          sectionId: targetSectionId,
          history: newHistory,
        );

        await _firestoreService.setDocument('students', id, updated.toJson());
      }
    }
  }

  @override
  Future<void> updateStudentLifecycleState({
    required String studentId,
    required StudentLifecycleState newState,
    String? remarks,
  }) async {
    final doc = await _firestoreService.getDocument('students', studentId);
    if (doc == null) throw const BackendValidationException('Student not found');
    final current = Student.fromJson(doc);
    _validateScope(current.collegeId, current.departmentId);

    if (!current.lifecycleState.isValidTransition(newState)) {
      throw BackendValidationException('Invalid state transition from ${current.lifecycleState.displayName} to ${newState.displayName}');
    }

    final isGraduatedOrAlumni = newState == StudentLifecycleState.graduated || newState == StudentLifecycleState.alumni;

    final timelineRecord = AcademicTimelineRecord(
      id: 'hist_${DateTime.now().millisecondsSinceEpoch}_$studentId',
      academicYearId: current.academicYearId,
      semesterId: current.semesterId,
      sectionId: current.sectionId,
      departmentId: current.departmentId,
      courseId: current.courseId,
      status: newState.displayName,
      termEndDate: DateTime.now(),
      remarks: remarks ?? 'Lifecycle state updated to ${newState.displayName}',
    );

    final newHistory = List<AcademicTimelineRecord>.from(current.history)..add(timelineRecord);

    final updated = current.copyWith(
      lifecycleState: newState,
      isActive: !isGraduatedOrAlumni,
      graduationDate: isGraduatedOrAlumni ? (current.graduationDate ?? DateTime.now()) : current.graduationDate,
      history: newHistory,
    );

    await _firestoreService.setDocument('students', studentId, updated.toJson());
  }

  @override
  Future<void> bulkGraduateStudents({
    required List<String> studentIds,
    String? remarks,
  }) async {
    for (final id in studentIds) {
      await updateStudentLifecycleState(
        studentId: id,
        newState: StudentLifecycleState.graduated,
        remarks: remarks ?? 'Graduated student cohort',
      );
    }
  }

  @override
  Future<void> bulkArchiveAlumni({
    required List<String> studentIds,
  }) async {
    for (final id in studentIds) {
      await updateStudentLifecycleState(
        studentId: id,
        newState: StudentLifecycleState.alumni,
        remarks: 'Archived to Alumni Registry',
      );
    }
  }

  @override
  Future<StudentAcademicProfile> getStudentAcademicProfile(String studentId) async {
    final studentDoc = await _firestoreService.getDocument('students', studentId);
    if (studentDoc == null) throw const BackendValidationException('Student not found');
    final student = Student.fromJson(studentDoc);
    _validateScope(student.collegeId, student.departmentId);

    // Resolve structural entities
    Department? department;
    if (student.departmentId.isNotEmpty) {
      final dDoc = await _firestoreService.getDocument('departments', student.departmentId);
      if (dDoc != null) department = Department.fromJson(dDoc);
    }

    Course? course;
    if (student.courseId.isNotEmpty) {
      final cDoc = await _firestoreService.getDocument('courses', student.courseId);
      if (cDoc != null) course = Course.fromJson(cDoc);
    }

    AcademicYear? academicYear;
    if (student.academicYearId.isNotEmpty) {
      final yDoc = await _firestoreService.getDocument('academicYears', student.academicYearId);
      if (yDoc != null) academicYear = AcademicYear.fromJson(yDoc);
    }

    Semester? semester;
    if (student.semesterId.isNotEmpty) {
      final sDoc = await _firestoreService.getDocument('semesters', student.semesterId);
      if (sDoc != null) semester = Semester.fromJson(sDoc);
    }

    Section? section;
    if (student.sectionId.isNotEmpty) {
      final secDoc = await _firestoreService.getDocument('sections', student.sectionId);
      if (secDoc != null) section = Section.fromJson(secDoc);
    }

    // Resolve faculty assignments for this section
    final assignmentDocs = await _firestoreService.queryCollection('facultyAssignments', {
      'collegeId': student.collegeId,
      'sectionId': student.sectionId,
      'isActive': true,
    });
    final assignments = assignmentDocs.map((d) => FacultyAssignment.fromJson(d)).toList();

    // Resolve unique faculty objects
    final facultyIds = assignments.map((a) => a.facultyId).toSet();
    final facultyList = <Faculty>[];
    for (final fId in facultyIds) {
      final fDoc = await _firestoreService.getDocument('faculty', fId);
      if (fDoc != null) facultyList.add(Faculty.fromJson(fDoc));
    }

    // Resolve enrolled subjects
    final subjectDocs = await _firestoreService.queryCollection('subjects', {
      'collegeId': student.collegeId,
      'semesterId': student.semesterId,
      'isActive': true,
    });
    final enrolledSubjects = subjectDocs.map((d) => Subject.fromJson(d)).toList();

    // Resolve notes count
    final notesDocs = await _firestoreService.queryCollection('notes', {
      'collegeId': student.collegeId,
      'sectionId': student.sectionId,
    });

    // Resolve certificates count
    final certDocs = await _firestoreService.queryCollection('certificates', {
      'studentId': student.id,
    });

    return StudentAcademicProfile(
      student: student,
      department: department,
      course: course,
      academicYear: academicYear,
      semester: semester,
      section: section,
      assignedFaculty: facultyList,
      enrolledSubjects: enrolledSubjects,
      overallAttendancePercentage: 88.5,
      notesCount: notesDocs.length,
      certificatesCount: certDocs.length,
    );
  }

  @override
  Future<void> assignHodToDepartment(String departmentId, String hodUserId) async {
    final deptDoc = await _firestoreService.getDocument('departments', departmentId);
    if (deptDoc == null) throw Exception('Department not found');
    final department = Department.fromJson(deptDoc);
    _validateScope(department.collegeId, department.id);

    if (_currentUser != null &&
        _currentUser.role != AppRole.superAdmin &&
        _currentUser.role != AppRole.collegeAdmin) {
      throw const BackendPermissionException('Only College Admin or Super Admin can assign HODs');
    }

    final updatedDept = department.copyWith(hodId: hodUserId);
    await _firestoreService.setDocument('departments', departmentId, updatedDept.toJson());

    // Update user profile department link and role if necessary
    if (hodUserId.isNotEmpty) {
      final userDoc = await _firestoreService.getDocument('users', hodUserId);
      if (userDoc != null) {
        final user = UserModel.fromJson(userDoc);
        if (user.collegeId != null && user.collegeId != department.collegeId) {
          throw const BackendPermissionException('Cannot assign HOD from a different college');
        }
        final updatedUser = user.copyWith(
          departmentId: departmentId,
          role: AppRole.hod,
        );
        await _firestoreService.setDocument('users', hodUserId, updatedUser.toJson());
      }
    }
  }

  // --- Faculty Assignments ---

  @override
  Future<List<FacultyAssignment>> getFacultyAssignments({
    String? facultyId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? subjectId,
    String? academicYearId,
  }) async {
    final filters = _getScopeFilters(hasCollegeId: true);
    if (facultyId != null && facultyId.isNotEmpty) filters['facultyId'] = facultyId;
    if (departmentId != null && departmentId.isNotEmpty) filters['departmentId'] = departmentId;
    if (courseId != null && courseId.isNotEmpty) filters['courseId'] = courseId;
    if (semesterId != null && semesterId.isNotEmpty) filters['semesterId'] = semesterId;
    if (sectionId != null && sectionId.isNotEmpty) filters['sectionId'] = sectionId;
    if (subjectId != null && subjectId.isNotEmpty) filters['subjectId'] = subjectId;
    if (academicYearId != null && academicYearId.isNotEmpty) filters['academicYearId'] = academicYearId;
    filters['isActive'] = true;

    final docs = await _firestoreService.queryCollection('facultyAssignments', filters);
    return docs.map((d) => FacultyAssignment.fromJson(d)).where((a) => a.isActive).toList();
  }

  @override
  Future<void> createFacultyAssignment(FacultyAssignment assignment) async {
    _validateScope(assignment.collegeId, assignment.departmentId);

    if (_currentUser != null) {
      if (_currentUser.role != AppRole.superAdmin &&
          _currentUser.role != AppRole.collegeAdmin &&
          _currentUser.role != AppRole.hod) {
        throw const BackendPermissionException('Only Super Admin, College Admin, or HOD can create faculty assignments');
      }

      if (_currentUser.role == AppRole.hod && _currentUser.departmentId != assignment.departmentId) {
        throw const BackendPermissionException('HOD can only create assignments within their own department');
      }
    }

    // Validate that faculty exists and belongs to same college & department
    final facDoc = await _firestoreService.getDocument('faculty', assignment.facultyId);
    if (facDoc == null) {
      // Fallback check user table
      final userDoc = await _firestoreService.getDocument('users', assignment.facultyId);
      if (userDoc == null) {
        throw const BackendValidationException('Faculty not found');
      }
      final user = UserModel.fromJson(userDoc);
      if (user.collegeId != assignment.collegeId) {
        throw const BackendPermissionException('Faculty does not belong to this college');
      }
      if (user.departmentId != null && user.departmentId!.isNotEmpty && user.departmentId != assignment.departmentId) {
        throw const BackendPermissionException('Faculty does not belong to the selected department');
      }
    } else {
      final faculty = Faculty.fromJson(facDoc);
      if (faculty.collegeId != assignment.collegeId) {
        throw const BackendPermissionException('Faculty does not belong to this college');
      }
      if (faculty.departmentId.isNotEmpty && assignment.departmentId.isNotEmpty && faculty.departmentId != assignment.departmentId) {
        throw const BackendPermissionException('Faculty does not belong to the selected department');
      }

      // Add subjectId & sectionId to faculty entity for rapid lookups
      final updatedSubs = Set<String>.from(faculty.subjectIds)..add(assignment.subjectId);
      final updatedSecs = Set<String>.from(faculty.sectionIds)..add(assignment.sectionId);
      final updatedFaculty = faculty.copyWith(
        subjectIds: updatedSubs.toList(),
        sectionIds: updatedSecs.toList(),
      );
      await _firestoreService.setDocument('faculty', faculty.id, updatedFaculty.toJson());
    }

    // Check for duplicate active assignment across all scope parameters
    final existingDocs = await _firestoreService.queryCollection('facultyAssignments', {
      'collegeId': assignment.collegeId,
      'departmentId': assignment.departmentId,
      'facultyId': assignment.facultyId,
      'subjectId': assignment.subjectId,
      'sectionId': assignment.sectionId,
      'semesterId': assignment.semesterId,
      'isActive': true,
    });

    final duplicate = existingDocs.any((d) =>
      d['courseId'] == assignment.courseId &&
      (assignment.academicYearId.isEmpty || d['academicYearId'] == assignment.academicYearId)
    );

    if (duplicate || existingDocs.isNotEmpty) {
      throw const BackendValidationException('An active assignment already exists for this faculty, subject, and section');
    }

    final enrichedAssignment = assignment.copyWith(
      createdAt: assignment.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      assignedBy: assignment.assignedBy ?? _currentUser?.id,
    );

    await _firestoreService.setDocument(
      'facultyAssignments',
      enrichedAssignment.id,
      enrichedAssignment.toJson(),
    );
  }

  @override
  Future<void> removeFacultyAssignment(String assignmentId) async {
    final doc = await _firestoreService.getDocument('facultyAssignments', assignmentId);
    if (doc != null) {
      final assignment = FacultyAssignment.fromJson(doc);
      _validateScope(assignment.collegeId, assignment.departmentId);

      if (_currentUser != null) {
        if (_currentUser.role != AppRole.superAdmin &&
            _currentUser.role != AppRole.collegeAdmin &&
            _currentUser.role != AppRole.hod) {
          throw const BackendPermissionException('Only Super Admin, College Admin, or HOD can remove faculty assignments');
        }

        if (_currentUser.role == AppRole.hod && _currentUser.departmentId != assignment.departmentId) {
          throw const BackendPermissionException('HOD can only remove assignments within their own department');
        }
      }

      final updated = assignment.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );
      await _firestoreService.setDocument('facultyAssignments', assignmentId, updated.toJson());
    }
  }

  @override
  Future<List<StudentAcademicHistory>> getStudentAcademicHistory(String studentId) async {
    final filters = <String, dynamic>{'studentUid': studentId};
    final docs = await _firestoreService.queryCollection('studentAcademicHistory', filters);
    final historyList = docs.map((d) => StudentAcademicHistory.fromJson(d)).toList();
    historyList.sort((a, b) => b.startDate.compareTo(a.startDate));
    return historyList;
  }

  @override
  Future<void> recordAcademicHistory(StudentAcademicHistory history) async {
    _validateScope(history.collegeId, history.departmentId);
    await _firestoreService.setDocument('studentAcademicHistory', history.id, history.toJson());
  }

  @override
  Future<List<Student>> getStudentsBySection(String sectionId) async {
    final filters = _getScopeFilters(hasCollegeId: true);
    filters['sectionId'] = sectionId;
    final docs = await _firestoreService.queryCollection('students', filters);
    return docs.map((d) => Student.fromJson(d)).where((s) => s.isActive).toList();
  }

  @override
  Future<List<Student>> getStudentsBySemester(String semesterId) async {
    final filters = _getScopeFilters(hasCollegeId: true);
    filters['semesterId'] = semesterId;
    final docs = await _firestoreService.queryCollection('students', filters);
    return docs.map((d) => Student.fromJson(d)).where((s) => s.isActive).toList();
  }

  @override
  Future<List<Student>> getStudentsByCourse(String courseId) async {
    final filters = _getScopeFilters(hasCollegeId: true);
    filters['courseId'] = courseId;
    final docs = await _firestoreService.queryCollection('students', filters);
    return docs.map((d) => Student.fromJson(d)).where((s) => s.isActive).toList();
  }

  @override
  Future<List<Student>> getStudentsByDepartment(String departmentId) async {
    final filters = _getScopeFilters(hasCollegeId: true);
    filters['departmentId'] = departmentId;
    final docs = await _firestoreService.queryCollection('students', filters);
    return docs.map((d) => Student.fromJson(d)).where((s) => s.isActive).toList();
  }

  @override
  Future<List<FacultyWorkloadSummary>> getFacultyWorkloadSummaries({String? departmentId}) async {
    final facultyList = await getFaculty(departmentId: departmentId);
    final subjects = await getSubjects();
    final sections = await getSections();
    final assignments = await getFacultyAssignments(departmentId: departmentId);

    final subjectsMap = {for (final s in subjects) s.id: s.name};
    final sectionsMap = {for (final s in sections) s.id: s.name};

    return facultyList.map((fac) {
      final activeAssignments = assignments.where((fa) => fa.facultyId == fac.id && fa.isActive).toList();
      final subjectNames = activeAssignments.map((fa) => subjectsMap[fa.subjectId] ?? fa.subjectId).toSet().toList();
      final sectionNames = activeAssignments.map((fa) => sectionsMap[fa.sectionId] ?? fa.sectionId).toSet().toList();

      return FacultyWorkloadSummary(
        facultyId: fac.id,
        facultyName: fac.name,
        employeeId: fac.employeeId,
        departmentId: fac.departmentId,
        subjectNames: subjectNames,
        sectionNames: sectionNames,
        subjectsAssigned: subjectNames.length,
        sectionsAssigned: sectionNames.length,
        weeklyClasses: activeAssignments.length * 4,
        hasAttendanceResponsibility: activeAssignments.isNotEmpty,
        status: fac.isActive ? 'active' : 'inactive',
        isActive: fac.isActive,
      );
    }).toList();
  }

  @override
  Future<Map<String, int>> getDepartmentStudentCounts() async {
    final students = await getStudents();
    final map = <String, int>{};
    for (final s in students) {
      if (s.departmentId.isNotEmpty && s.isActive) {
        map[s.departmentId] = (map[s.departmentId] ?? 0) + 1;
      }
    }
    return map;
  }

  @override
  Future<Map<String, int>> getDepartmentFacultyCounts() async {
    final faculty = await getFaculty();
    final map = <String, int>{};
    for (final f in faculty) {
      if (f.isActive && f.departmentId.isNotEmpty) {
        map[f.departmentId] = (map[f.departmentId] ?? 0) + 1;
      }
    }
    return map;
  }

  @override
  Future<void> updateFacultyAssignment(
    String assignmentId, {
    String? roomId,
    int? maxStudents,
    String? assignmentType,
    bool? isActive,
  }) async {
    final doc = await _firestoreService.getDocument('facultyAssignments', assignmentId);
    if (doc != null) {
      final updated = Map<String, dynamic>.from(doc);
      if (roomId != null) updated['roomId'] = roomId;
      if (maxStudents != null) updated['maxStudents'] = maxStudents;
      if (assignmentType != null) updated['assignmentType'] = assignmentType;
      if (isActive != null) updated['isActive'] = isActive;
      updated['updatedAt'] = DateTime.now().toIso8601String();
      await _firestoreService.setDocument('facultyAssignments', assignmentId, updated);
    }
  }

  @override
  Future<List<StudentEnrollment>> getEnrollments({
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    String? studentId,
    String? status,
  }) async {
    final docs = await _firestoreService.queryCollection('studentEnrollments', {
      if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
      if (studentId != null && studentId.isNotEmpty) 'studentId': studentId,
    });
    return docs.map((d) => StudentEnrollment.fromJson(d)).toList();
  }

  @override
  Future<void> updateEnrollment(String id, {String? sectionId, String? status}) async {
    final doc = await _firestoreService.getDocument('studentEnrollments', id);
    if (doc != null) {
      final updated = Map<String, dynamic>.from(doc);
      if (sectionId != null) updated['sectionId'] = sectionId;
      if (status != null) updated['status'] = status;
      updated['updatedAt'] = DateTime.now().toIso8601String();
      await _firestoreService.setDocument('studentEnrollments', id, updated);
    }
  }

  @override
  Future<void> deleteEnrollment(String id) async {
    await updateEnrollment(id, status: 'withdrawn');
  }
}
