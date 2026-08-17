// Centralized file validation constants
// Change these to update limits application-wide
class CertificateFileConfig {
  /// Maximum certificate file size in bytes (10 MB)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Allowed file extensions for certificate uploads
  static const List<String> allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];

  /// Allowed MIME types for certificate uploads
  static const List<String> allowedMimeTypes = [
    'application/pdf',
    'image/jpeg',
    'image/png',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ];

  /// Blocked executable extensions — never allowed
  static const List<String> blockedExtensions = ['exe', 'dmg', 'apk', 'bat', 'sh', 'cmd', 'msi'];
}

String? validateCertificateFile({
  required String fileName,
  required int fileSizeBytes,
  String? mimeType,
}) {
  if (fileSizeBytes == 0) return 'File is empty.';
  if (fileSizeBytes > CertificateFileConfig.maxFileSizeBytes) {
    return 'File too large. Maximum size is 10MB.';
  }

  final ext = fileName.split('.').last.toLowerCase();

  if (CertificateFileConfig.blockedExtensions.contains(ext)) {
    return 'Executable files are not allowed.';
  }
  if (!CertificateFileConfig.allowedExtensions.contains(ext)) {
    return 'Unsupported file type. Allowed: PDF, JPG, PNG, DOC, DOCX.';
  }
  if (mimeType != null && !CertificateFileConfig.allowedMimeTypes.any((m) => mimeType.startsWith(m))) {
    return 'Invalid file format.';
  }
  return null;
}
