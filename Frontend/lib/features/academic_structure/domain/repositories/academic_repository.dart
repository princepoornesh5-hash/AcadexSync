import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/academic_models.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../../core/firebase/firebase_services.dart';

abstract class AcademicRepository {
  // Read Methods
  Future<List<College>> getColleges();
  Future<College> getCollegeById(String id);
  Future<Map<String, dynamic>> getCollegeSummary(String id);
  Future<List<Map<String, dynamic>>> getCollegeAdmins(String id);
  Future<List<Department>> getDepartments({String? collegeId, String? search, String? status});
  Future<Department> getDepartmentById(String id);
  Future<Map<String, dynamic>> getDepartmentSummary(String id);
  Future<Map<String, dynamic>?> getDepartmentHod(String departmentId);
  Future<List<Course>> getCourses({String? collegeId, String? departmentId, String? search});
  Future<Course> getCourseById(String id);
  Future<List<AcademicYear>> getAcademicYears({String? collegeId});
  Future<AcademicYear> getAcademicYearById(String id);
  Future<List<Semester>> getSemesters({String? courseId, String? academicYearId, String? collegeId});
  Future<Semester> getSemesterById(String id);
  Future<List<Section>> getSections({String? semesterId, String? courseId, String? collegeId});
  Future<Section> getSectionById(String id);
  Future<List<Subject>> getSubjects({String? semesterId, String? courseId, String? collegeId});
  Future<Subject> getSubjectById(String id);
  Future<List<Faculty>> getFaculty({String? departmentId, String? search, String? status});
  Future<PaginatedResponse<Faculty>> getPaginatedFaculty({String? departmentId, int limit = 20, DocumentSnapshot? startAfter});
  Future<Faculty?> getFacultyById(String id);
  Future<Map<String, dynamic>> getFacultySummary(String id);
  Future<List<Student>> getStudents({String? sectionId, String? departmentId});
  Future<PaginatedResponse<Student>> getPaginatedStudents({String? sectionId, String? departmentId, int limit = 20, DocumentSnapshot? startAfter});
  Future<Student?> getStudentById(String id);
  Future<bool> checkStudentExists(String rollNumber, String email);
  Future<bool> checkFacultyExists(String employeeId, String email);

  // Mutations
  Future<void> addCollege(College college);
  Future<void> updateCollege(College college);
  Future<void> deactivateCollege(String id);
  Future<void> updateCollegeStatus(String id, String status);
  Future<ProvisionAdminResult> provisionCollegeAdmin(String collegeId, Map<String, dynamic> data);

  Future<void> addDepartment(Department department);
  Future<void> updateDepartment(Department department);
  Future<void> deactivateDepartment(String id);
  Future<void> updateDepartmentStatus(String id, String status);
  Future<void> assignHodToDepartment(String departmentId, String hodUserId);

  Future<ProvisionHodResult> provisionHod({
    required String departmentId,
    required String name,
    required String instituteId,
    required String email,
    String? phone,
  });
  Future<List<UserModel>> getHods({String? departmentId, String? search, String? status});
  Future<UserModel> getHodById(String id);
  Future<void> updateHodProfile(String id, {String? name, String? email, String? phone});
  Future<void> transferHodDepartment(String id, String targetDepartmentId);
  Future<Map<String, dynamic>> getHodSummary(String id);

  Future<void> addCourse(Course course);
  Future<void> updateCourse(Course course);
  Future<void> deactivateCourse(String id);
  Future<void> updateCourseStatus(String id, bool isActive);

  Future<void> addAcademicYear(AcademicYear academicYear);
  Future<void> updateAcademicYear(AcademicYear academicYear);
  Future<void> setCurrentAcademicYear(String id);
  Future<void> updateAcademicYearStatus(String id, bool isActive);
  Future<void> deactivateAcademicYear(String id);
  Future<void> activateAcademicYear(String collegeId, String academicYearId);

  Future<void> addSemester(Semester semester);
  Future<void> updateSemester(Semester semester);
  Future<void> updateSemesterStatus(String id, bool isActive);
  Future<void> toggleSemesterCurrent(String id, bool isCurrent);
  Future<void> deactivateSemester(String id);
  Future<void> activateSemester(String collegeId, String courseId, String semesterId);
  Future<void> completeSemester(String semesterId);

  Future<void> addSection(Section section);
  Future<void> updateSection(Section section);
  Future<void> updateSectionStatus(String id, bool isActive);
  Future<void> deactivateSection(String id);
  Future<void> updateSectionCapacity(String sectionId, int newCapacity);
  Future<SectionCapacityInfo> getSectionCapacityInfo(String sectionId);
  Future<List<SectionTransferValidationResult>> validateBulkSectionTransfer(List<String> studentIds, String targetSectionId);
  Future<void> executeBulkSectionTransfer({required List<String> studentIds, required String targetSectionId});

  Future<void> addSubject(Subject subject);
  Future<void> updateSubject(Subject subject);
  Future<void> updateSubjectStatus(String id, bool isActive);
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
  Future<ProvisionStudentResult> provisionStudent(ProvisionStudentRequest request);
  Future<void> updateStudent(Student student);
  Future<void> deactivateStudent(String id);
  Future<void> transferStudentDepartment(String studentId, String newDepartmentId);
  Future<Map<String, dynamic>> getStudentSummary(String studentId);
  Future<void> enrollStudent({
    required String studentId,
    required String courseId,
    required String academicYearId,
    required String semesterId,
    required String sectionId,
    String? enrollmentDate,
  });
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
