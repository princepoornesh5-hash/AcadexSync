class NoteMimeHelper {
  static const int maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB max
  static const int maxFileSizeMb = 25;

  static const List<String> allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'pdf',
    'ppt',
    'pptx',
    'doc',
    'docx',
  ];

  static const Map<String, String> _extensionToMime = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'pdf': 'application/pdf',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };

  /// Returns the RFC-compliant MIME type for a given filename or extension.
  static String resolveMimeType(String fileNameOrExtension) {
    String ext = fileNameOrExtension.trim().toLowerCase();
    if (ext.contains('.')) {
      ext = ext.split('.').last;
    }
    return _extensionToMime[ext] ?? 'application/octet-stream';
  }

  /// Checks whether an extension is supported.
  static bool isExtensionSupported(String fileNameOrExtension) {
    String ext = fileNameOrExtension.trim().toLowerCase();
    if (ext.contains('.')) {
      ext = ext.split('.').last;
    }
    return allowedExtensions.contains(ext);
  }

  /// Returns true if the file format can be previewed directly in-browser or in-app.
  static bool isPreviewableFormat(String? fileTypeOrName) {
    if (fileTypeOrName == null || fileTypeOrName.isEmpty) return false;
    String ext = fileTypeOrName.trim().toLowerCase();
    if (ext.contains('.')) {
      ext = ext.split('.').last;
    }
    return ext == 'pdf' || ext == 'jpg' || ext == 'jpeg' || ext == 'png';
  }

  /// Validates file size against the 25MB ceiling.
  static bool isFileSizeValid(int sizeBytes) {
    return sizeBytes > 0 && sizeBytes <= maxFileSizeBytes;
  }

  /// Sanitizes filenames to avoid path traversal and reserved characters.
  static String sanitizeFileName(String fileName) {
    var safeName = fileName.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
    safeName = safeName.replaceAll('..', '_');
    if (safeName.length > 100) {
      safeName = safeName.substring(safeName.length - 100);
    }
    return safeName;
  }
}
