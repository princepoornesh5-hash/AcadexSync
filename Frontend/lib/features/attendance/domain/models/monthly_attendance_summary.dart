class MonthlyAttendanceSummary {
  final int month;
  final int year;
  final int classesConducted;
  final int classesAttended;
  final int classesMissed;

  MonthlyAttendanceSummary({
    required this.month,
    required this.year,
    required this.classesConducted,
    required this.classesAttended,
    required this.classesMissed,
  });

  double get percentage => classesConducted == 0 ? 0 : (classesAttended / classesConducted) * 100;

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
