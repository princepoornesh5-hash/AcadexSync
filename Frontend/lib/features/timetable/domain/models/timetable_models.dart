enum TimetableDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}

enum TimetableSessionType {
  lecture,
  lab,
  tutorial,
  practical,
  seminar,
  other;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}

class TimetableModel {
  final String id;
  final String collegeId;
  final String departmentId;
  final String courseId;
  final String academicYearId;
  final String semesterId;
  final String sectionId;
  final String subjectId;
  final String facultyId;
  final TimetableDay dayOfWeek;
  /// Format: "HH:mm" (24-hour)
  final String startTime;
  /// Format: "HH:mm" (24-hour)
  final String endTime;
  final String roomNumber;
  final String? building;
  final TimetableSessionType sessionType;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimetableModel({
    required this.id,
    required this.collegeId,
    required this.departmentId,
    required this.courseId,
    required this.academicYearId,
    required this.semesterId,
    required this.sectionId,
    required this.subjectId,
    required this.facultyId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.roomNumber,
    this.building,
    required this.sessionType,
    required this.createdAt,
    required this.updatedAt,
  });

  TimetableModel copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    String? subjectId,
    String? facultyId,
    TimetableDay? dayOfWeek,
    String? startTime,
    String? endTime,
    String? roomNumber,
    String? building,
    TimetableSessionType? sessionType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimetableModel(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      academicYearId: academicYearId ?? this.academicYearId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      subjectId: subjectId ?? this.subjectId,
      facultyId: facultyId ?? this.facultyId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      roomNumber: roomNumber ?? this.roomNumber,
      building: building ?? this.building,
      sessionType: sessionType ?? this.sessionType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    return TimetableModel(
      id: json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      academicYearId: json['academicYearId'] as String? ?? '',
      semesterId: json['semesterId'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      facultyId: json['facultyId'] as String? ?? '',
      dayOfWeek: TimetableDay.values.firstWhere(
        (e) => e.name == json['dayOfWeek'],
        orElse: () => TimetableDay.monday,
      ),
      startTime: json['startTime'] as String? ?? '00:00',
      endTime: json['endTime'] as String? ?? '00:00',
      roomNumber: json['roomNumber'] as String? ?? '',
      building: json['building'] as String?,
      sessionType: TimetableSessionType.values.firstWhere(
        (e) => e.name == json['sessionType'],
        orElse: () => TimetableSessionType.lecture,
      ),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
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
      'subjectId': subjectId,
      'facultyId': facultyId,
      'dayOfWeek': dayOfWeek.name,
      'startTime': startTime,
      'endTime': endTime,
      'roomNumber': roomNumber,
      if (building != null) 'building': building,
      'sessionType': sessionType.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool overlapsWith(TimetableModel other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    return startTime.compareTo(other.endTime) < 0 && endTime.compareTo(other.startTime) > 0;
  }
}
