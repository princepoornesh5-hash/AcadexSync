class AssignedClass {
  final String id;
  final String? timetableEntryId;
  final String? facultyId;
  final String subjectId;
  final String subjectName;
  final String sectionId;
  final String sectionName;
  final String semester;
  final String timeSlot; // e.g. "08:30 - 09:20"
  final String? startTime;
  final String? endTime;
  final String? roomNumber;
  final String? building;
  final DateTime date;
  final bool isAttendanceMarked;

  AssignedClass({
    required this.id,
    this.timetableEntryId,
    this.facultyId,
    required this.subjectId,
    required this.subjectName,
    required this.sectionId,
    required this.sectionName,
    required this.semester,
    required this.timeSlot,
    this.startTime,
    this.endTime,
    this.roomNumber,
    this.building,
    required this.date,
    this.isAttendanceMarked = false,
  });

  /// The effective timetable entry ID representing this class
  String get effectiveTimetableEntryId => timetableEntryId ?? id;

  AssignedClass copyWith({
    String? id,
    String? timetableEntryId,
    String? facultyId,
    String? subjectId,
    String? subjectName,
    String? sectionId,
    String? sectionName,
    String? semester,
    String? timeSlot,
    String? startTime,
    String? endTime,
    String? roomNumber,
    String? building,
    DateTime? date,
    bool? isAttendanceMarked,
  }) {
    return AssignedClass(
      id: id ?? this.id,
      timetableEntryId: timetableEntryId ?? this.timetableEntryId,
      facultyId: facultyId ?? this.facultyId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      semester: semester ?? this.semester,
      timeSlot: timeSlot ?? this.timeSlot,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      roomNumber: roomNumber ?? this.roomNumber,
      building: building ?? this.building,
      date: date ?? this.date,
      isAttendanceMarked: isAttendanceMarked ?? this.isAttendanceMarked,
    );
  }

  factory AssignedClass.fromJson(Map<String, dynamic> json) {
    return AssignedClass(
      id: json['id'] as String? ?? '',
      timetableEntryId: json['timetableEntryId'] as String?,
      facultyId: json['facultyId'] as String?,
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      sectionName: json['sectionName'] as String? ?? '',
      semester: json['semester'] as String? ?? json['semesterId'] as String? ?? '',
      timeSlot: json['timeSlot'] as String? ?? '',
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      roomNumber: json['roomNumber'] as String?,
      building: json['building'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      isAttendanceMarked: json['isAttendanceMarked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (timetableEntryId != null) 'timetableEntryId': timetableEntryId,
      if (facultyId != null) 'facultyId': facultyId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'semester': semester,
      'timeSlot': timeSlot,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (roomNumber != null) 'roomNumber': roomNumber,
      if (building != null) 'building': building,
      'date': date.toIso8601String(),
      'isAttendanceMarked': isAttendanceMarked,
    };
  }
}
