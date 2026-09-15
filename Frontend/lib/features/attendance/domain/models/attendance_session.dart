import 'attendance_record.dart';
import 'attendance_status.dart';

class AttendanceSession {
  final String id;
  final String collegeId;
  final String departmentId;
  final String facultyId;
  final String subjectId;
  final String subjectName;
  final String sectionId;
  final String sectionName;
  final String timeSlot;
  final DateTime date;
  final List<AttendanceRecord> records;
  final String status; // 'open', 'locked', 'closed', 'cancelled'
  final bool isSubmitted;
  final bool isLocked;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? lastModifiedAt;
  final String? lastModifiedBy;
  final int version;

  final String? timetableId;
  final String? timetableEntryId;
  final String? facultyAssignmentId;
  final String? roomNumber;
  final String? building;

  AttendanceSession({
    required this.id,
    required this.collegeId,
    required this.departmentId,
    required this.facultyId,
    required this.subjectId,
    required this.subjectName,
    required this.sectionId,
    required this.sectionName,
    required this.timeSlot,
    required this.date,
    required this.records,
    this.status = 'open',
    this.timetableId,
    this.timetableEntryId,
    this.facultyAssignmentId,
    this.roomNumber,
    this.building,
    this.isSubmitted = false,
    this.isLocked = false,
    this.createdAt,
    this.createdBy,
    this.lastModifiedAt,
    this.lastModifiedBy,
    this.version = 1,
  });

  bool get isOpen => status == 'open' && !isLocked;
  bool get isLockedState => status == 'locked' || isLocked;
  bool get isClosed => status == 'closed';
  bool get isCancelled => status == 'cancelled';

  int get totalStudents => records.length;
  int get presentCount => records.where((r) => r.status == AttendanceStatus.present).length;
  int get absentCount => records.where((r) => r.status == AttendanceStatus.absent).length;
  int get lateCount => records.where((r) => r.status == AttendanceStatus.late).length;
  int get excusedCount => records.where((r) => r.status == AttendanceStatus.excused).length;
  int get unmarkedCount => records.where((r) => r.status == null).length;

  double get attendancePercentage {
    if (records.isEmpty) return 0.0;
    return ((presentCount + lateCount) / records.length) * 100;
  }

  AttendanceSession copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? facultyId,
    String? subjectId,
    String? subjectName,
    String? sectionId,
    String? sectionName,
    String? timeSlot,
    DateTime? date,
    List<AttendanceRecord>? records,
    String? status,
    String? timetableId,
    String? timetableEntryId,
    String? facultyAssignmentId,
    String? roomNumber,
    String? building,
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
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      facultyId: facultyId ?? this.facultyId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      timeSlot: timeSlot ?? this.timeSlot,
      date: date ?? this.date,
      records: records ?? this.records,
      status: status ?? this.status,
      timetableId: timetableId ?? this.timetableId,
      timetableEntryId: timetableEntryId ?? this.timetableEntryId,
      facultyAssignmentId: facultyAssignmentId ?? this.facultyAssignmentId,
      roomNumber: roomNumber ?? this.roomNumber,
      building: building ?? this.building,
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
    final statusStr = (json['status'] as String?)?.toLowerCase() ?? 'open';
    final locked = (json['isLocked'] as bool?) ?? (statusStr == 'locked');
    return AttendanceSession(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      collegeId: (json['collegeId'] ?? '').toString(),
      departmentId: (json['departmentId'] ?? '').toString(),
      facultyId: (json['facultyId'] ?? '').toString(),
      subjectId: (json['subjectId'] ?? '').toString(),
      subjectName: (json['subjectName'] ?? '').toString(),
      sectionId: (json['sectionId'] ?? '').toString(),
      sectionName: (json['sectionName'] ?? '').toString(),
      timeSlot: (json['timeSlot'] ?? '').toString(),
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
      records: (json['records'] as List<dynamic>?)
              ?.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: statusStr,
      timetableId: (json['timetableId'] ?? json['timetable']?['_id'])?.toString(),
      timetableEntryId: (json['timetableEntryId'] ?? json['entry']?['_id'])?.toString(),
      facultyAssignmentId: (json['facultyAssignmentId'] ?? json['facultyAssignment']?['_id'])?.toString(),
      roomNumber: json['roomNumber'] as String?,
      building: json['building'] as String?,
      isSubmitted: json['isSubmitted'] as bool? ?? false,
      isLocked: locked,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      createdBy: json['createdBy'] as String?,
      lastModifiedAt: json['lastModifiedAt'] != null ? DateTime.tryParse(json['lastModifiedAt'].toString()) : null,
      lastModifiedBy: json['lastModifiedBy'] as String?,
      version: json['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'facultyId': facultyId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'timeSlot': timeSlot,
      'date': date.toIso8601String(),
      'records': records.map((r) => r.toJson()).toList(),
      'status': status,
      if (timetableId != null) 'timetableId': timetableId,
      if (timetableEntryId != null) 'timetableEntryId': timetableEntryId,
      if (facultyAssignmentId != null) 'facultyAssignmentId': facultyAssignmentId,
      if (roomNumber != null) 'roomNumber': roomNumber,
      if (building != null) 'building': building,
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
