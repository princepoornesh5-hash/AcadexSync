import '../../domain/models/academic_models.dart';
import '../../domain/repositories/academic_repository.dart';

class MockAcademicRepository implements AcademicRepository {
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
    Course(id: 'cr1', departmentId: 'd1', name: 'B.Tech', code: 'BTECH-CS'),
    Course(id: 'cr2', departmentId: 'd1', name: 'M.Tech', code: 'MTECH-CS'),
    Course(id: 'cr3', departmentId: 'd2', name: 'B.Tech', code: 'BTECH-ME'),
  ];

  final List<AcademicYear> _academicYears = [
    AcademicYear(id: 'ay1', collegeId: 'c1', name: '2025-2026', startDate: DateTime(2025, 8, 1), endDate: DateTime(2026, 7, 31)),
    AcademicYear(id: 'ay2', collegeId: 'c1', name: '2026-2027', startDate: DateTime(2026, 8, 1), endDate: DateTime(2027, 7, 31)),
  ];

  final List<Semester> _semesters = [
    Semester(id: 'sem1', courseId: 'cr1', academicYearId: 'ay1', name: 'Semester 1', number: 1),
    Semester(id: 'sem2', courseId: 'cr1', academicYearId: 'ay1', name: 'Semester 2', number: 2),
    Semester(id: 'sem3', courseId: 'cr1', academicYearId: 'ay2', name: 'Semester 3', number: 3),
  ];

  final List<Section> _sections = [
    Section(id: 'sec1', semesterId: 'sem1', name: 'A'),
    Section(id: 'sec2', semesterId: 'sem1', name: 'B'),
    Section(id: 'sec3', semesterId: 'sem1', name: 'C'),
  ];

  final List<Subject> _subjects = [
    Subject(id: 'sub1', departmentId: 'd1', semesterId: 'sem1', name: 'Data Structures', code: 'CS101', credits: 4, type: 'Theory'),
    Subject(id: 'sub2', departmentId: 'd1', semesterId: 'sem1', name: 'Programming Lab', code: 'CS101L', credits: 2, type: 'Lab'),
    Subject(id: 'sub3', departmentId: 'd1', semesterId: 'sem1', name: 'Discrete Math', code: 'MA101', credits: 3, type: 'Theory'),
  ];

  final List<Faculty> _faculty = [
    Faculty(id: 'f1', departmentId: 'd1', name: 'Prof. Alan Turing', employeeId: 'EMP001', email: 'alan@git.edu', phone: '9876543210', subjectIds: ['sub1', 'sub3'], sectionIds: ['sec1']),
    Faculty(id: 'f2', departmentId: 'd2', name: 'Prof. Nikola Tesla', employeeId: 'EMP002', email: 'tesla@git.edu', phone: '9876543211'),
    Faculty(id: 'f3', departmentId: 'd3', name: 'Prof. Ada Lovelace', employeeId: 'EMP003', email: 'ada@git.edu', phone: '9876543212'),
  ];

  final List<Student> _students = [
    Student(id: 's1', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', semesterId: 'sem1', sectionId: 'sec1', name: 'John Doe', rollNumber: 'CS2025001', email: 'john@student.git.edu', phone: '5551234567'),
    Student(id: 's2', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', semesterId: 'sem1', sectionId: 'sec1', name: 'Jane Smith', rollNumber: 'CS2025002', email: 'jane@student.git.edu', phone: '5551234568'),
    Student(id: 's3', collegeId: 'c1', departmentId: 'd1', courseId: 'cr1', semesterId: 'sem1', sectionId: 'sec2', name: 'Alice Bob', rollNumber: 'CS2025003', email: 'alice@student.git.edu', phone: '5551234569'),
  ];

  Future<void> _delay() async => await Future.delayed(const Duration(milliseconds: 200));

  // --- Getters ---
  @override
  Future<List<College>> getColleges() async { await _delay(); return List.from(_colleges.where((e) => e.isActive)); }
  @override
  Future<List<Department>> getDepartments() async { await _delay(); return List.from(_departments.where((e) => e.isActive)); }
  @override
  Future<List<Course>> getCourses() async { await _delay(); return List.from(_courses.where((e) => e.isActive)); }
  @override
  Future<List<AcademicYear>> getAcademicYears() async { await _delay(); return List.from(_academicYears.where((e) => e.isActive)); }
  @override
  Future<List<Semester>> getSemesters() async { await _delay(); return List.from(_semesters.where((e) => e.isActive)); }
  @override
  Future<List<Section>> getSections() async { await _delay(); return List.from(_sections.where((e) => e.isActive)); }
  @override
  Future<List<Subject>> getSubjects() async { await _delay(); return List.from(_subjects.where((e) => e.isActive)); }
  @override
  Future<List<Faculty>> getFaculty() async { await _delay(); return List.from(_faculty.where((e) => e.isActive)); }
  @override
  Future<List<Student>> getStudents() async { await _delay(); return List.from(_students.where((e) => e.isActive)); }

  // --- College Mutations ---
  @override
  Future<void> addCollege(College college) async { await _delay(); _colleges.add(college); }
  @override
  Future<void> updateCollege(College college) async {
    await _delay();
    final idx = _colleges.indexWhere((e) => e.id == college.id);
    if (idx != -1) _colleges[idx] = college;
  }
  @override
  Future<void> deactivateCollege(String id) async {
    await _delay();
    final idx = _colleges.indexWhere((e) => e.id == id);
    if (idx != -1) _colleges[idx] = _colleges[idx].copyWith(isActive: false);
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
    if (idx != -1) _departments[idx] = _departments[idx].copyWith(isActive: false);
  }

  // --- Course Mutations ---
  @override
  Future<void> addCourse(Course course) async { await _delay(); _courses.add(course); }
  @override
  Future<void> updateCourse(Course course) async {
    await _delay();
    final idx = _courses.indexWhere((e) => e.id == course.id);
    if (idx != -1) _courses[idx] = course;
  }
  @override
  Future<void> deactivateCourse(String id) async {
    await _delay();
    final idx = _courses.indexWhere((e) => e.id == id);
    if (idx != -1) _courses[idx] = _courses[idx].copyWith(isActive: false);
  }

  // --- Academic Year Mutations ---
  @override
  Future<void> addAcademicYear(AcademicYear academicYear) async { await _delay(); _academicYears.add(academicYear); }
  @override
  Future<void> updateAcademicYear(AcademicYear academicYear) async {
    await _delay();
    final idx = _academicYears.indexWhere((e) => e.id == academicYear.id);
    if (idx != -1) _academicYears[idx] = academicYear;
  }
  @override
  Future<void> deactivateAcademicYear(String id) async {
    await _delay();
    final idx = _academicYears.indexWhere((e) => e.id == id);
    if (idx != -1) _academicYears[idx] = _academicYears[idx].copyWith(isActive: false);
  }

  // --- Semester Mutations ---
  @override
  Future<void> addSemester(Semester semester) async { await _delay(); _semesters.add(semester); }
  @override
  Future<void> updateSemester(Semester semester) async {
    await _delay();
    final idx = _semesters.indexWhere((e) => e.id == semester.id);
    if (idx != -1) _semesters[idx] = semester;
  }
  @override
  Future<void> deactivateSemester(String id) async {
    await _delay();
    final idx = _semesters.indexWhere((e) => e.id == id);
    if (idx != -1) _semesters[idx] = _semesters[idx].copyWith(isActive: false);
  }

  // --- Section Mutations ---
  @override
  Future<void> addSection(Section section) async { await _delay(); _sections.add(section); }
  @override
  Future<void> updateSection(Section section) async {
    await _delay();
    final idx = _sections.indexWhere((e) => e.id == section.id);
    if (idx != -1) _sections[idx] = section;
  }
  @override
  Future<void> deactivateSection(String id) async {
    await _delay();
    final idx = _sections.indexWhere((e) => e.id == id);
    if (idx != -1) _sections[idx] = _sections[idx].copyWith(isActive: false);
  }

  // --- Subject Mutations ---
  @override
  Future<void> addSubject(Subject subject) async { await _delay(); _subjects.add(subject); }
  @override
  Future<void> updateSubject(Subject subject) async {
    await _delay();
    final idx = _subjects.indexWhere((e) => e.id == subject.id);
    if (idx != -1) _subjects[idx] = subject;
  }
  @override
  Future<void> deactivateSubject(String id) async {
    await _delay();
    final idx = _subjects.indexWhere((e) => e.id == id);
    if (idx != -1) _subjects[idx] = _subjects[idx].copyWith(isActive: false);
  }

  // --- Faculty Mutations ---
  @override
  Future<void> addFaculty(Faculty faculty) async { await _delay(); _faculty.add(faculty); }
  @override
  Future<void> updateFaculty(Faculty faculty) async {
    await _delay();
    final idx = _faculty.indexWhere((f) => f.id == faculty.id);
    if (idx != -1) _faculty[idx] = faculty;
  }
  @override
  Future<void> deactivateFaculty(String id) async {
    await _delay();
    final idx = _faculty.indexWhere((f) => f.id == id);
    if (idx != -1) _faculty[idx] = _faculty[idx].copyWith(isActive: false);
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
  Future<void> addStudent(Student student) async { await _delay(); _students.add(student); }
  @override
  Future<void> updateStudent(Student student) async {
    await _delay();
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index != -1) _students[index] = student;
  }
  @override
  Future<void> deactivateStudent(String id) async {
    await _delay();
    final index = _students.indexWhere((s) => s.id == id);
    if (index != -1) _students[index] = _students[index].copyWith(isActive: false);
  }
  @override
  Future<void> bulkPromoteStudents(List<String> studentIds, String newSemesterId, String newSectionId) async {
    await _delay();
    for (var id in studentIds) {
      final index = _students.indexWhere((s) => s.id == id);
      if (index != -1) {
        final current = _students[index];
        final newHistory = List<AcademicHistory>.from(current.history);
        newHistory.add(AcademicHistory(semesterId: current.semesterId, sectionId: current.sectionId, status: 'Promoted'));
        _students[index] = current.copyWith(
          semesterId: newSemesterId,
          sectionId: newSectionId,
          history: newHistory,
        );
      }
    }
  }
  @override
  Future<void> bulkTransferStudents(List<String> studentIds, String newSectionId) async {
    await _delay();
    for (var id in studentIds) {
      final index = _students.indexWhere((s) => s.id == id);
      if (index != -1) {
        _students[index] = _students[index].copyWith(sectionId: newSectionId);
      }
    }
  }
}

// Singleton instance
final mockAcademicRepo = MockAcademicRepository();

