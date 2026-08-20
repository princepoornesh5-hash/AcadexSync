import 'package:flutter/material.dart';
import '../design_system/acadex_colors.dart';
import '../design_system/acadex_spacing.dart';
import 'app_button.dart';

class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const AppErrorState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
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
                color: AcadexColors.coralErrorSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 36, color: AcadexColors.coralError),
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
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AcadexColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AcadexSpacing.lg),
              AppButton(
                label: retryLabel,
                onPressed: onRetry,
                variant: AppButtonVariant.primary,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
