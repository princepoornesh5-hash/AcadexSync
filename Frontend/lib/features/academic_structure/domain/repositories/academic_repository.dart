import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/academic_models.dart';
import '../../../../core/firebase/firebase_services.dart';

abstract class AcademicRepository {
  // Read Methods
  Future<List<College>> getColleges();
  Future<List<Department>> getDepartments();
  Future<List<Course>> getCourses();
  Future<List<AcademicYear>> getAcademicYears();
  Future<List<Semester>> getSemesters();
  Future<List<Section>> getSections();
  Future<List<Subject>> getSubjects();
  Future<List<Faculty>> getFaculty({String? departmentId});
  Future<PaginatedResponse<Faculty>> getPaginatedFaculty({String? departmentId, int limit = 20, DocumentSnapshot? startAfter});
  Future<Faculty?> getFacultyById(String id);
  Future<List<Student>> getStudents({String? sectionId, String? departmentId});
  Future<PaginatedResponse<Student>> getPaginatedStudents({String? sectionId, String? departmentId, int limit = 20, DocumentSnapshot? startAfter});
  Future<Student?> getStudentById(String id);
  Future<bool> checkStudentExists(String rollNumber, String email);
  Future<bool> checkFacultyExists(String employeeId, String email);

  // Mutations
  Future<void> addCollege(College college);
  Future<void> updateCollege(College college);
  Future<void> deactivateCollege(String id);

  Future<void> addDepartment(Department department);
  Future<void> updateDepartment(Department department);
  Future<void> deactivateDepartment(String id);
  Future<void> assignHodToDepartment(String departmentId, String hodUserId);

  Future<void> addCourse(Course course);
  Future<void> updateCourse(Course course);
  Future<void> deactivateCourse(String id);

  Future<void> addAcademicYear(AcademicYear academicYear);
  Future<void> updateAcademicYear(AcademicYear academicYear);
  Future<void> deactivateAcademicYear(String id);
  Future<void> activateAcademicYear(String collegeId, String academicYearId);

  Future<void> addSemester(Semester semester);
  Future<void> updateSemester(Semester semester);
  Future<void> deactivateSemester(String id);
  Future<void> activateSemester(String collegeId, String courseId, String semesterId);
  Future<void> completeSemester(String semesterId);

  Future<void> addSection(Section section);
  Future<void> updateSection(Section section);
  Future<void> deactivateSection(String id);
  Future<void> updateSectionCapacity(String sectionId, int newCapacity);
  Future<SectionCapacityInfo> getSectionCapacityInfo(String sectionId);
  Future<List<SectionTransferValidationResult>> validateBulkSectionTransfer(List<String> studentIds, String targetSectionId);
  Future<void> executeBulkSectionTransfer({required List<String> studentIds, required String targetSectionId});

  Future<void> addSubject(Subject subject);
  Future<void> updateSubject(Subject subject);
  Future<void> deactivateSubject(String id);

  Future<void> addFaculty(Faculty faculty);
  Future<ProvisionFacultyResult> provisionFaculty(ProvisionFacultyRequest request);
  Future<void> updateFaculty(Faculty faculty);
  Future<void> deactivateFaculty(String id);
  Future<void> bulkAssignSubjectsToFaculty(String facultyId, List<String> subjectIds, List<String> sectionIds);

  // Faculty Assignments
  Future<List<FacultyAssignment>> getFacultyAssignments({
    String? facultyId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? subjectId,
    String? academicYearId,
  });
  Future<void> createFacultyAssignment(FacultyAssignment assignment);
  Future<void> removeFacultyAssignment(String assignmentId);

  Future<void> addStudent(Student student);
  Future<void> updateStudent(Student student);
  Future<void> deactivateStudent(String id);
  Future<void> bulkPromoteStudents(List<String> studentIds, String newSemesterId, String newSectionId);
  Future<void> bulkTransferStudents(List<String> studentIds, String newSectionId);

  // Student Lifecycle Operations (Phase 3)
  Future<String> generateRollNumber(String collegeId, String courseId, String academicYearId);
  Future<void> admitStudent(Student student);
  Future<void> bulkAdmitStudents(List<Student> students);
  Future<void> promoteStudents({
    required List<String> studentIds,
    required String targetAcademicYearId,
    required String targetSemesterId,
    required String targetSectionId,
  });
  Future<void> transferStudentsSection({
    required List<String> studentIds,
    required String targetSectionId,
  });
  Future<void> transferStudentsDepartment({
    required List<String> studentIds,
    required String targetDepartmentId,
    required String targetCourseId,
    required String targetSemesterId,
    required String targetSectionId,
  });
  Future<void> updateStudentLifecycleState({
    required String studentId,
    required StudentLifecycleState newState,
    String? remarks,
  });
  Future<void> bulkGraduateStudents({
    required List<String> studentIds,
    String? remarks,
  });
  Future<void> bulkArchiveAlumni({
    required List<String> studentIds,
  });
  Future<StudentAcademicProfile> getStudentAcademicProfile(String studentId);
  Future<List<StudentAcademicHistory>> getStudentAcademicHistory(String studentId);
  Future<void> recordAcademicHistory(StudentAcademicHistory history);
  Future<List<Student>> getStudentsBySection(String sectionId);
  Future<List<Student>> getStudentsBySemester(String semesterId);
  Future<List<Student>> getStudentsByCourse(String courseId);
  Future<List<Student>> getStudentsByDepartment(String departmentId);
  Future<void> transferFacultyDepartment(String facultyId, String newDepartmentId);
  Future<List<FacultyWorkloadSummary>> getFacultyWorkloadSummaries({String? departmentId});
  Future<Map<String, int>> getDepartmentStudentCounts();
  Future<Map<String, int>> getDepartmentFacultyCounts();
}
