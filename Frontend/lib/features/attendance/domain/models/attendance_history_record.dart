import 'attendance_status.dart';

class AttendanceHistoryRecord {
  final String id;
  final DateTime date;
  final String subjectId;
  final String subjectName;
  final String facultyName;
  final AttendanceStatus status;
  final String timeSlot;

  AttendanceHistoryRecord({
    required this.id,
    required this.date,
    required this.subjectId,
    required this.subjectName,
    required this.facultyName,
    required this.status,
    required this.timeSlot,
  });
}
