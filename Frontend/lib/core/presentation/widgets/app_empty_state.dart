import 'package:flutter/material.dart';
import '../design_system/acadex_colors.dart';
import '../design_system/acadex_spacing.dart';
import 'app_button.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AcadexSpacing.cardPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AcadexColors.surfaceLightMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AcadexColors.textMutedLight),
            ),
            const SizedBox(height: AcadexSpacing.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AcadexColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AcadexSpacing.xs),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AcadexColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AcadexSpacing.lg),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
