class FacultyAttendanceCompletion {
  final String facultyId;
  final String facultyName;
  final List<String> assignedSubjects;
  final int completedClasses;
  final int pendingClasses;
  final DateTime? lastCompletionTime;

  FacultyAttendanceCompletion({
    required this.facultyId,
    required this.facultyName,
    required this.assignedSubjects,
    required this.completedClasses,
    required this.pendingClasses,
    this.lastCompletionTime,
  });
  
  double get progress => (completedClasses + pendingClasses) == 0 ? 0 : completedClasses / (completedClasses + pendingClasses);
}
