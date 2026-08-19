import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';

class AttendanceFooter extends StatelessWidget {
  final bool isReadyToSave;
  final VoidCallback onSave;

  const AttendanceFooter({
    super.key,
    required this.isReadyToSave,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AcadexButton(
              label: "Review & Save",
              variant: isReadyToSave ? AcadexButtonVariant.primary : AcadexButtonVariant.secondary,
              onPressed: isReadyToSave ? onSave : null,
            ),
          ],
        ),
      ),
    );
  }
}
