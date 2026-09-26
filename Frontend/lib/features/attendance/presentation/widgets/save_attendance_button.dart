import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';

class SaveAttendanceButton extends StatelessWidget {
  final int remainingCount;
  final int? totalStudents;
  final VoidCallback onSave;
  final bool isLoading;
  final bool isFullWidth;

  const SaveAttendanceButton({
    super.key,
    required this.remainingCount,
    this.totalStudents,
    required this.onSave,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasNoStudents = totalStudents != null && totalStudents == 0;
    final isValid = remainingCount == 0 && !hasNoStudents;
    final String label;
    if (hasNoStudents) {
      label = "No Students Enrolled";
    } else if (isValid) {
      label = "Save Attendance";
    } else {
      label = "Save Attendance ($remainingCount unmarked)";
    }

    return AcadexButton(
      label: label,
      icon: LucideIcons.checkCheck,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      variant: isValid ? AcadexButtonVariant.primary : AcadexButtonVariant.secondary,
      onPressed: () {
        if (hasNoStudents) {
          AcadexSnackBar.showWarning(
            context,
            "Cannot save attendance: No students are enrolled in this section.",
          );
        } else if (isValid) {
          onSave();
        } else {
          AcadexSnackBar.showWarning(
            context,
            "Please mark attendance for all $remainingCount remaining student(s) before saving.",
          );
        }
      },
    );
  }
}
