enum ShortageStatus { warning, critical }

class StudentShortage {
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String semester;
  final String section;
  final double currentPercentage;

  StudentShortage({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.semester,
    required this.section,
    required this.currentPercentage,
  });
  
  ShortageStatus get status => currentPercentage < 65 ? ShortageStatus.critical : ShortageStatus.warning;
}
