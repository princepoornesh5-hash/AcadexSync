import 'attendance_status.dart';

class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String sectionId;
  final AttendanceStatus? status;
  final AttendanceStatus? oldStatus; // Used during editing to show what changed
  final DateTime? lastModified;
  final String? modifiedBy; // ID of faculty who edited

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.sectionId,
    this.status,
    this.oldStatus,
    this.lastModified,
    this.modifiedBy,
  });

  AttendanceRecord copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? rollNumber,
    String? sectionId,
    AttendanceStatus? status,
    AttendanceStatus? oldStatus,
    DateTime? lastModified,
    String? modifiedBy,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      sectionId: sectionId ?? this.sectionId,
      status: status ?? this.status,
      oldStatus: oldStatus ?? this.oldStatus,
      lastModified: lastModified ?? this.lastModified,
      modifiedBy: modifiedBy ?? this.modifiedBy,
    );
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String? ?? json['attendanceId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      status: json['status'] != null
          ? AttendanceStatus.values.firstWhere(
              (e) => e.name == json['status'],
              orElse: () => AttendanceStatus.present,
            )
          : null,
      oldStatus: json['oldStatus'] != null
          ? AttendanceStatus.values.firstWhere(
              (e) => e.name == json['oldStatus'],
              orElse: () => AttendanceStatus.present,
            )
          : null,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      modifiedBy: json['modifiedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'rollNumber': rollNumber,
      'sectionId': sectionId,
      'status': status?.name,
      'oldStatus': oldStatus?.name,
      'lastModified': lastModified?.toIso8601String(),
      'modifiedBy': modifiedBy,
    };
  }
}
