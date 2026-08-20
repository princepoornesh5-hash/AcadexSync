import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/api_auth_repository.dart';
import '../providers/auth_provider.dart';

class ActivationState {
  final int step; // 0: Input college code + ID + activation code, 1: Set password, 2: Success
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? validatedUser;
  final String? collegeCode;
  final String? instituteId;
  final String? activationCode;

  const ActivationState({
    this.step = 0,
    this.isLoading = false,
    this.error,
    this.validatedUser,
    this.collegeCode,
    this.instituteId,
    this.activationCode,
  });

  ActivationState copyWith({
    int? step,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? validatedUser,
    String? collegeCode,
    String? instituteId,
    String? activationCode,
    bool clearError = false,
  }) {
    return ActivationState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      validatedUser: validatedUser ?? this.validatedUser,
      collegeCode: collegeCode ?? this.collegeCode,
      instituteId: instituteId ?? this.instituteId,
      activationCode: activationCode ?? this.activationCode,
    );
  }
}

class ActivationNotifier extends StateNotifier<ActivationState> {
  final ApiAuthRepository _authRepository;

  ActivationNotifier(this._authRepository) : super(const ActivationState());

  void reset() {
    state = const ActivationState();
  }

  /// Advance to password step — save credentials locally (no validation request to backend yet)
  void proceedToPasswordStep(String collegeCode, String instituteId, String activationCode) {
    state = state.copyWith(
      step: 1,
      collegeCode: collegeCode,
      instituteId: instituteId,
      activationCode: activationCode,
    );
  }

  /// Complete the activation in a single backend call with all credentials + password.
  /// The backend validates the code AND activates the account atomically.
  Future<void> completeActivation(String password) async {
    if (state.collegeCode == null || state.instituteId == null || state.activationCode == null) {
      state = state.copyWith(error: "Missing activation details. Please start over.");
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _authRepository.activateAccount(
        collegeCode: state.collegeCode!,
        instituteId: state.instituteId!,
        activationCode: state.activationCode!,
        password: password,
      );

      state = state.copyWith(
        isLoading: false,
        step: 2, // Success step
        validatedUser: result['user'] as Map<String, dynamic>?,
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
  final authRepository = ref.watch(apiAuthRepositoryProvider);
  return ActivationNotifier(authRepository);
});
