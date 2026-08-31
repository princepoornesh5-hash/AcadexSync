import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../domain/models/academic_models.dart';
import '../../domain/repositories/academic_repository.dart';

class ApiAcademicRepository implements AcademicRepository {
  final ApiClient _client;

  ApiAcademicRepository([ApiClient? client]) : _client = client ?? apiClient;

  Exception _extractError(DioException e, String fallback) {
    final message = e.response?.data?['error']?['message'] ??
        e.response?.data?['message'] ??
        e.message ??
        fallback;
    return Exception(message);
  }

  // ===========================================================================
  // 1. COLLEGES
  // ===========================================================================

  @override
  Future<List<College>> getColleges() async {
    try {
      final response = await _client.dio.get('/colleges');
      final body = response.data;
      final list = (body is Map<String, dynamic> && body['data'] is List)
          ? body['data'] as List
          : (body is List ? body : []);

      return list.map((e) => College.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch colleges');
    }
  }

  @override
  Future<void> addCollege(College college) async {
    try {
      await _client.dio.post('/colleges', data: college.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create college');
    }
  }

  @override
  Future<void> updateCollege(College college) async {
    try {
      await _client.dio.put('/colleges/${college.id}', data: college.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update college');
    }
  }

  @override
  Future<void> deactivateCollege(String id) async {
    try {
      await _client.dio.patch('/colleges/$id/status', data: {'status': 'inactive'});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to deactivate college');
    }
  }

  // ===========================================================================
  // 2. DEPARTMENTS
  // ===========================================================================

  @override
  Future<List<Department>> getDepartments() async {
    try {
      final response = await _client.dio.get('/departments');
      final body = response.data;
      final list = (body is Map<String, dynamic> && body['data'] is List)
          ? body['data'] as List
          : (body is List ? body : []);

      return list.map((e) => Department.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch departments');
    }
  }

  @override
  Future<void> addDepartment(Department department) async {
    try {
      await _client.dio.post('/departments', data: department.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create department');
    }
  }

  @override
  Future<void> updateDepartment(Department department) async {
    try {
      await _client.dio.put('/departments/${department.id}', data: department.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update department');
    }
  }

  @override
  Future<void> deactivateDepartment(String id) async {
    try {
      await _client.dio.patch('/departments/$id/status', data: {'status': 'inactive'});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to deactivate department');
    }
  }

  @override
  Future<void> assignHodToDepartment(String departmentId, String hodUserId) async {
    try {
      await _client.dio.put('/departments/$departmentId', data: {'hodId': hodUserId});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to assign HOD to department');
    }
  }

  // ===========================================================================
  // 3. COURSES / PROGRAMS
  // ===========================================================================

  @override
  Future<List<Course>> getCourses() async {
    try {
      final response = await _client.dio.get('/academics/courses');
      final body = response.data;
      final list = (body is Map<String, dynamic> && body['data'] is List)
          ? body['data'] as List
          : (body is List ? body : []);

      return list.map((e) => Course.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch courses');
    }
  }

  @override
  Future<void> addCourse(Course course) async {
    try {
      await _client.dio.post('/academics/courses', data: course.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create course');
    }
  }

  @override
  Future<void> updateCourse(Course course) async {
    try {
      await _client.dio.put('/academics/courses/${course.id}', data: course.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update course');
    }
  }

  @override
  Future<void> deactivateCourse(String id) async {
    try {
      await _client.dio.put('/academics/courses/$id', data: {'isActive': false});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to deactivate course');
    }
  }

  // ===========================================================================
  // 4. ACADEMIC YEARS
  // ===========================================================================

  @override
  Future<List<AcademicYear>> getAcademicYears() async {
    try {
      final response = await _client.dio.get('/academics/academic-years');
      final body = response.data;
      final list = (body is Map<String, dynamic> && body['data'] is List)
          ? body['data'] as List
          : (body is List ? body : []);

      return list.map((e) => AcademicYear.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch academic years');
    }
  }

  @override
  Future<void> addAcademicYear(AcademicYear academicYear) async {
    try {
      await _client.dio.post('/academics/academic-years', data: academicYear.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create academic year');
    }
  }

  @override
  Future<void> updateAcademicYear(AcademicYear academicYear) async {
    try {
      await _client.dio.put('/academics/academic-years/${academicYear.id}', data: academicYear.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update academic year');
    }
  }

  @override
  Future<void> deactivateAcademicYear(String id) async {
    try {
      await _client.dio.put('/academics/academic-years/$id', data: {'status': 'archived'});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to deactivate academic year');
    }
  }

  @override
  Future<void> activateAcademicYear(String collegeId, String academicYearId) async {
    try {
      await _client.dio.put('/academics/academic-years/$academicYearId', data: {'status': 'active'});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to activate academic year');
    }
  }

  // ===========================================================================
  // 5. SEMESTERS
  // ===========================================================================

  @override
  Future<List<Semester>> getSemesters() async {
    try {
      final response = await _client.dio.get('/academics/semesters');
      final body = response.data;
      final list = (body is Map<String, dynamic> && body['data'] is List)
          ? body['data'] as List
          : (body is List ? body : []);

      return list.map((e) => Semester.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch semesters');
    }
  }

  @override
  Future<void> addSemester(Semester semester) async {
    try {
      await _client.dio.post('/academics/semesters', data: semester.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create semester');
    }
  }

  @override
  Future<void> updateSemester(Semester semester) async {
    try {
      await _client.dio.put('/academics/semesters/${semester.id}', data: semester.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update semester');
    }
  }

  @override
  Future<void> deactivateSemester(String id) async {
    try {
      await _client.dio.put('/academics/semesters/$id', data: {'status': 'archived'});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to deactivate semester');
    }
  }

  @override
  Future<void> activateSemester(String collegeId, String courseId, String semesterId) async {
    try {
      await _client.dio.put('/academics/semesters/$semesterId', data: {'status': 'active'});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to activate semester');
    }
  }

  @override
  Future<void> completeSemester(String semesterId) async {
    try {
      await _client.dio.put('/academics/semesters/$semesterId', data: {'status': 'completed'});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to complete semester');
    }
  }

  // ===========================================================================
  // 6. SECTIONS
  // ===========================================================================

  @override
  Future<List<Section>> getSections() async {
    try {
      final response = await _client.dio.get('/academics/sections');
      final body = response.data;
      final list = (body is Map<String, dynamic> && body['data'] is List)
          ? body['data'] as List
          : (body is List ? body : []);

      return list.map((e) => Section.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch sections');
    }
  }

  @override
  Future<void> addSection(Section section) async {
    try {
      await _client.dio.post('/academics/sections', data: section.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create section');
    }
  }

  @override
  Future<void> updateSection(Section section) async {
    try {
      await _client.dio.put('/academics/sections/${section.id}', data: section.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update section');
    }
  }

  @override
  Future<void> deactivateSection(String id) async {
    try {
      await _client.dio.put('/academics/sections/$id', data: {'status': 'inactive'});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to deactivate section');
    }
  }

  @override
  Future<void> updateSectionCapacity(String sectionId, int newCapacity) async {
    try {
      await _client.dio.put('/academics/sections/$sectionId', data: {'capacity': newCapacity});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update section capacity');
    }
  }

  @override
  Future<SectionCapacityInfo> getSectionCapacityInfo(String sectionId) async {
    final sections = await getSections();
    final sec = sections.firstWhere((s) => s.id == sectionId, orElse: () => throw Exception('Section not found'));
    final students = await getStudentsBySection(sectionId);
    return SectionCapacityInfo(
      sectionId: sectionId,
      sectionName: sec.name,
      enrolledCount: students.length,
      capacity: sec.capacity,
    );
  }

  @override
  Future<List<SectionTransferValidationResult>> validateBulkSectionTransfer(
      List<String> studentIds, String targetSectionId) async {
    final targetInfo = await getSectionCapacityInfo(targetSectionId);
    final hasRoom = (targetInfo.enrolledCount + studentIds.length) <= targetInfo.capacity;
    return studentIds.map((id) => SectionTransferValidationResult(
      studentId: id,
      studentName: 'Student $id',
      rollNumber: id,
      canMove: hasRoom,
      reason: hasRoom ? null : 'Target section capacity exceeded',
    )).toList();
  }

  @override
  Future<void> executeBulkSectionTransfer({
    required List<String> studentIds,
    required String targetSectionId,
  }) async {
    for (final id in studentIds) {
      await _client.dio.put('/academics/students/$id', data: {'sectionId': targetSectionId});
    }
  }

  // ===========================================================================
  // 7. SUBJECTS
  // ===========================================================================

  @override
  Future<List<Subject>> getSubjects() async {
    try {
      final response = await _client.dio.get('/academics/subjects');
      final body = response.data;
      final list = (body is Map<String, dynamic> && body['data'] is List)
          ? body['data'] as List
          : (body is List ? body : []);

      return list.map((e) => Subject.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch subjects');
    }
  }

  @override
  Future<void> addSubject(Subject subject) async {
    try {
      await _client.dio.post('/academics/subjects', data: subject.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create subject');
    }
  }

  @override
  Future<void> updateSubject(Subject subject) async {
    try {
      await _client.dio.put('/academics/subjects/${subject.id}', data: subject.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update subject');
    }
  }

  @override
  Future<void> deactivateSubject(String id) async {
    try {
      await _client.dio.put('/academics/subjects/$id', data: {'status': 'inactive'});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to deactivate subject');
    }
  }

  // ===========================================================================
  // 8. FACULTY
  // ===========================================================================

  @override
  Future<List<Faculty>> getFaculty({String? departmentId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (departmentId != null && departmentId.isNotEmpty) {
        queryParams['departmentId'] = departmentId;
      }
      final response = await _client.dio.get('/academics/faculty', queryParameters: queryParams);
      final body = response.data;
      final list = (body is Map<String, dynamic> && body['data'] is List)
          ? body['data'] as List
          : (body is List ? body : []);

      return list.map((e) => Faculty.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch faculty');
    }
  }

  @override
  Future<PaginatedResponse<Faculty>> getPaginatedFaculty({
    String? departmentId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final list = await getFaculty(departmentId: departmentId);
    return PaginatedResponse(data: list, hasMore: false);
  }

  @override
  Future<Faculty?> getFacultyById(String id) async {
    try {
      final response = await _client.dio.get('/academics/faculty/$id');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return Faculty.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _extractError(e, 'Failed to fetch faculty profile');
    }
  }

  @override
  Future<ProvisionFacultyResult> provisionFaculty(ProvisionFacultyRequest request) async {
    try {
      final response = await _client.dio.post('/academics/faculty', data: request.toJson());
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return ProvisionFacultyResult.fromJson(data);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to provision faculty');
    }
  }

  @override
  Future<void> addFaculty(Faculty faculty) async {
    try {
      await provisionFaculty(ProvisionFacultyRequest(
        departmentId: faculty.departmentId,
        name: faculty.name,
        instituteId: faculty.employeeId.isNotEmpty ? faculty.employeeId : faculty.id,
        email: faculty.email,
        phone: faculty.phone.isNotEmpty ? faculty.phone : null,
        employeeId: faculty.employeeId.isNotEmpty ? faculty.employeeId : null,
        designation: faculty.designation,
        qualification: faculty.qualification,
        specialization: faculty.specialization,
        joiningDate: faculty.joiningDate?.toIso8601String(),
      ));
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to provision faculty');
    }
  }

  @override
  Future<void> updateFaculty(Faculty faculty) async {
    try {
      await _client.dio.put('/academics/faculty/${faculty.id}', data: faculty.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update faculty profile');
    }
  }

  @override
  Future<void> deactivateFaculty(String id) async {
    try {
      await _client.dio.put('/academics/faculty/$id', data: {'isActive': false});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to deactivate faculty');
    }
  }

  @override
  Future<void> bulkAssignSubjectsToFaculty(
      String facultyId, List<String> subjectIds, List<String> sectionIds) async {
    for (int i = 0; i < subjectIds.length; i++) {
      await createFacultyAssignment(FacultyAssignment(
        id: '',
        collegeId: '',
        facultyId: facultyId,
        facultyName: '',
        subjectId: subjectIds[i],
        sectionId: sectionIds.length > i ? sectionIds[i] : (sectionIds.isNotEmpty ? sectionIds[0] : ''),
        academicYearId: '',
        semesterId: '',
        departmentId: '',
        courseId: '',
      ));
    }
  }

  @override
  Future<bool> checkFacultyExists(String employeeId, String email) async {
    try {
      final list = await getFaculty();
      return list.any((f) => f.employeeId == employeeId || f.email == email);
    } catch (_) {
      return false;
    }
  }

  // =========================================================================
  // 9. FACULTY ASSIGNMENTS & WORKLOAD
  // =========================================================================

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
    try {
      final facultyList = await getFaculty(departmentId: departmentId);
      final assignments = <FacultyAssignment>[];
      for (final f in facultyList) {
        if (facultyId != null && f.id != facultyId) continue;
        for (final subId in f.subjectIds) {
          if (subjectId != null && subId != subjectId) continue;
          assignments.add(FacultyAssignment(
            id: 'assign_${f.id}_$subId',
            collegeId: f.collegeId,
            facultyId: f.id,
            facultyName: f.name,
            subjectId: subId,
            sectionId: sectionId ?? (f.sectionIds.isNotEmpty ? f.sectionIds.first : ''),
            academicYearId: academicYearId ?? '',
            semesterId: semesterId ?? '',
            departmentId: f.departmentId,
            courseId: courseId ?? '',
          ));
        }
      }
      return assignments;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> createFacultyAssignment(FacultyAssignment assignment) async {
    try {
      await _client.dio.post('/academics/faculty-assignments', data: assignment.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create faculty assignment');
    }
  }

  @override
  Future<void> removeFacultyAssignment(String assignmentId) async {
    // Legacy stub
  }

  @override
  Future<void> transferFacultyDepartment(String facultyId, String newDepartmentId) async {
    try {
      await _client.dio.patch('/academics/faculty/$facultyId/department', data: {
        'departmentId': newDepartmentId,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to transfer faculty department');
    }
  }

  @override
  Future<List<FacultyWorkloadSummary>> getFacultyWorkloadSummaries({String? departmentId}) async {
    final facultyList = await getFaculty(departmentId: departmentId);
    return facultyList.map((f) => FacultyWorkloadSummary(
      facultyId: f.id,
      facultyName: f.name,
      employeeId: f.employeeId,
      departmentId: f.departmentId,
      subjectsAssigned: f.subjectIds.length,
      sectionsAssigned: f.sectionIds.length,
      weeklyClasses: f.subjectIds.length * 4,
    )).toList();
  }

  // ===========================================================================
  // 10. STUDENTS
  // ===========================================================================

  @override
  Future<List<Student>> getStudents({String? sectionId, String? departmentId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (sectionId != null && sectionId.isNotEmpty) queryParams['sectionId'] = sectionId;
      if (departmentId != null && departmentId.isNotEmpty) queryParams['departmentId'] = departmentId;

      final response = await _client.dio.get('/academics/students', queryParameters: queryParams);
      final body = response.data;
      final list = (body is Map<String, dynamic> && body['data'] is List)
          ? body['data'] as List
          : (body is List ? body : []);

      return list.map((e) => Student.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch students');
    }
  }

  @override
  Future<PaginatedResponse<Student>> getPaginatedStudents({
    String? sectionId,
    String? departmentId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final list = await getStudents(sectionId: sectionId, departmentId: departmentId);
    return PaginatedResponse(data: list, hasMore: false);
  }

  @override
  Future<Student?> getStudentById(String id) async {
    try {
      final response = await _client.dio.get('/academics/students/$id');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return Student.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _extractError(e, 'Failed to fetch student profile');
    }
  }

  @override
  Future<void> addStudent(Student student) async {
    try {
      await _client.dio.post('/academics/students', data: student.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to provision student');
    }
  }

  @override
  Future<void> updateStudent(Student student) async {
    try {
      await _client.dio.put('/academics/students/${student.id}', data: student.toJson());
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update student profile');
    }
  }

  @override
  Future<void> deactivateStudent(String id) async {
    try {
      await _client.dio.put('/academics/students/$id', data: {'status': 'inactive'});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to deactivate student');
    }
  }

  @override
  Future<bool> checkStudentExists(String rollNumber, String email) async {
    try {
      final list = await getStudents();
      return list.any((s) => s.rollNumber == rollNumber || s.email == email);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> bulkPromoteStudents(List<String> studentIds, String newSemesterId, String newSectionId) async {
    for (final id in studentIds) {
      await _client.dio.put('/academics/students/$id', data: {
        'semesterId': newSemesterId,
        'sectionId': newSectionId,
      });
    }
  }

  @override
  Future<void> bulkTransferStudents(List<String> studentIds, String newSectionId) async {
    for (final id in studentIds) {
      await _client.dio.put('/academics/students/$id', data: {
        'sectionId': newSectionId,
      });
    }
  }

  @override
  Future<String> generateRollNumber(String collegeId, String courseId, String academicYearId) async {
    return 'ROLL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  Future<void> admitStudent(Student student) => addStudent(student);

  @override
  Future<void> bulkAdmitStudents(List<Student> students) async {
    for (final s in students) {
      await addStudent(s);
    }
  }

  @override
  Future<void> promoteStudents({
    required List<String> studentIds,
    required String targetAcademicYearId,
    required String targetSemesterId,
    required String targetSectionId,
  }) => bulkPromoteStudents(studentIds, targetSemesterId, targetSectionId);

  @override
  Future<void> transferStudentsSection({
    required List<String> studentIds,
    required String targetSectionId,
  }) => bulkTransferStudents(studentIds, targetSectionId);

  @override
  Future<void> transferStudentsDepartment({
    required List<String> studentIds,
    required String targetDepartmentId,
    required String targetCourseId,
    required String targetSemesterId,
    required String targetSectionId,
  }) async {
    for (final id in studentIds) {
      await _client.dio.patch('/academics/students/$id/department', data: {
        'departmentId': targetDepartmentId,
        'courseId': targetCourseId,
        'semesterId': targetSemesterId,
        'sectionId': targetSectionId,
      });
    }
  }

  @override
  Future<void> updateStudentLifecycleState({
    required String studentId,
    required StudentLifecycleState newState,
    String? remarks,
  }) async {
    await _client.dio.put('/academics/students/$studentId', data: {
      'status': newState.name,
      if (remarks != null) 'remarks': remarks,
    });
  }

  @override
  Future<void> bulkGraduateStudents({
    required List<String> studentIds,
    String? remarks,
  }) async {
    for (final id in studentIds) {
      await updateStudentLifecycleState(studentId: id, newState: StudentLifecycleState.graduated, remarks: remarks);
    }
  }

  @override
  Future<void> bulkArchiveAlumni({
    required List<String> studentIds,
  }) async {
    for (final id in studentIds) {
      await updateStudentLifecycleState(studentId: id, newState: StudentLifecycleState.alumni);
    }
  }

  @override
  Future<StudentAcademicProfile> getStudentAcademicProfile(String studentId) async {
    final student = await getStudentById(studentId);
    if (student == null) throw Exception('Student not found: $studentId');
    return StudentAcademicProfile(
      student: student,
      overallAttendancePercentage: 0.0,
      enrolledSubjects: const [],
      notesCount: 0,
    );
  }

  @override
  Future<List<StudentAcademicHistory>> getStudentAcademicHistory(String studentId) async {
    return [];
  }

  @override
  Future<void> recordAcademicHistory(StudentAcademicHistory history) async {}

  @override
  Future<List<Student>> getStudentsBySection(String sectionId) =>
      getStudents(sectionId: sectionId);

  @override
  Future<List<Student>> getStudentsBySemester(String semesterId) async {
    final students = await getStudents();
    return students.where((s) => s.semesterId == semesterId).toList();
  }

  @override
  Future<List<Student>> getStudentsByCourse(String courseId) async {
    final students = await getStudents();
    return students.where((s) => s.courseId == courseId).toList();
  }

  @override
  Future<List<Student>> getStudentsByDepartment(String departmentId) =>
      getStudents(departmentId: departmentId);

  @override
  Future<Map<String, int>> getDepartmentStudentCounts() async {
    final students = await getStudents();
    final counts = <String, int>{};
    for (final s in students) {
      counts[s.departmentId] = (counts[s.departmentId] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<Map<String, int>> getDepartmentFacultyCounts() async {
    final faculty = await getFaculty();
    final counts = <String, int>{};
    for (final f in faculty) {
      counts[f.departmentId] = (counts[f.departmentId] ?? 0) + 1;
    }
    return counts;
  }
}
