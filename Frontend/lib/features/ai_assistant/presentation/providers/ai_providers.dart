import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/ai_message.dart';
import '../../domain/models/ai_stream_event.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../data/repositories/api_ai_repository.dart';
import '../../data/repositories/mock_ai_repository.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  // Use MockAiRepository only if explicitly requested at compile time with --dart-define=USE_MOCK_AI=true
  const bool forceMock = bool.fromEnvironment(
    'USE_MOCK_AI',
    defaultValue: false,
  );
  if (forceMock) {
    return MockAiRepository();
  }
  return ApiAiRepository();
});

class AiChatState {
  final List<AiMessage> messages;
  final bool isLoading;
  final String? error;
  final String?
  errorCategory; // 'application_limit', 'gemini_quota_limit', 'timeout', 'auth_config', 'network', 'generic'
  final int? retryAfterSeconds;
  final int? cooldownRemainingSeconds;
  final AiStreamStatus streamStatus;
  final String? activeMessageId;
  final String? lastSubmittedQuery;
  final String? correlationId;

  AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.errorCategory,
    this.retryAfterSeconds,
    this.cooldownRemainingSeconds,
    this.streamStatus = AiStreamStatus.idle,
    this.activeMessageId,
    this.lastSubmittedQuery,
    this.correlationId,
  });

  bool get isStreaming =>
      streamStatus == AiStreamStatus.connecting ||
      streamStatus == AiStreamStatus.waitingForFirstChunk ||
      streamStatus == AiStreamStatus.streaming;

  bool get isCooldownActive => (cooldownRemainingSeconds ?? 0) > 0;

  AiChatState copyWith({
    List<AiMessage>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? errorCategory,
    int? retryAfterSeconds,
    int? cooldownRemainingSeconds,
    bool clearCooldown = false,
    AiStreamStatus? streamStatus,
    String? activeMessageId,
    bool clearActiveMessage = false,
    String? lastSubmittedQuery,
    String? correlationId,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      errorCategory: clearError ? null : (errorCategory ?? this.errorCategory),
      retryAfterSeconds: clearError
          ? null
          : (retryAfterSeconds ?? this.retryAfterSeconds),
      cooldownRemainingSeconds: clearCooldown
          ? null
          : (cooldownRemainingSeconds ?? this.cooldownRemainingSeconds),
      streamStatus: streamStatus ?? this.streamStatus,
      activeMessageId: clearActiveMessage
          ? null
          : (activeMessageId ?? this.activeMessageId),
      lastSubmittedQuery: lastSubmittedQuery ?? this.lastSubmittedQuery,
      correlationId: correlationId ?? this.correlationId,
    );
  }
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final Ref _ref;
  DateTime? _lastRequestTime;
  StreamSubscription<AiStreamEvent>? _streamSubscription;
  Completer<void>? _activeCompleter;
  Timer? _cooldownTimer;

  AiChatNotifier(this._ref) : super(AiChatState()) {
    _initWelcomeMessage();
  }

  void _initWelcomeMessage() {
    state = state.copyWith(
      messages: [
        AiMessage(
          text:
              "Hello! I am your Acadex AI Assistant. How can I help you with your academic tasks today?",
          isAi: true,
        ),
      ],
    );
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    final clamped = seconds.clamp(1, 120);
    state = state.copyWith(
      retryAfterSeconds: clamped,
      cooldownRemainingSeconds: clamped,
    );

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = state.cooldownRemainingSeconds ?? 0;
      if (remaining <= 1) {
        timer.cancel();
        _cooldownTimer = null;
        state = state.copyWith(clearCooldown: true);
      } else {
        state = state.copyWith(cooldownRemainingSeconds: remaining - 1);
      }
    });
  }

  void clearChat() {
    stopGenerating();
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    state = AiChatState();
    _initWelcomeMessage();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void stopGenerating() {
    if (_streamSubscription != null) {
      _streamSubscription?.cancel();
      _streamSubscription = null;
    }

    if (state.activeMessageId != null) {
      final updatedMessages = List<AiMessage>.from(state.messages);
      final idx = updatedMessages.indexWhere(
        (m) => m.id == state.activeMessageId,
      );
      if (idx != -1) {
        final activeMsg = updatedMessages[idx];
        if (activeMsg.text.trim().isNotEmpty) {
          updatedMessages[idx] = activeMsg.copyWith(
            isStreaming: false,
            isInterrupted: true,
          );
        } else {
          updatedMessages.removeAt(idx);
        }
      }
      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        streamStatus: AiStreamStatus.cancelled,
        clearActiveMessage: true,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        streamStatus: AiStreamStatus.cancelled,
        clearActiveMessage: true,
      );
    }

    if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
      _activeCompleter!.complete();
      _activeCompleter = null;
    }
  }

  Future<void> retryLastMessage() {
    if (state.isCooldownActive || state.isLoading || state.isStreaming) {
      return Future.value();
    }

    final queryToRetry =
        state.lastSubmittedQuery ??
        (state.messages.where((m) => !m.isAi).isNotEmpty
            ? state.messages.where((m) => !m.isAi).last.text
            : null);

    if (queryToRetry == null || queryToRetry.trim().isEmpty)
      return Future.value();

    // If last message was a failed or interrupted AI message, remove it cleanly before retrying
    if (state.messages.isNotEmpty && state.messages.last.isAi) {
      final lastAi = state.messages.last;
      if (lastAi.actionStatus == null ||
          lastAi.actionStatus == 'FAILED' ||
          lastAi.isInterrupted) {
        final trimmed = List<AiMessage>.from(state.messages)..removeLast();
        state = state.copyWith(messages: trimmed, clearError: true);
      }
    }

    // Re-dispatch using isRetry: true to avoid duplicating user message in list
    return sendMessage(queryToRetry, isRetry: true);
  }

  Future<void> sendMessage(String query, {bool isRetry = false}) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;
    if (state.isCooldownActive) return;
    if (state.isStreaming || state.isLoading) return;

    // Rapid double-submission protection (ignore rapid clicks within 800ms)
    final now = DateTime.now();
    if (!isRetry &&
        _lastRequestTime != null &&
        now.difference(_lastRequestTime!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastRequestTime = now;

    stopGenerating();

    final assistantId = const Uuid().v4();
    final clientCorrelationId =
        'cli_${now.millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}';

    if (isRetry) {
      // Re-use existing user message in history, clear error and set connecting
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        streamStatus: AiStreamStatus.connecting,
        activeMessageId: assistantId,
        lastSubmittedQuery: trimmedQuery,
        correlationId: clientCorrelationId,
      );
    } else {
      final userMsg = AiMessage(text: trimmedQuery, isAi: false);
      state = state.copyWith(
        messages: [...state.messages, userMsg],
        isLoading: true,
        clearError: true,
        streamStatus: AiStreamStatus.connecting,
        activeMessageId: assistantId,
        lastSubmittedQuery: trimmedQuery,
        correlationId: clientCorrelationId,
      );
    }

    final completer = Completer<void>();
    _activeCompleter = completer;

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

      // Bounded conversational history (last 6 turns, excluding welcome)
      final historyEligible = state.messages
          .where(
            (m) =>
                m.text.isNotEmpty &&
                m.id != assistantId &&
                !m.text.startsWith('Hello! I am your Acadex AI Assistant'),
          )
          .toList();
      final boundedHistory = historyEligible.length > 6
          ? historyEligible.sublist(historyEligible.length - 6)
          : historyEligible;
      final historyPayload = boundedHistory
          .map(
            (m) => <String, String>{
              'role': m.isAi ? 'assistant' : 'user',
              'content': m.text,
            },
          )
          .toList();

      state = state.copyWith(streamStatus: AiStreamStatus.waitingForFirstChunk);

      final stream = repository.streamChatMessage(
        query: trimmedQuery,
        context: context,
        history: historyPayload.isNotEmpty ? historyPayload : null,
      );

      _streamSubscription = stream.listen(
        (event) {
          if (!mounted) return;

          switch (event) {
            case AiStreamStartEvent e:
              final currentMsgs = List<AiMessage>.from(state.messages);
              final idx = currentMsgs.indexWhere((m) => m.id == assistantId);
              if (idx != -1) {
                currentMsgs[idx] = currentMsgs[idx].copyWith(
                  correlationId: e.correlationId,
                );
                state = state.copyWith(
                  messages: currentMsgs,
                  correlationId: e.correlationId,
                );
              }
              break;

            case AiStreamDeltaEvent e:
              final currentMsgs = List<AiMessage>.from(state.messages);
              final idx = currentMsgs.indexWhere((m) => m.id == assistantId);
              if (idx == -1) {
                currentMsgs.add(
                  AiMessage(
                    id: assistantId,
                    text: e.text,
                    isAi: true,
                    isStreaming: true,
                  ),
                );
              } else {
                currentMsgs[idx] = currentMsgs[idx].copyWith(
                  text: currentMsgs[idx].text + e.text,
                  isStreaming: true,
                );
              }
              state = state.copyWith(
                messages: currentMsgs,
                streamStatus: AiStreamStatus.streaming,
              );
              break;

            case AiStreamProposalEvent e:
              final currentMsgs = List<AiMessage>.from(state.messages);
              final idx = currentMsgs.indexWhere((m) => m.id == assistantId);
              if (idx == -1) {
                currentMsgs.add(
                  AiMessage(
                    id: assistantId,
                    text: '',
                    isAi: true,
                    isStreaming: true,
                    proposal: e.proposal,
                    actionStatus: 'PENDING',
                  ),
                );
              } else {
                currentMsgs[idx] = currentMsgs[idx].copyWith(
                  proposal: e.proposal,
                  actionStatus: 'PENDING',
                );
              }
              state = state.copyWith(messages: currentMsgs);
              break;

            case AiStreamDoneEvent e:
              final currentMsgs = List<AiMessage>.from(state.messages);
              final idx = currentMsgs.indexWhere((m) => m.id == assistantId);
              if (idx == -1) {
                currentMsgs.add(
                  AiMessage(
                    id: assistantId,
                    text: e.answer,
                    isAi: true,
                    isStreaming: false,
                    proposal: e.proposal,
                    actionStatus: e.proposal != null ? 'PENDING' : null,
                  ),
                );
              } else {
                currentMsgs[idx] = currentMsgs[idx].copyWith(
                  text: currentMsgs[idx].text.isEmpty
                      ? e.answer
                      : currentMsgs[idx].text,
                  isStreaming: false,
                  proposal: e.proposal ?? currentMsgs[idx].proposal,
                  actionStatus:
                      (e.proposal != null || currentMsgs[idx].proposal != null)
                      ? (currentMsgs[idx].actionStatus ?? 'PENDING')
                      : null,
                );
              }
              state = state.copyWith(
                messages: currentMsgs,
                isLoading: false,
                streamStatus: AiStreamStatus.completed,
                clearActiveMessage: true,
                clearError: true,
              );
              _streamSubscription?.cancel();
              _streamSubscription = null;
              if (!completer.isCompleted) completer.complete();
              break;

            case AiStreamErrorEvent e:
              final currentMsgs = List<AiMessage>.from(state.messages);
              final idx = currentMsgs.indexWhere((m) => m.id == assistantId);
              if (idx != -1) {
                if (currentMsgs[idx].text.isNotEmpty) {
                  currentMsgs[idx] = currentMsgs[idx].copyWith(
                    isStreaming: false,
                    isInterrupted: true,
                  );
                } else {
                  currentMsgs.removeAt(idx);
                }
              }

              if (e.retryAfterSeconds != null && e.retryAfterSeconds! > 0) {
                _startCooldown(e.retryAfterSeconds!);
              }

              state = state.copyWith(
                messages: currentMsgs,
                isLoading: false,
                streamStatus: AiStreamStatus.failed,
                error: e.message,
                errorCategory: e.category ?? 'generic',
                retryAfterSeconds: e.retryAfterSeconds,
                correlationId: e.correlationId,
                clearActiveMessage: true,
              );
              _streamSubscription?.cancel();
              _streamSubscription = null;
              if (!completer.isCompleted) completer.complete();
              break;
          }
        },
        onError: (err) {
          if (!mounted) return;
          final currentMsgs = List<AiMessage>.from(state.messages);
          final idx = currentMsgs.indexWhere((m) => m.id == assistantId);
          if (idx != -1) {
            if (currentMsgs[idx].text.isNotEmpty) {
              currentMsgs[idx] = currentMsgs[idx].copyWith(
                isStreaming: false,
                isInterrupted: true,
              );
            } else {
              currentMsgs.removeAt(idx);
            }
          }

          String errorMsg = err.toString().replaceAll('Exception: ', '');
          String errorCategory = 'generic';
          int? retryAfter;

          if (err is AiChatException) {
            errorMsg = err.message;
            errorCategory = err.category;
            retryAfter = err.retryAfterSeconds;
          }

          if (retryAfter != null && retryAfter > 0) {
            _startCooldown(retryAfter);
          }

          state = state.copyWith(
            messages: currentMsgs,
            isLoading: false,
            streamStatus: AiStreamStatus.failed,
            error: errorMsg,
            errorCategory: errorCategory,
            retryAfterSeconds: retryAfter,
            clearActiveMessage: true,
          );
          _streamSubscription?.cancel();
          _streamSubscription = null;
          if (!completer.isCompleted) completer.complete();
        },
        onDone: () {
          if (!mounted) return;
          if (state.isStreaming) {
            final currentMsgs = List<AiMessage>.from(state.messages);
            final idx = currentMsgs.indexWhere((m) => m.id == assistantId);
            if (idx != -1) {
              currentMsgs[idx] = currentMsgs[idx].copyWith(isStreaming: false);
            }
            state = state.copyWith(
              messages: currentMsgs,
              isLoading: false,
              streamStatus: AiStreamStatus.completed,
              clearActiveMessage: true,
            );
          }
          _streamSubscription = null;
          if (!completer.isCompleted) completer.complete();
        },
      );
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      String errorCategory = 'generic';
      int? retryAfter;

      if (e is AiChatException) {
        errorMsg = e.message;
        errorCategory = e.category;
        retryAfter = e.retryAfterSeconds;
      }

      if (retryAfter != null && retryAfter > 0) {
        _startCooldown(retryAfter);
      }

      state = state.copyWith(
        isLoading: false,
        streamStatus: AiStreamStatus.failed,
        error: errorMsg,
        errorCategory: errorCategory,
        retryAfterSeconds: retryAfter,
        clearActiveMessage: true,
      );
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future;
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
        expiredMessages[messageIndex] = currentMsg.copyWith(
          actionStatus: 'EXPIRED',
        );
        state = state.copyWith(
          messages: expiredMessages,
          error: 'Action proposal has expired. Please request a fresh preview.',
        );
        return;
      }
    }

    // Set message to confirming
    final updatedMessages = List<AiMessage>.from(state.messages);
    updatedMessages[messageIndex] = currentMsg.copyWith(
      actionStatus: 'CONFIRMING',
    );
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
          : actionType == 'CREATE_REQUEST'
          ? 'Request submitted successfully to the responsible authority.'
          : actionType == 'RESPOND_REQUEST'
          ? 'Request decision recorded and applied successfully.'
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
        await reconcileActionStatus(
          actionId,
          messageId,
          fallbackError: rawError,
        );
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
    reconcilingMessages[messageIndex] = currentMsg.copyWith(
      actionStatus: 'RECONCILING',
    );
    state = state.copyWith(messages: reconcilingMessages, error: null);

    try {
      final repository = _ref.read(aiRepositoryProvider);
      final statusData = await repository.getActionStatus(actionId: actionId);

      if (!mounted) return;

      final serverStatus = (statusData['status'] as String? ?? 'PENDING')
          .toUpperCase();
      final updatedMessages = List<AiMessage>.from(state.messages);
      final idx = updatedMessages.indexWhere((m) => m.id == messageId);
      if (idx == -1) return;

      if (serverStatus == 'EXECUTED') {
        final actionType = currentMsg.proposal?['actionType'] ?? 'ACTION';
        final successSummary = actionType == 'CREATE_ASSIGNMENT'
            ? 'Assignment verified as successfully created and published.'
            : actionType == 'CREATE_REQUEST'
            ? 'Request verified as successfully submitted for review.'
            : actionType == 'RESPOND_REQUEST'
            ? 'Request decision verified as successfully recorded.'
            : 'Calendar event verified as successfully scheduled and published.';
        updatedMessages[idx] = updatedMessages[idx].copyWith(
          actionStatus: 'EXECUTED',
          executionResultSummary: successSummary,
        );
        state = state.copyWith(messages: updatedMessages, error: null);
      } else if (serverStatus == 'CANCELLED') {
        updatedMessages[idx] = updatedMessages[idx].copyWith(
          actionStatus: 'CANCELLED',
        );
        state = state.copyWith(
          messages: updatedMessages,
          error: 'Proposal was cancelled.',
        );
      } else if (serverStatus == 'EXPIRED') {
        updatedMessages[idx] = updatedMessages[idx].copyWith(
          actionStatus: 'EXPIRED',
        );
        state = state.copyWith(
          messages: updatedMessages,
          error: 'Action proposal has expired.',
        );
      } else {
        updatedMessages[idx] = updatedMessages[idx].copyWith(
          actionStatus: 'FAILED',
        );
        state = state.copyWith(
          messages: updatedMessages,
          error:
              fallbackError ??
              'Operation was not saved on server. You can safely retry.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      final uncertainMessages = List<AiMessage>.from(state.messages);
      final idx = uncertainMessages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        uncertainMessages[idx] = uncertainMessages[idx].copyWith(
          actionStatus: 'UNCERTAIN',
        );
      }
      state = state.copyWith(
        messages: uncertainMessages,
        error:
            'Network connection issue. Persistence outcome is temporarily unknown. Tap "Reconcile Status" to verify.',
      );
    }
  }

  Future<void> cancelAction(String actionId, String messageId) async {
    final messageIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final currentMsg = state.messages[messageIndex];
    if (currentMsg.actionStatus == 'CANCELLED' ||
        currentMsg.actionStatus == 'EXECUTED') {
      return;
    }

    try {
      final repository = _ref.read(aiRepositoryProvider);
      await repository.cancelAction(actionId: actionId);

      if (!mounted) return;

      final updatedMessages = List<AiMessage>.from(state.messages);
      final idx = updatedMessages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        updatedMessages[idx] = updatedMessages[idx].copyWith(
          actionStatus: 'CANCELLED',
        );
      }

      state = state.copyWith(messages: updatedMessages, error: null);
    } catch (e) {
      if (!mounted) return;
      final updatedMessages = List<AiMessage>.from(state.messages);
      final idx = updatedMessages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        updatedMessages[idx] = updatedMessages[idx].copyWith(
          actionStatus: 'CANCELLED',
        );
      }
      state = state.copyWith(
        messages: updatedMessages,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _streamSubscription?.cancel();
    super.dispose();
  }
}

final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((
  ref,
) {
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous is AuthAuthenticated &&
        (next is! AuthAuthenticated || previous.user.id != next.user.id)) {
      ref.invalidateSelf();
    }
  });
  return AiChatNotifier(ref);
});
