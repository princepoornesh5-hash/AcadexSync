import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/ai_message.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../data/repositories/api_ai_repository.dart';
import '../../data/repositories/mock_ai_repository.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return MockAiRepository();
  }
  return ApiAiRepository();
});

class AiChatState {
  final List<AiMessage> messages;
  final bool isLoading;
  final String? error;

  AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<AiMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final Ref _ref;
  DateTime? _lastRequestTime;
  static const _rateLimitDuration = Duration(seconds: 3);

  AiChatNotifier(this._ref) : super(AiChatState()) {
    _initWelcomeMessage();
  }

  void _initWelcomeMessage() {
    state = state.copyWith(messages: [
      AiMessage(
        text: "Hello! I am your Acadex AI Assistant. How can I help you with your academic tasks today?",
        isAi: true,
      ),
    ]);
  }

  void clearChat() {
    state = AiChatState();
    _initWelcomeMessage();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> sendMessage(String query) async {
    if (query.trim().isEmpty) return;
    if (state.isLoading) return;

    // Rate Limiting
    final now = DateTime.now();
    if (_lastRequestTime != null && now.difference(_lastRequestTime!) < _rateLimitDuration) {
      state = state.copyWith(error: 'Please wait a few seconds before asking another question.');
      return;
    }
    _lastRequestTime = now;

    final userMsg = AiMessage(text: query.trim(), isAi: false);
    
    state = AiChatState(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final repository = _ref.read(aiRepositoryProvider);
      
      // Build safe context
      final authState = _ref.read(authProvider);
      Map<String, dynamic> context = {};
      
      if (authState is AuthAuthenticated) {
        final user = authState.user;
        context = {
          'role': user.role.name,
          if (user.collegeId != null) 'collegeId': user.collegeId,
          if (user.departmentId != null) 'departmentId': user.departmentId,
        };
      }

      // Bounded conversational history (last 6 turns, excluding welcome message)
      final nonWelcome = state.messages
          .where((m) => m.text.isNotEmpty && !m.text.startsWith('Hello! I am your Acadex AI Assistant'))
          .toList();
      final boundedHistory = nonWelcome.length > 6 ? nonWelcome.sublist(nonWelcome.length - 6) : nonWelcome;
      final historyPayload = boundedHistory
          .map((m) => <String, String>{
                'role': m.isAi ? 'assistant' : 'user',
                'content': m.text,
              })
          .toList();

      final aiResponse = await repository.sendChatMessage(
        query: query.trim(),
        context: context,
        history: historyPayload.isNotEmpty ? historyPayload : null,
      );
      
      if (!mounted) return;

      final aiMsg = AiMessage(
        text: aiResponse.answer,
        isAi: true,
        proposal: aiResponse.proposal,
        actionStatus: aiResponse.proposal != null ? 'PENDING' : null,
      );
      
      state = AiChatState(
        messages: [...state.messages, aiMsg],
        isLoading: false,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = AiChatState(
        messages: state.messages,
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> confirmAction(String actionId, String messageId) async {
    final messageIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final currentMsg = state.messages[messageIndex];
    if (currentMsg.actionStatus == 'CONFIRMING' ||
        currentMsg.actionStatus == 'RECONCILING' ||
        currentMsg.actionStatus == 'EXECUTED') {
      return;
    }

    // Check expiry client-side
    final expiresAtStr = currentMsg.proposal?['expiresAt'] as String?;
    if (expiresAtStr != null) {
      final expiryDate = DateTime.tryParse(expiresAtStr);
      if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
        final expiredMessages = List<AiMessage>.from(state.messages);
        expiredMessages[messageIndex] = currentMsg.copyWith(actionStatus: 'EXPIRED');
        state = state.copyWith(
          messages: expiredMessages,
          error: 'Action proposal has expired. Please request a fresh preview.',
        );
        return;
      }
    }

    // Set message to confirming
    final updatedMessages = List<AiMessage>.from(state.messages);
    updatedMessages[messageIndex] = currentMsg.copyWith(actionStatus: 'CONFIRMING');
    state = state.copyWith(messages: updatedMessages, error: null);

    try {
      final repository = _ref.read(aiRepositoryProvider);
      await repository.confirmAction(
        actionId: actionId,
        idempotencyKey: 'idem-$actionId',
      );

      if (!mounted) return;

      final actionType = currentMsg.proposal?['actionType'] ?? 'ACTION';
      final successSummary = actionType == 'CREATE_ASSIGNMENT'
          ? 'Assignment created and published successfully to student coursework.'
          : 'Calendar event successfully scheduled and published in the academic calendar.';

      final finalMessages = List<AiMessage>.from(state.messages);
      final idx = finalMessages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        finalMessages[idx] = finalMessages[idx].copyWith(
          actionStatus: 'EXECUTED',
          executionResultSummary: successSummary,
        );
      }

      state = state.copyWith(messages: finalMessages, error: null);
    } catch (e) {
      if (!mounted) return;
      final rawError = e.toString().replaceAll('Exception: ', '');

      // Reconcile uncertain outcomes on timeout or network interruption
      final lowerErr = rawError.toLowerCase();
      if (lowerErr.contains('timed out') ||
          lowerErr.contains('connection') ||
          lowerErr.contains('network') ||
          lowerErr.contains('504')) {
        await reconcileActionStatus(actionId, messageId, fallbackError: rawError);
      } else {
        final isExpired = lowerErr.contains('expired');
        final failedMessages = List<AiMessage>.from(state.messages);
        final idx = failedMessages.indexWhere((m) => m.id == messageId);
        if (idx != -1) {
          failedMessages[idx] = failedMessages[idx].copyWith(
            actionStatus: isExpired ? 'EXPIRED' : 'FAILED',
          );
        }
        state = state.copyWith(messages: failedMessages, error: rawError);
      }
    }
  }

  Future<void> reconcileActionStatus(
    String actionId,
    String messageId, {
    String? fallbackError,
  }) async {
    final messageIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final currentMsg = state.messages[messageIndex];
    final reconcilingMessages = List<AiMessage>.from(state.messages);
    reconcilingMessages[messageIndex] = currentMsg.copyWith(actionStatus: 'RECONCILING');
    state = state.copyWith(messages: reconcilingMessages, error: null);

    try {
      final repository = _ref.read(aiRepositoryProvider);
      final statusData = await repository.getActionStatus(actionId: actionId);

      if (!mounted) return;

      final serverStatus = (statusData['status'] as String? ?? 'PENDING').toUpperCase();
      final updatedMessages = List<AiMessage>.from(state.messages);
      final idx = updatedMessages.indexWhere((m) => m.id == messageId);
      if (idx == -1) return;

      if (serverStatus == 'EXECUTED') {
        final actionType = currentMsg.proposal?['actionType'] ?? 'ACTION';
        final successSummary = actionType == 'CREATE_ASSIGNMENT'
            ? 'Assignment verified as successfully created and published.'
            : 'Calendar event verified as successfully scheduled and published.';
        updatedMessages[idx] = updatedMessages[idx].copyWith(
          actionStatus: 'EXECUTED',
          executionResultSummary: successSummary,
        );
        state = state.copyWith(messages: updatedMessages, error: null);
      } else if (serverStatus == 'CANCELLED') {
        updatedMessages[idx] = updatedMessages[idx].copyWith(actionStatus: 'CANCELLED');
        state = state.copyWith(messages: updatedMessages, error: 'Proposal was cancelled.');
      } else if (serverStatus == 'EXPIRED') {
        updatedMessages[idx] = updatedMessages[idx].copyWith(actionStatus: 'EXPIRED');
        state = state.copyWith(messages: updatedMessages, error: 'Action proposal has expired.');
      } else {
        // Still pending on server
        updatedMessages[idx] = updatedMessages[idx].copyWith(actionStatus: 'FAILED');
        state = state.copyWith(
          messages: updatedMessages,
          error: fallbackError ?? 'Operation was not saved on server. You can safely retry.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      // Reconcile query also failed: mark outcome as UNCERTAIN
      final uncertainMessages = List<AiMessage>.from(state.messages);
      final idx = uncertainMessages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        uncertainMessages[idx] = uncertainMessages[idx].copyWith(actionStatus: 'UNCERTAIN');
      }
      state = state.copyWith(
        messages: uncertainMessages,
        error: 'Network connection issue. Persistence outcome is temporarily unknown. Tap "Reconcile Status" to verify.',
      );
    }
  }

  Future<void> cancelAction(String actionId, String messageId) async {
    final messageIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final currentMsg = state.messages[messageIndex];
    if (currentMsg.actionStatus == 'CANCELLED' || currentMsg.actionStatus == 'EXECUTED') {
      return;
    }

    try {
      final repository = _ref.read(aiRepositoryProvider);
      await repository.cancelAction(actionId: actionId);

      if (!mounted) return;

      final updatedMessages = List<AiMessage>.from(state.messages);
      final idx = updatedMessages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        updatedMessages[idx] = updatedMessages[idx].copyWith(actionStatus: 'CANCELLED');
      }

      state = state.copyWith(messages: updatedMessages, error: null);
    } catch (e) {
      if (!mounted) return;
      // Mark cancelled locally even if server returns error or was already cancelled
      final updatedMessages = List<AiMessage>.from(state.messages);
      final idx = updatedMessages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        updatedMessages[idx] = updatedMessages[idx].copyWith(actionStatus: 'CANCELLED');
      }
      state = state.copyWith(messages: updatedMessages, error: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous is AuthAuthenticated && (next is! AuthAuthenticated || previous.user.id != next.user.id)) {
      ref.invalidateSelf();
    }
  });
  return AiChatNotifier(ref);
});
