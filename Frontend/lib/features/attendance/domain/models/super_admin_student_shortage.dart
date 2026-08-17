import 'student_shortage.dart' show ShortageStatus;

class SuperAdminStudentShortage {
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String collegeName;
  final String departmentName;
  final String semester;
  final double currentPercentage;
  final ShortageStatus status;

  SuperAdminStudentShortage({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.collegeName,
    required this.departmentName,
    required this.semester,
    required this.currentPercentage,
    required this.status,
  });
}
