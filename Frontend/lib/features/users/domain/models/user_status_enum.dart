enum UserStatus {
  active,
  inactive,
  suspended,
  graduated,
  transferred,
}

extension UserStatusExtension on UserStatus {
  String get value {
    switch (this) {
      case UserStatus.active:
        return 'ACTIVE';
      case UserStatus.inactive:
        return 'INACTIVE';
      case UserStatus.suspended:
        return 'SUSPENDED';
      case UserStatus.graduated:
        return 'GRADUATED';
      case UserStatus.transferred:
        return 'TRANSFERRED';
    }
  }

  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.inactive:
        return 'Inactive';
      case UserStatus.suspended:
        return 'Suspended';
      case UserStatus.graduated:
        return 'Graduated';
      case UserStatus.transferred:
        return 'Transferred';
    }
  }

  static UserStatus fromValue(String value) {
    switch (value) {
      case 'ACTIVE':
        return UserStatus.active;
      case 'INACTIVE':
        return UserStatus.inactive;
      case 'SUSPENDED':
        return UserStatus.suspended;
      case 'GRADUATED':
        return UserStatus.graduated;
      case 'TRANSFERRED':
        return UserStatus.transferred;
      default:
        return UserStatus.active;
    }
  }
}
