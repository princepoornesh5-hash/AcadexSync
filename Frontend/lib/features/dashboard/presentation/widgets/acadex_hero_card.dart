import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Standardized Hero / Priority card used across all role dashboards.
/// For Super Admin, adopts the Deep Action Blue (#003366) / Primary Action Blue (#0066CC) hierarchy.
class AcadexHeroCard extends ConsumerWidget {
  final String eyebrow;
  final Widget? badge;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Widget? customContent;

  const AcadexHeroCard({
    super.key,
    required this.eyebrow,
    this.badge,
    required this.title,
    this.subtitle,
    this.icon,
    this.primaryActionLabel,
    this.primaryActionIcon,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.customContent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = AcadexBreakpoints.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final isGradientRole = authState is AuthAuthenticated &&
        (authState.user.role == AppRole.superAdmin ||
            authState.user.role == AppRole.collegeAdmin ||
            authState.user.role == AppRole.hod ||
            authState.user.role == AppRole.faculty ||
            authState.user.role == AppRole.student);

    final accentColor = isGradientRole ? AcadexColors.superAdminDeepAction : AcadexColors.primary;
    final iconBgColor = isGradientRole ? AcadexColors.superAdminSoftAction : AcadexColors.primaryLight;
    final iconFgColor = isGradientRole ? AcadexColors.superAdminPrimaryAction : AcadexColors.primary;
    final primaryBtnBg = isGradientRole ? AcadexColors.superAdminDeepAction : AcadexColors.primary;
    final secondaryBtnBorder = isGradientRole ? AcadexColors.superAdminPrimaryAction : AcadexColors.border;
    final secondaryBtnText = isGradientRole ? AcadexColors.superAdminDeepAction : AcadexColors.ink;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : const Color(0xFFDBEAFE),
          width: 1.2,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Eyebrow + Status Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    eyebrow.toUpperCase(),
                    style: AcadexTypography.eyebrow(
                      color: accentColor,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
              if (badge != null) badge!,
            ],
          ),
          const SizedBox(height: 10),

          // Main Title & Optional Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: isMobile ? 38 : 44,
                  height: isMobile ? 38 : 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: AcadexRadius.borderRadiusMd,
                  ),
                  child: Icon(
                    icon,
                    color: iconFgColor,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AcadexTypography.heading2(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(
                        fontSize: isMobile ? 17 : 20,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                        ).copyWith(
                          fontSize: isMobile ? 12 : 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (customContent != null) ...[
            const SizedBox(height: 12),
            customContent!,
          ],

          // Action Buttons
          if (primaryActionLabel != null || secondaryActionLabel != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (primaryActionLabel != null)
                  ElevatedButton.icon(
                    onPressed: onPrimaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBtnBg,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                      ),
                    ),
                    icon: Icon(primaryActionIcon ?? Icons.arrow_forward, size: 16, color: Colors.white),
                    label: Text(
                      primaryActionLabel!,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Colors.white),
                    ),
                  ),
                if (secondaryActionLabel != null)
                  OutlinedButton(
                    onPressed: onSecondaryAction,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: secondaryBtnText,
                      side: BorderSide(color: secondaryBtnBorder, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                      ),
                    ),
                    child: Text(
                      secondaryActionLabel!,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: secondaryBtnText),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
