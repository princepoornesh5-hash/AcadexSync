import '../../domain/repositories/ai_repository.dart';
import '../../domain/models/ai_response.dart';
import '../../domain/models/ai_stream_event.dart';

class MockAiRepository implements AiRepository {
  @override
  Future<String> sendMessage({
    required String query,
    required Map<String, dynamic> context,
  }) async {
    final res = await sendChatMessage(query: query, context: context);
    return res.answer;
  }

  @override
  Stream<AiStreamEvent> streamChatMessage({
    required String query,
    required Map<String, dynamic> context,
    List<Map<String, String>>? history,
  }) async* {
    yield const AiStreamStartEvent(
      model: 'mock-gemini-stream',
      correlationId: 'mock-corr-1',
    );
    await Future.delayed(const Duration(milliseconds: 50));

    final fullResponse = await sendChatMessage(
      query: query,
      context: context,
      history: history,
    );

    if (fullResponse.proposal != null) {
      yield AiStreamProposalEvent(proposal: fullResponse.proposal!);
    }

    final words = fullResponse.answer.split(' ');
    for (int i = 0; i < words.length; i += 3) {
      final chunk =
          words.skip(i).take(3).join(' ') + (i + 3 < words.length ? ' ' : '');
      await Future.delayed(const Duration(milliseconds: 20));
      yield AiStreamDeltaEvent(text: chunk);
    }

    yield AiStreamDoneEvent(
      answer: fullResponse.answer,
      model: fullResponse.model ?? 'mock-gemini-stream',
      proposal: fullResponse.proposal,
    );
  }

  @override
  Future<AiResponse> sendChatMessage({
    required String query,
    required Map<String, dynamic> context,
    List<Map<String, String>>? history,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final role = context['role']?.toString().toLowerCase() ?? 'unknown';
    final q = query.toLowerCase();

    // Prompt Injection Defense & Unauthorized Access Simulation
    if (q.contains('ignore') && q.contains('rules') ||
        q.contains('database') ||
        q.contains('another student') ||
        q.contains('credentials') ||
        q.contains('password') ||
        q.contains('activation code') ||
        q.contains('another department') ||
        q.contains('another college') ||
        q.contains('create user') ||
        q.contains('modify attendance') ||
        q.contains('change password') ||
        q.contains('notifications') || // Blocks privileged notification access
        q.contains('api key') ||
        q.contains('change my role')) {
      return const AiResponse(
        answer:
            'I cannot fulfill this request. It violates my security constraints and authorization boundaries.',
      );
    }

    // Phase 3: Simulated confirmed assignment creation workflow
    if (q.contains('create') &&
        (q.contains('assignment') || q.contains('iot'))) {
      if (role != 'faculty' && role != 'hod') {
        return const AiResponse(
          answer:
              'You do not have permission to create assignments. Only authorized faculty and academic administrators may create coursework assignments.',
        );
      }

      return const AiResponse(
        answer:
            'I have prepared a draft for the IoT assignment for Section A. Please review the details in the preview below and confirm to publish.',
        proposal: {
          'actionId': 'mock-action-asgn-1',
          'actionType': 'CREATE_ASSIGNMENT',
          'summary':
              'Create Homework assignment "IoT Sensor Analysis" for Internet of Things (Section A), due on 2026-11-25 at 05:00 PM (50 marks).',
          'preview': {
            'title': 'IoT Sensor Analysis',
            'subject': 'Internet of Things',
            'section': 'Section A',
            'dueDate': '2026-11-25',
            'dueTime': '05:00 PM',
            'maximumMarks': 50,
            'description': 'Analyze sensor packets from urban testbed.',
            'assignmentType': 'Homework',
          },
          'expiresAt': '2026-11-25T17:00:00.000Z',
        },
      );
    }

    // Phase 3: Simulated confirmed calendar event creation workflow
    if (q.contains('schedule') &&
        (q.contains('meeting') ||
            q.contains('event') ||
            q.contains('workshop'))) {
      if (role == 'student') {
        return const AiResponse(
          answer:
              'Students are not authorized to create calendar events. Please contact your department coordinator.',
        );
      }

      return const AiResponse(
        answer:
            'I have prepared a draft for the Department Curriculum Review Meeting. Please review the preview card and confirm to add it to the academic calendar.',
        proposal: {
          'actionId': 'mock-action-cal-1',
          'actionType': 'CREATE_CALENDAR_EVENT',
          'summary':
              'Schedule meeting "Department Curriculum Review Meeting" on 2026-11-20 at 10:00 AM (Seminar Hall 1).',
          'preview': {
            'title': 'Department Curriculum Review Meeting',
            'eventType': 'EVENT',
            'startDate': '2026-11-20',
            'startTime': '10:00 AM',
            'endTime': '11:30 AM',
            'location': 'Seminar Hall 1',
            'description': 'Review updated syllabi and laboratory experiments.',
            'scope': 'DEPARTMENT',
          },
          'expiresAt': '2026-11-20T11:30:00.000Z',
        },
      );
    }

    if (q.contains('attendance')) {
      if (role == 'student') {
        return const AiResponse(
          answer:
              'To check your attendance, open the "Attendance" module from the main navigation menu. It will show your percentage and history.',
        );
      } else if (role == 'faculty') {
        return const AiResponse(
          answer:
              'To mark attendance, navigate to the "Attendance" module, select your assigned section, and log the presence of each student.',
        );
      } else if (role == 'hod') {
        return const AiResponse(
          answer:
              'You can view department-wide attendance shortages by navigating to the "Analytics" or "Attendance" module and filtering by your department.',
        );
      }
    }

    if (q.contains('note') || q.contains('material')) {
      if (role == 'faculty') {
        return const AiResponse(
          answer:
              'To publish chapter notes, open the "Notes" module and click "Create Note". You can attach files and select the target subject and section.',
        );
      } else if (role == 'student') {
        return const AiResponse(
          answer:
              'Your study materials are available in the "Notes" module. You can browse and download files published by your faculty.',
        );
      }
    }

    if (q.contains('certificate')) {
      return const AiResponse(
        answer:
            'Certificate management (uploads/downloads) is currently not available in Acadex. It is a planned feature for a future update.',
      );
    }

    if (q.contains('role') || q.contains('admin')) {
      if (role == 'super_admin') {
        return const AiResponse(
          answer:
              'As a Super Admin, you can manage colleges and assign roles via the Settings and Analytics modules.',
        );
      } else {
        return const AiResponse(
          answer:
              'You can view your current role and profile in the "Settings" module.',
        );
      }
    }

    if (q.contains('department')) {
      if (role == 'college_admin') {
        return const AiResponse(
          answer:
              'You can manage your college departments from the Academic Structure module.',
        );
      }
    }

    return AiResponse(
      answer:
          'I am the Acadex AI Assistant. I see you are logged in as a ${role.toUpperCase()}. How can I help you navigate the system or find academic information today?',
    );
  }

  @override
  Future<Map<String, dynamic>> confirmAction({
    required String actionId,
    String? idempotencyKey,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'actionId': actionId,
      'status': 'EXECUTED',
      'result': {'persisted': true, 'id': 'mock_confirmed_$actionId'},
    };
  }

  @override
  Future<Map<String, dynamic>> cancelAction({required String actionId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {'actionId': actionId, 'status': 'CANCELLED'};
  }

  @override
  Future<Map<String, dynamic>> getActionStatus({
    required String actionId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return {
      'actionId': actionId,
      'status': 'PENDING',
      'summary': 'Mock pending action proposal',
    };
  }

  @override
  Future<AiResponse> sendPublicSupportQuery({
    required String query,
    List<Map<String, String>>? history,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final lower = query.toLowerCase();
    if (lower.contains('activate')) {
      return const AiResponse(
        answer:
            'To activate your account, click Activate Account on the login screen, enter your institutional email or activation code, and verify your email OTP.',
        model: 'mock-gemini-support',
      );
    }
    if (lower.contains('otp')) {
      return const AiResponse(
        answer:
            'To sign in with Email OTP, select Sign in with Email OTP on login, enter your email, and input the 6-digit code.',
        model: 'mock-gemini-support',
      );
    }
    if (lower.contains('college') || lower.contains('register')) {
      return const AiResponse(
        answer:
            'To register your college, click Register Your College on the Contact Us screen to send an onboarding request to ragoorupoornesh@gmail.com.',
        model: 'mock-gemini-support',
      );
    }
    return const AiResponse(
      answer:
          'ACADEXSYNC AI Support is available for public questions about account activation, email OTP sign-in, and onboarding.',
      model: 'mock-gemini-support',
    );
  }
}
