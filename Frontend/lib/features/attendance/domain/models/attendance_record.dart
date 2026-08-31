import 'attendance_status.dart';

class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String sectionId;
  final AttendanceStatus? status;
  final AttendanceStatus? oldStatus; // Used during editing/corrections to show what changed
  final DateTime? lastModified;
  final String? modifiedBy; // ID of faculty or HOD who edited/corrected
  final String? remarks;
  final bool isCancelled;

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
    this.remarks,
    this.isCancelled = false,
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
    String? remarks,
    bool? isCancelled,
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
      remarks: remarks ?? this.remarks,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: (json['id'] ?? json['_id'] ?? json['attendanceId'] ?? '').toString(),
      studentId: (json['studentId'] is Map
              ? (json['studentId']['_id'] ?? json['studentId']['id'] ?? '')
              : (json['studentId'] ?? ''))
          .toString(),
      studentName: json['studentName'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      sectionId: (json['sectionId'] is Map
              ? (json['sectionId']['_id'] ?? json['sectionId']['id'] ?? '')
              : (json['sectionId'] ?? ''))
          .toString(),
      status: json['status'] != null
          ? AttendanceStatus.values.firstWhere(
              (e) => e.name.toLowerCase() == json['status'].toString().toLowerCase(),
              orElse: () => AttendanceStatus.present,
            )
          : null,
      oldStatus: json['oldStatus'] != null
          ? AttendanceStatus.values.firstWhere(
              (e) => e.name.toLowerCase() == json['oldStatus'].toString().toLowerCase(),
              orElse: () => AttendanceStatus.present,
            )
          : null,
      lastModified: json['lastModified'] != null
          ? DateTime.tryParse(json['lastModified'].toString())
          : null,
      modifiedBy: json['modifiedBy'] as String?,
      remarks: json['remarks'] as String?,
      isCancelled: json['isCancelled'] as bool? ?? false,
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
      'remarks': remarks,
      'isCancelled': isCancelled,
    };
  }
}
