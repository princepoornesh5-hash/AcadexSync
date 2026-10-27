import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:campus_management/features/ai_assistant/domain/models/ai_response.dart';
import 'package:campus_management/features/ai_assistant/domain/models/ai_stream_event.dart';
import 'package:campus_management/features/ai_assistant/domain/repositories/ai_repository.dart';
import 'package:campus_management/features/ai_assistant/presentation/providers/ai_providers.dart';
import 'package:campus_management/features/ai_assistant/presentation/widgets/ai_markdown_view.dart';
import 'package:campus_management/features/ai_assistant/presentation/widgets/ai_thinking_indicator.dart';

class ControllableMockAiRepository implements AiRepository {
  final StreamController<AiStreamEvent> _controller = StreamController<AiStreamEvent>.broadcast();
  StreamController<AiStreamEvent> get controller => _controller;

  int streamCalls = 0;

  @override
  Stream<AiStreamEvent> streamChatMessage({
    required String query,
    required Map<String, dynamic> context,
    List<Map<String, String>>? history,
  }) {
    streamCalls++;
    return _controller.stream;
  }

  @override
  Future<String> sendMessage({
    required String query,
    required Map<String, dynamic> context,
  }) async {
    return 'Legacy mock response';
  }

  @override
  Future<AiResponse> sendChatMessage({
    required String query,
    required Map<String, dynamic> context,
    List<Map<String, String>>? history,
  }) async {
    return const AiResponse(
      answer: 'Legacy response',
      model: 'mock',
    );
  }

  @override
  Future<Map<String, dynamic>> confirmAction({
    required String actionId,
    String? idempotencyKey,
  }) async {
    return {
      'actionId': actionId,
      'status': 'EXECUTED',
      'message': 'Action executed successfully',
    };
  }

  @override
  Future<Map<String, dynamic>> cancelAction({required String actionId}) async {
    return {
      'actionId': actionId,
      'status': 'CANCELLED',
    };
  }

  @override
  Future<Map<String, dynamic>> getActionStatus({required String actionId}) async {
    return {
      'actionId': actionId,
      'status': 'EXECUTED',
    };
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('AI Streaming Responses & ChatGPT-style Progressive Rendering Tests', () {
    test('Multiple text chunks arriving incrementally update assistant message content progressively', () async {
      final repo = ControllableMockAiRepository();
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(() {
        container.dispose();
        repo.dispose();
      });

      final notifier = container.read(aiChatProvider.notifier);

      // Start stream
      final sendFuture = notifier.sendMessage('Generate a greeting');

      // State immediately loading
      expect(container.read(aiChatProvider).isLoading, isTrue);
      expect(container.read(aiChatProvider).messages.length, 2); // Welcome + User query

      // 1. Emit start event
      repo.controller.add(const AiStreamStartEvent(
        model: 'gemini-3.5-flash-lite',
        correlationId: 'test-corr-1',
      ));
      await Future<void>.delayed(Duration.zero);

      // 2. Emit first chunk
      repo.controller.add(const AiStreamDeltaEvent(text: 'Hello '));
      await Future<void>.delayed(Duration.zero);

      // Verify first chunk is visible immediately before completion
      var state = container.read(aiChatProvider);
      expect(state.messages.length, 3); // Welcome + User + Assistant
      expect(state.messages.last.isAi, isTrue);
      expect(state.messages.last.text, 'Hello ');
      expect(state.messages.last.isStreaming, isTrue);

      // 3. Emit second chunk
      repo.controller.add(const AiStreamDeltaEvent(text: 'world of '));
      await Future<void>.delayed(Duration.zero);

      state = container.read(aiChatProvider);
      expect(state.messages.last.text, 'Hello world of ');
      expect(state.messages.last.isStreaming, isTrue);

      // 4. Emit third chunk
      repo.controller.add(const AiStreamDeltaEvent(text: 'ACADEX streaming!'));
      await Future<void>.delayed(Duration.zero);

      state = container.read(aiChatProvider);
      expect(state.messages.last.text, 'Hello world of ACADEX streaming!');
      expect(state.messages.last.isStreaming, isTrue);

      // 5. Complete the stream
      repo.controller.add(const AiStreamDoneEvent(
        answer: 'Hello world of ACADEX streaming!',
        model: 'gemini-3.5-flash-lite',
      ));
      await repo.controller.close();
      await sendFuture;

      state = container.read(aiChatProvider);
      expect(state.isLoading, isFalse);
      expect(state.messages.last.text, 'Hello world of ACADEX streaming!');
      expect(state.messages.last.isStreaming, isFalse);
      expect(state.messages.last.isInterrupted, isFalse);
    });

    test('Stop Generating cancels active stream and marks message as interrupted', () async {
      final repo = ControllableMockAiRepository();
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(() {
        container.dispose();
        repo.dispose();
      });

      final notifier = container.read(aiChatProvider.notifier);

      notifier.sendMessage('Write a long essay');
      await Future<void>.delayed(Duration.zero);

      // Emit start and partial chunk
      repo.controller.add(const AiStreamStartEvent(
        model: 'gemini-3.5-flash-lite',
        correlationId: 'test-corr-2',
      ));
      repo.controller.add(const AiStreamDeltaEvent(text: 'Introduction to campus architecture...'));
      await Future<void>.delayed(Duration.zero);

      var state = container.read(aiChatProvider);
      expect(state.isLoading, isTrue);
      expect(state.messages.last.text, 'Introduction to campus architecture...');

      // User presses Stop Generating
      notifier.stopGenerating();
      await Future<void>.delayed(Duration.zero);

      state = container.read(aiChatProvider);
      expect(state.isLoading, isFalse);
      expect(state.messages.last.isStreaming, isFalse);
      expect(state.messages.last.isInterrupted, isTrue);
      expect(state.messages.last.text, 'Introduction to campus architecture...');
    });

    test('Retry interrupted response clears the partial message and re-sends user query', () async {
      final repo = ControllableMockAiRepository();
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(() {
        container.dispose();
        repo.dispose();
      });

      final notifier = container.read(aiChatProvider.notifier);

      notifier.sendMessage('Explain quantum computing');
      await Future<void>.delayed(Duration.zero);

      repo.controller.add(const AiStreamDeltaEvent(text: 'Quantum bits...'));
      await Future<void>.delayed(Duration.zero);

      notifier.stopGenerating();
      await Future<void>.delayed(Duration.zero);

      var state = container.read(aiChatProvider);
      expect(state.messages.last.isInterrupted, isTrue);

      // Retry
      notifier.retryLastMessage();
      await Future<void>.delayed(Duration.zero);

      state = container.read(aiChatProvider);
      expect(state.isLoading, isTrue);
      expect(repo.streamCalls, 2);
    });

    test('Provider error before first chunk displays error banner without phantom message', () async {
      final repo = ControllableMockAiRepository();
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(() {
        container.dispose();
        repo.dispose();
      });

      final notifier = container.read(aiChatProvider.notifier);

      final sendFuture = notifier.sendMessage('Check timetable');
      await Future<void>.delayed(Duration.zero);

      repo.controller.add(const AiStreamErrorEvent(
        code: 'AI_UPSTREAM_ERROR',
        message: 'Upstream Gemini model unavailable. Please try again.',
      ));
      await repo.controller.close();
      await sendFuture;

      final state = container.read(aiChatProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, contains('Upstream Gemini model unavailable'));
      // No assistant message was appended because 0 chunks arrived
      expect(state.messages.length, 2); // Welcome + User query only
    });

    test('Provider error after partial chunk preserves partial output and sets isInterrupted', () async {
      final repo = ControllableMockAiRepository();
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(() {
        container.dispose();
        repo.dispose();
      });

      final notifier = container.read(aiChatProvider.notifier);

      final sendFuture = notifier.sendMessage('Show my results');
      await Future<void>.delayed(Duration.zero);

      repo.controller.add(const AiStreamDeltaEvent(text: 'Here are your semester 5 results: '));
      await Future<void>.delayed(Duration.zero);

      repo.controller.add(const AiStreamErrorEvent(
        code: 'AI_STREAM_INTERRUPTED',
        message: 'Connection lost during streaming.',
      ));
      await repo.controller.close();
      await sendFuture;

      final state = container.read(aiChatProvider);
      expect(state.isLoading, isFalse);
      expect(state.messages.last.text, 'Here are your semester 5 results: ');
      expect(state.messages.last.isStreaming, isFalse);
      expect(state.messages.last.isInterrupted, isTrue);
    });

    test('Safe action proposal is received via stream without premature execution', () async {
      final repo = ControllableMockAiRepository();
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(() {
        container.dispose();
        repo.dispose();
      });

      final notifier = container.read(aiChatProvider.notifier);

      final sendFuture = notifier.sendMessage('Create assignment for Physics Section A');
      await Future<void>.delayed(Duration.zero);

      final proposal = <String, dynamic>{
        'actionId': 'prop-stream-101',
        'actionType': 'create_assignment',
        'title': 'Physics Assignment 1',
        'summary': 'Draft Physics assignment on Thermodynamics',
        'status': 'PENDING',
        'expiresAt': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
        'preview': {'title': 'Physics Assignment 1', 'section': 'A'},
      };

      // Proposal event emitted first
      repo.controller.add(AiStreamProposalEvent(proposal: proposal));
      // Then explanation text streamed
      repo.controller.add(const AiStreamDeltaEvent(text: 'I have prepared a draft assignment proposal for your review.'));
      repo.controller.add(AiStreamDoneEvent(
        answer: 'I have prepared a draft assignment proposal for your review.',
        proposal: proposal,
      ));
      await repo.controller.close();
      await sendFuture;

      final state = container.read(aiChatProvider);
      expect(state.messages.last.proposal, isNotNull);
      expect(state.messages.last.proposal!['actionId'], 'prop-stream-101');
      expect(state.messages.last.proposal!['status'], 'PENDING');
      expect(state.messages.last.proposal!['status'], isNot('EXECUTED'));
    });

    testWidgets('AiThinkingIndicator renders "ACADEX is thinking..." with reduced-motion support', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiThinkingIndicator(),
          ),
        ),
      );

      expect(find.text('ACADEX is thinking...'), findsOneWidget);
    });

    testWidgets('AiMarkdownView renders incomplete code blocks progressively with copy button and proper indentation', (tester) async {
      const incompleteCodeMarkdown = '''Here is the requested Dart algorithm:
```dart
int calculateTotal(List<int> numbers) {
  int total = 0;
  for (final n in numbers) {
    total += n;
  }
  return total;
}
'''; // Closing ``` has not arrived yet

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiMarkdownView(
              text: incompleteCodeMarkdown,
              isStreaming: true,
            ),
          ),
        ),
      );

      // Language header
      expect(find.text('DART'), findsOneWidget);
      // Copy button
      expect(find.text('Copy'), findsOneWidget);
      // Formatted code lines
      expect(find.textContaining('int calculateTotal(List<int> numbers)'), findsOneWidget);
      expect(find.textContaining('total += n;'), findsOneWidget);

      // Copy action
      await tester.tap(find.text('Copy'));
      await tester.pump();
      expect(find.text('Copied!'), findsOneWidget);
      // Drain the 2-second timer in _CodeBlockWidget
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('AiMarkdownView shows blinking cursor when isStreaming is true and hides when false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiMarkdownView(
              text: 'Generating streaming response...',
              isStreaming: true,
            ),
          ),
        ),
      );

      // When streaming, blinking cursor key is present
      expect(find.byKey(const Key('ai_blinking_cursor')), findsOneWidget);

      // When not streaming, cursor is absent
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiMarkdownView(
              text: 'Completed response.',
              isStreaming: false,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('ai_blinking_cursor')), findsNothing);
    });
  });
}
