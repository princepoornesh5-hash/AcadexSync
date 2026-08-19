class College {
  final String id;
  final String name;
  final String code;
  final String address;
  final String email;
  final String phone;
  final String principal;
  final bool isActive;
  final String? logoUrl;

  College({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.email,
    required this.phone,
    required this.principal,
    this.isActive = true,
    this.logoUrl,
  });

  College copyWith({
    String? id,
    String? name,
    String? code,
    String? address,
    String? email,
    String? phone,
    String? principal,
    bool? isActive,
    String? logoUrl,
  }) {
    return College(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      principal: principal ?? this.principal,
      isActive: isActive ?? this.isActive,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      address: json['address'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      principal: json['principal'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      logoUrl: json['logoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'email': email,
      'phone': phone,
      'principal': principal,
      'isActive': isActive,
      if (logoUrl != null) 'logoUrl': logoUrl,
    };
  }
}

class Department {
  final String id;
  final String collegeId;
  final String name;
  final String code;
  final String hodId;
  final String description;
  final bool isActive;

  Department({
    required this.id,
    required this.collegeId,
    required this.name,
    required this.code,
    required this.hodId,
    required this.description,
    this.isActive = true,
  });

  Department copyWith({
    String? id,
    String? collegeId,
    String? name,
    String? code,
    String? hodId,
    String? description,
    bool? isActive,
  }) {
    return Department(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      name: name ?? this.name,
      code: code ?? this.code,
      hodId: hodId ?? this.hodId,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      hodId: json['hodId'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'name': name,
      'code': code,
      'hodId': hodId,
      'description': description,
      'isActive': isActive,
    };
  }
}

class Course {
  final String id;
  final String collegeId;
  final String departmentId;
  final String name;
  final String code;
  final bool isActive;

  Course({
    required this.id,
    required this.collegeId,
    required this.departmentId,
    required this.name,
    required this.code,
    this.isActive = true,
  });

  Course copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? name,
    String? code,
    bool? isActive,
  }) {
    return Course(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      name: name ?? this.name,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'name': name,
      'code': code,
      'isActive': isActive,
    };
  }
}

class AcademicYear {
  final String id;
  final String collegeId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'upcoming', 'active', 'completed', 'archived'
  final bool isCurrent;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  AcademicYear({
    required this.id,
    required this.collegeId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.status = 'upcoming',
    this.isCurrent = false,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  AcademicYear copyWith({
    String? id,
    String? collegeId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    bool? isCurrent,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return AcademicYear(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory AcademicYear.fromJson(Map<String, dynamic> json) {
    return AcademicYear(
      id: json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : DateTime.now(),
      status: json['status'] as String? ?? (json['isActive'] == true ? 'active' : 'upcoming'),
      isCurrent: json['isCurrent'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'isCurrent': isCurrent,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class Semester {
  final String id;
  final String collegeId;
  final String departmentId;
  final String courseId;
  final String academicYearId;
  final String name;
  final int number;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status; // 'upcoming', 'active', 'completed', 'archived'
  final bool isCurrent;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Semester({
    required this.id,
    required this.collegeId,
    required this.departmentId,
    required this.courseId,
    required this.academicYearId,
    required this.name,
    required this.number,
    this.startDate,
    this.endDate,
    this.status = 'upcoming',
    this.isCurrent = false,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  int get semesterNumber => number;

  Semester copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? name,
    int? number,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    bool? isCurrent,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Semester(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      academicYearId: academicYearId ?? this.academicYearId,
      name: name ?? this.name,
      number: number ?? this.number,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      academicYearId: json['academicYearId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      number: json['number'] as int? ?? 1,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'] as String) : null,
      status: json['status'] as String? ?? (json['isActive'] == true ? 'active' : 'upcoming'),
      isCurrent: json['isCurrent'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'courseId': courseId,
      'academicYearId': academicYearId,
      'name': name,
      'number': number,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
      'isCurrent': isCurrent,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class Section {
  final String id;
  final String collegeId;
  final String departmentId;
  final String courseId;
  final String academicYearId;
  final String semesterId;
  final String name;
  final int capacity;
  final String status; // 'active', 'inactive', 'archived'
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Section({
    required this.id,
    required this.collegeId,
    required this.departmentId,
    this.courseId = '',
    this.academicYearId = '',
    required this.semesterId,
    required this.name,
    this.capacity = 60,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  Section copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? name,
    int? capacity,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Section(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      academicYearId: academicYearId ?? this.academicYearId,
      semesterId: semesterId ?? this.semesterId,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      academicYearId: json['academicYearId'] as String? ?? '',
      semesterId: json['semesterId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 60,
      status: json['status'] as String? ?? (json['isActive'] == false ? 'inactive' : 'active'),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'courseId': courseId,
      'academicYearId': academicYearId,
      'semesterId': semesterId,
      'name': name,
      'capacity': capacity,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class SectionCapacityInfo {
  final String sectionId;
  final String sectionName;
  final int enrolledCount;
  final int capacity;

  const SectionCapacityInfo({
    required this.sectionId,
    required this.sectionName,
    required this.enrolledCount,
    required this.capacity,
  });

  int get availableSeats => capacity > enrolledCount ? capacity - enrolledCount : 0;
  bool get isFull => enrolledCount >= capacity;
  double get utilizationPercentage => capacity > 0 ? ((enrolledCount / capacity) * 100).clamp(0.0, 100.0) : 0.0;
}

class SectionTransferValidationResult {
  final String studentId;
  final String studentName;
  final String rollNumber;
  final bool canMove;
  final String? reason;

  const SectionTransferValidationResult({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.canMove,
    this.reason,
  });
}

class Subject {
  final String id;
  final String collegeId;
  final String departmentId;
  final String semesterId;
  final String name;
  final String code;
  final int credits;
  final String type;
  final bool isActive;

  Subject({
    required this.id,
    required this.collegeId,
    required this.departmentId,
    required this.semesterId,
    required this.name,
    required this.code,
    required this.credits,
    required this.type,
    this.isActive = true,
  });

  Subject copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? semesterId,
    String? name,
    String? code,
    int? credits,
    String? type,
    bool? isActive,
  }) {
    return Subject(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      semesterId: semesterId ?? this.semesterId,
      name: name ?? this.name,
      code: code ?? this.code,
      credits: credits ?? this.credits,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      semesterId: json['semesterId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      credits: json['credits'] as int? ?? 0,
      type: json['type'] as String? ?? 'Theory',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'semesterId': semesterId,
      'name': name,
      'code': code,
      'credits': credits,
      'type': type,
      'isActive': isActive,
    };
  }
}

class Faculty {
  final String id;
  final String collegeId;
  final String departmentId;
  final String name;
  final String employeeId;
  final String email;
  final String phone;
  final bool isActive;
  final List<String> subjectIds;
  final List<String> sectionIds;

  Faculty({
    required this.id,
    required this.collegeId,
    required this.departmentId,
    required this.name,
    required this.employeeId,
    required this.email,
    required this.phone,
    this.isActive = true,
    this.subjectIds = const [],
    this.sectionIds = const [],
  });

  Faculty copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? name,
    String? employeeId,
    String? email,
    String? phone,
    bool? isActive,
    List<String>? subjectIds,
    List<String>? sectionIds,
  }) {
    return Faculty(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      name: name ?? this.name,
      employeeId: employeeId ?? this.employeeId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      subjectIds: subjectIds ?? this.subjectIds,
      sectionIds: sectionIds ?? this.sectionIds,
    );
  }

  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      id: json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      subjectIds: (json['subjectIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      sectionIds: (json['sectionIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'name': name,
      'employeeId': employeeId,
      'email': email,
      'phone': phone,
      'isActive': isActive,
      'subjectIds': subjectIds,
      'sectionIds': sectionIds,
    };
  }
}

enum StudentLifecycleState {
  applicant,
  admitted,
  active,
  onLeave,
  suspended,
  transferred,
  graduated,
  alumni;

  String get displayName {
    switch (this) {
      case StudentLifecycleState.applicant:
        return 'Applicant';
      case StudentLifecycleState.admitted:
        return 'Admitted';
      case StudentLifecycleState.active:
        return 'Active';
      case StudentLifecycleState.onLeave:
        return 'On Leave';
      case StudentLifecycleState.suspended:
        return 'Suspended';
      case StudentLifecycleState.transferred:
        return 'Transferred';
      case StudentLifecycleState.graduated:
        return 'Graduated';
      case StudentLifecycleState.alumni:
        return 'Alumni';
    }
  }

  bool isValidTransition(StudentLifecycleState target) {
    if (this == target) return true;
    switch (this) {
      case StudentLifecycleState.applicant:
        return target == StudentLifecycleState.admitted;
      case StudentLifecycleState.admitted:
        return target == StudentLifecycleState.active || target == StudentLifecycleState.transferred;
      case StudentLifecycleState.active:
        return target == StudentLifecycleState.onLeave ||
            target == StudentLifecycleState.suspended ||
            target == StudentLifecycleState.transferred ||
            target == StudentLifecycleState.graduated ||
            target == StudentLifecycleState.alumni;
      case StudentLifecycleState.onLeave:
        return target == StudentLifecycleState.active ||
            target == StudentLifecycleState.suspended ||
            target == StudentLifecycleState.transferred;
      case StudentLifecycleState.suspended:
        return target == StudentLifecycleState.active || target == StudentLifecycleState.transferred;
      case StudentLifecycleState.transferred:
        return target == StudentLifecycleState.active || target == StudentLifecycleState.alumni;
      case StudentLifecycleState.graduated:
        return target == StudentLifecycleState.alumni;
      case StudentLifecycleState.alumni:
        return false; // Terminal state
    }
  }

  static StudentLifecycleState fromString(String? value) {
    if (value == null) return StudentLifecycleState.active;
    return StudentLifecycleState.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => StudentLifecycleState.active,
    );
  }
}

class AcademicTimelineRecord {
  final String id;
  final String academicYearId;
  final String academicYearName;
  final String semesterId;
  final String semesterName;
  final String sectionId;
  final String sectionName;
  final String departmentId;
  final String courseId;
  final String status;
  final DateTime? termStartDate;
  final DateTime? termEndDate;
  final double? attendancePercentage;
  final String? remarks;

  AcademicTimelineRecord({
    required this.id,
    required this.academicYearId,
    this.academicYearName = '',
    required this.semesterId,
    this.semesterName = '',
    required this.sectionId,
    this.sectionName = '',
    this.departmentId = '',
    this.courseId = '',
    required this.status,
    this.termStartDate,
    this.termEndDate,
    this.attendancePercentage,
    this.remarks,
  });

  factory AcademicTimelineRecord.fromJson(Map<String, dynamic> json) {
    return AcademicTimelineRecord(
      id: json['id'] as String? ?? '',
      academicYearId: json['academicYearId'] as String? ?? '',
      academicYearName: json['academicYearName'] as String? ?? '',
      semesterId: json['semesterId'] as String? ?? '',
      semesterName: json['semesterName'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      sectionName: json['sectionName'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      status: json['status'] as String? ?? 'Active',
      termStartDate: json['termStartDate'] != null ? DateTime.tryParse(json['termStartDate'] as String) : null,
      termEndDate: json['termEndDate'] != null ? DateTime.tryParse(json['termEndDate'] as String) : null,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble(),
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'academicYearId': academicYearId,
      'academicYearName': academicYearName,
      'semesterId': semesterId,
      'semesterName': semesterName,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'departmentId': departmentId,
      'courseId': courseId,
      'status': status,
      'termStartDate': termStartDate?.toIso8601String(),
      'termEndDate': termEndDate?.toIso8601String(),
      'attendancePercentage': attendancePercentage,
      'remarks': remarks,
    };
  }
}

class StudentAcademicHistory {
  final String id;
  final String studentUid;
  final String collegeId;
  final String departmentId;
  final String courseId;
  final String academicYearId;
  final String semesterId;
  final String sectionId;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final DateTime createdAt;

  StudentAcademicHistory({
    required this.id,
    required this.studentUid,
    required this.collegeId,
    required this.departmentId,
    required this.courseId,
    required this.academicYearId,
    required this.semesterId,
    required this.sectionId,
    required this.startDate,
    this.endDate,
    this.status = 'active',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  StudentAcademicHistory copyWith({
    String? id,
    String? studentUid,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    DateTime? createdAt,
  }) {
    return StudentAcademicHistory(
      id: id ?? this.id,
      studentUid: studentUid ?? this.studentUid,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      academicYearId: academicYearId ?? this.academicYearId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory StudentAcademicHistory.fromJson(Map<String, dynamic> json) {
    return StudentAcademicHistory(
      id: json['id'] as String? ?? '',
      studentUid: (json['studentUid'] ?? json['studentId']) as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      academicYearId: json['academicYearId'] as String? ?? '',
      semesterId: json['semesterId'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      startDate: json['startDate'] != null
          ? (json['startDate'] is String
              ? DateTime.parse(json['startDate'] as String)
              : (json['startDate'] as dynamic).toDate())
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? (json['endDate'] is String
              ? DateTime.tryParse(json['endDate'] as String)
              : (json['endDate'] as dynamic).toDate())
          : null,
      status: json['status'] as String? ?? 'active',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
              ? DateTime.parse(json['createdAt'] as String)
              : (json['createdAt'] as dynamic).toDate())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentUid': studentUid,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'courseId': courseId,
      'academicYearId': academicYearId,
      'semesterId': semesterId,
      'sectionId': sectionId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// Alias for backward compatibility
typedef AcademicHistory = AcademicTimelineRecord;

class Student {
  final String id;
  final String collegeId;
  final String departmentId;
  final String courseId;
  final String academicYearId;
  final String semesterId;
  final String sectionId;
  final String name;
  final String rollNumber;
  final String email;
  final String phone;
  final StudentLifecycleState lifecycleState;
  final DateTime? admissionDate;
  final DateTime? graduationDate;
  final String? parentName;
  final String? parentPhone;
  final String? bloodGroup;
  final String? address;
  final DateTime? dateOfBirth;
  final bool isActive;
  final List<AcademicTimelineRecord> history;

  Student({
    required this.id,
    required this.collegeId,
    required this.departmentId,
    required this.courseId,
    this.academicYearId = '',
    required this.semesterId,
    required this.sectionId,
    required this.name,
    required this.rollNumber,
    required this.email,
    required this.phone,
    this.lifecycleState = StudentLifecycleState.active,
    this.admissionDate,
    this.graduationDate,
    this.parentName,
    this.parentPhone,
    this.bloodGroup,
    this.address,
    this.dateOfBirth,
    this.isActive = true,
    this.history = const [],
  });

  Student copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    String? name,
    String? rollNumber,
    String? email,
    String? phone,
    StudentLifecycleState? lifecycleState,
    DateTime? admissionDate,
    DateTime? graduationDate,
    String? parentName,
    String? parentPhone,
    String? bloodGroup,
    String? address,
    DateTime? dateOfBirth,
    bool? isActive,
    List<AcademicTimelineRecord>? history,
  }) {
    return Student(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      academicYearId: academicYearId ?? this.academicYearId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      lifecycleState: lifecycleState ?? this.lifecycleState,
      admissionDate: admissionDate ?? this.admissionDate,
      graduationDate: graduationDate ?? this.graduationDate,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isActive: isActive ?? this.isActive,
      history: history ?? this.history,
    );
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      academicYearId: json['academicYearId'] as String? ?? '',
      semesterId: json['semesterId'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      lifecycleState: json['lifecycleState'] != null
          ? StudentLifecycleState.fromString(json['lifecycleState'] as String)
          : (json['isActive'] == false ? StudentLifecycleState.alumni : StudentLifecycleState.active),
      admissionDate: json['admissionDate'] != null ? DateTime.tryParse(json['admissionDate'] as String) : null,
      graduationDate: json['graduationDate'] != null ? DateTime.tryParse(json['graduationDate'] as String) : null,
      parentName: json['parentName'] as String?,
      parentPhone: json['parentPhone'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      address: json['address'] as String?,
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth'] as String) : null,
      isActive: json['isActive'] as bool? ?? true,
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => AcademicTimelineRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'courseId': courseId,
      'academicYearId': academicYearId,
      'semesterId': semesterId,
      'sectionId': sectionId,
      'name': name,
      'rollNumber': rollNumber,
      'email': email,
      'phone': phone,
      'lifecycleState': lifecycleState.name,
      'admissionDate': admissionDate?.toIso8601String(),
      'graduationDate': graduationDate?.toIso8601String(),
      'parentName': parentName,
      'parentPhone': parentPhone,
      'bloodGroup': bloodGroup,
      'address': address,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'isActive': isActive,
      'history': history.map((h) => h.toJson()).toList(),
    };
  }
}

class StudentAcademicProfile {
  final Student student;
  final Department? department;
  final Course? course;
  final AcademicYear? academicYear;
  final Semester? semester;
  final Section? section;
  final List<Faculty> assignedFaculty;
  final List<Subject> enrolledSubjects;
  final double overallAttendancePercentage;
  final Map<String, double> subjectAttendanceMap;
  final int notesCount;
  final int certificatesCount;

  StudentAcademicProfile({
    required this.student,
    this.department,
    this.course,
    this.academicYear,
    this.semester,
    this.section,
    this.assignedFaculty = const [],
    this.enrolledSubjects = const [],
    this.overallAttendancePercentage = 0.0,
    this.subjectAttendanceMap = const {},
    this.notesCount = 0,
    this.certificatesCount = 0,
  });
}

class FacultyAssignment {
  final String id;
  final String collegeId;
  final String departmentId;
  final String facultyId;
  final String facultyName;
  final String courseId;
  final String semesterId;
  final String sectionId;
  final String subjectId;
  final String academicYearId;
  final bool isActive;
  final DateTime? assignedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? assignedBy;
  final String? createdBy;
  final String? roomId;
  final int? maxStudents;
  final String? assignmentType;

  FacultyAssignment({
    required this.id,
    required this.collegeId,
    required this.departmentId,
    required this.facultyId,
    required this.facultyName,
    required this.courseId,
    required this.semesterId,
    required this.sectionId,
    required this.subjectId,
    required this.academicYearId,
    this.isActive = true,
    this.assignedAt,
    this.createdAt,
    this.updatedAt,
    this.assignedBy,
    this.createdBy,
    this.roomId,
    this.maxStudents,
    this.assignmentType,
  });

  FacultyAssignment copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? facultyId,
    String? facultyName,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? subjectId,
    String? academicYearId,
    bool? isActive,
    DateTime? assignedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedBy,
    String? createdBy,
    String? roomId,
    int? maxStudents,
    String? assignmentType,
  }) {
    return FacultyAssignment(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      facultyId: facultyId ?? this.facultyId,
      facultyName: facultyName ?? this.facultyName,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      subjectId: subjectId ?? this.subjectId,
      academicYearId: academicYearId ?? this.academicYearId,
      isActive: isActive ?? this.isActive,
      assignedAt: assignedAt ?? this.assignedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedBy: assignedBy ?? this.assignedBy,
      createdBy: createdBy ?? this.createdBy ?? assignedBy ?? this.assignedBy,
      roomId: roomId ?? this.roomId,
      maxStudents: maxStudents ?? this.maxStudents,
      assignmentType: assignmentType ?? this.assignmentType,
    );
  }

  factory FacultyAssignment.fromJson(Map<String, dynamic> json) {
    final rawAssignedAt = json['assignedAt'] != null ? DateTime.tryParse(json['assignedAt'] as String) : null;
    final rawCreatedAt = json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : rawAssignedAt;
    final rawUpdatedAt = json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null;

    final creator = json['createdBy'] as String? ?? json['assignedBy'] as String?;

    return FacultyAssignment(
      id: json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      facultyId: json['facultyId'] as String? ?? '',
      facultyName: json['facultyName'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      semesterId: json['semesterId'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      academicYearId: json['academicYearId'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      assignedAt: rawAssignedAt,
      createdAt: rawCreatedAt,
      updatedAt: rawUpdatedAt,
      assignedBy: creator,
      createdBy: creator,
      roomId: json['roomId'] as String?,
      maxStudents: json['maxStudents'] as int?,
      assignmentType: json['assignmentType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'facultyId': facultyId,
      'facultyName': facultyName,
      'courseId': courseId,
      'semesterId': semesterId,
      'sectionId': sectionId,
      'subjectId': subjectId,
      'academicYearId': academicYearId,
      'isActive': isActive,
      'assignedAt': (assignedAt ?? createdAt)?.toIso8601String(),
      'createdAt': (createdAt ?? assignedAt)?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'assignedBy': assignedBy ?? createdBy,
      'createdBy': createdBy ?? assignedBy,
      if (roomId != null) 'roomId': roomId,
      if (maxStudents != null) 'maxStudents': maxStudents,
      if (assignmentType != null) 'assignmentType': assignmentType,
    };
  }

  bool isDuplicateOf(FacultyAssignment other) {
    return collegeId == other.collegeId &&
        departmentId == other.departmentId &&
        facultyId == other.facultyId &&
        courseId == other.courseId &&
        semesterId == other.semesterId &&
        sectionId == other.sectionId &&
        subjectId == other.subjectId &&
        academicYearId == other.academicYearId &&
        isActive && other.isActive;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacultyAssignment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class FacultyWorkloadSummary {
  final String facultyId;
  final String facultyName;
  final String employeeId;
  final String departmentId;
  final List<String> subjectNames;
  final List<String> sectionNames;
  final int subjectsAssigned;
  final int sectionsAssigned;
  final int weeklyClasses;
  final bool hasAttendanceResponsibility;
  final String status;
  final bool isActive;

  FacultyWorkloadSummary({
    required this.facultyId,
    required this.facultyName,
    required this.employeeId,
    required this.departmentId,
    this.subjectNames = const [],
    this.sectionNames = const [],
    this.subjectsAssigned = 0,
    this.sectionsAssigned = 0,
    this.weeklyClasses = 0,
    this.hasAttendanceResponsibility = true,
    this.status = 'active',
    this.isActive = true,
  });
}