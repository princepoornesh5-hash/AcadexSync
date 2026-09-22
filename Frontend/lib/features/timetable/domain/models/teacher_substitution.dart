class TeacherSubstitution {
  final String id;
  final String collegeId;
  final String departmentId;
  final String sectionId;
  final String timetableId;
  final String timetableEntryId;
  final String date; // YYYY-MM-DD
  final String originalFacultyId;
  final String substituteFacultyId;
  final String? originalFacultyName;
  final String? substituteFacultyName;
  final String reason;
  final String status;
  final String? createdBy;
  final DateTime? createdAt;

  const TeacherSubstitution({
    required this.id,
    required this.collegeId,
    required this.departmentId,
    required this.sectionId,
    required this.timetableId,
    required this.timetableEntryId,
    required this.date,
    required this.originalFacultyId,
    required this.substituteFacultyId,
    this.originalFacultyName,
    this.substituteFacultyName,
    required this.reason,
    this.status = 'ACTIVE',
    this.createdBy,
    this.createdAt,
  });

  factory TeacherSubstitution.fromJson(Map<String, dynamic> json) {
    String extractId(dynamic val) {
      if (val is Map<String, dynamic>) {
        return val['_id']?.toString() ?? val['id']?.toString() ?? '';
      }
      return val?.toString() ?? '';
    }

    String? extractName(dynamic val) {
      if (val is Map<String, dynamic>) {
        return val['name']?.toString();
      }
      return null;
    }

    return TeacherSubstitution(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      collegeId: extractId(json['collegeId']),
      departmentId: extractId(json['departmentId']),
      sectionId: extractId(json['sectionId']),
      timetableId: extractId(json['timetableId']),
      timetableEntryId: extractId(json['timetableEntryId']),
      date: json['date']?.toString() ?? '',
      originalFacultyId: extractId(json['originalFacultyId']),
      substituteFacultyId: extractId(json['substituteFacultyId']),
      originalFacultyName: extractName(json['originalFacultyId']),
      substituteFacultyName: extractName(json['substituteFacultyId']),
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      createdBy: extractId(json['createdBy']),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timetableId': timetableId,
      'timetableEntryId': timetableEntryId,
      'date': date,
      'substituteFacultyId': substituteFacultyId,
      if (originalFacultyId.isNotEmpty) 'originalFacultyId': originalFacultyId,
      'reason': reason,
    };
  }

  TeacherSubstitution copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? sectionId,
    String? timetableId,
    String? timetableEntryId,
    String? date,
    String? originalFacultyId,
    String? substituteFacultyId,
    String? originalFacultyName,
    String? substituteFacultyName,
    String? reason,
    String? status,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return TeacherSubstitution(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      sectionId: sectionId ?? this.sectionId,
      timetableId: timetableId ?? this.timetableId,
      timetableEntryId: timetableEntryId ?? this.timetableEntryId,
      date: date ?? this.date,
      originalFacultyId: originalFacultyId ?? this.originalFacultyId,
      substituteFacultyId: substituteFacultyId ?? this.substituteFacultyId,
      originalFacultyName: originalFacultyName ?? this.originalFacultyName,
      substituteFacultyName: substituteFacultyName ?? this.substituteFacultyName,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
