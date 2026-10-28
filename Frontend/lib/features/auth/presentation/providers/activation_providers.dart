import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/activation_model.dart';
import '../../domain/repositories/activation_repository.dart';
import '../../data/repositories/api_activation_repository.dart';

enum ActivationStep {
  enterCode, // Step 1: Input activation code
  confirmIdentity, // Step 2: Confirm identity ("Is this you?")
  selectContact, // Step 3: Select email/phone & request OTP
  verifyOtp, // Step 4: Verify 6-digit OTP code
  setPassword, // Step 5: Set & confirm password (or activate for existing user)
  success, // Step 6: Confirmation & redirect to login
}

class ActivationState {
  final ActivationStep currentStep;
  final bool isLoading;
  final String? error;
  final String? activationCode;
  final ActivationValidationResult? validationResult;
  final String? selectedContactMethod;
  final SendOtpResult? sendOtpResult;
  final int resendCooldownRemaining;
  final int otpExpiryRemaining;
  final String? activationToken;
  final bool isExistingUser;
  final CompleteActivationResult? completionResult;

  const ActivationState({
    this.currentStep = ActivationStep.enterCode,
    this.isLoading = false,
    this.error,
    this.activationCode,
    this.validationResult,
    this.selectedContactMethod,
    this.sendOtpResult,
    this.resendCooldownRemaining = 0,
    this.otpExpiryRemaining = 0,
    this.activationToken,
    this.isExistingUser = false,
    this.completionResult,
  });

  int get step => currentStep.index;

  Map<String, dynamic>? get validatedUser => completionResult?.user;

  String? get collegeCode => validationResult?.collegeCode;
  String? get instituteId => completionResult?.user?['instituteId'] as String?;

  ActivationState copyWith({
    ActivationStep? currentStep,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? activationCode,
    ActivationValidationResult? validationResult,
    String? selectedContactMethod,
    SendOtpResult? sendOtpResult,
    int? resendCooldownRemaining,
    int? otpExpiryRemaining,
    String? activationToken,
    bool clearActivationToken = false,
    bool? isExistingUser,
    CompleteActivationResult? completionResult,
  }) {
    return ActivationState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activationCode: activationCode ?? this.activationCode,
      validationResult: validationResult ?? this.validationResult,
      selectedContactMethod:
          selectedContactMethod ?? this.selectedContactMethod,
      sendOtpResult: sendOtpResult ?? this.sendOtpResult,
      resendCooldownRemaining:
          resendCooldownRemaining ?? this.resendCooldownRemaining,
      otpExpiryRemaining: otpExpiryRemaining ?? this.otpExpiryRemaining,
      activationToken: clearActivationToken
          ? null
          : (activationToken ?? this.activationToken),
      isExistingUser: isExistingUser ?? this.isExistingUser,
      completionResult: completionResult ?? this.completionResult,
    );
  }
}

class ActivationNotifier extends StateNotifier<ActivationState> {
  final ActivationRepository _repository;
  Timer? _cooldownTimer;
  Timer? _expiryTimer;

  ActivationNotifier(this._repository) : super(const ActivationState());

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _expiryTimer?.cancel();
    _expiryTimer = null;
  }

  void reset() {
    _cancelTimers();
    state = const ActivationState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Step 1: Validate Activation Code
  Future<bool> validateActivationCode(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) {
      state = state.copyWith(error: 'Please enter your activation code.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.validateActivationCode(code);
      String? defaultMethod;
      if (result.contactOptions.isNotEmpty) {
        defaultMethod = result.contactOptions.first.method;
      }

      state = state.copyWith(
        isLoading: false,
        activationCode: code,
        validationResult: result,
        selectedContactMethod: defaultMethod,
        isExistingUser: result.isExistingUser,
        currentStep: ActivationStep.confirmIdentity,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Step 2: Confirm Identity ("Is this you?")
  void confirmIdentity(bool confirmed) {
    if (!confirmed) {
      // User says "This Isn't Me" -> safely clear temporary state and restart
      reset();
      return;
    }

    if (state.validationResult == null) {
      state = state.copyWith(
        error: 'Please validate your activation code first.',
      );
      return;
    }

    if (state.validationResult!.contactOptions.isEmpty) {
      state = state.copyWith(
        error:
            'No registered email or phone found on this account. Please contact your campus administrator.',
      );
      return;
    }

    state = state.copyWith(
      currentStep: ActivationStep.selectContact,
      clearError: true,
    );
  }

  /// Step 3: Select Contact Method
  void selectContactMethod(String method) {
    if (state.selectedContactMethod == method) return;
    state = state.copyWith(selectedContactMethod: method, clearError: true);
  }

  /// Step 3 -> 4: Send OTP
  Future<bool> sendOtp() async {
    final flowId = state.validationResult?.activationFlowId;
    final method = state.selectedContactMethod;

    if (flowId == null || flowId.isEmpty) {
      state = state.copyWith(
        error:
            'Activation session expired. Please re-enter your activation code.',
      );
      return false;
    }

    if (method == null || method.isEmpty) {
      state = state.copyWith(
        error:
            'Please select a contact method to receive your verification code.',
      );
      return false;
    }

    if (state.resendCooldownRemaining > 0) {
      state = state.copyWith(
        error:
            'Please wait ${state.resendCooldownRemaining} seconds before requesting another code.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.sendActivationOtp(
        activationFlowId: flowId,
        contactMethod: method,
      );

      _startCooldownTimer(result.cooldownSeconds);
      _startExpiryTimer(result.expiresInSeconds);

      state = state.copyWith(
        isLoading: false,
        sendOtpResult: result,
        resendCooldownRemaining: result.cooldownSeconds,
        otpExpiryRemaining: result.expiresInSeconds,
        currentStep: ActivationStep.verifyOtp,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Resend OTP (subject to cooldown)
  Future<bool> resendOtp() async {
    if (state.resendCooldownRemaining > 0) return false;
    return sendOtp();
  }

  void _startCooldownTimer(int seconds) {
    _cooldownTimer?.cancel();
    state = state.copyWith(resendCooldownRemaining: seconds);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCooldownRemaining > 1) {
        state = state.copyWith(
          resendCooldownRemaining: state.resendCooldownRemaining - 1,
        );
      } else {
        state = state.copyWith(resendCooldownRemaining: 0);
        timer.cancel();
      }
    });
  }

  void _startExpiryTimer(int seconds) {
    _expiryTimer?.cancel();
    state = state.copyWith(otpExpiryRemaining: seconds);

    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.otpExpiryRemaining > 1) {
        state = state.copyWith(
          otpExpiryRemaining: state.otpExpiryRemaining - 1,
        );
      } else {
        state = state.copyWith(otpExpiryRemaining: 0);
        timer.cancel();
      }
    });
  }

  /// Step 4: Verify OTP
  Future<bool> verifyOtp(String rawOtp) async {
    final flowId = state.validationResult?.activationFlowId;
    final method = state.selectedContactMethod;
    final otp = rawOtp.trim();

    if (flowId == null || method == null) {
      state = state.copyWith(
        error: 'Verification session expired. Please start over.',
      );
      return false;
    }

    if (otp.length != 6) {
      state = state.copyWith(
        error: 'Please enter the complete 6-digit verification code.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.verifyActivationOtp(
        activationFlowId: flowId,
        contactMethod: method,
        otp: otp,
      );

      _cancelTimers();

      state = state.copyWith(
        isLoading: false,
        activationToken: result.activationToken,
        isExistingUser: result.isExistingActiveUser || state.isExistingUser,
        currentStep: ActivationStep.setPassword,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Step 5: Complete Activation
  Future<bool> completeActivation({
    String? password,
    String? confirmPassword,
  }) async {
    final token = state.activationToken;
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        error:
            'Verification session has expired. Please verify your OTP again.',
        currentStep: ActivationStep.selectContact,
      );
      return false;
    }

    // New user client-side password policy validation
    if (!state.isExistingUser) {
      if (password == null || password.isEmpty) {
        state = state.copyWith(error: 'Please enter a password.');
        return false;
      }
      if (confirmPassword == null || confirmPassword.isEmpty) {
        state = state.copyWith(error: 'Please confirm your password.');
        return false;
      }
      if (password != confirmPassword) {
        state = state.copyWith(error: 'Passwords do not match.');
        return false;
      }
      if (password.length < 8) {
        state = state.copyWith(
          error: 'Password must be at least 8 characters long.',
        );
        return false;
      }
      if (!RegExp(r'[a-zA-Z]').hasMatch(password) ||
          !RegExp(r'[0-9]').hasMatch(password)) {
        state = state.copyWith(
          error: 'Password must contain at least one letter and one number.',
        );
        return false;
      }
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.completeActivation(
        activationToken: token,
        password: state.isExistingUser ? null : password,
        confirmPassword: state.isExistingUser ? null : confirmPassword,
      );

      state = state.copyWith(
        isLoading: false,
        completionResult: result,
        clearActivationToken:
            true, // Immediately clear secret token from memory
        currentStep: ActivationStep.success,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Allow moving safely backward to prior steps
  void goToStep(ActivationStep step) {
    if (step == ActivationStep.enterCode) {
      reset();
      return;
    }
    // Cannot skip forward to setPassword without an verified activation token
    if (step == ActivationStep.setPassword && state.activationToken == null) {
      return;
    }
    // Cannot skip to verifyOtp without sending OTP
    if (step == ActivationStep.verifyOtp && state.sendOtpResult == null) {
      return;
    }
    // Cannot skip to selectContact without validationResult
    if (step == ActivationStep.selectContact &&
        state.validationResult == null) {
      return;
    }
    state = state.copyWith(currentStep: step, clearError: true);
  }
}

final apiActivationRepositoryProvider = Provider<ActivationRepository>((ref) {
  return ApiActivationRepository();
});

final activationRepositoryProvider = Provider<ActivationRepository>((ref) {
  return ref.watch(apiActivationRepositoryProvider);
});

final activationNotifierProvider =
    StateNotifierProvider.autoDispose<ActivationNotifier, ActivationState>((
      ref,
    ) {
      return ActivationNotifier(ref.watch(activationRepositoryProvider));
    });
