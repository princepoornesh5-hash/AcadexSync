class SectionAttendanceSummary {
  final String sectionId;
  final String sectionName;
  final String semester;
  final double attendancePercentage;
  final int present;
  final int absent;
  final int late;
  final int totalStudents;

  SectionAttendanceSummary({
    required this.sectionId,
    required this.sectionName,
    required this.semester,
    required this.attendancePercentage,
    required this.present,
    required this.absent,
    required this.late,
    required this.totalStudents,
  });
}
