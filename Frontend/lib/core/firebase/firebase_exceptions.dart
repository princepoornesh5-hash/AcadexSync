import 'package:firebase_auth/firebase_auth.dart';

sealed class AcadexBackendException implements Exception {
  final String message;
  const AcadexBackendException(this.message);

  @override
  String toString() => message;
}

class BackendAuthException extends AcadexBackendException {
  const BackendAuthException(super.message);
}

class BackendPermissionException extends AcadexBackendException {
  const BackendPermissionException(super.message);
}

class BackendNetworkException extends AcadexBackendException {
  const BackendNetworkException(super.message);
}

class BackendDatabaseException extends AcadexBackendException {
  const BackendDatabaseException(super.message);
}

class BackendStorageException extends AcadexBackendException {
  const BackendStorageException(super.message);
}

class BackendValidationException extends AcadexBackendException {
  const BackendValidationException(super.message);
}

class UnknownBackendException extends AcadexBackendException {
  const UnknownBackendException(super.message);
}

class FirebaseErrorMapper {
  static AcadexBackendException map(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return const BackendAuthException('The email address format is invalid.');
        case 'user-not-found':
          return const BackendAuthException('No user account exists with this email.');
        case 'wrong-password':
          return const BackendAuthException('Incorrect password.');
        case 'invalid-credential':
          return const BackendAuthException('Invalid email or password.');
        case 'user-disabled':
          return const BackendAuthException('This account has been disabled.');
        case 'too-many-requests':
          return const BackendAuthException('Too many failed attempts. Please try again later.');
        case 'operation-not-allowed':
          return const BackendAuthException('Email/password authentication is not enabled in Firebase Console.');
        case 'email-already-in-use':
          return const BackendAuthException('The email address is already registered.');
        case 'weak-password':
          return const BackendAuthException('The password provided is too weak.');
        case 'network-request-failed':
          return const BackendNetworkException('Network error. Please check your internet connection.');
        default:
          return BackendAuthException(error.message ?? 'Authentication failed.');
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return const BackendPermissionException('You are not authorized to perform this action.');
        case 'unavailable':
          return const BackendNetworkException('Service temporarily unavailable. Try again later.');
        default:
          if (error.plugin == 'firestore') {
            return BackendDatabaseException(error.message ?? 'Database transaction failed.');
          } else if (error.plugin == 'storage') {
            return BackendStorageException(error.message ?? 'File storage transaction failed.');
          }
          return UnknownBackendException(error.message ?? 'An unexpected database error occurred.');
      }
    }

    return UnknownBackendException(error.toString());
  }
}
