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
      error: error, // Can be set to null explicitly by not keeping the old value if not provided, but typically we want `error: error ?? this.error`. Actually, passing null to clear the error is important. Let's do a custom clearError or just allow null.
    );
  }
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final Ref _ref;

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
      
      final aiMsg = AiMessage(text: responseText, isAi: true);
      
      state = AiChatState(
        messages: [...state.messages, aiMsg],
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = AiChatState(
        messages: state.messages,
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  return AiChatNotifier(ref);
});
