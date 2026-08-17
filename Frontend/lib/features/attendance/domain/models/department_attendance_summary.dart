class DepartmentAttendanceSummary {
  final double overallPercentage;
  final int studentsBelow75;
  final int facultyCompleted;
  final int facultyPending;
  final int todayClasses;
  final int totalStudents;
  final int totalFaculty;

  DepartmentAttendanceSummary({
    required this.overallPercentage,
    required this.studentsBelow75,
    required this.facultyCompleted,
    required this.facultyPending,
    required this.todayClasses,
    required this.totalStudents,
    required this.totalFaculty,
  });
}
