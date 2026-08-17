class CollegeFacultyCompletion {
  final String facultyId;
  final String facultyName;
  final String departmentName;
  final List<String> assignedSubjects;
  final int completedClasses;
  final int pendingClasses;
  final DateTime? lastCompletionTime;

  CollegeFacultyCompletion({
    required this.facultyId,
    required this.facultyName,
    required this.departmentName,
    required this.assignedSubjects,
    required this.completedClasses,
    required this.pendingClasses,
    this.lastCompletionTime,
  });
  
  double get progress => (completedClasses + pendingClasses) == 0 ? 0 : completedClasses / (completedClasses + pendingClasses);
}
