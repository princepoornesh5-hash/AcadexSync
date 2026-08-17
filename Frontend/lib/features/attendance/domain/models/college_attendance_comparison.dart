import 'department_attendance_comparison.dart' show TrendDirection;

class CollegeAttendanceComparison {
  final String collegeId;
  final String collegeName;
  final String collegeCode;
  final double attendancePercentage;
  final int studentCount;
  final int facultyCount;
  final int departmentCount;
  final double completionRate;
  final TrendDirection trend;

  CollegeAttendanceComparison({
    required this.collegeId,
    required this.collegeName,
    required this.collegeCode,
    required this.attendancePercentage,
    required this.studentCount,
    required this.facultyCount,
    required this.departmentCount,
    required this.completionRate,
    required this.trend,
  });
}
