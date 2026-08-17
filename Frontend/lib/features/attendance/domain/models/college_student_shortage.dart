import 'student_shortage.dart';

class CollegeStudentShortage {
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String departmentName;
  final String semester;
  final double currentPercentage;
  final ShortageStatus status;

  CollegeStudentShortage({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.departmentName,
    required this.semester,
    required this.currentPercentage,
    required this.status,
  });
}
