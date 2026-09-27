enum InstitutionType {
  engineering('ENGINEERING', 'Engineering College'),
  polytechnic('POLYTECHNIC', 'Polytechnic College'),
  artsAndScience('ARTS_AND_SCIENCE', 'Arts & Science College'),
  university('UNIVERSITY', 'University / Autonomous Institute'),
  custom('CUSTOM', 'Custom Configuration');

  final String value;
  final String displayName;
  const InstitutionType(this.value, this.displayName);

  static InstitutionType fromValue(String? val) {
    if (val == null) return InstitutionType.engineering;
    return InstitutionType.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => InstitutionType.engineering,
    );
  }
}

enum AcademicConcept {
  department,
  program,
  academicYear,
  semester,
  section,
  subject,
  building,
  room,
}

class ConceptTerm {
  final String singular;
  final String plural;

  const ConceptTerm({
    required this.singular,
    required this.plural,
  });

  factory ConceptTerm.fromJson(Map<String, dynamic>? json, {required String defaultSingular, required String defaultPlural}) {
    if (json == null) {
      return ConceptTerm(singular: defaultSingular, plural: defaultPlural);
    }
    return ConceptTerm(
      singular: json['singular']?.toString().trim() ?? defaultSingular,
      plural: json['plural']?.toString().trim() ?? defaultPlural,
    );
  }

  Map<String, dynamic> toJson() => {
    'singular': singular,
    'plural': plural,
  };

  ConceptTerm copyWith({String? singular, String? plural}) {
    return ConceptTerm(
      singular: singular ?? this.singular,
      plural: plural ?? this.plural,
    );
  }
}

class AcademicStructureConfig {
  final bool program;
  final bool academicYear;
  final bool semester;
  final bool section;
  final bool subject;
  final bool building;
  final bool room;

  const AcademicStructureConfig({
    this.program = true,
    this.academicYear = true,
    this.semester = true,
    this.section = true,
    this.subject = true,
    this.building = true,
    this.room = true,
  });

  factory AcademicStructureConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AcademicStructureConfig();
    return AcademicStructureConfig(
      program: json['program'] as bool? ?? true,
      academicYear: json['academicYear'] as bool? ?? true,
      semester: json['semester'] as bool? ?? true,
      section: json['section'] as bool? ?? true,
      subject: json['subject'] as bool? ?? true,
      building: json['building'] as bool? ?? true,
      room: json['room'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'program': program,
    'academicYear': academicYear,
    'semester': semester,
    'section': section,
    'subject': subject,
    'building': building,
    'room': room,
  };

  AcademicStructureConfig copyWith({
    bool? program,
    bool? academicYear,
    bool? semester,
    bool? section,
    bool? subject,
    bool? building,
    bool? room,
  }) {
    return AcademicStructureConfig(
      program: program ?? this.program,
      academicYear: academicYear ?? this.academicYear,
      semester: semester ?? this.semester,
      section: section ?? this.section,
      subject: subject ?? this.subject,
      building: building ?? this.building,
      room: room ?? this.room,
    );
  }
}

class TerminologyConfig {
  final ConceptTerm department;
  final ConceptTerm program;
  final ConceptTerm academicYear;
  final ConceptTerm semester;
  final ConceptTerm section;
  final ConceptTerm subject;
  final ConceptTerm building;
  final ConceptTerm room;

  const TerminologyConfig({
    this.department = const ConceptTerm(singular: 'Department', plural: 'Departments'),
    this.program = const ConceptTerm(singular: 'Course', plural: 'Courses'),
    this.academicYear = const ConceptTerm(singular: 'Academic Year', plural: 'Academic Years'),
    this.semester = const ConceptTerm(singular: 'Semester', plural: 'Semesters'),
    this.section = const ConceptTerm(singular: 'Section', plural: 'Sections'),
    this.subject = const ConceptTerm(singular: 'Subject', plural: 'Subjects'),
    this.building = const ConceptTerm(singular: 'Building', plural: 'Buildings'),
    this.room = const ConceptTerm(singular: 'Room', plural: 'Rooms'),
  });

  factory TerminologyConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TerminologyConfig();
    return TerminologyConfig(
      department: ConceptTerm.fromJson(json['department'] as Map<String, dynamic>?, defaultSingular: 'Department', defaultPlural: 'Departments'),
      program: ConceptTerm.fromJson(json['program'] as Map<String, dynamic>?, defaultSingular: 'Course', defaultPlural: 'Courses'),
      academicYear: ConceptTerm.fromJson(json['academicYear'] as Map<String, dynamic>?, defaultSingular: 'Academic Year', defaultPlural: 'Academic Years'),
      semester: ConceptTerm.fromJson(json['semester'] as Map<String, dynamic>?, defaultSingular: 'Semester', defaultPlural: 'Semesters'),
      section: ConceptTerm.fromJson(json['section'] as Map<String, dynamic>?, defaultSingular: 'Section', defaultPlural: 'Sections'),
      subject: ConceptTerm.fromJson(json['subject'] as Map<String, dynamic>?, defaultSingular: 'Subject', defaultPlural: 'Subjects'),
      building: ConceptTerm.fromJson(json['building'] as Map<String, dynamic>?, defaultSingular: 'Building', defaultPlural: 'Buildings'),
      room: ConceptTerm.fromJson(json['room'] as Map<String, dynamic>?, defaultSingular: 'Room', defaultPlural: 'Rooms'),
    );
  }

  Map<String, dynamic> toJson() => {
    'department': department.toJson(),
    'program': program.toJson(),
    'academicYear': academicYear.toJson(),
    'semester': semester.toJson(),
    'section': section.toJson(),
    'subject': subject.toJson(),
    'building': building.toJson(),
    'room': room.toJson(),
  };

  ConceptTerm getTerm(AcademicConcept concept) {
    switch (concept) {
      case AcademicConcept.department:
        return department;
      case AcademicConcept.program:
        return program;
      case AcademicConcept.academicYear:
        return academicYear;
      case AcademicConcept.semester:
        return semester;
      case AcademicConcept.section:
        return section;
      case AcademicConcept.subject:
        return subject;
      case AcademicConcept.building:
        return building;
      case AcademicConcept.room:
        return room;
    }
  }

  TerminologyConfig copyWith({
    ConceptTerm? department,
    ConceptTerm? program,
    ConceptTerm? academicYear,
    ConceptTerm? semester,
    ConceptTerm? section,
    ConceptTerm? subject,
    ConceptTerm? building,
    ConceptTerm? room,
  }) {
    return TerminologyConfig(
      department: department ?? this.department,
      program: program ?? this.program,
      academicYear: academicYear ?? this.academicYear,
      semester: semester ?? this.semester,
      section: section ?? this.section,
      subject: subject ?? this.subject,
      building: building ?? this.building,
      room: room ?? this.room,
    );
  }
}

class AttendanceAlertsConfig {
  final bool enabled;
  final double warningPercentage;
  final double criticalPercentage;
  final bool absenceAlertsEnabled;

  const AttendanceAlertsConfig({
    this.enabled = true,
    this.warningPercentage = 75.0,
    this.criticalPercentage = 65.0,
    this.absenceAlertsEnabled = true,
  });

  factory AttendanceAlertsConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AttendanceAlertsConfig();
    return AttendanceAlertsConfig(
      enabled: json['enabled'] as bool? ?? true,
      warningPercentage: (json['warningPercentage'] as num?)?.toDouble() ?? 75.0,
      criticalPercentage: (json['criticalPercentage'] as num?)?.toDouble() ?? 65.0,
      absenceAlertsEnabled: json['absenceAlertsEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'warningPercentage': warningPercentage,
    'criticalPercentage': criticalPercentage,
    'absenceAlertsEnabled': absenceAlertsEnabled,
  };

  AttendanceAlertsConfig copyWith({
    bool? enabled,
    double? warningPercentage,
    double? criticalPercentage,
    bool? absenceAlertsEnabled,
  }) {
    return AttendanceAlertsConfig(
      enabled: enabled ?? this.enabled,
      warningPercentage: warningPercentage ?? this.warningPercentage,
      criticalPercentage: criticalPercentage ?? this.criticalPercentage,
      absenceAlertsEnabled: absenceAlertsEnabled ?? this.absenceAlertsEnabled,
    );
  }
}

class InstitutionConfigModel {
  final String collegeId;
  final InstitutionType institutionType;
  final AcademicStructureConfig academicStructure;
  final TerminologyConfig terminology;
  final AttendanceAlertsConfig attendanceAlerts;
  final bool isConfigured;

  const InstitutionConfigModel({
    required this.collegeId,
    this.institutionType = InstitutionType.engineering,
    this.academicStructure = const AcademicStructureConfig(),
    this.terminology = const TerminologyConfig(),
    this.attendanceAlerts = const AttendanceAlertsConfig(),
    this.isConfigured = false,
  });

  factory InstitutionConfigModel.fromJson(Map<String, dynamic> json) {
    return InstitutionConfigModel(
      collegeId: json['collegeId']?.toString() ?? '',
      institutionType: InstitutionType.fromValue(json['institutionType']?.toString()),
      academicStructure: AcademicStructureConfig.fromJson(
        json['academicStructure'] as Map<String, dynamic>?,
      ),
      terminology: TerminologyConfig.fromJson(
        json['terminology'] as Map<String, dynamic>?,
      ),
      attendanceAlerts: AttendanceAlertsConfig.fromJson(
        json['attendanceAlerts'] as Map<String, dynamic>?,
      ),
      isConfigured: json['isConfigured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'collegeId': collegeId,
    'institutionType': institutionType.value,
    'academicStructure': academicStructure.toJson(),
    'terminology': terminology.toJson(),
    'attendanceAlerts': attendanceAlerts.toJson(),
    'isConfigured': isConfigured,
  };

  InstitutionConfigModel copyWith({
    String? collegeId,
    InstitutionType? institutionType,
    AcademicStructureConfig? academicStructure,
    TerminologyConfig? terminology,
    AttendanceAlertsConfig? attendanceAlerts,
    bool? isConfigured,
  }) {
    return InstitutionConfigModel(
      collegeId: collegeId ?? this.collegeId,
      institutionType: institutionType ?? this.institutionType,
      academicStructure: academicStructure ?? this.academicStructure,
      terminology: terminology ?? this.terminology,
      attendanceAlerts: attendanceAlerts ?? this.attendanceAlerts,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }
}

class InstitutionPresetModel {
  final InstitutionType id;
  final String name;
  final String description;
  final AcademicStructureConfig suggestedStructure;
  final TerminologyConfig suggestedTerminology;

  const InstitutionPresetModel({
    required this.id,
    required this.name,
    required this.description,
    required this.suggestedStructure,
    required this.suggestedTerminology,
  });

  factory InstitutionPresetModel.fromJson(Map<String, dynamic> json) {
    return InstitutionPresetModel(
      id: InstitutionType.fromValue(json['id']?.toString()),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      suggestedStructure: AcademicStructureConfig.fromJson(
        json['suggestedStructure'] as Map<String, dynamic>?,
      ),
      suggestedTerminology: TerminologyConfig.fromJson(
        json['suggestedTerminology'] as Map<String, dynamic>?,
      ),
    );
  }
}
