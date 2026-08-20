import 'package:flutter/material.dart';
import '../design_system/acadex_colors.dart';
import '../design_system/acadex_spacing.dart';
import 'app_badge.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.count,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AcadexSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AcadexColors.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: AcadexSpacing.sm),
                      AppBadge(
                        label: count.toString(),
                        variant: AppBadgeVariant.neutral,
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AcadexSpacing.xxs),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AcadexColors.textMutedLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AcadexColors.emeraldTeal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
