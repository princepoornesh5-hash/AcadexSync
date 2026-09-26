import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';

/// Reusable contextual continuation modal for Create & Continue workflows (Prompt 10)
class SetupContinuationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? entityName;
  final String primaryActionLabel;
  final VoidCallback onContinue;
  final String secondaryActionLabel;
  final VoidCallback? onDone;
  final bool isWaitingOnAdmin;
  final String? waitingNotice;

  const SetupContinuationDialog({
    super.key,
    required this.title,
    required this.message,
    this.entityName,
    required this.primaryActionLabel,
    required this.onContinue,
    this.secondaryActionLabel = 'Done',
    this.onDone,
    this.isWaitingOnAdmin = false,
    this.waitingNotice,
  });

  /// Displays the contextual Create & Continue dialog modally
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? entityName,
    required String primaryActionLabel,
    required VoidCallback onContinue,
    String secondaryActionLabel = 'Done',
    VoidCallback? onDone,
    bool isWaitingOnAdmin = false,
    String? waitingNotice,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SetupContinuationDialog(
        title: title,
        message: message,
        entityName: entityName,
        primaryActionLabel: primaryActionLabel,
        onContinue: () {
          Navigator.of(ctx).pop();
          onContinue();
        },
        secondaryActionLabel: secondaryActionLabel,
        onDone: () {
          Navigator.of(ctx).pop();
          if (onDone != null) {
            onDone();
          }
        },
        isWaitingOnAdmin: isWaitingOnAdmin,
        waitingNotice: waitingNotice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
          borderRadius: AcadexRadius.borderRadiusLg,
          border: Border.all(
            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
            width: 1,
          ),
          boxShadow: AcadexShadows.lightLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AcadexColors.success.withValues(alpha: 0.12),
                    borderRadius: AcadexRadius.borderRadiusMd,
                  ),
                  child: const Icon(
                    LucideIcons.checkCircle2,
                    color: AcadexColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AcadexTypography.heading3(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      if (entityName != null && entityName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          entityName!,
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ),
            ),
            if (isWaitingOnAdmin && waitingNotice != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight,
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(color: AcadexColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.clock, size: 16, color: AcadexColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        waitingNotice!,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.warning : AcadexColors.warningDark,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Actions
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  AcadexButton(
                    label: secondaryActionLabel,
                    variant: AcadexButtonVariant.secondary,
                    size: AcadexButtonSize.md,
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onDone != null) onDone!();
                    },
                  ),
                  if (!isWaitingOnAdmin)
                    AcadexButton(
                      label: primaryActionLabel,
                      icon: LucideIcons.arrowRight,
                      variant: AcadexButtonVariant.primary,
                      size: AcadexButtonSize.md,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onContinue();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
