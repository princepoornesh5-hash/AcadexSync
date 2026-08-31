import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../domain/models/academic_models.dart';
import '../../../auth/domain/models/user_model.dart';
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
      final response = await _client.dio.get('/colleges', queryParameters: {'limit': 100});
      final body = response.data;
      // Backend returns paginated: { data: { items: [...], total, page } }
      List raw = [];
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic> && data['items'] is List) {
          raw = data['items'] as List;
        } else if (data is List) {
          raw = data;
        }
      } else if (body is List) {
        raw = body;
      }
      return raw.map((e) => College.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch colleges');
    }
  }

  @override
  Future<College> getCollegeById(String id) async {
    try {
      final response = await _client.dio.get('/colleges/$id');
      final body = response.data;
      final data = (body is Map<String, dynamic> && body['data'] != null)
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;
      return College.fromJson(data);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to fetch college');
    }
  }

  @override
  Future<Map<String, dynamic>> getCollegeSummary(String id) async {
    try {
      final response = await _client.dio.get('/colleges/$id/summary');
      final body = response.data;
      final data = (body is Map<String, dynamic> && body['data'] != null)
          ? body['data'] as Map<String, dynamic>
          : (body is Map<String, dynamic> ? body : <String, dynamic>{});
      return data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return {};
      }
      throw _extractError(e, 'Failed to fetch college summary');
    }
  }

  @override
  Future<void> updateCollegeStatus(String id, String status) async {
    try {
      await _client.dio.patch('/colleges/$id/status', data: {'status': status});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update college status');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCollegeAdmins(String id) async {
    try {
      final response = await _client.dio.get('/colleges/$id/admins');
      final body = response.data;
      List raw = [];
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is List) {
          raw = data;
        } else if (data is Map<String, dynamic> && data['items'] is List) {
          raw = data['items'] as List;
        }
      } else if (body is List) {
        raw = body;
      }
      return raw.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch college admins');
    }
  }

  @override
  Future<ProvisionAdminResult> provisionCollegeAdmin(
    String collegeId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.dio.post('/colleges/$collegeId/admins', data: data);
      final body = response.data;
      final payload = (body is Map<String, dynamic> && body['data'] != null)
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;
      return ProvisionAdminResult.fromJson(payload);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to provision college admin');
    }
  }

  @override
  Future<void> addCollege(College college) async {
    try {
      // Send only backend-validated fields (not id/isActive which are backend-controlled)
      await _client.dio.post('/colleges', data: {
        'name': college.name,
        'code': college.code,
        'address': college.address,
        'email': college.email,
        'phone': college.phone,
        'principal': college.principal,
        if (college.logoUrl != null) 'logoUrl': college.logoUrl,
      });
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
  // ===========================================================================
  // 2. DEPARTMENTS
  // ===========================================================================

  @override
  Future<List<Department>> getDepartments({String? collegeId, String? search, String? status}) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': 100,
        if (collegeId != null && collegeId.isNotEmpty) 'collegeId': collegeId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      };
      final response = await _client.dio.get('/departments', queryParameters: queryParams);
      final body = response.data;
      List raw = [];
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic> && data['items'] is List) {
          raw = data['items'] as List;
        } else if (data is List) {
          raw = data;
        }
      } else if (body is List) {
        raw = body;
      }

      return raw.map((e) => Department.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch departments');
    }
  }

  @override
  Future<Department> getDepartmentById(String id) async {
    try {
      final response = await _client.dio.get('/departments/$id');
      final body = response.data;
      final data = (body is Map<String, dynamic> && body['data'] != null)
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;
      return Department.fromJson(data);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to fetch department');
    }
  }

  @override
  Future<Map<String, dynamic>> getDepartmentSummary(String id) async {
    try {
      final response = await _client.dio.get('/departments/$id/summary');
      final body = response.data;
      final data = (body is Map<String, dynamic> && body['data'] != null)
          ? body['data'] as Map<String, dynamic>
          : (body is Map<String, dynamic> ? body : <String, dynamic>{});
      return data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return {};
      }
      throw _extractError(e, 'Failed to fetch department summary');
    }
  }

  @override
  Future<Map<String, dynamic>?> getDepartmentHod(String departmentId) async {
    try {
      final response = await _client.dio.get('/departments/$departmentId/hod');
      final body = response.data;
      if (body is Map<String, dynamic> && body['data'] != null) {
        return body['data'] as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return null;
      }
      throw _extractError(e, 'Failed to fetch department HOD');
    }
  }

  @override
  Future<void> addDepartment(Department department) async {
    try {
      await _client.dio.post('/departments', data: {
        'name': department.name,
        'code': department.code,
        if (department.description.isNotEmpty) 'description': department.description,
        if (department.collegeId.isNotEmpty) 'collegeId': department.collegeId,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create department');
    }
  }

  @override
  Future<void> updateDepartment(Department department) async {
    try {
      await _client.dio.put('/departments/${department.id}', data: {
        'name': department.name,
        'code': department.code,
        'description': department.description,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update department');
    }
  }

  @override
  Future<void> updateDepartmentStatus(String id, String status) async {
    try {
      await _client.dio.patch('/departments/$id/status', data: {'status': status});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update department status');
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
  // 2b. HEADS OF DEPARTMENT (HOD)
  // ===========================================================================

  @override
  Future<ProvisionHodResult> provisionHod({
    required String departmentId,
    required String name,
    required String instituteId,
    required String email,
    String? phone,
  }) async {
    try {
      final response = await _client.dio.post('/academics/hods', data: {
        'departmentId': departmentId,
        'name': name,
        'instituteId': instituteId,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      final body = response.data;
      final data = (body is Map<String, dynamic> && body['data'] != null)
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;
      return ProvisionHodResult.fromJson(data);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to provision HOD');
    }
  }

  @override
  Future<List<UserModel>> getHods({String? departmentId, String? search, String? status}) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': 100,
        if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      };
      final response = await _client.dio.get('/academics/hods', queryParameters: queryParams);
      final body = response.data;
      List raw = [];
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic> && data['items'] is List) {
          raw = data['items'] as List;
        } else if (data is List) {
          raw = data;
        }
      } else if (body is List) {
        raw = body;
      }

      return raw.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch HODs');
    }
  }

  @override
  Future<UserModel> getHodById(String id) async {
    try {
      final response = await _client.dio.get('/academics/hods/$id');
      final body = response.data;
      final data = (body is Map<String, dynamic> && body['data'] != null)
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to fetch HOD details');
    }
  }

  @override
  Future<void> updateHodProfile(String id, {String? name, String? email, String? phone}) async {
    try {
      await _client.dio.put('/academics/hods/$id', data: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update HOD profile');
    }
  }

  @override
  Future<void> transferHodDepartment(String id, String targetDepartmentId) async {
    try {
      await _client.dio.patch('/academics/hods/$id/department', data: {
        'departmentId': targetDepartmentId,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to transfer HOD department');
    }
  }

  @override
  Future<Map<String, dynamic>> getHodSummary(String id) async {
    try {
      final response = await _client.dio.get('/academics/hods/$id/summary');
      final body = response.data;
      final data = (body is Map<String, dynamic> && body['data'] != null)
          ? body['data'] as Map<String, dynamic>
          : (body is Map<String, dynamic> ? body : <String, dynamic>{});
      return data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return {};
      }
      throw _extractError(e, 'Failed to fetch HOD summary');
    }
  }

  // ===========================================================================
  // 3. COURSES / PROGRAMS
  // ===========================================================================

  @override
  Future<List<Course>> getCourses({String? collegeId, String? departmentId, String? search}) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': 100,
        if (collegeId != null && collegeId.isNotEmpty) 'collegeId': collegeId,
        if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final response = await _client.dio.get('/academics/courses', queryParameters: queryParams);
      final body = response.data;
      List raw = [];
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic> && data['items'] is List) {
          raw = data['items'] as List;
        } else if (data is List) {
          raw = data;
        }
      } else if (body is List) {
        raw = body;
      }

      return raw.map((e) => Course.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch courses');
    }
  }

  @override
  Future<Course> getCourseById(String id) async {
    try {
      final response = await _client.dio.get('/academics/courses/$id');
      final body = response.data;
      final data = (body is Map<String, dynamic> && body['data'] != null)
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;
      return Course.fromJson(data);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to fetch course');
    }
  }

  @override
  Future<void> addCourse(Course course) async {
    try {
      await _client.dio.post('/academics/courses', data: {
        'departmentId': course.departmentId,
        'name': course.name,
        'code': course.code,
        'duration': course.duration,
        if (course.collegeId.isNotEmpty) 'collegeId': course.collegeId,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create course');
    }
  }

  @override
  Future<void> updateCourse(Course course) async {
    try {
      await _client.dio.put('/academics/courses/${course.id}', data: {
        'name': course.name,
        'code': course.code,
        'duration': course.duration,
        'isActive': course.isActive,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update course');
    }
  }

  @override
  Future<void> updateCourseStatus(String id, bool isActive) async {
    try {
      await _client.dio.put('/academics/courses/$id', data: {'isActive': isActive});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update course status');
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
  Future<List<AcademicYear>> getAcademicYears({String? collegeId}) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': 100,
        if (collegeId != null && collegeId.isNotEmpty) 'collegeId': collegeId,
      };
      final response = await _client.dio.get('/academics/academic-years', queryParameters: queryParams);
      final body = response.data;
      List raw = [];
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic> && data['items'] is List) {
          raw = data['items'] as List;
        } else if (data is List) {
          raw = data;
        }
      } else if (body is List) {
        raw = body;
      }

      return raw.map((e) => AcademicYear.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch academic years');
    }
  }

  @override
  Future<AcademicYear> getAcademicYearById(String id) async {
    try {
      final response = await _client.dio.get('/academics/academic-years/$id');
      final body = response.data;
      final data = (body is Map<String, dynamic> && body['data'] != null)
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;
      return AcademicYear.fromJson(data);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to fetch academic year');
    }
  }

  @override
  Future<void> addAcademicYear(AcademicYear academicYear) async {
    try {
      await _client.dio.post('/academics/academic-years', data: {
        'name': academicYear.name,
        'startDate': academicYear.startDate.toIso8601String(),
        'endDate': academicYear.endDate.toIso8601String(),
        'isCurrent': academicYear.isCurrent,
        if (academicYear.collegeId.isNotEmpty) 'collegeId': academicYear.collegeId,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create academic year');
    }
  }

  @override
  Future<void> updateAcademicYear(AcademicYear academicYear) async {
    try {
      await _client.dio.put('/academics/academic-years/${academicYear.id}', data: {
        'name': academicYear.name,
        'startDate': academicYear.startDate.toIso8601String(),
        'endDate': academicYear.endDate.toIso8601String(),
        'isCurrent': academicYear.isCurrent,
        'isActive': academicYear.isActive,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update academic year');
    }
  }

  @override
  Future<void> setCurrentAcademicYear(String id) async {
    try {
      await _client.dio.put('/academics/academic-years/$id', data: {'isCurrent': true});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to set current academic year');
    }
  }

  @override
  Future<void> updateAcademicYearStatus(String id, bool isActive) async {
    try {
      await _client.dio.put('/academics/academic-years/$id', data: {'isActive': isActive});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update academic year status');
    }
  }

  @override
  Future<void> deactivateAcademicYear(String id) async {
    try {
      await _client.dio.put('/academics/academic-years/$id', data: {'isActive': false});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to deactivate academic year');
    }
  }

  @override
  Future<void> activateAcademicYear(String collegeId, String academicYearId) async {
    try {
      await _client.dio.put('/academics/academic-years/$academicYearId', data: {'isCurrent': true, 'isActive': true});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to activate academic year');
    }
  }

  // ===========================================================================
  // 5. SEMESTERS
  // ===========================================================================

  @override
  Future<List<Semester>> getSemesters({String? courseId, String? academicYearId, String? collegeId}) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': 100,
        if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
        if (academicYearId != null && academicYearId.isNotEmpty) 'academicYearId': academicYearId,
        if (collegeId != null && collegeId.isNotEmpty) 'collegeId': collegeId,
      };
      final response = await _client.dio.get('/academics/semesters', queryParameters: queryParams);
      final body = response.data;
      List raw = [];
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic> && data['items'] is List) {
          raw = data['items'] as List;
        } else if (data is List) {
          raw = data;
        }
      } else if (body is List) {
        raw = body;
      }

      return raw.map((e) => Semester.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch semesters');
    }
  }

  @override
  Future<Semester> getSemesterById(String id) async {
    try {
      final response = await _client.dio.get('/academics/semesters/$id');
      final body = response.data;
      final data = (body is Map<String, dynamic> && body['data'] != null)
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;
      return Semester.fromJson(data);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to fetch semester');
    }
  }

  @override
  Future<void> addSemester(Semester semester) async {
    try {
      await _client.dio.post('/academics/semesters', data: {
        'courseId': semester.courseId,
        'academicYearId': semester.academicYearId,
        'name': semester.name,
        'number': semester.number,
        if (semester.startDate != null) 'startDate': semester.startDate!.toIso8601String(),
        if (semester.endDate != null) 'endDate': semester.endDate!.toIso8601String(),
        'isCurrent': semester.isCurrent,
        if (semester.collegeId.isNotEmpty) 'collegeId': semester.collegeId,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create semester');
    }
  }

  @override
  Future<void> updateSemester(Semester semester) async {
    try {
      await _client.dio.put('/academics/semesters/${semester.id}', data: {
        'name': semester.name,
        'number': semester.number,
        if (semester.startDate != null) 'startDate': semester.startDate!.toIso8601String(),
        if (semester.endDate != null) 'endDate': semester.endDate!.toIso8601String(),
        'isCurrent': semester.isCurrent,
        'isActive': semester.isActive,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update semester');
    }
  }

  @override
  Future<void> updateSemesterStatus(String id, bool isActive) async {
    try {
      await _client.dio.put('/academics/semesters/$id', data: {'isActive': isActive});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update semester status');
    }
  }

  @override
  Future<void> toggleSemesterCurrent(String id, bool isCurrent) async {
    try {
      await _client.dio.put('/academics/semesters/$id', data: {'isCurrent': isCurrent});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update semester current state');
    }
  }

  @override
  Future<void> deactivateSemester(String id) async {
    try {
      await _client.dio.put('/academics/semesters/$id', data: {'isActive': false});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to deactivate semester');
    }
  }

  @override
  Future<void> activateSemester(String collegeId, String courseId, String semesterId) async {
    try {
      await _client.dio.put('/academics/semesters/$semesterId', data: {'isCurrent': true, 'isActive': true});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to activate semester');
    }
  }

  @override
  Future<void> completeSemester(String semesterId) async {
    try {
      await _client.dio.put('/academics/semesters/$semesterId', data: {'isCurrent': false, 'isActive': true});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to complete semester');
    }
  }

  // ===========================================================================
  // 6. SECTIONS
  // ===========================================================================

  @override
  Future<List<Section>> getSections({String? semesterId, String? courseId, String? collegeId}) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': 100,
        if (semesterId != null && semesterId.isNotEmpty) 'semesterId': semesterId,
        if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
        if (collegeId != null && collegeId.isNotEmpty) 'collegeId': collegeId,
      };
      final response = await _client.dio.get('/academics/sections', queryParameters: queryParams);
      final body = response.data;
      List raw = [];
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic> && data['items'] is List) {
          raw = data['items'] as List;
        } else if (data is List) {
          raw = data;
        }
      } else if (body is List) {
        raw = body;
      }

      return raw.map((e) => Section.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch sections');
    }
  }

  @override
  Future<Section> getSectionById(String id) async {
    try {
      final response = await _client.dio.get('/academics/sections/$id');
      final body = response.data;
      final data = (body is Map<String, dynamic> && body['data'] != null)
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;
      return Section.fromJson(data);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to fetch section');
    }
  }

  @override
  Future<void> addSection(Section section) async {
    try {
      await _client.dio.post('/academics/sections', data: {
        'courseId': section.courseId,
        'academicYearId': section.academicYearId,
        'semesterId': section.semesterId,
        'name': section.name,
        'capacity': section.capacity,
        if (section.collegeId.isNotEmpty) 'collegeId': section.collegeId,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create section');
    }
  }

  @override
  Future<void> updateSection(Section section) async {
    try {
      await _client.dio.put('/academics/sections/${section.id}', data: {
        'name': section.name,
        'capacity': section.capacity,
        'isActive': section.isActive,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update section');
    }
  }

  @override
  Future<void> updateSectionStatus(String id, bool isActive) async {
    try {
      await _client.dio.put('/academics/sections/$id', data: {'isActive': isActive});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update section status');
    }
  }

  @override
  Future<void> deactivateSection(String id) async {
    try {
      await _client.dio.put('/academics/sections/$id', data: {'isActive': false});
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

  // ===========================================================================
  // 7. SUBJECTS
  // ===========================================================================

  @override
  Future<List<Subject>> getSubjects({String? semesterId, String? courseId, String? collegeId}) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': 100,
        if (semesterId != null && semesterId.isNotEmpty) 'semesterId': semesterId,
        if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
        if (collegeId != null && collegeId.isNotEmpty) 'collegeId': collegeId,
      };
      final response = await _client.dio.get('/academics/subjects', queryParameters: queryParams);
      final body = response.data;
      List raw = [];
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic> && data['items'] is List) {
          raw = data['items'] as List;
        } else if (data is List) {
          raw = data;
        }
      } else if (body is List) {
        raw = body;
      }

      return raw.map((e) => Subject.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch subjects');
    }
  }

  @override
  Future<Subject> getSubjectById(String id) async {
    try {
      final response = await _client.dio.get('/academics/subjects/$id');
      final body = response.data;
      final data = (body is Map<String, dynamic> && body['data'] != null)
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;
      return Subject.fromJson(data);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to fetch subject');
    }
  }

  @override
  Future<void> addSubject(Subject subject) async {
    try {
      await _client.dio.post('/academics/subjects', data: {
        'courseId': subject.courseId,
        'semesterId': subject.semesterId,
        'name': subject.name,
        'code': subject.code,
        'credits': subject.credits,
        'type': subject.type,
        if (subject.collegeId.isNotEmpty) 'collegeId': subject.collegeId,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to create subject');
    }
  }

  @override
  Future<void> updateSubject(Subject subject) async {
    try {
      await _client.dio.put('/academics/subjects/${subject.id}', data: {
        'name': subject.name,
        'code': subject.code,
        'credits': subject.credits,
        'type': subject.type,
        'isActive': subject.isActive,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update subject');
    }
  }

  @override
  Future<void> updateSubjectStatus(String id, bool isActive) async {
    try {
      await _client.dio.put('/academics/subjects/$id', data: {'isActive': isActive});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update subject status');
    }
  }

  @override
  Future<void> deactivateSubject(String id) async {
    try {
      await _client.dio.put('/academics/subjects/$id', data: {'isActive': false});
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to deactivate subject');
    }
  }

  // ===========================================================================
  // 8. FACULTY
  // ===========================================================================

  @override
  Future<List<Faculty>> getFaculty({String? departmentId, String? search, String? status}) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': 100,
        if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      };
      final response = await _client.dio.get('/academics/faculty', queryParameters: queryParams);
      final body = response.data;
      List raw = [];
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic> && data['items'] is List) {
          raw = data['items'] as List;
        } else if (data is List) {
          raw = data;
        }
      } else if (body is List) {
        raw = body;
      }

      return raw.map((e) => Faculty.fromJson(e as Map<String, dynamic>)).toList();
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
      final body = response.data;
      final data = (body is Map<String, dynamic> && body['data'] != null)
          ? body['data'] as Map<String, dynamic>
          : (body is Map<String, dynamic> ? body : <String, dynamic>{});
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
      await _client.dio.put('/academics/faculty/${faculty.id}', data: {
        'name': faculty.name,
        'email': faculty.email,
        if (faculty.phone.isNotEmpty) 'phone': faculty.phone,
        if (faculty.employeeId.isNotEmpty) 'employeeId': faculty.employeeId,
        if (faculty.designation != null) 'designation': faculty.designation,
        if (faculty.qualification != null) 'qualification': faculty.qualification,
        if (faculty.specialization != null) 'specialization': faculty.specialization,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update faculty profile');
    }
  }

  @override
  Future<Map<String, dynamic>> getFacultySummary(String id) async {
    try {
      final response = await _client.dio.get('/academics/faculty/$id/summary');
      final body = response.data;
      final data = (body is Map<String, dynamic> && body['data'] != null)
          ? body['data'] as Map<String, dynamic>
          : (body is Map<String, dynamic> ? body : <String, dynamic>{});
      return data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return {};
      }
      throw _extractError(e, 'Failed to fetch faculty summary');
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
      final queryParams = <String, dynamic>{
        'limit': 100,
        if (facultyId != null && facultyId.isNotEmpty) 'facultyId': facultyId,
        if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
        if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
        if (semesterId != null && semesterId.isNotEmpty) 'semesterId': semesterId,
        if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
        if (subjectId != null && subjectId.isNotEmpty) 'subjectId': subjectId,
        if (academicYearId != null && academicYearId.isNotEmpty) 'academicYearId': academicYearId,
      };
      final response = await _client.dio.get('/academics/faculty-assignments', queryParameters: queryParams);
      final body = response.data;
      List raw = [];
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic> && data['items'] is List) {
          raw = data['items'] as List;
        } else if (data is List) {
          raw = data;
        }
      } else if (body is List) {
        raw = body;
      }

      return raw.map((e) => FacultyAssignment.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch faculty assignments');
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
    try {
      await _client.dio.delete('/academics/faculty-assignments/$assignmentId');
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to remove faculty assignment');
    }
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
    try {
      final queryParams = <String, dynamic>{
        if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
      };
      final response = await _client.dio.get('/academics/faculty-assignments/workload', queryParameters: queryParams);
      final body = response.data;
      List raw = [];
      if (body is Map<String, dynamic> && body['data'] is List) {
        raw = body['data'] as List;
      } else if (body is List) {
        raw = body;
      }
      return raw.map((e) {
        final m = e as Map<String, dynamic>;
        return FacultyWorkloadSummary(
          facultyId: m['facultyId'] ?? '',
          facultyName: m['facultyName'] ?? '',
          employeeId: m['employeeId'] ?? '',
          departmentId: m['departmentId'] ?? '',
          subjectsAssigned: m['assignedSubjectCount'] ?? 0,
          sectionsAssigned: m['assignedSectionCount'] ?? 0,
          weeklyClasses: (m['assignedSubjectCount'] ?? 0) * 4,
        );
      }).toList();
    } catch (_) {
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
  }

  // ===========================================================================
  // 10. STUDENTS
  // ===========================================================================

  @override
  Future<List<Student>> getStudents({String? sectionId, String? departmentId, String? search, String? status}) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': 100,
      };
      if (sectionId != null && sectionId.isNotEmpty) queryParams['sectionId'] = sectionId;
      if (departmentId != null && departmentId.isNotEmpty) queryParams['departmentId'] = departmentId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final response = await _client.dio.get('/academics/students', queryParameters: queryParams);
      final body = response.data;
      final dynamic listRaw = (body is Map<String, dynamic> && body['data'] != null)
          ? (body['data'] is Map<String, dynamic> ? body['data']['items'] : body['data'])
          : (body is List ? body : []);
      final list = listRaw is List ? listRaw : [];

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
  Future<ProvisionStudentResult> provisionStudent(ProvisionStudentRequest request) async {
    try {
      final response = await _client.dio.post('/academics/students', data: request.toJson());
      final body = response.data as Map<String, dynamic>;
      final resultData = body['data'] as Map<String, dynamic>? ?? body;
      final result = ProvisionStudentResult.fromJson(resultData);

      // Perform initial enrollment if academic hierarchy was selected
      if (request.courseId != null &&
          request.academicYearId != null &&
          request.semesterId != null &&
          request.sectionId != null) {
        try {
          await enrollStudent(
            studentId: result.student.id,
            courseId: request.courseId!,
            academicYearId: request.academicYearId!,
            semesterId: request.semesterId!,
            sectionId: request.sectionId!,
          );
        } catch (_) {
          // Non-fatal if enrollment fails, student profile is already provisioned
        }
      }

      return result;
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to provision student');
    }
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
    try {
      await _client.dio.post('/academics/enrollments', data: {
        'studentId': studentId,
        'courseId': courseId,
        'academicYearId': academicYearId,
        'semesterId': semesterId,
        'sectionId': sectionId,
        if (enrollmentDate != null) 'enrollmentDate': enrollmentDate,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to enroll student in section');
    }
  }

  @override
  Future<void> transferStudentDepartment(String studentId, String newDepartmentId) async {
    try {
      await _client.dio.patch('/academics/students/$studentId/department', data: {
        'departmentId': newDepartmentId,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to transfer student department');
    }
  }

  @override
  Future<Map<String, dynamic>> getStudentSummary(String studentId) async {
    try {
      final response = await _client.dio.get('/academics/students/$studentId/summary');
      final body = response.data as Map<String, dynamic>;
      return body['data'] as Map<String, dynamic>? ?? body;
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to fetch student summary');
    }
  }

  @override
  Future<void> updateStudent(Student student) async {
    try {
      await _client.dio.put('/academics/students/${student.id}', data: {
        if (student.name.isNotEmpty) 'name': student.name,
        if (student.email.isNotEmpty) 'email': student.email,
        if (student.phone.isNotEmpty) 'phone': student.phone,
        if (student.rollNumber.isNotEmpty) 'rollNumber': student.rollNumber,
        if (student.admissionNumber != null && student.admissionNumber!.isNotEmpty) 'admissionNumber': student.admissionNumber,
        if (student.parentName != null) 'parentName': student.parentName,
        if (student.parentPhone != null) 'parentPhone': student.parentPhone,
        if (student.bloodGroup != null) 'bloodGroup': student.bloodGroup,
        if (student.address != null) 'address': student.address,
        if (student.dateOfBirth != null) 'dateOfBirth': student.dateOfBirth!.toIso8601String(),
        if (student.admissionDate != null) 'admissionDate': student.admissionDate!.toIso8601String(),
      });
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
