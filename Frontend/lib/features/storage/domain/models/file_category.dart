enum FileCategory {
  profileImage,
  certificate,
  noteAttachment,
  other
}

extension FileCategoryExtension on FileCategory {
  String get value {
    switch (this) {
      case FileCategory.profileImage:
        return 'profile_image';
      case FileCategory.certificate:
        return 'certificate';
      case FileCategory.noteAttachment:
        return 'note_attachment';
      case FileCategory.other:
        return 'other';
    }
  }

  static FileCategory fromValue(String value) {
    switch (value) {
      case 'profile_image':
        return FileCategory.profileImage;
      case 'certificate':
        return FileCategory.certificate;
      case 'note_attachment':
        return FileCategory.noteAttachment;
      default:
        return FileCategory.other;
    }
  }
}
