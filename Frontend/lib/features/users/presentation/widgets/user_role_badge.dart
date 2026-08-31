import 'package:flutter/material.dart';
import '../../../../core/presentation/design_system/acadex_colors.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../auth/domain/models/role_enum.dart';

class UserRoleBadge extends StatelessWidget {
  final AppRole role;
  final bool isCompact;

  const UserRoleBadge({
    super.key,
    required this.role,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color textColor;

    switch (role) {
      case AppRole.superAdmin:
        badgeColor = AcadexColors.superAdminBadge.withAlpha(35);
        textColor = AcadexColors.superAdminBadge;
        break;
      case AppRole.collegeAdmin:
        badgeColor = AcadexColors.collegeAdminBadge.withAlpha(35);
        textColor = AcadexColors.collegeAdminBadge;
        break;
      case AppRole.hod:
        badgeColor = AcadexColors.hodBadge.withAlpha(35);
        textColor = AcadexColors.hodBadge;
        break;
      case AppRole.faculty:
        badgeColor = AcadexColors.facultyBadge.withAlpha(35);
        textColor = AcadexColors.facultyBadge;
        break;
      case AppRole.student:
        badgeColor = AcadexColors.studentBadge.withAlpha(35);
        textColor = AcadexColors.studentBadge;
        break;
    }

    return AcadexBadge(
      label: role.displayName,
      backgroundColor: badgeColor,
      textColor: textColor,
    );
  }
}
