import '../models/academic_models.dart';

abstract class AcademicRepository {
  // Read Methods
  Future<List<College>> getColleges();
  Future<List<Department>> getDepartments();
  Future<List<Course>> getCourses();
  Future<List<AcademicYear>> getAcademicYears();
  Future<List<Semester>> getSemesters();
  Future<List<Section>> getSections();
  Future<List<Subject>> getSubjects();
  Future<List<Faculty>> getFaculty();
  Future<List<Student>> getStudents();

  // Mutations
  Future<void> addCollege(College college);
  Future<void> updateCollege(College college);
  Future<void> deactivateCollege(String id);

  Future<void> addDepartment(Department department);
  Future<void> updateDepartment(Department department);
  Future<void> deactivateDepartment(String id);

  Future<void> addCourse(Course course);
  Future<void> updateCourse(Course course);
  Future<void> deactivateCourse(String id);

  Future<void> addAcademicYear(AcademicYear academicYear);
  Future<void> updateAcademicYear(AcademicYear academicYear);
  Future<void> deactivateAcademicYear(String id);

  Future<void> addSemester(Semester semester);
  Future<void> updateSemester(Semester semester);
  Future<void> deactivateSemester(String id);

  Future<void> addSection(Section section);
  Future<void> updateSection(Section section);
  Future<void> deactivateSection(String id);

  Future<void> addSubject(Subject subject);
  Future<void> updateSubject(Subject subject);
  Future<void> deactivateSubject(String id);

  Future<void> addFaculty(Faculty faculty);
  Future<void> updateFaculty(Faculty faculty);
  Future<void> deactivateFaculty(String id);
  Future<void> bulkAssignSubjectsToFaculty(String facultyId, List<String> subjectIds, List<String> sectionIds);

  Future<void> addStudent(Student student);
  Future<void> updateStudent(Student student);
  Future<void> deactivateStudent(String id);
  Future<void> bulkPromoteStudents(List<String> studentIds, String newSemesterId, String newSectionId);
  Future<void> bulkTransferStudents(List<String> studentIds, String newSectionId);
}
