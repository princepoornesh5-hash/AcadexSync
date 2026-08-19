import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';

class SaveAttendanceButton extends StatelessWidget {
  final int remainingCount;
  final VoidCallback onSave;
  final bool isLoading;
  final bool isFullWidth;

  const SaveAttendanceButton({
    super.key,
    required this.remainingCount,
    required this.onSave,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isValid = remainingCount == 0;
    final label = isValid ? "Save Attendance" : "Save Attendance ($remainingCount unmarked)";

    return AcadexButton(
      label: label,
      icon: LucideIcons.checkCheck,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      variant: isValid ? AcadexButtonVariant.primary : AcadexButtonVariant.secondary,
      onPressed: () {
        if (isValid) {
          onSave();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Please mark attendance for all $remainingCount remaining student(s) before saving.",
                style: AcadexTypography.bodySmall(color: Colors.white),
              ),
              backgroundColor: AcadexColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }
}
