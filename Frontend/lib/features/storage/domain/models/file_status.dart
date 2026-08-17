enum FileStatus {
  active,
  deleted,
  failed,
}

extension FileStatusExtension on FileStatus {
  String get value {
    switch (this) {
      case FileStatus.active:
        return 'active';
      case FileStatus.deleted:
        return 'deleted';
      case FileStatus.failed:
        return 'failed';
    }
  }

  static FileStatus fromValue(String value) {
    switch (value) {
      case 'active':
        return FileStatus.active;
      case 'deleted':
        return FileStatus.deleted;
      case 'failed':
        return FileStatus.failed;
      default:
        return FileStatus.active;
    }
  }
}
