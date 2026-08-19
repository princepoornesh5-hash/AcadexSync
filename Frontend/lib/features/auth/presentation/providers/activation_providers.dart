import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../domain/repositories/activation_repository.dart';
import '../../data/repositories/mock_activation_repository.dart';
import '../../data/repositories/firebase_activation_repository.dart';

final activationRepositoryProvider = Provider<AccountActivationRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return mockActivationRepo;
  }
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FirebaseActivationRepository(firestoreService);
});

class ActivationState {
  final int step; // 0: Input ID/Code, 1: Password Creation, 2: Success
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? validatedUser;
  final String? identifier;
  final String? activationCode;

  const ActivationState({
    this.step = 0,
    this.isLoading = false,
    this.error,
    this.validatedUser,
    this.identifier,
    this.activationCode,
  });

  ActivationState copyWith({
    int? step,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? validatedUser,
    String? identifier,
    String? activationCode,
    bool clearError = false,
  }) {
    return ActivationState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      validatedUser: validatedUser ?? this.validatedUser,
      identifier: identifier ?? this.identifier,
      activationCode: activationCode ?? this.activationCode,
    );
  }
}

class ActivationNotifier extends StateNotifier<ActivationState> {
  final AccountActivationRepository _repository;

  ActivationNotifier(this._repository) : super(const ActivationState());

  void reset() {
    state = const ActivationState();
  }

  Future<void> validateCode(String identifier, String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final user = await _repository.validateActivation(identifier, code);
      state = state.copyWith(
        isLoading: false,
        step: 1, // Move to Password step
        validatedUser: user as Map<String, dynamic>?,
        identifier: identifier,
        activationCode: code,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll("Exception: ", ""),
      );
    }
  }

  Future<void> completeActivation(String password) async {
    if (state.identifier == null || state.activationCode == null) {
      state = state.copyWith(error: "Missing activation details.");
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await _repository.completeActivation(state.identifier!, state.activationCode!, password);
      state = state.copyWith(
        isLoading: false,
        step: 2, // Move to Success step
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll("Exception: ", ""),
      );
    }
  }
  
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final activationNotifierProvider = StateNotifierProvider<ActivationNotifier, ActivationState>((ref) {
  final repository = ref.watch(activationRepositoryProvider);
  return ActivationNotifier(repository);
});
