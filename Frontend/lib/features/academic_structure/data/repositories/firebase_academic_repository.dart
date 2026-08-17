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

  Map<String, dynamic> _getScopeFilters({bool isCollege = false}) {
    if (_currentUser == null) return {};
    if (_currentUser.role == AppRole.superAdmin) return {};
    
    final filters = <String, dynamic>{};
    
    if (isCollege) {
      filters['id'] = _currentUser.collegeId;
      return filters;
    }
    
    if (_currentUser.collegeId?.isNotEmpty == true) {
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
  Future<List<Department>> getDepartments() async {
    final filters = _getScopeFilters();
    final docs = await _firestoreService.queryCollection('departments', filters);
    return docs.map((d) => Department.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<List<Course>> getCourses() async {
    final filters = _getScopeFilters();
    final docs = await _firestoreService.queryCollection('courses', filters);
    return docs.map((d) => Course.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<List<AcademicYear>> getAcademicYears() async {
    final filters = _getScopeFilters();
    final docs = await _firestoreService.queryCollection('academicYears', filters);
    return docs.map((d) => AcademicYear.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<List<Semester>> getSemesters() async {
    final filters = _getScopeFilters();
    final docs = await _firestoreService.queryCollection('semesters', filters);
    return docs.map((d) => Semester.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<List<Section>> getSections() async {
    final filters = _getScopeFilters();
    final docs = await _firestoreService.queryCollection('sections', filters);
    return docs.map((d) => Section.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<List<Subject>> getSubjects() async {
    final filters = _getScopeFilters();
    final docs = await _firestoreService.queryCollection('subjects', filters);
    return docs.map((d) => Subject.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<List<Faculty>> getFaculty() async {
    final filters = _getScopeFilters();
    final docs = await _firestoreService.queryCollection('faculty', filters);
    return docs.map((d) => Faculty.fromJson(d)).where((c) => c.isActive).toList();
  }

  @override
  Future<List<Student>> getStudents() async {
    final filters = _getScopeFilters();
    final docs = await _firestoreService.queryCollection('students', filters);
    return docs.map((d) => Student.fromJson(d)).where((c) => c.isActive).toList();
  }

  // --- College Mutations ---

  @override
  Future<void> addCollege(College college) async {
    _validateScope(college.id);
    await _firestoreService.setDocument('colleges', college.id, college.toJson());
  }

  @override
  Future<void> updateCollege(College college) async {
    _validateScope(college.id);
    await _firestoreService.setDocument('colleges', college.id, college.toJson());
  }

  @override
  Future<void> deactivateCollege(String id) async {
    _validateScope(id);
    final doc = await _firestoreService.getDocument('colleges', id);
    if (doc != null) {
      final updated = College.fromJson(doc).copyWith(isActive: false);
      await _firestoreService.setDocument('colleges', id, updated.toJson());
    }
  }

  // --- Department Mutations ---

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
      final updated = department.copyWith(isActive: false);
      await _firestoreService.setDocument('departments', id, updated.toJson());
    }
  }

  // --- Course Mutations ---

  @override
  Future<void> addCourse(Course course) async {
    _validateScope(null, course.departmentId);
    await _firestoreService.setDocument('courses', course.id, course.toJson());
  }

  @override
  Future<void> updateCourse(Course course) async {
    _validateScope(null, course.departmentId);
    await _firestoreService.setDocument('courses', course.id, course.toJson());
  }

  @override
  Future<void> deactivateCourse(String id) async {
    final doc = await _firestoreService.getDocument('courses', id);
    if (doc != null) {
      final course = Course.fromJson(doc);
      _validateScope(null, course.departmentId);
      final updated = course.copyWith(isActive: false);
      await _firestoreService.setDocument('courses', id, updated.toJson());
    }
  }

  // --- Academic Year Mutations ---

  @override
  Future<void> addAcademicYear(AcademicYear academicYear) async {
    _validateScope(academicYear.collegeId);
    await _firestoreService.setDocument('academicYears', academicYear.id, academicYear.toJson());
  }

  @override
  Future<void> updateAcademicYear(AcademicYear academicYear) async {
    _validateScope(academicYear.collegeId);
    await _firestoreService.setDocument('academicYears', academicYear.id, academicYear.toJson());
  }

  @override
  Future<void> deactivateAcademicYear(String id) async {
    final doc = await _firestoreService.getDocument('academicYears', id);
    if (doc != null) {
      final academicYear = AcademicYear.fromJson(doc);
      _validateScope(academicYear.collegeId);
      final updated = academicYear.copyWith(isActive: false);
      await _firestoreService.setDocument('academicYears', id, updated.toJson());
    }
  }

  // --- Semester Mutations ---

  @override
  Future<void> addSemester(Semester semester) async {
    await _firestoreService.setDocument('semesters', semester.id, semester.toJson());
  }

  @override
  Future<void> updateSemester(Semester semester) async {
    await _firestoreService.setDocument('semesters', semester.id, semester.toJson());
  }

  @override
  Future<void> deactivateSemester(String id) async {
    final doc = await _firestoreService.getDocument('semesters', id);
    if (doc != null) {
      final updated = Semester.fromJson(doc).copyWith(isActive: false);
      await _firestoreService.setDocument('semesters', id, updated.toJson());
    }
  }

  // --- Section Mutations ---

  @override
  Future<void> addSection(Section section) async {
    await _firestoreService.setDocument('sections', section.id, section.toJson());
  }

  @override
  Future<void> updateSection(Section section) async {
    await _firestoreService.setDocument('sections', section.id, section.toJson());
  }

  @override
  Future<void> deactivateSection(String id) async {
    final doc = await _firestoreService.getDocument('sections', id);
    if (doc != null) {
      final updated = Section.fromJson(doc).copyWith(isActive: false);
      await _firestoreService.setDocument('sections', id, updated.toJson());
    }
  }

  // --- Subject Mutations ---

  @override
  Future<void> addSubject(Subject subject) async {
    _validateScope(null, subject.departmentId);
    await _firestoreService.setDocument('subjects', subject.id, subject.toJson());
  }

  @override
  Future<void> updateSubject(Subject subject) async {
    _validateScope(null, subject.departmentId);
    await _firestoreService.setDocument('subjects', subject.id, subject.toJson());
  }

  @override
  Future<void> deactivateSubject(String id) async {
    final doc = await _firestoreService.getDocument('subjects', id);
    if (doc != null) {
      final subject = Subject.fromJson(doc);
      _validateScope(null, subject.departmentId);
      final updated = subject.copyWith(isActive: false);
      await _firestoreService.setDocument('subjects', id, updated.toJson());
    }
  }

  // --- Faculty Mutations ---

  @override
  Future<void> addFaculty(Faculty faculty) async {
    _validateScope(null, faculty.departmentId);
    await _firestoreService.setDocument('faculty', faculty.id, faculty.toJson());
  }

  @override
  Future<void> updateFaculty(Faculty faculty) async {
    _validateScope(null, faculty.departmentId);
    await _firestoreService.setDocument('faculty', faculty.id, faculty.toJson());
  }

  @override
  Future<void> deactivateFaculty(String id) async {
    final doc = await _firestoreService.getDocument('faculty', id);
    if (doc != null) {
      final faculty = Faculty.fromJson(doc);
      _validateScope(null, faculty.departmentId);
      final updated = faculty.copyWith(isActive: false);
      await _firestoreService.setDocument('faculty', id, updated.toJson());
    }
  }

  @override
  Future<void> bulkAssignSubjectsToFaculty(String facultyId, List<String> subjectIds, List<String> sectionIds) async {
    final doc = await _firestoreService.getDocument('faculty', facultyId);
    if (doc != null) {
      final faculty = Faculty.fromJson(doc);
      _validateScope(null, faculty.departmentId);
      final updated = faculty.copyWith(subjectIds: subjectIds, sectionIds: sectionIds);
      await _firestoreService.setDocument('faculty', facultyId, updated.toJson());
    }
  }

  // --- Student Mutations ---

  @override
  Future<void> addStudent(Student student) async {
    _validateScope(student.collegeId, student.departmentId);
    await _firestoreService.setDocument('students', student.id, student.toJson());
  }

  @override
  Future<void> updateStudent(Student student) async {
    _validateScope(student.collegeId, student.departmentId);
    await _firestoreService.setDocument('students', student.id, student.toJson());
  }

  @override
  Future<void> deactivateStudent(String id) async {
    final doc = await _firestoreService.getDocument('students', id);
    if (doc != null) {
      final student = Student.fromJson(doc);
      _validateScope(student.collegeId, student.departmentId);
      final updated = student.copyWith(isActive: false);
      await _firestoreService.setDocument('students', id, updated.toJson());
    }
  }

  @override
  Future<void> bulkPromoteStudents(List<String> studentIds, String newSemesterId, String newSectionId) async {
    for (final id in studentIds) {
      final doc = await _firestoreService.getDocument('students', id);
      if (doc != null) {
        final current = Student.fromJson(doc);
        _validateScope(current.collegeId, current.departmentId);
        final newHistory = List<AcademicHistory>.from(current.history);
        newHistory.add(AcademicHistory(semesterId: current.semesterId, sectionId: current.sectionId, status: 'Promoted'));
        final updated = current.copyWith(semesterId: newSemesterId, sectionId: newSectionId, history: newHistory);
        await _firestoreService.setDocument('students', id, updated.toJson());
      }
    }
  }

  @override
  Future<void> bulkTransferStudents(List<String> studentIds, String newSectionId) async {
    for (final id in studentIds) {
      final doc = await _firestoreService.getDocument('students', id);
      if (doc != null) {
        final current = Student.fromJson(doc);
        _validateScope(current.collegeId, current.departmentId);
        final updated = current.copyWith(sectionId: newSectionId);
        await _firestoreService.setDocument('students', id, updated.toJson());
      }
    }
  }
}
