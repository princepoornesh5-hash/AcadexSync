import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../core/firebase/firebase_exceptions.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/academic_models.dart';
import '../../domain/repositories/academic_repository.dart';

class MockAcademicRepository implements AcademicRepository {
  final UserModel? currentUser;
  final Duration latency;

  MockAcademicRepository({this.currentUser, this.latency = Duration.zero});

  // Mock Data Store
  final List<College> _colleges = [
    College(id: 'c1', name: 'Global Institute of Technology', code: 'GIT', address: '123 Tech Park', email: 'admin@git.edu', phone: '1234567890', principal: 'Dr. Smith'),
  ];

  final List<Department> _departments = [
    Department(id: 'd1', collegeId: 'c1', name: 'Computer Engineering', code: 'CS', hodId: 'f1', description: 'Computing & AI'),
    Department(id: 'd2', collegeId: 'c1', name: 'Mechanical Engineering', code: 'ME', hodId: 'f2', description: 'Thermal & Manufacturing'),
    Department(id: 'd3', collegeId: 'c1', name: 'Civil Engineering', code: 'CE', hodId: 'f3', description: 'Structural & Design'),
  ];

  final List<Course> _courses = [
    Course(id: 'cr1', collegeId: 'c1', departmentId: 'd1', name: 'B.Tech', code: 'BTECH-CS'),
    Course(id: 'cr2', collegeId: 'c1', departmentId: 'd1', name: 'M.Tech', code: 'MTECH-CS'),
    Course(id: 'cr3', collegeId: 'c1', departmentId: 'd2', name: 'B.Tech', code: 'BTECH-ME'),
  ];

  final List<AcademicYear> _academicYears = [
    AcademicYear(id: 'ay1', collegeId: 'c1', name: '2025-2026', startDate: DateTime(2025, 8, 1), endDate: DateTime(2026, 7, 31), status: 'completed', isCurrent: false),
    AcademicYear(id: 'ay2', collegeId: 'c1', name: '2026-2027', startDate: DateTime(2026, 8, 1), endDate: DateTime(2027, 7, 31), status: 'active', isCurrent: true),
  ];

  final List<Semester> _semesters = [
    Semester(id: 'sem1', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', academicYearId: 'ay1', name: 'Semester 1', number: 1, status: 'completed', isCurrent: false, startDate: DateTime(2025, 8, 1), endDate: DateTime(2025, 12, 31)),
    Semester(id: 'sem2', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', academicYearId: 'ay1', name: 'Semester 2', number: 2, status: 'completed', isCurrent: false, startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 6, 30)),
    Semester(id: 'sem3', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', academicYearId: 'ay2', name: 'Semester 3', number: 3, status: 'active', isCurrent: true, startDate: DateTime(2026, 8, 1), endDate: DateTime(2026, 12, 31)),
    Semester(id: 'sem_me1', collegeId: 'c1', departmentId: 'd2', courseId: 'cr3', academicYearId: 'ay1', name: 'ME Semester 1', number: 1, status: 'active', isCurrent: true, startDate: DateTime(2025, 8, 1), endDate: DateTime(2026, 6, 30)),
  ];

  final List<Section> _sections = [
    Section(id: 'sec1', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', academicYearId: 'ay1', semesterId: 'sem1', name: 'A', capacity: 60, status: 'active'),
    Section(id: 'sec2', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', academicYearId: 'ay1', semesterId: 'sem1', name: 'B', capacity: 60, status: 'active'),
    Section(id: 'sec3', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', academicYearId: 'ay1', semesterId: 'sem1', name: 'C', capacity: 60, status: 'active'),
    Section(id: 'sec_sem2_a', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', academicYearId: 'ay1', semesterId: 'sem2', name: 'A', capacity: 60, status: 'active'),
    Section(id: 'sec_sem2_b', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', academicYearId: 'ay1', semesterId: 'sem2', name: 'B', capacity: 60, status: 'active'),
    Section(id: 'sec_sem3_a', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', academicYearId: 'ay2', semesterId: 'sem3', name: 'A', capacity: 60, status: 'active'),
    Section(id: 'sec_me1', collegeId: 'c1', departmentId: 'd2', courseId: 'cr3', academicYearId: 'ay1', semesterId: 'sem_me1', name: 'A', capacity: 60, status: 'active'),
  ];

  final List<Subject> _subjects = [
    Subject(id: 'sub1', collegeId: 'c1', departmentId: 'd1', semesterId: 'sem1', name: 'Data Structures', code: 'CS101', credits: 4, type: 'Theory'),
    Subject(id: 'sub2', collegeId: 'c1', departmentId: 'd1', semesterId: 'sem1', name: 'Programming Lab', code: 'CS101L', credits: 2, type: 'Lab'),
    Subject(id: 'sub3', collegeId: 'c1', departmentId: 'd1', semesterId: 'sem1', name: 'Discrete Math', code: 'MA101', credits: 3, type: 'Theory'),
  ];

  final List<Faculty> _faculty = [
    Faculty(id: 'f1', collegeId: 'c1', departmentId: 'd1', name: 'Prof. Alan Turing', employeeId: 'EMP001', email: 'alan@git.edu', phone: '9876543210', subjectIds: ['sub1', 'sub3'], sectionIds: ['sec1']),
    Faculty(id: 'f2', collegeId: 'c1', departmentId: 'd2', name: 'Prof. Nikola Tesla', employeeId: 'EMP002', email: 'tesla@git.edu', phone: '9876543211'),
    Faculty(id: 'f3', collegeId: 'c1', departmentId: 'd3', name: 'Prof. Ada Lovelace', employeeId: 'EMP003', email: 'ada@git.edu', phone: '9876543212'),
  ];

  final List<Student> _students = [
    Student(id: 's1', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', semesterId: 'sem1', sectionId: 'sec1', name: 'John Doe', rollNumber: 'CS2025001', email: 'john@student.git.edu', phone: '5551234567'),
    Student(id: 's2', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', semesterId: 'sem1', sectionId: 'sec1', name: 'Jane Smith', rollNumber: 'CS2025002', email: 'jane@student.git.edu', phone: '5551234568'),
    Student(id: 's3', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', semesterId: 'sem1', sectionId: 'sec2', name: 'Alice Bob', rollNumber: 'CS2025003', email: 'alice@student.git.edu', phone: '5551234569'),
  ];

  final List<StudentAcademicHistory> _studentAcademicHistory = [
    StudentAcademicHistory(
      id: 'hist_s1_init',
      studentUid: 's1',
      collegeId: 'c1',
      departmentId: 'd1',
      courseId: 'cr1',
      academicYearId: 'ay1',
      semesterId: 'sem1',
      sectionId: 'sec1',
      startDate: DateTime(2025, 8, 1),
      status: 'active',
      createdAt: DateTime(2025, 8, 1),
    ),
    StudentAcademicHistory(
      id: 'hist_s2_init',
      studentUid: 's2',
      collegeId: 'c1',
      departmentId: 'd1',
      courseId: 'cr1',
      academicYearId: 'ay1',
      semesterId: 'sem1',
      sectionId: 'sec1',
      startDate: DateTime(2025, 8, 1),
      status: 'active',
      createdAt: DateTime(2025, 8, 1),
    ),
    StudentAcademicHistory(
      id: 'hist_s3_init',
      studentUid: 's3',
      collegeId: 'c1',
      departmentId: 'd1',
      courseId: 'cr1',
      academicYearId: 'ay1',
      semesterId: 'sem1',
      sectionId: 'sec2',
      startDate: DateTime(2025, 8, 1),
      status: 'active',
      createdAt: DateTime(2025, 8, 1),
    ),
  ];

  Future<void> _delay() async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
  }

  // --- Getters ---
  @override
  Future<List<College>> getColleges() async { await _delay(); return List.from(_colleges.where((e) => e.isActive)); }
  @override
  Future<List<Department>> getDepartments({String? collegeId, String? search, String? status}) async {
    await _delay();
    return List.from(_departments.where((e) => e.isActive));
  }

  @override
  Future<Department> getDepartmentById(String id) async {
    await _delay();
    return _departments.firstWhere((e) => e.id == id, orElse: () => throw Exception('Department not found'));
  }

  @override
  Future<Map<String, dynamic>> getDepartmentSummary(String id) async {
    await _delay();
    return {};
  }

  @override
  Future<Map<String, dynamic>?> getDepartmentHod(String departmentId) async {
    await _delay();
    return null;
  }

  @override
  Future<void> updateDepartmentStatus(String id, String status) async {
    await _delay();
    final idx = _departments.indexWhere((e) => e.id == id);
    if (idx != -1) _departments[idx] = _departments[idx].copyWith(isActive: status == 'active');
  }
  @override
  Future<List<Course>> getCourses({String? collegeId, String? departmentId, String? search}) async {
    await _delay();
    return List.from(_courses.where((e) => e.isActive));
  }

  @override
  Future<Course> getCourseById(String id) async {
    await _delay();
    return _courses.firstWhere((e) => e.id == id, orElse: () => throw Exception('Course not found'));
  }

  @override
  Future<void> updateCourseStatus(String id, bool isActive) async {
    await _delay();
    final idx = _courses.indexWhere((e) => e.id == id);
    if (idx != -1) _courses[idx] = _courses[idx].copyWith(isActive: isActive);
  }
  @override
  Future<List<AcademicYear>> getAcademicYears({String? collegeId}) async {
    await _delay();
    return List.from(_academicYears.where((e) => e.isActive));
  }

  @override
  Future<AcademicYear> getAcademicYearById(String id) async {
    await _delay();
    return _academicYears.firstWhere((e) => e.id == id, orElse: () => throw Exception('Academic Year not found'));
  }

  @override
  Future<void> setCurrentAcademicYear(String id) async {
    await _delay();
    for (int i = 0; i < _academicYears.length; i++) {
      if (_academicYears[i].id == id) {
        _academicYears[i] = _academicYears[i].copyWith(isCurrent: true);
      } else {
        _academicYears[i] = _academicYears[i].copyWith(isCurrent: false);
      }
    }
  }

  @override
  Future<void> updateAcademicYearStatus(String id, bool isActive) async {
    await _delay();
    final idx = _academicYears.indexWhere((e) => e.id == id);
    if (idx != -1) _academicYears[idx] = _academicYears[idx].copyWith(isActive: isActive);
  }
  @override
  Future<List<Semester>> getSemesters({String? courseId, String? academicYearId, String? collegeId}) async {
    await _delay();
    return List.from(_semesters.where((e) {
      if (!e.isActive) return false;
      if (courseId != null && e.courseId != courseId) return false;
      if (academicYearId != null && e.academicYearId != academicYearId) return false;
      return true;
    }));
  }

  @override
  Future<Semester> getSemesterById(String id) async {
    await _delay();
    return _semesters.firstWhere((e) => e.id == id, orElse: () => throw Exception('Semester not found'));
  }

  @override
  Future<void> updateSemesterStatus(String id, bool isActive) async {
    await _delay();
    final idx = _semesters.indexWhere((e) => e.id == id);
    if (idx != -1) _semesters[idx] = _semesters[idx].copyWith(isActive: isActive);
  }

  @override
  Future<void> toggleSemesterCurrent(String id, bool isCurrent) async {
    await _delay();
    final idx = _semesters.indexWhere((e) => e.id == id);
    if (idx != -1) _semesters[idx] = _semesters[idx].copyWith(isCurrent: isCurrent);
  }
  @override
  Future<List<Section>> getSections({String? semesterId, String? courseId, String? collegeId}) async {
    await _delay();
    return List.from(_sections.where((e) {
      if (!e.isActive) return false;
      if (semesterId != null && e.semesterId != semesterId) return false;
      if (courseId != null && e.courseId != courseId) return false;
      return true;
    }));
  }

  @override
  Future<Section> getSectionById(String id) async {
    await _delay();
    return _sections.firstWhere((e) => e.id == id, orElse: () => throw Exception('Section not found'));
  }

  @override
  Future<void> updateSectionStatus(String id, bool isActive) async {
    await _delay();
    final idx = _sections.indexWhere((e) => e.id == id);
    if (idx != -1) _sections[idx] = _sections[idx].copyWith(isActive: isActive);
  }

  @override
  Future<ProvisionHodResult> provisionHod({
    required String departmentId,
    required String name,
    required String instituteId,
    required String email,
    String? phone,
  }) async {
    await _delay();
    final user = UserModel(
      id: 'hod-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      instituteId: instituteId,
      email: email,
      phone: phone,
      role: AppRole.hod,
      departmentId: departmentId,
      accountStatus: AccountStatus.pendingActivation,
    );
    return ProvisionHodResult(
      activationCode: 'MOCK-HOD-1234',
      user: user,
      invitationId: 'inv-mock-1',
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
    );
  }

  @override
  Future<List<UserModel>> getHods({String? departmentId, String? search, String? status}) async {
    await _delay();
    return [];
  }

  @override
  Future<UserModel> getHodById(String id) async {
    await _delay();
    throw Exception('HOD not found');
  }

  @override
  Future<void> updateHodProfile(String id, {String? name, String? email, String? phone}) async {
    await _delay();
  }

  @override
  Future<void> transferHodDepartment(String id, String targetDepartmentId) async {
    await _delay();
  }

  @override
  Future<void> assignExistingUserToHod(String userId, String departmentId) async {
    await _delay();
  }

  @override
  Future<void> unassignHod(String id, {String? newRole}) async {
    await _delay();
  }

  @override
  Future<void> updateHodStatus(String id, String status, {String? reason}) async {
    await _delay();
  }

  @override
  Future<Map<String, dynamic>> getHodSummary(String id) async {
    await _delay();
    return {};
  }
  @override
  Future<List<Subject>> getSubjects({String? semesterId, String? courseId, String? collegeId}) async {
    await _delay();
    return List.from(_subjects.where((e) {
      if (!e.isActive) return false;
      if (semesterId != null && e.semesterId != semesterId) return false;
      if (courseId != null && e.courseId != courseId) return false;
      return true;
    }));
  }

  @override
  Future<Subject> getSubjectById(String id) async {
    await _delay();
    return _subjects.firstWhere((e) => e.id == id, orElse: () => throw Exception('Subject not found'));
  }

  @override
  Future<void> updateSubjectStatus(String id, bool isActive) async {
    await _delay();
    final idx = _subjects.indexWhere((e) => e.id == id);
    if (idx != -1) _subjects[idx] = _subjects[idx].copyWith(isActive: isActive);
  }
  @override
  Future<List<Faculty>> getFaculty({String? departmentId, String? search, String? status}) async { 
    await _delay(); 
    return List.from(_faculty.where((e) => e.isActive && (departmentId == null || e.departmentId == departmentId))); 
  }

  @override
  Future<Map<String, dynamic>> getFacultySummary(String id) async {
    await _delay();
    return {};
  }
  
  @override
  Future<PaginatedResponse<Faculty>> getPaginatedFaculty({String? departmentId, int limit = 20, DocumentSnapshot? startAfter}) async {
    final list = await getFaculty(departmentId: departmentId);
    final paginated = list.take(limit).toList();
    return PaginatedResponse(data: paginated, hasMore: list.length > limit, lastDocument: null);
  }

  @override
  Future<List<Student>> getStudents({String? sectionId, String? departmentId}) async { 
    await _delay(); 
    return List.from(_students.where((e) => e.isActive && (sectionId == null || e.sectionId == sectionId) && (departmentId == null || e.departmentId == departmentId))); 
  }

  @override
  Future<PaginatedResponse<Student>> getPaginatedStudents({String? sectionId, String? departmentId, int limit = 20, DocumentSnapshot? startAfter}) async {
    final list = await getStudents(sectionId: sectionId, departmentId: departmentId);
    final paginated = list.take(limit).toList();
    return PaginatedResponse(data: paginated, hasMore: list.length > limit, lastDocument: null);
  }

  @override
  Future<bool> checkStudentExists(String rollNumber, String email) async {
    await _delay();
    return _students.any((s) => s.rollNumber == rollNumber || s.email == email);
  }

  @override
  Future<bool> checkFacultyExists(String employeeId, String email) async {
    await _delay();
    return _faculty.any((f) => f.employeeId == employeeId || f.email == email);
  }

  // --- College Mutations (Super Admin only) ---
  @override
  Future<void> addCollege(College college) async {
    await _delay();
    if (currentUser != null && currentUser!.role != AppRole.superAdmin) {
      throw const BackendPermissionException("Only Super Admin can create colleges");
    }
    _colleges.add(college);
  }

  @override
  Future<void> updateCollege(College college) async {
    await _delay();
    if (currentUser != null && currentUser!.role != AppRole.superAdmin) {
      throw const BackendPermissionException("Only Super Admin can update colleges");
    }
    final idx = _colleges.indexWhere((e) => e.id == college.id);
    if (idx != -1) _colleges[idx] = college;
  }

  @override
  Future<void> deactivateCollege(String id) async {
    await _delay();
    if (currentUser != null && currentUser!.role != AppRole.superAdmin) {
      throw const BackendPermissionException("Only Super Admin can deactivate colleges");
    }
    final idx = _colleges.indexWhere((e) => e.id == id);
    if (idx != -1) _colleges[idx] = _colleges[idx].copyWith(isActive: false);
  }

  @override
  Future<void> deleteCollegePermanently(String id) async {
    await _delay();
    if (currentUser != null && currentUser!.role != AppRole.superAdmin) {
      throw const BackendPermissionException("Only Super Admin can permanently delete colleges");
    }
    _colleges.removeWhere((e) => e.id == id);
    _departments.removeWhere((e) => e.collegeId == id);
    _courses.removeWhere((e) => e.collegeId == id);
    _academicYears.removeWhere((e) => e.collegeId == id);
    _semesters.removeWhere((e) => e.collegeId == id);
    _sections.removeWhere((e) => e.collegeId == id);
    _subjects.removeWhere((e) => e.collegeId == id);
    _faculty.removeWhere((e) => e.collegeId == id);
    _students.removeWhere((e) => e.collegeId == id);
  }

  @override
  Future<College> getCollegeById(String id) async {
    await _delay();
    return _colleges.firstWhere((e) => e.id == id, orElse: () => throw Exception('College not found'));
  }

  @override
  Future<Map<String, dynamic>> getCollegeSummary(String id) async {
    await _delay();
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> getCollegeAdmins(String id) async {
    await _delay();
    return [];
  }

  @override
  Future<void> updateCollegeStatus(String id, String status) async {
    await _delay();
    final idx = _colleges.indexWhere((e) => e.id == id);
    if (idx != -1) _colleges[idx] = _colleges[idx].copyWith(isActive: status == 'active');
  }

  @override
  Future<ProvisionAdminResult> provisionCollegeAdmin(String collegeId, Map<String, dynamic> data) async {
    throw UnimplementedError('provisionCollegeAdmin not supported in mock repo');
  }

  // --- Department Mutations ---
  @override
  Future<void> addDepartment(Department department) async { await _delay(); _departments.add(department); }
  @override
  Future<void> updateDepartment(Department department) async {
    await _delay();
    final idx = _departments.indexWhere((e) => e.id == department.id);
    if (idx != -1) _departments[idx] = department;
  }
  @override
  Future<void> deactivateDepartment(String id) async {
    await _delay();
    final idx = _departments.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final dept = _departments[idx];
      _validateScope(dept.collegeId, dept.id);

      final hasActiveAssignments = _facultyAssignments.any((fa) => fa.departmentId == id && fa.isActive);
      if (hasActiveAssignments) {
        throw const BackendValidationException("Cannot deactivate department with active faculty assignments. Reassign or remove them first.");
      }

      final hasActiveStudents = _students.any((s) => s.departmentId == id);
      if (hasActiveStudents) {
        throw const BackendValidationException("Cannot deactivate department with enrolled students. Transfer them first.");
      }

      _departments[idx] = _departments[idx].copyWith(isActive: false);
    }
  }

  // --- Course Mutations ---
  @override
  Future<void> addCourse(Course course) async {
    await _delay();
    final dept = _departments.firstWhere((d) => d.id == course.departmentId, orElse: () => throw Exception("Invalid Department"));
    _validateScope(dept.collegeId, course.departmentId);
    _courses.add(course);
  }
  @override
  Future<void> updateCourse(Course course) async {
    await _delay();
    final dept = _departments.firstWhere((d) => d.id == course.departmentId, orElse: () => throw Exception("Invalid Department"));
    _validateScope(dept.collegeId, course.departmentId);
    final idx = _courses.indexWhere((e) => e.id == course.id);
    if (idx != -1) _courses[idx] = course;
  }
  @override
  Future<void> deactivateCourse(String id) async {
    await _delay();
    final idx = _courses.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final course = _courses[idx];
      final dept = _departments.firstWhere((d) => d.id == course.departmentId);
      _validateScope(dept.collegeId, course.departmentId);
      
      final activeSemesters = _semesters.where((s) => s.courseId == id && s.isActive).toList();
      if (activeSemesters.isNotEmpty) throw Exception("Cannot deactivate course with active semesters");

      _courses[idx] = course.copyWith(isActive: false);
    }
  }

  // --- Academic Year Mutations ---
  @override
  Future<void> addAcademicYear(AcademicYear academicYear) async {
    await _delay();
    _validateScope(academicYear.collegeId, null);
    if (!academicYear.endDate.isAfter(academicYear.startDate)) {
      throw const BackendValidationException("End date must be after start date");
    }

    // Single active year enforcement
    if (academicYear.isCurrent || academicYear.status == 'active') {
      for (var i = 0; i < _academicYears.length; i++) {
        if (_academicYears[i].collegeId == academicYear.collegeId && (_academicYears[i].isCurrent || _academicYears[i].status == 'active')) {
          _academicYears[i] = _academicYears[i].copyWith(status: 'completed', isCurrent: false, updatedAt: DateTime.now());
        }
      }
    }

    _academicYears.add(academicYear.copyWith(
      createdAt: academicYear.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> updateAcademicYear(AcademicYear academicYear) async {
    await _delay();
    _validateScope(academicYear.collegeId, null);
    if (!academicYear.endDate.isAfter(academicYear.startDate)) {
      throw const BackendValidationException("End date must be after start date");
    }

    if (academicYear.isCurrent || academicYear.status == 'active') {
      for (var i = 0; i < _academicYears.length; i++) {
        if (_academicYears[i].collegeId == academicYear.collegeId && _academicYears[i].id != academicYear.id && (_academicYears[i].isCurrent || _academicYears[i].status == 'active')) {
          _academicYears[i] = _academicYears[i].copyWith(status: 'completed', isCurrent: false, updatedAt: DateTime.now());
        }
      }
    }

    final idx = _academicYears.indexWhere((e) => e.id == academicYear.id);
    if (idx != -1) {
      _academicYears[idx] = academicYear.copyWith(updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> deactivateAcademicYear(String id) async {
    await _delay();
    final idx = _academicYears.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _validateScope(_academicYears[idx].collegeId, null);
      _academicYears[idx] = _academicYears[idx].copyWith(isActive: false, status: 'archived', isCurrent: false, updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> activateAcademicYear(String collegeId, String academicYearId) async {
    await _delay();
    _validateScope(collegeId, null);
    final targetIdx = _academicYears.indexWhere((y) => y.id == academicYearId && y.collegeId == collegeId);
    if (targetIdx == -1) throw const BackendValidationException("Academic year not found");

    for (var i = 0; i < _academicYears.length; i++) {
      if (_academicYears[i].collegeId == collegeId) {
        if (_academicYears[i].id == academicYearId) {
          _academicYears[i] = _academicYears[i].copyWith(
            status: 'active',
            isCurrent: true,
            isActive: true,
            updatedAt: DateTime.now(),
          );
        } else if (_academicYears[i].isCurrent || _academicYears[i].status == 'active') {
          _academicYears[i] = _academicYears[i].copyWith(
            status: 'completed',
            isCurrent: false,
            updatedAt: DateTime.now(),
          );
        }
      }
    }
  }

  // --- Semester Mutations ---
  @override
  Future<void> addSemester(Semester semester) async {
    await _delay();
    final course = _courses.firstWhere((c) => c.id == semester.courseId, orElse: () => throw const BackendValidationException("Invalid Course"));
    final dept = _departments.firstWhere((d) => d.id == course.departmentId);
    _validateScope(dept.collegeId, dept.id);

    if (semester.startDate != null && semester.endDate != null && !semester.endDate!.isAfter(semester.startDate!)) {
      throw const BackendValidationException("End date must be after start date");
    }

    // Prevent duplicate semester numbers inside college + course + academicYear
    final duplicate = _semesters.any((s) =>
        s.collegeId == dept.collegeId &&
        s.courseId == semester.courseId &&
        s.academicYearId == semester.academicYearId &&
        s.number == semester.number &&
        s.isActive);
    if (duplicate) {
      throw const BackendValidationException("Duplicate semester number inside same course and academic year");
    }

    // Single active semester per course & academic year
    if (semester.isCurrent || semester.status == 'active') {
      for (var i = 0; i < _semesters.length; i++) {
        if (_semesters[i].courseId == semester.courseId &&
            _semesters[i].academicYearId == semester.academicYearId &&
            (_semesters[i].isCurrent || _semesters[i].status == 'active')) {
          _semesters[i] = _semesters[i].copyWith(status: 'completed', isCurrent: false, updatedAt: DateTime.now());
        }
      }
    }

    _semesters.add(semester.copyWith(
      collegeId: dept.collegeId,
      departmentId: dept.id,
      createdAt: semester.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> updateSemester(Semester semester) async {
    await _delay();
    final course = _courses.firstWhere((c) => c.id == semester.courseId, orElse: () => throw const BackendValidationException("Invalid Course"));
    final dept = _departments.firstWhere((d) => d.id == course.departmentId);
    _validateScope(dept.collegeId, dept.id);

    final idx = _semesters.indexWhere((e) => e.id == semester.id);
    if (idx != -1) {
      if (semester.isCurrent || semester.status == 'active') {
        for (var i = 0; i < _semesters.length; i++) {
          if (_semesters[i].id != semester.id &&
              _semesters[i].courseId == semester.courseId &&
              _semesters[i].academicYearId == semester.academicYearId &&
              (_semesters[i].isCurrent || _semesters[i].status == 'active')) {
            _semesters[i] = _semesters[i].copyWith(status: 'completed', isCurrent: false, updatedAt: DateTime.now());
          }
        }
      }
      _semesters[idx] = semester.copyWith(updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> deactivateSemester(String id) async {
    await _delay();
    final idx = _semesters.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final sem = _semesters[idx];
      final course = _courses.firstWhere((c) => c.id == sem.courseId);
      final dept = _departments.firstWhere((d) => d.id == course.departmentId);
      _validateScope(dept.collegeId, dept.id);

      final activeSections = _sections.where((s) => s.semesterId == id && s.isActive).toList();
      if (activeSections.isNotEmpty) throw const BackendValidationException("Cannot deactivate semester with active sections");

      _semesters[idx] = sem.copyWith(isActive: false, status: 'archived', isCurrent: false, updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> activateSemester(String collegeId, String courseId, String semesterId) async {
    await _delay();
    final semIdx = _semesters.indexWhere((s) => s.id == semesterId);
    if (semIdx == -1) throw const BackendValidationException("Semester not found");
    final sem = _semesters[semIdx];
    _validateScope(collegeId, sem.departmentId);

    for (var i = 0; i < _semesters.length; i++) {
      if (_semesters[i].courseId == courseId && _semesters[i].academicYearId == sem.academicYearId) {
        if (_semesters[i].id == semesterId) {
          _semesters[i] = _semesters[i].copyWith(
            status: 'active',
            isCurrent: true,
            isActive: true,
            updatedAt: DateTime.now(),
          );
        } else if (_semesters[i].isCurrent || _semesters[i].status == 'active') {
          _semesters[i] = _semesters[i].copyWith(
            status: 'completed',
            isCurrent: false,
            updatedAt: DateTime.now(),
          );
        }
      }
    }
  }

  @override
  Future<void> completeSemester(String semesterId) async {
    await _delay();
    final semIdx = _semesters.indexWhere((s) => s.id == semesterId);
    if (semIdx == -1) throw const BackendValidationException("Semester not found");
    final sem = _semesters[semIdx];
    _validateScope(sem.collegeId, sem.departmentId);

    _semesters[semIdx] = sem.copyWith(
      status: 'completed',
      isCurrent: false,
      updatedAt: DateTime.now(),
    );
  }

  // --- Section Mutations & Capacity ---
  @override
  Future<void> addSection(Section section) async {
    await _delay();
    final sem = _semesters.firstWhere((s) => s.id == section.semesterId, orElse: () => throw const BackendValidationException("Invalid Semester"));
    final course = _courses.firstWhere((c) => c.id == sem.courseId);
    final dept = _departments.firstWhere((d) => d.id == course.departmentId);
    _validateScope(dept.collegeId, dept.id);

    if (section.capacity <= 0) {
      throw const BackendValidationException("Section capacity must be greater than 0");
    }

    _sections.add(section.copyWith(
      collegeId: dept.collegeId,
      departmentId: dept.id,
      courseId: course.id,
      academicYearId: sem.academicYearId,
      createdAt: section.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> updateSection(Section section) async {
    await _delay();
    final sem = _semesters.firstWhere((s) => s.id == section.semesterId, orElse: () => throw const BackendValidationException("Invalid Semester"));
    final course = _courses.firstWhere((c) => c.id == sem.courseId);
    final dept = _departments.firstWhere((d) => d.id == course.departmentId);
    _validateScope(dept.collegeId, dept.id);
    final idx = _sections.indexWhere((e) => e.id == section.id);
    if (idx != -1) _sections[idx] = section.copyWith(updatedAt: DateTime.now());
  }

  @override
  Future<void> updateSectionCapacity(String sectionId, int newCapacity) async {
    await _delay();
    if (newCapacity <= 0) {
      throw const BackendValidationException("Section capacity must be greater than 0");
    }
    final idx = _sections.indexWhere((e) => e.id == sectionId);
    if (idx == -1) throw const BackendValidationException("Section not found");
    final section = _sections[idx];
    _validateScope(section.collegeId, section.departmentId);

    _sections[idx] = section.copyWith(capacity: newCapacity, updatedAt: DateTime.now());
  }

  @override
  Future<SectionCapacityInfo> getSectionCapacityInfo(String sectionId) async {
    await _delay();
    final section = _sections.where((s) => s.id == sectionId).firstOrNull;
    if (section == null) throw const BackendValidationException("Section not found");
    final count = _students.where((s) => s.sectionId == sectionId && s.isActive).length;
    return SectionCapacityInfo(
      sectionId: section.id,
      sectionName: section.name,
      enrolledCount: count,
      capacity: section.capacity,
    );
  }

  @override
  Future<List<SectionTransferValidationResult>> validateBulkSectionTransfer(List<String> studentIds, String targetSectionId) async {
    await _delay();
    final targetSection = _sections.where((s) => s.id == targetSectionId).firstOrNull;
    if (targetSection == null) throw const BackendValidationException("Target section does not exist");

    final currentCount = _students.where((s) => s.sectionId == targetSectionId && s.isActive).length;
    final availableSeats = targetSection.capacity - currentCount;
    int eligibleAssigned = 0;
    final List<SectionTransferValidationResult> results = [];

    for (final id in studentIds) {
      final student = _students.where((s) => s.id == id).firstOrNull;
      if (student == null) {
        results.add(SectionTransferValidationResult(studentId: id, studentName: 'Unknown', rollNumber: 'N/A', canMove: false, reason: 'Student not found'));
        continue;
      }
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
    await _delay();
    final idx = _sections.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final section = _sections[idx];
      final sem = _semesters.firstWhere((s) => s.id == section.semesterId);
      final course = _courses.firstWhere((c) => c.id == sem.courseId);
      final dept = _departments.firstWhere((d) => d.id == course.departmentId);
      _validateScope(dept.collegeId, dept.id);

      final activeStudents = _students.where((s) => s.sectionId == id && s.isActive).toList();
      if (activeStudents.isNotEmpty) throw const BackendValidationException("Cannot deactivate section with active students");

      _sections[idx] = section.copyWith(isActive: false, status: 'archived', updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> addSubject(Subject subject) async {
    await _delay();
    final dept = _departments.firstWhere((d) => d.id == subject.departmentId, orElse: () => throw Exception("Invalid Department"));
    _semesters.firstWhere((s) => s.id == subject.semesterId, orElse: () => throw Exception("Invalid Semester"));
    _validateScope(dept.collegeId, dept.id);
    _subjects.add(subject);
  }
  @override
  Future<void> updateSubject(Subject subject) async {
    await _delay();
    final dept = _departments.firstWhere((d) => d.id == subject.departmentId, orElse: () => throw Exception("Invalid Department"));
    _semesters.firstWhere((s) => s.id == subject.semesterId, orElse: () => throw Exception("Invalid Semester"));
    _validateScope(dept.collegeId, dept.id);
    final idx = _subjects.indexWhere((e) => e.id == subject.id);
    if (idx != -1) _subjects[idx] = subject;
  }
  @override
  Future<void> deactivateSubject(String id) async {
    await _delay();
    final idx = _subjects.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final subject = _subjects[idx];
      final dept = _departments.firstWhere((d) => d.id == subject.departmentId);
      _validateScope(dept.collegeId, dept.id);
      _subjects[idx] = subject.copyWith(isActive: false);
    }
  }

  // --- Faculty Mutations ---
  @override
  Future<void> addFaculty(Faculty faculty) async {
    await _delay();
    final dept = _departments.firstWhere((d) => d.id == faculty.departmentId, orElse: () => throw Exception("Invalid Department"));
    _validateScope(dept.collegeId, dept.id);
    _faculty.add(faculty);
  }

  @override
  Future<ProvisionFacultyResult> provisionFaculty(ProvisionFacultyRequest request) async {
    await _delay();
    final dept = _departments.firstWhere((d) => d.id == request.departmentId, orElse: () => throw Exception("Invalid Department"));
    _validateScope(dept.collegeId, dept.id);
    final id = 'f_${_faculty.length + 1}';
    final faculty = Faculty(
      id: id,
      collegeId: dept.collegeId,
      departmentId: dept.id,
      name: request.name,
      employeeId: request.employeeId ?? 'EMP-$id',
      instituteId: request.instituteId,
      email: request.email,
      phone: request.phone ?? '',
      designation: request.designation,
      qualification: request.qualification,
      specialization: request.specialization,
      joiningDate: request.joiningDate != null ? DateTime.tryParse(request.joiningDate!) : DateTime.now(),
      isActive: true,
      accountStatus: AccountStatus.active,
    );
    _faculty.add(faculty);
    final user = UserModel(
      id: 'u_$id',
      name: request.name,
      email: request.email,
      role: AppRole.faculty,
      collegeId: dept.collegeId,
      departmentId: dept.id,
    );
    return ProvisionFacultyResult(
      user: user,
      faculty: faculty,
      invitation: InvitationInfo(
        id: 'inv_$id',
        status: 'pending',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      ),
      activationCode: '123456',
    );
  }
  @override
  Future<void> updateFaculty(Faculty faculty) async {
    await _delay();
    final dept = _departments.firstWhere((d) => d.id == faculty.departmentId, orElse: () => throw Exception("Invalid Department"));
    _validateScope(dept.collegeId, dept.id);
    final idx = _faculty.indexWhere((f) => f.id == faculty.id);
    if (idx != -1) {
      final oldDeptId = _faculty[idx].departmentId;
      if (oldDeptId.isNotEmpty && oldDeptId != faculty.departmentId) {
        // Invalidate old department assignments
        for (int i = 0; i < _facultyAssignments.length; i++) {
          if (_facultyAssignments[i].facultyId == faculty.id && _facultyAssignments[i].departmentId == oldDeptId && _facultyAssignments[i].isActive) {
            _facultyAssignments[i] = _facultyAssignments[i].copyWith(isActive: false, updatedAt: DateTime.now());
          }
        }
        _faculty[idx] = faculty.copyWith(subjectIds: [], sectionIds: []);
      } else {
        _faculty[idx] = faculty;
      }
    }
  }

  @override
  Future<void> transferFacultyDepartment(String facultyId, String newDepartmentId) async {
    await _delay();
    final facIdx = _faculty.indexWhere((f) => f.id == facultyId);
    if (facIdx == -1) throw Exception("Faculty not found");
    final fac = _faculty[facIdx];
    final targetDept = _departments.firstWhere((d) => d.id == newDepartmentId, orElse: () => throw Exception("Target Department not found"));
    
    _validateScope(fac.collegeId);
    if (fac.collegeId != targetDept.collegeId) {
      throw const BackendPermissionException("Cannot transfer faculty to a different college");
    }

    final oldDeptId = fac.departmentId;
    if (oldDeptId != newDepartmentId) {
      // Invalidate old department assignments
      for (int i = 0; i < _facultyAssignments.length; i++) {
        if (_facultyAssignments[i].facultyId == facultyId && _facultyAssignments[i].departmentId == oldDeptId && _facultyAssignments[i].isActive) {
          _facultyAssignments[i] = _facultyAssignments[i].copyWith(isActive: false, updatedAt: DateTime.now());
        }
      }
      _faculty[facIdx] = fac.copyWith(
        departmentId: newDepartmentId,
        subjectIds: [],
        sectionIds: [],
      );
    }
  }

  @override
  Future<void> deactivateFaculty(String id) async {
    await _delay();
    final idx = _faculty.indexWhere((f) => f.id == id);
    if (idx != -1) {
      final faculty = _faculty[idx];
      final dept = _departments.firstWhere((d) => d.id == faculty.departmentId);
      _validateScope(dept.collegeId, dept.id);
      _faculty[idx] = faculty.copyWith(isActive: false, accountStatus: AccountStatus.deactivated);
      for (int i = 0; i < _facultyAssignments.length; i++) {
        if (_facultyAssignments[i].facultyId == id && _facultyAssignments[i].isActive) {
          _facultyAssignments[i] = _facultyAssignments[i].copyWith(isActive: false, updatedAt: DateTime.now());
        }
      }
    }
  }
  @override
  Future<void> bulkAssignSubjectsToFaculty(String facultyId, List<String> subjectIds, List<String> sectionIds) async {
    await _delay();
    final index = _faculty.indexWhere((f) => f.id == facultyId);
    if (index != -1) {
      _faculty[index] = _faculty[index].copyWith(
        subjectIds: subjectIds,
        sectionIds: sectionIds,
      );
    }
  }

  // --- Student Mutations ---
  @override
  Future<void> addStudent(Student student) async {
    await _delay();
    
    // Deep validation for student assignments
    final dept = _departments.firstWhere((d) => d.id == student.departmentId, orElse: () => throw Exception("Invalid Department"));
    if (dept.collegeId != student.collegeId) throw Exception("Department does not belong to College");
    
    final course = _courses.firstWhere((c) => c.id == student.courseId, orElse: () => throw Exception("Invalid Course"));
    if (course.departmentId != student.departmentId) throw Exception("Course does not belong to Department");
    
    final sem = _semesters.firstWhere((s) => s.id == student.semesterId, orElse: () => throw Exception("Invalid Semester"));
    if (sem.courseId != student.courseId) throw Exception("Semester does not belong to Course");
    
    final sec = _sections.firstWhere((s) => s.id == student.sectionId, orElse: () => throw Exception("Invalid Section"));
    if (sec.semesterId != student.semesterId) throw Exception("Section does not belong to Semester");

    _validateScope(student.collegeId, student.departmentId);
    _students.add(student);
  }

  @override
  Future<ProvisionStudentResult> provisionStudent(ProvisionStudentRequest request) async {
    await _delay();
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
    _students.add(student);
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
      activationCode: 'MOCK-STU1-CODE',
    );
  }

  @override
  Future<void> transferStudentDepartment(String studentId, String newDepartmentId) async {
    await _delay();
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      _students[index] = _students[index].copyWith(departmentId: newDepartmentId);
    }
  }

  @override
  Future<Map<String, dynamic>> getStudentSummary(String studentId) async {
    await _delay();
    return {
      'enrollmentCount': 1,
    };
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
    await _delay();
    final index = _students.indexWhere((s) => s.id == studentId);
    final student = index != -1 ? _students[index] : null;
    if (student == null || !student.isActive || student.accountStatus == AccountStatus.deactivated) {
      throw const BackendValidationException('Student not found or inactive');
    }
    final isAlreadyEnrolled = _enrollments.any((e) =>
        e.studentId == studentId &&
        e.sectionId == sectionId &&
        e.status == 'active');
    if (isAlreadyEnrolled) {
      throw const BackendValidationException('Student is already enrolled in this section.');
    }
    _students[index] = _students[index].copyWith(
      courseId: courseId,
      academicYearId: academicYearId,
      semesterId: semesterId,
      sectionId: sectionId,
    );
    _enrollments.removeWhere((e) => e.studentId == studentId && e.semesterId == semesterId && e.status == 'active');
    _enrollments.add(StudentEnrollment(
      id: 'enr-${_enrollments.length + 1}',
      collegeId: student.collegeId,
      departmentId: student.departmentId,
      courseId: courseId,
      academicYearId: academicYearId,
      semesterId: semesterId,
      sectionId: sectionId,
      studentId: studentId,
      status: 'active',
      enrollmentDate: enrollmentDate != null ? DateTime.tryParse(enrollmentDate) ?? DateTime.now() : DateTime.now(),
      student: {'id': student.id, 'name': student.name, 'rollNumber': student.rollNumber, 'email': student.email},
    ));
  }
  @override
  Future<void> updateStudent(Student student) async {
    await _delay();
    
    final dept = _departments.firstWhere((d) => d.id == student.departmentId, orElse: () => throw Exception("Invalid Department"));
    if (dept.collegeId != student.collegeId) throw Exception("Department does not belong to College");
    
    final course = _courses.firstWhere((c) => c.id == student.courseId, orElse: () => throw Exception("Invalid Course"));
    if (course.departmentId != student.departmentId) throw Exception("Course does not belong to Department");
    
    final sem = _semesters.firstWhere((s) => s.id == student.semesterId, orElse: () => throw Exception("Invalid Semester"));
    if (sem.courseId != student.courseId) throw Exception("Semester does not belong to Course");
    
    final sec = _sections.firstWhere((s) => s.id == student.sectionId, orElse: () => throw Exception("Invalid Section"));
    if (sec.semesterId != student.semesterId) throw Exception("Section does not belong to Semester");

    _validateScope(student.collegeId, student.departmentId);
    
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index != -1) _students[index] = student;
  }
  @override
  Future<void> deactivateStudent(String id) async {
    await _delay();
    final index = _students.indexWhere((s) => s.id == id);
    if (index != -1) {
      final student = _students[index];
      _validateScope(student.collegeId, student.departmentId);
      _students[index] = student.copyWith(
        isActive: false,
        accountStatus: AccountStatus.deactivated,
      );
    }
  }

  @override
  Future<void> bulkPromoteStudents(List<String> studentIds, String newSemesterId, String newSectionId) async {
    await promoteStudents(
      studentIds: studentIds,
      targetAcademicYearId: 'ay1',
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
    await _delay();
    final crs = _courses.where((c) => c.id == courseId).firstOrNull;
    final code = crs?.code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase() ?? 'STU';
    final year = DateTime.now().year;
    final prefix = '$code-$year-';
    final matching = _students.where((s) => s.rollNumber.startsWith(prefix)).length;
    final nextSeq = (matching + 1).toString().padLeft(3, '0');
    return '$prefix$nextSeq';
  }

  @override
  Future<void> admitStudent(Student student) async {
    await _delay();
    _validateScope(student.collegeId, student.departmentId);

    // Validate duplicate roll number
    if (_students.any((s) => s.rollNumber == student.rollNumber && s.id != student.id)) {
      throw const BackendValidationException('Roll number already exists');
    }

    // Validate section consistency & capacity
    final sec = _sections.where((s) => s.id == student.sectionId).firstOrNull;
    if (sec != null) {
      if (student.collegeId.isNotEmpty && sec.collegeId.isNotEmpty && student.collegeId != sec.collegeId) {
        throw const BackendValidationException('Student college does not match section college');
      }
      if (student.departmentId.isNotEmpty && sec.departmentId.isNotEmpty && student.departmentId != sec.departmentId) {
        throw const BackendValidationException('Student department does not match section department');
      }
      if (student.semesterId.isNotEmpty && sec.semesterId.isNotEmpty && student.semesterId != sec.semesterId) {
        throw const BackendValidationException('Student semester does not match section semester');
      }
      final currentEnrolled = _students.where((s) => s.sectionId == student.sectionId && s.isActive && s.id != student.id).length;
      if (currentEnrolled >= sec.capacity) {
        throw BackendValidationException('Section ${sec.name} is full (Capacity: ${sec.capacity})');
      }
    }

    final initialTimeline = AcademicTimelineRecord(
      id: 'hist_${DateTime.now().millisecondsSinceEpoch}_${student.id}',
      academicYearId: student.academicYearId,
      semesterId: student.semesterId,
      sectionId: student.sectionId,
      departmentId: student.departmentId,
      courseId: student.courseId,
      status: 'Admitted',
      termStartDate: student.admissionDate ?? DateTime.now(),
      remarks: 'Student admitted to section ${student.sectionId}',
    );

    final enriched = student.copyWith(
      admissionDate: student.admissionDate ?? DateTime.now(),
      lifecycleState: student.lifecycleState == StudentLifecycleState.applicant
          ? StudentLifecycleState.admitted
          : student.lifecycleState,
      isActive: true,
      history: student.history.isNotEmpty ? student.history : [initialTimeline],
    );

    final idx = _students.indexWhere((s) => s.id == enriched.id);
    if (idx != -1) {
      _students[idx] = enriched;
    } else {
      _students.add(enriched);
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
    await _delay();
    final sem = _semesters.where((s) => s.id == targetSemesterId).firstOrNull;
    final sec = _sections.where((s) => s.id == targetSectionId).firstOrNull;

    if (sem == null) throw const BackendValidationException('Target semester does not exist');
    if (sec == null) throw const BackendValidationException('Target section does not exist');

    for (var id in studentIds) {
      final index = _students.indexWhere((s) => s.id == id);
      if (index == -1) throw const BackendValidationException('Student not found');

      final current = _students[index];
      _validateScope(current.collegeId, current.departmentId);

      // Prevent cross-department promotion
      if (sem.departmentId.isNotEmpty && current.departmentId.isNotEmpty && sem.departmentId != current.departmentId) {
        throw const BackendValidationException('Cross-department promotion is strictly prohibited');
      }

      // Prevent cross-department section assignment
      if (sec.departmentId.isNotEmpty && current.departmentId.isNotEmpty && sec.departmentId != current.departmentId) {
        throw const BackendValidationException('Cross-department section assignment is strictly prohibited');
      }

      // Prevent cross-course promotion
      if (sem.courseId.isNotEmpty && current.courseId.isNotEmpty && sem.courseId != current.courseId) {
        throw const BackendValidationException('Cross-course promotion is not allowed. Use department transfer instead');
      }

        final timeline = AcademicTimelineRecord(
          id: 'hist_${DateTime.now().millisecondsSinceEpoch}_$id',
          academicYearId: current.academicYearId,
          semesterId: current.semesterId,
          sectionId: current.sectionId,
          departmentId: current.departmentId,
          courseId: current.courseId,
          status: 'Promoted',
          termEndDate: DateTime.now(),
          remarks: 'Promoted to ${sem.name} (Section ${sec.name})',
        );

        final newHistory = List<AcademicTimelineRecord>.from(current.history)..add(timeline);

        // Update StudentAcademicHistory collection records
        final prevHistIdx = _studentAcademicHistory.indexWhere((h) =>
            h.studentUid == id &&
            h.semesterId == current.semesterId &&
            h.sectionId == current.sectionId &&
            h.status == 'active');
        if (prevHistIdx != -1) {
          _studentAcademicHistory[prevHistIdx] = _studentAcademicHistory[prevHistIdx].copyWith(
            endDate: DateTime.now(),
            status: 'promoted',
          );
        } else {
          _studentAcademicHistory.add(StudentAcademicHistory(
            id: 'hist_${DateTime.now().millisecondsSinceEpoch}_${id}_prev',
            studentUid: id,
            collegeId: current.collegeId,
            departmentId: current.departmentId,
            courseId: current.courseId,
            academicYearId: current.academicYearId,
            semesterId: current.semesterId,
            sectionId: current.sectionId,
            startDate: DateTime.now().subtract(const Duration(days: 120)),
            endDate: DateTime.now(),
            status: 'promoted',
            createdAt: DateTime.now(),
          ));
        }

        // New active placement history
        _studentAcademicHistory.add(StudentAcademicHistory(
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
        ));

        _students[index] = current.copyWith(
          academicYearId: targetAcademicYearId,
          semesterId: targetSemesterId,
          sectionId: targetSectionId,
          lifecycleState: StudentLifecycleState.active,
          isActive: true,
          history: newHistory,
        );
      }
  }

  @override
  Future<void> transferStudentsSection({
    required List<String> studentIds,
    required String targetSectionId,
  }) async {
    await _delay();
    final sec = _sections.where((s) => s.id == targetSectionId).firstOrNull;

    for (var id in studentIds) {
      final index = _students.indexWhere((s) => s.id == id);
      if (index != -1) {
        final current = _students[index];
        _validateScope(current.collegeId, current.departmentId);

        final timeline = AcademicTimelineRecord(
          id: 'hist_${DateTime.now().millisecondsSinceEpoch}_$id',
          academicYearId: current.academicYearId,
          semesterId: current.semesterId,
          sectionId: current.sectionId,
          departmentId: current.departmentId,
          courseId: current.courseId,
          status: 'Transferred',
          termEndDate: DateTime.now(),
          remarks: 'Transferred to Section ${sec?.name ?? targetSectionId}',
        );

        final newHistory = List<AcademicTimelineRecord>.from(current.history)..add(timeline);

        _students[index] = current.copyWith(
          sectionId: targetSectionId,
          history: newHistory,
        );
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
    await _delay();
    for (var id in studentIds) {
      final index = _students.indexWhere((s) => s.id == id);
      if (index != -1) {
        final current = _students[index];
        _validateScope(current.collegeId, current.departmentId);

        final timeline = AcademicTimelineRecord(
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

        final newHistory = List<AcademicTimelineRecord>.from(current.history)..add(timeline);

        _students[index] = current.copyWith(
          departmentId: targetDepartmentId,
          courseId: targetCourseId,
          semesterId: targetSemesterId,
          sectionId: targetSectionId,
          history: newHistory,
        );
      }
    }
  }

  @override
  Future<void> updateStudentLifecycleState({
    required String studentId,
    required StudentLifecycleState newState,
    String? remarks,
  }) async {
    await _delay();
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index == -1) throw const BackendValidationException('Student not found');
    final current = _students[index];
    _validateScope(current.collegeId, current.departmentId);

    if (!current.lifecycleState.isValidTransition(newState)) {
      throw BackendValidationException('Invalid state transition from ${current.lifecycleState.displayName} to ${newState.displayName}');
    }

    final isGraduatedOrAlumni = newState == StudentLifecycleState.graduated || newState == StudentLifecycleState.alumni;

    final timeline = AcademicTimelineRecord(
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

    final newHistory = List<AcademicTimelineRecord>.from(current.history)..add(timeline);

    _students[index] = current.copyWith(
      lifecycleState: newState,
      isActive: !isGraduatedOrAlumni,
      graduationDate: isGraduatedOrAlumni ? (current.graduationDate ?? DateTime.now()) : current.graduationDate,
      history: newHistory,
    );
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
    await _delay();
    final student = _students.where((s) => s.id == studentId).firstOrNull;
    if (student == null) throw const BackendValidationException('Student not found');

    final dept = _departments.where((d) => d.id == student.departmentId).firstOrNull;
    final crs = _courses.where((c) => c.id == student.courseId).firstOrNull;
    final yr = _academicYears.where((y) => y.id == student.academicYearId).firstOrNull;
    final sem = _semesters.where((s) => s.id == student.semesterId).firstOrNull;
    final sec = _sections.where((s) => s.id == student.sectionId).firstOrNull;

    final assignments = _facultyAssignments.where((a) => a.sectionId == student.sectionId && a.isActive).toList();
    final facultyIds = assignments.map((a) => a.facultyId).toSet();
    final facultyList = _faculty.where((f) => facultyIds.contains(f.id)).toList();

    final enrolledSubjects = _subjects.where((s) => s.semesterId == student.semesterId && s.isActive).toList();

    return StudentAcademicProfile(
      student: student,
      department: dept,
      course: crs,
      academicYear: yr,
      semester: sem,
      section: sec,
      assignedFaculty: facultyList,
      enrolledSubjects: enrolledSubjects,
      overallAttendancePercentage: 91.2,
      notesCount: 14,
      certificatesCount: 2,
    );
  }

  final List<FacultyAssignment> _facultyAssignments = [
    FacultyAssignment(
      id: 'fa1',
      collegeId: 'c1',
      departmentId: 'd1',
      facultyId: 'f1',
      facultyName: 'Prof. Alan Turing',
      courseId: 'cr1',
      semesterId: 'sem1',
      sectionId: 'sec1',
      subjectId: 'sub1',
      academicYearId: 'ay1',
      isActive: true,
      assignedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  @override
  Future<void> assignHodToDepartment(String departmentId, String hodUserId) async {
    await _delay();
    final index = _departments.indexWhere((d) => d.id == departmentId);
    if (index == -1) throw Exception("Department not found");
    final dept = _departments[index];
    _validateScope(dept.collegeId, dept.id);

    if (currentUser != null &&
        currentUser!.role != AppRole.superAdmin &&
        currentUser!.role != AppRole.collegeAdmin) {
      throw const BackendPermissionException('Only College Admin or Super Admin can assign HODs');
    }

    if (hodUserId.isNotEmpty) {
      final fac = _faculty.where((f) => f.id == hodUserId).firstOrNull;
      if (fac != null && fac.collegeId != dept.collegeId) {
        throw const BackendPermissionException('Cannot assign HOD from a different college');
      }
    }

    _departments[index] = dept.copyWith(hodId: hodUserId);
  }

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
    await _delay();
    return _facultyAssignments.where((fa) {
      if (!fa.isActive) return false;
      if (facultyId != null && facultyId.isNotEmpty && fa.facultyId != facultyId) return false;
      if (departmentId != null && departmentId.isNotEmpty && fa.departmentId != departmentId) return false;
      if (courseId != null && courseId.isNotEmpty && fa.courseId != courseId) return false;
      if (semesterId != null && semesterId.isNotEmpty && fa.semesterId != semesterId) return false;
      if (sectionId != null && sectionId.isNotEmpty && fa.sectionId != sectionId) return false;
      if (subjectId != null && subjectId.isNotEmpty && fa.subjectId != subjectId) return false;
      if (academicYearId != null && academicYearId.isNotEmpty && fa.academicYearId != academicYearId) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> createFacultyAssignment(FacultyAssignment assignment) async {
    await _delay();
    // 1. Validate faculty exists, is active, and matches college & department
    final fac = _faculty.where((f) => f.id == assignment.facultyId).firstOrNull;
    if (fac == null || !fac.isActive) {
      throw const BackendValidationException('Faculty not found or inactive');
    }
    if (fac.collegeId != assignment.collegeId) {
      throw const BackendPermissionException('Faculty does not belong to this college');
    }
    if (fac.departmentId.isNotEmpty && assignment.departmentId.isNotEmpty && fac.departmentId != assignment.departmentId) {
      throw const BackendPermissionException('Faculty does not belong to the selected department');
    }

    // 2. Validate subject belongs to department and semester
    final subj = _subjects.where((s) => s.id == assignment.subjectId).firstOrNull;
    if (subj != null) {
      if (subj.collegeId.isNotEmpty && subj.collegeId != assignment.collegeId) {
        throw const BackendPermissionException('Subject does not belong to this college');
      }
      if (subj.departmentId.isNotEmpty && subj.departmentId != assignment.departmentId) {
        throw const BackendPermissionException('Subject does not belong to this department');
      }
      if (subj.semesterId.isNotEmpty && subj.semesterId != assignment.semesterId) {
        throw const BackendValidationException('Subject does not match the assignment semester');
      }
    }

    // 3. Validate section belongs to semester
    final sec = _sections.where((s) => s.id == assignment.sectionId).firstOrNull;
    if (sec != null) {
      if (sec.collegeId.isNotEmpty && sec.collegeId != assignment.collegeId) {
        throw const BackendPermissionException('Section does not belong to this college');
      }
      if (sec.semesterId.isNotEmpty && sec.semesterId != assignment.semesterId) {
        throw const BackendValidationException('Section does not match the assignment semester');
      }
    }

    // 4. Validate academic year
    final ay = _academicYears.where((a) => a.id == assignment.academicYearId).firstOrNull;
    if (ay != null) {
      if (ay.collegeId != assignment.collegeId) {
        throw const BackendPermissionException('Academic year does not belong to this college');
      }
      if (ay.status == 'archived') {
        throw const BackendValidationException('Cannot assign to an archived academic year');
      }
    }

    // 5. Check duplicate active assignment
    final existingIdx = _facultyAssignments.indexWhere((fa) =>
      fa.facultyId == assignment.facultyId &&
      fa.subjectId == assignment.subjectId &&
      fa.sectionId == assignment.sectionId &&
      fa.semesterId == assignment.semesterId &&
      fa.academicYearId == assignment.academicYearId &&
      fa.isActive);
    if (existingIdx != -1) {
      throw const BackendValidationException('An active assignment already exists for this faculty, subject, section, and semester');
    }

    final enrichedAssignment = assignment.copyWith(
      createdAt: assignment.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _facultyAssignments.add(enrichedAssignment);

    // Also sync subjectIds / sectionIds on the Faculty entity for fast lookups
    final facIdx = _faculty.indexOf(fac);
    final newSubs = Set<String>.from(fac.subjectIds)..add(assignment.subjectId);
    final newSecs = Set<String>.from(fac.sectionIds)..add(assignment.sectionId);
    _faculty[facIdx] = fac.copyWith(subjectIds: newSubs.toList(), sectionIds: newSecs.toList());
  }

  @override
  Future<void> removeFacultyAssignment(String assignmentId) async {
    await _delay();
    final index = _facultyAssignments.indexWhere((fa) => fa.id == assignmentId);
    if (index != -1) {
      _facultyAssignments[index] = _facultyAssignments[index].copyWith(isActive: false);
    }
  }

  void _validateScope(String? collegeId, [String? departmentId]) {
    if (collegeId == null) throw Exception("College ID is required");
    if (currentUser != null) {
      if (currentUser!.role == AppRole.superAdmin) return;
      if (currentUser!.collegeId != null && currentUser!.collegeId != collegeId) {
        throw const BackendPermissionException("Access denied to college");
      }
      if (currentUser!.role == AppRole.hod && departmentId != null && currentUser!.departmentId != departmentId) {
        throw const BackendPermissionException("Access denied to department");
      }
      if (currentUser!.role == AppRole.student) {
        throw const BackendPermissionException("Students cannot perform academic modifications");
      }
    }
  }

  @override
  Future<Faculty?> getFacultyById(String id) async {
    await _delay();
    try {
      return _faculty.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Student?> getStudentById(String id) async {
    await _delay();
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<StudentAcademicHistory>> getStudentAcademicHistory(String studentId) async {
    await _delay();
    return List.from(_studentAcademicHistory.where((h) => h.studentUid == studentId));
  }

  @override
  Future<void> recordAcademicHistory(StudentAcademicHistory history) async {
    await _delay();
    _studentAcademicHistory.add(history);
  }

  @override
  Future<List<Student>> getStudentsBySection(String sectionId) async {
    await _delay();
    return List.from(_students.where((s) => s.sectionId == sectionId && s.isActive));
  }

  @override
  Future<List<Student>> getStudentsBySemester(String semesterId) async {
    await _delay();
    return List.from(_students.where((s) => s.semesterId == semesterId && s.isActive));
  }

  @override
  Future<List<Student>> getStudentsByCourse(String courseId) async {
    await _delay();
    return List.from(_students.where((s) => s.courseId == courseId && s.isActive));
  }

  @override
  Future<List<Student>> getStudentsByDepartment(String departmentId) async {
    await _delay();
    return List.from(_students.where((s) => s.departmentId == departmentId && s.isActive));
  }

  @override
  Future<List<FacultyWorkloadSummary>> getFacultyWorkloadSummaries({String? departmentId}) async {
    await _delay();
    final facultyList = _faculty.where((f) => f.isActive && (departmentId == null || f.departmentId == departmentId)).toList();
    final subjectsMap = {for (final s in _subjects) s.id: s.name};
    final sectionsMap = {for (final s in _sections) s.id: s.name};

    return facultyList.map((fac) {
      final activeAssignments = _facultyAssignments.where((fa) => fa.facultyId == fac.id && fa.isActive).toList();
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
    await _delay();
    final map = <String, int>{};
    for (final s in _students) {
      if (s.departmentId.isNotEmpty && s.isActive) {
        map[s.departmentId] = (map[s.departmentId] ?? 0) + 1;
      }
    }
    return map;
  }

  @override
  Future<Map<String, int>> getDepartmentFacultyCounts() async {
    await _delay();
    final map = <String, int>{};
    for (final f in _faculty) {
      if (f.isActive && f.departmentId.isNotEmpty) {
        map[f.departmentId] = (map[f.departmentId] ?? 0) + 1;
      }
    }
    return map;
  }

  final List<StudentEnrollment> _enrollments = [
    StudentEnrollment(
      id: 'enr-s1',
      collegeId: 'c1',
      departmentId: 'd1',
      courseId: 'cr1',
      academicYearId: 'ay1',
      semesterId: 'sem1',
      sectionId: 'sec1',
      studentId: 's1',
      status: 'active',
      enrollmentDate: DateTime(2025, 8, 1),
      student: {'id': 's1', 'name': 'John Doe', 'rollNumber': 'CS2025001', 'email': 'john@student.git.edu'},
    ),
    StudentEnrollment(
      id: 'enr-s2',
      collegeId: 'c1',
      departmentId: 'd1',
      courseId: 'cr1',
      academicYearId: 'ay1',
      semesterId: 'sem1',
      sectionId: 'sec1',
      studentId: 's2',
      status: 'active',
      enrollmentDate: DateTime(2025, 8, 1),
      student: {'id': 's2', 'name': 'Jane Smith', 'rollNumber': 'CS2025002', 'email': 'jane@student.git.edu'},
    ),
    StudentEnrollment(
      id: 'enr-s3',
      collegeId: 'c1',
      departmentId: 'd1',
      courseId: 'cr1',
      academicYearId: 'ay1',
      semesterId: 'sem1',
      sectionId: 'sec2',
      studentId: 's3',
      status: 'active',
      enrollmentDate: DateTime(2025, 8, 1),
      student: {'id': 's3', 'name': 'Alice Bob', 'rollNumber': 'CS2025003', 'email': 'alice@student.git.edu'},
    ),
  ];

  @override
  Future<void> updateFacultyAssignment(
    String assignmentId, {
    String? roomId,
    int? maxStudents,
    String? assignmentType,
    bool? isActive,
  }) async {
    await _delay();
    final idx = _facultyAssignments.indexWhere((a) => a.id == assignmentId);
    if (idx != -1) {
      _facultyAssignments[idx] = _facultyAssignments[idx].copyWith(
        roomId: roomId,
        maxStudents: maxStudents,
        assignmentType: assignmentType,
        isActive: isActive,
        updatedAt: DateTime.now(),
      );
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
    await _delay();
    return _enrollments.where((e) {
      if (sectionId != null && e.sectionId != sectionId) return false;
      if (studentId != null && e.studentId != studentId) return false;
      if (status != null && e.status != status) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> updateEnrollment(String id, {String? sectionId, String? status}) async {
    await _delay();
    final idx = _enrollments.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _enrollments[idx] = _enrollments[idx].copyWith(
        sectionId: sectionId,
        status: status,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deleteEnrollment(String id) async {
    await updateEnrollment(id, status: 'withdrawn');
  }

  final List<Room> _rooms = [
    Room(id: 'room_1', collegeId: 'c1', name: 'Room 101', code: 'R101', capacity: 60),
    Room(id: 'room_2', collegeId: 'c1', name: 'Lab 201', code: 'L201', capacity: 40, type: 'lab'),
  ];

  @override
  Future<List<Room>> getRooms({String? collegeId, String? departmentId}) async {
    await _delay();
    return List.from(_rooms);
  }

  @override
  Future<Room> addRoom(Room room) async {
    await _delay();
    final newRoom = room.copyWith(id: 'room_${DateTime.now().millisecondsSinceEpoch}');
    _rooms.add(newRoom);
    return newRoom;
  }
}


// Singleton instance
final mockAcademicRepo = MockAcademicRepository();
