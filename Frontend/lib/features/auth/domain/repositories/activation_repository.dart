import '../../../academic_structure/domain/models/academic_models.dart';

abstract class AccountActivationRepository {
  /// Generates a new activation code for a pre-provisioned student.
  /// Returns the generated plaintext code which should be given to the student once.
  Future<String> generateActivationCode(Student student);

  /// Validates an activation code against a roll number.
  /// Returns the Student if valid, otherwise throws an exception.
  Future<Student> validateActivation(String rollNumber, String code);

  /// Completes the activation process, creates the Auth account, and returns the User ID.
  Future<String> completeActivation(String rollNumber, String code, String newPassword);
}
