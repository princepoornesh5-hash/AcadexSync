enum PracticalSessionStatus {
  planned,
  open,
  completed,
  cancelled;

  static PracticalSessionStatus fromString(String? val) {
    if (val == null) return PracticalSessionStatus.planned;
    switch (val.toUpperCase()) {
      case 'OPEN':
        return PracticalSessionStatus.open;
      case 'COMPLETED':
        return PracticalSessionStatus.completed;
      case 'CANCELLED':
        return PracticalSessionStatus.cancelled;
      case 'PLANNED':
      default:
        return PracticalSessionStatus.planned;
    }
  }

  String get displayName {
    switch (this) {
      case PracticalSessionStatus.open:
        return 'Open';
      case PracticalSessionStatus.completed:
        return 'Completed';
      case PracticalSessionStatus.cancelled:
        return 'Cancelled';
      case PracticalSessionStatus.planned:
        return 'Planned';
    }
  }

  String toJson() => name.toUpperCase();
}

enum PracticalParticipationStatus {
  notStarted,
  inProgress,
  completed,
  absent,
  excused;

  static PracticalParticipationStatus fromString(String? val) {
    if (val == null) return PracticalParticipationStatus.notStarted;
    switch (val.toUpperCase()) {
      case 'IN_PROGRESS':
        return PracticalParticipationStatus.inProgress;
      case 'COMPLETED':
        return PracticalParticipationStatus.completed;
      case 'ABSENT':
        return PracticalParticipationStatus.absent;
      case 'EXCUSED':
        return PracticalParticipationStatus.excused;
      case 'NOT_STARTED':
      default:
        return PracticalParticipationStatus.notStarted;
    }
  }

  String get displayName {
    switch (this) {
      case PracticalParticipationStatus.inProgress:
        return 'In Progress';
      case PracticalParticipationStatus.completed:
        return 'Completed';
      case PracticalParticipationStatus.absent:
        return 'Absent';
      case PracticalParticipationStatus.excused:
        return 'Excused';
      case PracticalParticipationStatus.notStarted:
        return 'Not Started';
    }
  }

  String get backendValue {
    switch (this) {
      case PracticalParticipationStatus.inProgress:
        return 'IN_PROGRESS';
      case PracticalParticipationStatus.completed:
        return 'COMPLETED';
      case PracticalParticipationStatus.absent:
        return 'ABSENT';
      case PracticalParticipationStatus.excused:
        return 'EXCUSED';
      case PracticalParticipationStatus.notStarted:
        return 'NOT_STARTED';
    }
  }

  String toJson() => backendValue;
}

class PracticalSessionModel {
  final String id;
  final String collegeId;
  final String departmentId;
  final String courseId;
  final String semesterId;
  final String? sectionId;
  final String subjectId;
  final String? subjectName;
  final String? subjectCode;
  final String facultyAssignmentId;
  final String facultyId;
  final String? facultyName;
  final String? timetableEntryId;
  final String? roomId;
  final String? roomNumber;
  final String? building;
  final int sessionNumber;
  final String topic;
  final String? instructions;
  final DateTime scheduledDate;
  final String? startTime;
  final String? endTime;
  final DateTime? actualDate;
  final PracticalSessionStatus status;
  final int totalEnrolled;
  final int completedCount;
  final int inProgressCount;
  final int absentCount;
  final String? attendanceSessionId;

  PracticalSessionModel({
    required this.id,
    required this.collegeId,
    required this.departmentId,
    required this.courseId,
    required this.semesterId,
    this.sectionId,
    required this.subjectId,
    this.subjectName,
    this.subjectCode,
    required this.facultyAssignmentId,
    required this.facultyId,
    this.facultyName,
    this.timetableEntryId,
    this.roomId,
    this.roomNumber,
    this.building,
    this.sessionNumber = 1,
    required this.topic,
    this.instructions,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    this.actualDate,
    this.status = PracticalSessionStatus.planned,
    this.totalEnrolled = 0,
    this.completedCount = 0,
    this.inProgressCount = 0,
    this.absentCount = 0,
    this.attendanceSessionId,
  });

  factory PracticalSessionModel.fromJson(Map<String, dynamic> json) {
    String subName = '';
    String subCode = '';
    if (json['subjectId'] is Map<String, dynamic>) {
      final subMap = json['subjectId'] as Map<String, dynamic>;
      subName = subMap['name']?.toString() ?? '';
      subCode = subMap['code']?.toString() ?? '';
    }

    String facName = '';
    if (json['facultyId'] is Map<String, dynamic>) {
      final facMap = json['facultyId'] as Map<String, dynamic>;
      facName = facMap['name']?.toString() ?? '';
    }

    String rNum = json['roomNumber']?.toString() ?? '';
    if (rNum.isEmpty && json['roomId'] is Map<String, dynamic>) {
      final rMap = json['roomId'] as Map<String, dynamic>;
      rNum = rMap['name']?.toString() ?? rMap['code']?.toString() ?? '';
    }

    DateTime schedDate = DateTime.now();
    if (json['scheduledDate'] != null) {
      schedDate = DateTime.tryParse(json['scheduledDate'].toString()) ?? DateTime.now();
    }

    DateTime? actDate;
    if (json['actualDate'] != null) {
      actDate = DateTime.tryParse(json['actualDate'].toString());
    }

    final subjIdRaw = json['subjectId'];
    final subjId = subjIdRaw is Map<String, dynamic>
        ? (subjIdRaw['id']?.toString() ?? subjIdRaw['_id']?.toString() ?? '')
        : (subjIdRaw?.toString() ?? '');

    final facIdRaw = json['facultyId'];
    final facId = facIdRaw is Map<String, dynamic>
        ? (facIdRaw['id']?.toString() ?? facIdRaw['_id']?.toString() ?? '')
        : (facIdRaw?.toString() ?? '');

    final roomIdRaw = json['roomId'];
    final rId = roomIdRaw is Map<String, dynamic>
        ? (roomIdRaw['id']?.toString() ?? roomIdRaw['_id']?.toString())
        : roomIdRaw?.toString();

    return PracticalSessionModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      collegeId: json['collegeId']?.toString() ?? '',
      departmentId: json['departmentId']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      semesterId: json['semesterId']?.toString() ?? '',
      sectionId: json['sectionId']?.toString(),
      subjectId: subjId,
      subjectName: subName.isNotEmpty ? subName : json['subjectName']?.toString(),
      subjectCode: subCode.isNotEmpty ? subCode : json['subjectCode']?.toString(),
      facultyAssignmentId: json['facultyAssignmentId']?.toString() ?? '',
      facultyId: facId,
      facultyName: facName.isNotEmpty ? facName : json['facultyName']?.toString(),
      timetableEntryId: json['timetableEntryId']?.toString(),
      roomId: rId,
      roomNumber: rNum.isNotEmpty ? rNum : null,
      building: json['building']?.toString(),
      sessionNumber: (json['sessionNumber'] as num?)?.toInt() ?? 1,
      topic: json['topic']?.toString() ?? '',
      instructions: json['instructions']?.toString(),
      scheduledDate: schedDate,
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      actualDate: actDate,
      status: PracticalSessionStatus.fromString(json['status']?.toString()),
      totalEnrolled: (json['totalEnrolled'] as num?)?.toInt() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      inProgressCount: (json['inProgressCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      attendanceSessionId: json['attendanceSessionId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'collegeId': collegeId,
    'departmentId': departmentId,
    'courseId': courseId,
    'semesterId': semesterId,
    if (sectionId != null) 'sectionId': sectionId,
    'subjectId': subjectId,
    if (subjectName != null) 'subjectName': subjectName,
    if (subjectCode != null) 'subjectCode': subjectCode,
    'facultyAssignmentId': facultyAssignmentId,
    'facultyId': facultyId,
    if (facultyName != null) 'facultyName': facultyName,
    if (timetableEntryId != null) 'timetableEntryId': timetableEntryId,
    if (roomId != null) 'roomId': roomId,
    if (roomNumber != null) 'roomNumber': roomNumber,
    if (building != null) 'building': building,
    'sessionNumber': sessionNumber,
    'topic': topic,
    if (instructions != null) 'instructions': instructions,
    'scheduledDate': scheduledDate.toIso8601String(),
    if (startTime != null) 'startTime': startTime,
    if (endTime != null) 'endTime': endTime,
    if (actualDate != null) 'actualDate': actualDate!.toIso8601String(),
    'status': status.name.toUpperCase(),
    'totalEnrolled': totalEnrolled,
    'completedCount': completedCount,
    'inProgressCount': inProgressCount,
    'absentCount': absentCount,
    if (attendanceSessionId != null) 'attendanceSessionId': attendanceSessionId,
  };

  PracticalSessionModel copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? subjectId,
    String? subjectName,
    String? subjectCode,
    String? facultyAssignmentId,
    String? facultyId,
    String? facultyName,
    String? timetableEntryId,
    String? roomId,
    String? roomNumber,
    String? building,
    int? sessionNumber,
    String? topic,
    String? instructions,
    DateTime? scheduledDate,
    String? startTime,
    String? endTime,
    DateTime? actualDate,
    PracticalSessionStatus? status,
    int? totalEnrolled,
    int? completedCount,
    int? inProgressCount,
    int? absentCount,
    String? attendanceSessionId,
  }) {
    return PracticalSessionModel(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      facultyAssignmentId: facultyAssignmentId ?? this.facultyAssignmentId,
      facultyId: facultyId ?? this.facultyId,
      facultyName: facultyName ?? this.facultyName,
      timetableEntryId: timetableEntryId ?? this.timetableEntryId,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      building: building ?? this.building,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      topic: topic ?? this.topic,
      instructions: instructions ?? this.instructions,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      actualDate: actualDate ?? this.actualDate,
      status: status ?? this.status,
      totalEnrolled: totalEnrolled ?? this.totalEnrolled,
      completedCount: completedCount ?? this.completedCount,
      inProgressCount: inProgressCount ?? this.inProgressCount,
      absentCount: absentCount ?? this.absentCount,
      attendanceSessionId: attendanceSessionId ?? this.attendanceSessionId,
    );
  }
}

class PracticalParticipationModel {
  final String participationId;
  final String studentId;
  final String studentName;
  final String? rollNumber;
  final PracticalParticipationStatus status;
  final String? notes;
  final DateTime? startedAt;
  final DateTime? completedAt;

  PracticalParticipationModel({
    required this.participationId,
    required this.studentId,
    required this.studentName,
    this.rollNumber,
    this.status = PracticalParticipationStatus.notStarted,
    this.notes,
    this.startedAt,
    this.completedAt,
  });

  String get id => participationId;

  factory PracticalParticipationModel.fromJson(Map<String, dynamic> json) {
    DateTime? started;
    if (json['startedAt'] != null) {
      started = DateTime.tryParse(json['startedAt'].toString());
    }

    DateTime? completed;
    if (json['completedAt'] != null) {
      completed = DateTime.tryParse(json['completedAt'].toString());
    }

    return PracticalParticipationModel(
      participationId: json['participationId']?.toString() ?? json['id']?.toString() ?? json['_id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? 'Student',
      rollNumber: json['rollNumber']?.toString(),
      status: PracticalParticipationStatus.fromString(json['status']?.toString()),
      notes: json['notes']?.toString(),
      startedAt: started,
      completedAt: completed,
    );
  }

  Map<String, dynamic> toJson() => {
    'participationId': participationId,
    'studentId': studentId,
    'studentName': studentName,
    if (rollNumber != null) 'rollNumber': rollNumber,
    'status': status.toJson(),
    if (notes != null) 'notes': notes,
    if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
    if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
  };

  PracticalParticipationModel copyWith({
    String? participationId,
    String? studentId,
    String? studentName,
    String? rollNumber,
    PracticalParticipationStatus? status,
    String? notes,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return PracticalParticipationModel(
      participationId: participationId ?? this.participationId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class StudentPracticalHistoryModel {
  final String sessionId;
  final String topic;
  final int sessionNumber;
  final DateTime scheduledDate;
  final String subjectName;
  final String subjectCode;
  final PracticalSessionStatus sessionStatus;
  final PracticalParticipationStatus participationStatus;
  final String? notes;
  final DateTime? completedAt;
  final String? roomNumber;

  StudentPracticalHistoryModel({
    required this.sessionId,
    required this.topic,
    required this.sessionNumber,
    required this.scheduledDate,
    required this.subjectName,
    required this.subjectCode,
    required this.sessionStatus,
    required this.participationStatus,
    this.notes,
    this.completedAt,
    this.roomNumber,
  });

  factory StudentPracticalHistoryModel.fromJson(Map<String, dynamic> json) {
    DateTime schedDate = DateTime.now();
    if (json['scheduledDate'] != null) {
      schedDate = DateTime.tryParse(json['scheduledDate'].toString()) ?? DateTime.now();
    }

    DateTime? compDate;
    if (json['completedAt'] != null) {
      compDate = DateTime.tryParse(json['completedAt'].toString());
    }

    return StudentPracticalHistoryModel(
      sessionId: json['sessionId']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      sessionNumber: (json['sessionNumber'] as num?)?.toInt() ?? 1,
      scheduledDate: schedDate,
      subjectName: json['subjectName']?.toString() ?? 'Subject',
      subjectCode: json['subjectCode']?.toString() ?? '',
      sessionStatus: PracticalSessionStatus.fromString(json['sessionStatus']?.toString()),
      participationStatus: PracticalParticipationStatus.fromString(json['participationStatus']?.toString()),
      notes: json['notes']?.toString(),
      completedAt: compDate,
      roomNumber: json['roomNumber']?.toString(),
    );
  }
}
