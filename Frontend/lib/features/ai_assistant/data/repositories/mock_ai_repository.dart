import '../../domain/repositories/ai_repository.dart';

class MockAiRepository implements AiRepository {
  @override
  Future<String> sendMessage({
    required String query,
    required Map<String, dynamic> context,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final role = context['role']?.toString().toLowerCase() ?? 'unknown';
    final q = query.toLowerCase();

    // Prompt Injection Defense & Unauthorized Access Simulation
    if (q.contains('ignore') && q.contains('rules') ||
        q.contains('database') ||
        q.contains('another student') ||
        q.contains('credentials') ||
        q.contains('api key') ||
        q.contains('change my role')) {
      return 'I cannot fulfill this request. It violates my security constraints and authorization boundaries.';
    }

    if (q.contains('attendance')) {
      if (role == 'student') {
        return 'To check your attendance, open the "Attendance" module from the main navigation menu. It will show your percentage and history.';
      } else if (role == 'faculty') {
        return 'To mark attendance, navigate to the "Attendance" module, select your assigned section, and log the presence of each student.';
      } else if (role == 'hod') {
        return 'You can view department-wide attendance shortages by navigating to the "Analytics" or "Attendance" module and filtering by your department.';
      }
    }

    if (q.contains('note') || q.contains('material')) {
      if (role == 'faculty') {
        return 'To publish chapter notes, open the "Notes" module and click "Create Note". You can attach files and select the target subject and section.';
      } else if (role == 'student') {
        return 'Your study materials are available in the "Notes" module. You can browse and download files published by your faculty.';
      }
    }

    if (q.contains('certificate')) {
      return 'Certificate management (uploads/downloads) is currently not available in Acadex. It is a planned feature for a future update.';
    }

    if (q.contains('role') || q.contains('admin')) {
      if (role == 'super_admin') {
        return 'As a Super Admin, you can manage colleges and assign roles via the Settings and Analytics modules.';
      } else {
        return 'You can view your current role and profile in the "Settings" module.';
      }
    }

    if (q.contains('department')) {
      if (role == 'college_admin') {
        return 'You can manage your college departments from the Academic Structure module.';
      }
    }

    return 'I am the Acadex AI Assistant. I see you are logged in as a ${role.toUpperCase()}. How can I help you navigate the system or find academic information today?';
  }
}
