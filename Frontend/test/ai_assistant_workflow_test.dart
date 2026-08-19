import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/ai_assistant/data/repositories/mock_ai_repository.dart';
import 'package:campus_management/features/ai_assistant/data/repositories/api_ai_repository.dart';
import 'package:campus_management/features/ai_assistant/presentation/providers/ai_providers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  group('AI Assistant Workflow Tests', () {
    test('MockAiRepository provides role-aware responses', () async {
      final repo = MockAiRepository();

      // Student
      final studentRes = await repo.sendMessage(
        query: 'How do I check my attendance?',
        context: {'role': 'student'},
      );
      expect(studentRes.contains('open the "Attendance" module from the main navigation menu'), isTrue);

      // Faculty
      final facultyRes = await repo.sendMessage(
        query: 'How do I mark attendance?',
        context: {'role': 'faculty'},
      );
      expect(facultyRes.contains('select your assigned section, and log the presence'), isTrue);

      // HOD
      final hodRes = await repo.sendMessage(
        query: 'attendance shortages',
        context: {'role': 'hod'},
      );
      expect(hodRes.contains('department-wide attendance shortages'), isTrue);
    });

    test('MockAiRepository denies unsupported features (Certificates)', () async {
      final repo = MockAiRepository();

      final res = await repo.sendMessage(
        query: 'I want to upload a certificate',
        context: {'role': 'student'},
      );
      expect(res.contains('Certificate management (uploads/downloads) is currently not available'), isTrue);
    });

    test('ApiAiRepository handles offline backend cleanly', () async {
      final repo = ApiAiRepository();
      
      // Because apiClient.aiDio isn't actually bound to a running test server, 
      // this should throw the explicit limitation string we designed.
      expect(
        () => repo.sendMessage(
          query: 'Test',
          context: {},
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Acadex AI is temporarily unavailable.'))),
      );
    });

    test('AiChatNotifier manages state correctly', () async {
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWithValue(MockAiRepository()),
        ]
      );

      final notifier = container.read(aiChatProvider.notifier);
      
      // Starts with 1 welcome message
      expect(container.read(aiChatProvider).messages.length, 1);
      
      // Send a message
      final future = notifier.sendMessage('attendance');
      
      // Loading state immediately
      expect(container.read(aiChatProvider).isLoading, isTrue);
      expect(container.read(aiChatProvider).messages.length, 2); // Welcome + User query

      await future;
      
      // Response received
      expect(container.read(aiChatProvider).isLoading, isFalse);
      expect(container.read(aiChatProvider).messages.length, 3); // Welcome + User + AI
      expect(container.read(aiChatProvider).messages[2].isAi, isTrue);
      
      // Clear chat
      notifier.clearChat();
      expect(container.read(aiChatProvider).messages.length, 1);
    });
  });
}
