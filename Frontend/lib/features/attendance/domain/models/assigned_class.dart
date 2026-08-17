class AssignedClass {
  final String id;
  final String subjectId;
  final String subjectName;
  final String sectionId;
  final String sectionName;
  final String semester;
  final String timeSlot; // e.g. "08:30 - 09:20"
  final DateTime date;
  final bool isAttendanceMarked;

  AssignedClass({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.sectionId,
    required this.sectionName,
    required this.semester,
    required this.timeSlot,
    required this.date,
    this.isAttendanceMarked = false,
  });

  AssignedClass copyWith({
    String? id,
    String? subjectId,
    String? subjectName,
    String? sectionId,
    String? sectionName,
    String? semester,
    String? timeSlot,
    DateTime? date,
    bool? isAttendanceMarked,
  }) {
    return AssignedClass(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      semester: semester ?? this.semester,
      timeSlot: timeSlot ?? this.timeSlot,
      date: date ?? this.date,
      isAttendanceMarked: isAttendanceMarked ?? this.isAttendanceMarked,
    );
  }
}
