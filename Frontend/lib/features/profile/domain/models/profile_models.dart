import '../../../auth/domain/models/role_enum.dart';

class BaseUserProfileModel {
  final String id;
  final String instituteId;
  final String name;
  final String email;
  final String phone;
  final AppRole role;
  final String? profilePictureUrl;
  final String? bio;
  final String? collegeId;
  final String? collegeName;
  final String? departmentId;
  final String? departmentName;

  const BaseUserProfileModel({
    required this.id,
    required this.instituteId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profilePictureUrl,
    this.bio,
    this.collegeId,
    this.collegeName,
    this.departmentId,
    this.departmentName,
  });

  factory BaseUserProfileModel.fromJson(Map<String, dynamic> json) {
    return BaseUserProfileModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      instituteId: (json['instituteId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: AppRoleExtension.fromValue((json['role'] ?? 'STUDENT').toString()),
      profilePictureUrl: json['profilePictureUrl'] as String?,
      bio: json['bio'] as String?,
      collegeId: json['collegeId'] as String?,
      collegeName: json['collegeName'] as String?,
      departmentId: json['departmentId'] as String?,
      departmentName: json['departmentName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'instituteId': instituteId,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.value,
        'profilePictureUrl': profilePictureUrl,
        'bio': bio,
        'collegeId': collegeId,
        'collegeName': collegeName,
        'departmentId': departmentId,
        'departmentName': departmentName,
      };

  BaseUserProfileModel copyWith({
    String? id,
    String? instituteId,
    String? name,
    String? email,
    String? phone,
    AppRole? role,
    String? profilePictureUrl,
    String? bio,
    String? collegeId,
    String? collegeName,
    String? departmentId,
    String? departmentName,
  }) {
    return BaseUserProfileModel(
      id: id ?? this.id,
      instituteId: instituteId ?? this.instituteId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      bio: bio ?? this.bio,
      collegeId: collegeId ?? this.collegeId,
      collegeName: collegeName ?? this.collegeName,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
    );
  }
}

class CurrentEnrollmentSummaryModel {
  final String enrollmentId;
  final String courseId;
  final String courseName;
  final String courseCode;
  final String semesterId;
  final String semesterName;
  final int? semesterNumber;
  final String academicYearId;
  final String academicYearName;
  final String? sectionId;
  final String? sectionName;
  final String? academicStage;
  final String? cohort;
  final String status;

  const CurrentEnrollmentSummaryModel({
    required this.enrollmentId,
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.semesterId,
    required this.semesterName,
    this.semesterNumber,
    required this.academicYearId,
    required this.academicYearName,
    this.sectionId,
    this.sectionName,
    this.academicStage,
    this.cohort,
    required this.status,
  });

  factory CurrentEnrollmentSummaryModel.fromJson(Map<String, dynamic> json) {
    return CurrentEnrollmentSummaryModel(
      enrollmentId: (json['enrollmentId'] ?? json['id'] ?? '').toString(),
      courseId: (json['courseId'] ?? '').toString(),
      courseName: (json['courseName'] ?? '—').toString(),
      courseCode: (json['courseCode'] ?? '—').toString(),
      semesterId: (json['semesterId'] ?? '').toString(),
      semesterName: (json['semesterName'] ?? '—').toString(),
      semesterNumber: (json['semesterNumber'] as num?)?.toInt(),
      academicYearId: (json['academicYearId'] ?? '').toString(),
      academicYearName: (json['academicYearName'] ?? '—').toString(),
      sectionId: json['sectionId']?.toString(),
      sectionName: json['sectionName']?.toString(),
      academicStage: json['academicStage']?.toString(),
      cohort: json['cohort']?.toString(),
      status: (json['status'] ?? 'active').toString(),
    );
  }
}

class StudentRoleProfileModel {
  final String studentId;
  final String? rollNumber;
  final String? admissionNumber;
  final String? academicStage;
  final String? cohort;
  final bool isEnrollmentAvailable;
  final CurrentEnrollmentSummaryModel? currentEnrollment;

  const StudentRoleProfileModel({
    required this.studentId,
    this.rollNumber,
    this.admissionNumber,
    this.academicStage,
    this.cohort,
    required this.isEnrollmentAvailable,
    this.currentEnrollment,
  });

  factory StudentRoleProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentRoleProfileModel(
      studentId: (json['studentId'] ?? '').toString(),
      rollNumber: json['rollNumber'] as String?,
      admissionNumber: json['admissionNumber'] as String?,
      academicStage: json['academicStage'] as String?,
      cohort: json['cohort'] as String?,
      isEnrollmentAvailable: json['isEnrollmentAvailable'] == true,
      currentEnrollment: json['currentEnrollment'] != null
          ? CurrentEnrollmentSummaryModel.fromJson(
              json['currentEnrollment'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TeachingAssignmentSummaryModel {
  final String assignmentId;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String courseId;
  final String courseName;
  final String semesterId;
  final String semesterName;
  final String? sectionId;
  final String? sectionName;
  final String? assignmentType;

  const TeachingAssignmentSummaryModel({
    required this.assignmentId,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.courseId,
    required this.courseName,
    required this.semesterId,
    required this.semesterName,
    this.sectionId,
    this.sectionName,
    this.assignmentType,
  });

  factory TeachingAssignmentSummaryModel.fromJson(Map<String, dynamic> json) {
    return TeachingAssignmentSummaryModel(
      assignmentId: (json['assignmentId'] ?? '').toString(),
      subjectId: (json['subjectId'] ?? '').toString(),
      subjectName: (json['subjectName'] ?? '—').toString(),
      subjectCode: (json['subjectCode'] ?? '—').toString(),
      courseId: (json['courseId'] ?? '').toString(),
      courseName: (json['courseName'] ?? '—').toString(),
      semesterId: (json['semesterId'] ?? '').toString(),
      semesterName: (json['semesterName'] ?? '—').toString(),
      sectionId: json['sectionId']?.toString(),
      sectionName: json['sectionName']?.toString(),
      assignmentType: json['assignmentType'] as String?,
    );
  }
}

class FacultyRoleProfileModel {
  final String facultyId;
  final String? employeeId;
  final String? designation;
  final String? qualification;
  final String? specialization;
  final DateTime? joiningDate;
  final List<TeachingAssignmentSummaryModel> activeAssignments;

  const FacultyRoleProfileModel({
    required this.facultyId,
    this.employeeId,
    this.designation,
    this.qualification,
    this.specialization,
    this.joiningDate,
    this.activeAssignments = const [],
  });

  factory FacultyRoleProfileModel.fromJson(Map<String, dynamic> json) {
    final assignmentsList = json['activeAssignments'] as List<dynamic>? ?? [];
    return FacultyRoleProfileModel(
      facultyId: (json['facultyId'] ?? '').toString(),
      employeeId: json['employeeId'] as String?,
      designation: json['designation'] as String?,
      qualification: json['qualification'] as String?,
      specialization: json['specialization'] as String?,
      joiningDate: json['joiningDate'] != null
          ? DateTime.tryParse(json['joiningDate'].toString())
          : null,
      activeAssignments: assignmentsList
          .map((a) => TeachingAssignmentSummaryModel.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HodRoleProfileModel {
  final String? facultyId;
  final String departmentId;
  final String departmentName;
  final String departmentCode;
  final String? designation;
  final int programsCount;
  final int facultyCount;
  final int studentsCount;

  const HodRoleProfileModel({
    this.facultyId,
    required this.departmentId,
    required this.departmentName,
    required this.departmentCode,
    this.designation,
    required this.programsCount,
    required this.facultyCount,
    required this.studentsCount,
  });

  factory HodRoleProfileModel.fromJson(Map<String, dynamic> json) {
    final scope = json['managedScope'] as Map<String, dynamic>? ?? {};
    return HodRoleProfileModel(
      facultyId: json['facultyId'] as String?,
      departmentId: (json['departmentId'] ?? '').toString(),
      departmentName: (json['departmentName'] ?? '—').toString(),
      departmentCode: (json['departmentCode'] ?? '—').toString(),
      designation: json['designation'] as String?,
      programsCount: (scope['programsCount'] as num?)?.toInt() ?? 0,
      facultyCount: (scope['facultyCount'] as num?)?.toInt() ?? 0,
      studentsCount: (scope['studentsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class CollegeAdminRoleProfileModel {
  final String collegeId;
  final String collegeName;
  final String collegeCode;
  final int departmentsCount;
  final int facultyCount;
  final int studentsCount;

  const CollegeAdminRoleProfileModel({
    required this.collegeId,
    required this.collegeName,
    required this.collegeCode,
    required this.departmentsCount,
    required this.facultyCount,
    required this.studentsCount,
  });

  factory CollegeAdminRoleProfileModel.fromJson(Map<String, dynamic> json) {
    final scope = json['administrativeScope'] as Map<String, dynamic>? ?? {};
    return CollegeAdminRoleProfileModel(
      collegeId: (json['collegeId'] ?? '').toString(),
      collegeName: (json['collegeName'] ?? '—').toString(),
      collegeCode: (json['collegeCode'] ?? '—').toString(),
      departmentsCount: (scope['departmentsCount'] as num?)?.toInt() ?? 0,
      facultyCount: (scope['facultyCount'] as num?)?.toInt() ?? 0,
      studentsCount: (scope['studentsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class SuperAdminRoleProfileModel {
  final String scope;

  const SuperAdminRoleProfileModel({required this.scope});

  factory SuperAdminRoleProfileModel.fromJson(Map<String, dynamic> json) {
    return SuperAdminRoleProfileModel(
      scope: (json['scope'] ?? 'GLOBAL').toString(),
    );
  }
}

class RoleProfileCompositeModel {
  final StudentRoleProfileModel? student;
  final FacultyRoleProfileModel? faculty;
  final HodRoleProfileModel? hod;
  final CollegeAdminRoleProfileModel? collegeAdmin;
  final SuperAdminRoleProfileModel? superAdmin;

  const RoleProfileCompositeModel({
    this.student,
    this.faculty,
    this.hod,
    this.collegeAdmin,
    this.superAdmin,
  });

  factory RoleProfileCompositeModel.fromJson(Map<String, dynamic> json) {
    return RoleProfileCompositeModel(
      student: json['student'] != null
          ? StudentRoleProfileModel.fromJson(json['student'] as Map<String, dynamic>)
          : null,
      faculty: json['faculty'] != null
          ? FacultyRoleProfileModel.fromJson(json['faculty'] as Map<String, dynamic>)
          : null,
      hod: json['hod'] != null
          ? HodRoleProfileModel.fromJson(json['hod'] as Map<String, dynamic>)
          : null,
      collegeAdmin: json['collegeAdmin'] != null
          ? CollegeAdminRoleProfileModel.fromJson(json['collegeAdmin'] as Map<String, dynamic>)
          : null,
      superAdmin: json['superAdmin'] != null
          ? SuperAdminRoleProfileModel.fromJson(json['superAdmin'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ProfileCompletionModel {
  final int percentage;
  final List<String> completedFields;
  final List<String> missingFields;

  const ProfileCompletionModel({
    required this.percentage,
    this.completedFields = const [],
    this.missingFields = const [],
  });

  factory ProfileCompletionModel.fromJson(Map<String, dynamic> json) {
    return ProfileCompletionModel(
      percentage: (json['percentage'] as num?)?.toInt() ?? 100,
      completedFields: (json['completedFields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      missingFields: (json['missingFields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class ComposedProfileModel {
  final BaseUserProfileModel user;
  final RoleProfileCompositeModel roleProfile;
  final ProfileCompletionModel completion;
  final List<String> editableFields;

  const ComposedProfileModel({
    required this.user,
    required this.roleProfile,
    required this.completion,
    this.editableFields = const [],
  });

  factory ComposedProfileModel.fromJson(Map<String, dynamic> json) {
    return ComposedProfileModel(
      user: BaseUserProfileModel.fromJson(json['user'] as Map<String, dynamic>),
      roleProfile: RoleProfileCompositeModel.fromJson(
          json['roleProfile'] as Map<String, dynamic>? ?? {}),
      completion: ProfileCompletionModel.fromJson(
          json['completion'] as Map<String, dynamic>? ?? {}),
      editableFields: (json['editableFields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
