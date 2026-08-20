enum UserStatus {
  active,
  pending,
  inactive,
  deactivated,
  suspended,
  graduated,
  transferred,
}

extension UserStatusExtension on UserStatus {
  String get value {
    switch (this) {
      case UserStatus.active:
        return 'ACTIVE';
      case UserStatus.pending:
        return 'PENDING_ACTIVATION';
      case UserStatus.inactive:
        return 'INACTIVE';
      case UserStatus.deactivated:
        return 'DEACTIVATED';
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
      case UserStatus.pending:
        return 'Pending Activation';
      case UserStatus.inactive:
        return 'Inactive';
      case UserStatus.deactivated:
        return 'Deactivated';
      case UserStatus.suspended:
        return 'Suspended';
      case UserStatus.graduated:
        return 'Graduated';
      case UserStatus.transferred:
        return 'Transferred';
    }
  }

  static UserStatus fromValue(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized.contains('PENDING') || normalized.contains('INVITED')) {
      return UserStatus.pending;
    }
    if (normalized.contains('DEACTIVAT')) {
      return UserStatus.deactivated;
    }
    switch (normalized) {
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
