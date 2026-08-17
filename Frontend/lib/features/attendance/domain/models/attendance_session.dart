import 'attendance_record.dart';

class AttendanceSession {
  final String id;
  final String facultyId;
  final String subjectId;
  final String subjectName;
  final String sectionId;
  final String sectionName;
  final String timeSlot;
  final DateTime date;
  final List<AttendanceRecord> records;
  final bool isSubmitted;
  final bool isLocked;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? lastModifiedAt;
  final String? lastModifiedBy;
  final int version;

  AttendanceSession({
    required this.id,
    required this.facultyId,
    required this.subjectId,
    required this.subjectName,
    required this.sectionId,
    required this.sectionName,
    required this.timeSlot,
    required this.date,
    required this.records,
    this.isSubmitted = false,
    this.isLocked = false,
    this.createdAt,
    this.createdBy,
    this.lastModifiedAt,
    this.lastModifiedBy,
    this.version = 1,
  });

  AttendanceSession copyWith({
    String? id,
    String? facultyId,
    String? subjectId,
    String? subjectName,
    String? sectionId,
    String? sectionName,
    String? timeSlot,
    DateTime? date,
    List<AttendanceRecord>? records,
    bool? isSubmitted,
    bool? isLocked,
    DateTime? createdAt,
    String? createdBy,
    DateTime? lastModifiedAt,
    String? lastModifiedBy,
    int? version,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      facultyId: facultyId ?? this.facultyId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      timeSlot: timeSlot ?? this.timeSlot,
      date: date ?? this.date,
      records: records ?? this.records,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      version: version ?? this.version,
    );
  }

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'] as String? ?? '',
      facultyId: json['facultyId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      sectionName: json['sectionName'] as String? ?? '',
      timeSlot: json['timeSlot'] as String? ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      records: (json['records'] as List<dynamic>?)
              ?.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isSubmitted: json['isSubmitted'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      createdBy: json['createdBy'] as String?,
      lastModifiedAt: json['lastModifiedAt'] != null ? DateTime.parse(json['lastModifiedAt'] as String) : null,
      lastModifiedBy: json['lastModifiedBy'] as String?,
      version: json['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'facultyId': facultyId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'timeSlot': timeSlot,
      'date': date.toIso8601String(),
      'records': records.map((r) => r.toJson()).toList(),
      'isSubmitted': isSubmitted,
      'isLocked': isLocked,
      'createdAt': createdAt?.toIso8601String(),
      'createdBy': createdBy,
      'lastModifiedAt': lastModifiedAt?.toIso8601String(),
      'lastModifiedBy': lastModifiedBy,
      'version': version,
    };
  }
}
