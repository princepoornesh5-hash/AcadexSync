enum AppRole {
  superAdmin,
  collegeAdmin,
  hod,
  faculty,
  student,
}

extension AppRoleExtension on AppRole {
  String get value {
    switch (this) {
      case AppRole.superAdmin:
        return 'SUPER_ADMIN';
      case AppRole.collegeAdmin:
        return 'COLLEGE_ADMIN';
      case AppRole.hod:
        return 'HOD';
      case AppRole.faculty:
        return 'FACULTY';
      case AppRole.student:
        return 'STUDENT';
    }
  }

  String get displayName {
    switch (this) {
      case AppRole.superAdmin:
        return 'Super Admin';
      case AppRole.collegeAdmin:
        return 'College Admin';
      case AppRole.hod:
        return 'HOD';
      case AppRole.faculty:
        return 'Faculty';
      case AppRole.student:
        return 'Student';
    }
  }

  static AppRole fromValue(String value) {
    final normalized = value.trim().replaceAll('_', '').toUpperCase();
    switch (normalized) {
      case 'SUPERADMIN':
        return AppRole.superAdmin;
      case 'COLLEGEADMIN':
        return AppRole.collegeAdmin;
      case 'HOD':
        return AppRole.hod;
      case 'FACULTY':
        return AppRole.faculty;
      case 'STUDENT':
        return AppRole.student;
      default:
        throw ArgumentError('Unrecognized or invalid AppRole value: "$value"');
    }
  }
}
