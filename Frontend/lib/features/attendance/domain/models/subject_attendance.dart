class SubjectAttendance {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String facultyName;
  final int totalClasses;
  final int attendedClasses;
  final int missedClasses;

  SubjectAttendance({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.facultyName,
    required this.totalClasses,
    required this.attendedClasses,
    required this.missedClasses,
  });

  double get percentage => totalClasses == 0 ? 0 : (attendedClasses / totalClasses) * 100;
}
