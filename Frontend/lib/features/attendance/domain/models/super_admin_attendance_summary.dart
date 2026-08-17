class SuperAdminAttendanceSummary {
  final int totalColleges;
  final int totalDepartments;
  final int totalFaculty;
  final int totalStudents;
  final double todayAttendancePercentage;
  final int pendingColleges;

  SuperAdminAttendanceSummary({
    required this.totalColleges,
    required this.totalDepartments,
    required this.totalFaculty,
    required this.totalStudents,
    required this.todayAttendancePercentage,
    required this.pendingColleges,
  });
}
