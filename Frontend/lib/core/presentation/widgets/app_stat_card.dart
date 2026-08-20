import 'package:flutter/material.dart';
import '../design_system/acadex_colors.dart';
import '../design_system/acadex_spacing.dart';
import 'app_card.dart';

class AppStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final VoidCallback? onTap;

  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AcadexColors.primaryNavy;
    final effectiveBgColor = iconBackgroundColor ?? AcadexColors.surfaceLightMuted;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AcadexColors.textSecondaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveBgColor,
                  borderRadius: AcadexRadius.smBorder,
                ),
                child: Icon(icon, size: 18, color: effectiveIconColor),
              ),
            ],
          ),
          const SizedBox(height: AcadexSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AcadexColors.textPrimaryLight,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AcadexSpacing.xs),
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
    );
  }
}
