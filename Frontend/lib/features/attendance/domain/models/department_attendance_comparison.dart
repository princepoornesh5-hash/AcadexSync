enum TrendDirection { up, down, neutral }

class DepartmentAttendanceComparison {
  final String departmentId;
  final String departmentName;
  final double attendancePercentage;
  final int studentCount;
  final int facultyCount;
  final double todayCompletionPercentage;
  final TrendDirection trend;

  DepartmentAttendanceComparison({
    required this.departmentId,
    required this.departmentName,
    required this.attendancePercentage,
    required this.studentCount,
    required this.facultyCount,
    required this.todayCompletionPercentage,
    required this.trend,
  });
}
