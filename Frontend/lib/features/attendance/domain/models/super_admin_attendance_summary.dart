class SuperAdminAttendanceSummary {
  final int totalColleges;
  final int totalDepartments;
  final int totalFaculty;
  final int totalStudents;
  final int totalCollegeAdmins;
  final double todayAttendancePercentage;
  final int pendingColleges;

  SuperAdminAttendanceSummary({
    required this.totalColleges,
    required this.totalDepartments,
    required this.totalFaculty,
    required this.totalStudents,
    this.totalCollegeAdmins = 0,
    required this.todayAttendancePercentage,
    required this.pendingColleges,
  });
}
