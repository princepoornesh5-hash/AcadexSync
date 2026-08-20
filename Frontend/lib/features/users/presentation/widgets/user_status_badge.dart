import 'package:flutter/material.dart';
import '../../../../core/presentation/design_system/acadex_colors.dart';
import '../../../../core/presentation/widgets/app_badge.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/user_status_enum.dart';

class UserStatusBadge extends StatelessWidget {
  final dynamic status; // AccountStatus, UserStatus, or String

  const UserStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    String label = 'Active';
    Color bgColor = AcadexColors.present.withAlpha(35);
    Color textColor = AcadexColors.present;

    final str = (status is AccountStatus)
        ? (status as AccountStatus).name.toLowerCase()
        : (status is UserStatus)
            ? (status as UserStatus).name.toLowerCase()
            : status.toString().toLowerCase();

    if (str.contains('pending') || str.contains('invited')) {
      label = 'Pending Activation';
      bgColor = AcadexColors.late.withAlpha(35);
      textColor = AcadexColors.late;
    } else if (str.contains('deactivat') || str.contains('inactive')) {
      label = 'Deactivated';
      bgColor = AcadexColors.absent.withAlpha(35);
      textColor = AcadexColors.absent;
    } else if (str.contains('suspend')) {
      label = 'Suspended';
      bgColor = AcadexColors.coral.withAlpha(35);
      textColor = AcadexColors.coral;
    } else {
      label = 'Active';
      bgColor = AcadexColors.emerald.withAlpha(35);
      textColor = AcadexColors.emerald;
    }

    return AppBadge(
      label: label,
      backgroundColor: bgColor,
      textColor: textColor,
    );
  }
}
