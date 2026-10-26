import '../../../academic_structure/domain/models/academic_models.dart';
import '../models/activation_model.dart';

abstract class AccountActivationRepository {
  /// Generates a new activation code for a pre-provisioned student.
  /// Returns the generated plaintext code which should be given to the student once.
  Future<String> generateActivationCode(Student student);

  /// Generates a new activation code for a pre-provisioned faculty.
  Future<String> generateFacultyActivationCode(Faculty faculty);

  /// Validates an activation code against a roll number or employee ID.
  /// Returns the User (Student or Faculty) as a Map if valid.
  Future<dynamic> validateActivation(String identifier, String code);

  /// Completes the activation process for either role and creates Auth account.
  Future<String> completeActivation(String identifier, String code, String newPassword);
}

abstract class ActivationRepository {
  Future<ActivationValidationResult> validateActivationCode(String activationCode);
  
  Future<SendOtpResult> sendActivationOtp({
    required String activationFlowId,
    required String contactMethod,
  });
  
  Future<VerifyOtpResult> verifyActivationOtp({
    required String activationFlowId,
    required String contactMethod,
    required String otp,
  });
  
  Future<CompleteActivationResult> completeActivation({
    required String activationToken,
    String? password,
    String? confirmPassword,
  });
}
