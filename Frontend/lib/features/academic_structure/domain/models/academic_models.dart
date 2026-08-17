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
  final String departmentId;
  final String name;
  final String code;
  final bool isActive;

  Course({
    required this.id,
    required this.departmentId,
    required this.name,
    required this.code,
    this.isActive = true,
  });

  Course copyWith({
    String? id,
    String? departmentId,
    String? name,
    String? code,
    bool? isActive,
  }) {
    return Course(
      id: id ?? this.id,
      departmentId: departmentId ?? this.departmentId,
      name: name ?? this.name,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
  final bool isActive;

  AcademicYear({
    required this.id,
    required this.collegeId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  AcademicYear copyWith({
    String? id,
    String? collegeId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return AcademicYear(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
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
      'isActive': isActive,
    };
  }
}

class Semester {
  final String id;
  final String courseId;
  final String academicYearId;
  final String name;
  final int number;
  final bool isActive;

  Semester({
    required this.id,
    required this.courseId,
    required this.academicYearId,
    required this.name,
    required this.number,
    this.isActive = true,
  });

  Semester copyWith({
    String? id,
    String? courseId,
    String? academicYearId,
    String? name,
    int? number,
    bool? isActive,
  }) {
    return Semester(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      academicYearId: academicYearId ?? this.academicYearId,
      name: name ?? this.name,
      number: number ?? this.number,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      academicYearId: json['academicYearId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      number: json['number'] as int? ?? 1,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'academicYearId': academicYearId,
      'name': name,
      'number': number,
      'isActive': isActive,
    };
  }
}

class Section {
  final String id;
  final String semesterId;
  final String name;
  final bool isActive;

  Section({
    required this.id,
    required this.semesterId,
    required this.name,
    this.isActive = true,
  });

  Section copyWith({
    String? id,
    String? semesterId,
    String? name,
    bool? isActive,
  }) {
    return Section(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'] as String? ?? '',
      semesterId: json['semesterId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semesterId': semesterId,
      'name': name,
      'isActive': isActive,
    };
  }
}

class Subject {
  final String id;
  final String departmentId;
  final String semesterId;
  final String name;
  final String code;
  final int credits;
  final String type;
  final bool isActive;

  Subject({
    required this.id,
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

class AcademicHistory {
  final String semesterId;
  final String sectionId;
  final String status;

  AcademicHistory({
    required this.semesterId,
    required this.sectionId,
    required this.status,
  });

  factory AcademicHistory.fromJson(Map<String, dynamic> json) {
    return AcademicHistory(
      semesterId: json['semesterId'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semesterId': semesterId,
      'sectionId': sectionId,
      'status': status,
    };
  }
}

class Student {
  final String id;
  final String collegeId;
  final String departmentId;
  final String courseId;
  final String semesterId;
  final String sectionId;
  final String name;
  final String rollNumber;
  final String email;
  final String phone;
  final bool isActive;
  final List<AcademicHistory> history;

  Student({
    required this.id,
    required this.collegeId,
    required this.departmentId,
    required this.courseId,
    required this.semesterId,
    required this.sectionId,
    required this.name,
    required this.rollNumber,
    required this.email,
    required this.phone,
    this.isActive = true,
    this.history = const [],
  });

  Student copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? name,
    String? rollNumber,
    String? email,
    String? phone,
    bool? isActive,
    List<AcademicHistory>? history,
  }) {
    return Student(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      email: email ?? this.email,
      phone: phone ?? this.phone,
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
      semesterId: json['semesterId'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => AcademicHistory.fromJson(e as Map<String, dynamic>))
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
      'semesterId': semesterId,
      'sectionId': sectionId,
      'name': name,
      'rollNumber': rollNumber,
      'email': email,
      'phone': phone,
      'isActive': isActive,
      'history': history.map((h) => h.toJson()).toList(),
    };
  }
}