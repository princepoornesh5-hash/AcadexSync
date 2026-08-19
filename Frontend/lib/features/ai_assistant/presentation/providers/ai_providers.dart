import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/ai_message.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../data/repositories/firebase_ai_repository.dart';
import '../../data/repositories/mock_ai_repository.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return MockAiRepository();
  }
  return FirebaseAiRepository();
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
      error: error, // Can be set to null explicitly by not keeping the old value if not provided, but typically we want `error: error ?? this.error`. Actually, passing null to clear the error is important. Let's do a custom clearError or just allow null.
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
          // DO NOT pass sensitive tokens, credentials, or private identifiers unnecessarily
        };
      }

      final responseText = await repository.sendMessage(query: query.trim(), context: context);
      
      if (!mounted) return;

      final aiMsg = AiMessage(text: responseText, isAi: true);
      
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
}

final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous is AuthAuthenticated && (next is! AuthAuthenticated || previous.user.id != next.user.id)) {
      ref.invalidateSelf();
    }
  });
  return AiChatNotifier(ref);
});
