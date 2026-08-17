class CollegeAttendanceSummary {
  final int totalDepartments;
  final int totalStudents;
  final int totalFaculty;
  final double todayAttendancePercentage;
  final int studentsBelowThreshold;
  final int pendingFaculty;
  final int completedFaculty;

  CollegeAttendanceSummary({
    required this.totalDepartments,
    required this.totalStudents,
    required this.totalFaculty,
    required this.todayAttendancePercentage,
    required this.studentsBelowThreshold,
    required this.pendingFaculty,
    required this.completedFaculty,
  });
}
