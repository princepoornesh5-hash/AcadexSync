import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class AcadexCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;

  const AcadexCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface);
    final border = borderColor ?? (isDark ? AcadexColors.darkHairline : AcadexColors.hairline);
    final radius = borderRadius ?? AcadexRadius.borderRadiusLg;

    final content = Container(
      width: width,
      height: height,
      padding: padding ?? AcadexSpacing.cardPadding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: border, width: 1),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }

    return content;
  }
}

class AcadexStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String? trend;
  final bool? isPositiveTrend;
  final VoidCallback? onTap;

  const AcadexStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.iconColor,
    this.iconBackgroundColor,
    this.trend,
    this.isPositiveTrend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultIconColor = iconColor ?? AcadexColors.primary;
    final defaultIconBg = iconBackgroundColor ??
        (isDark ? AcadexColors.primaryMuted.withValues(alpha: 0.15) : AcadexColors.primaryLight);

    return AcadexCard(
      onTap: onTap,
      padding: AcadexSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AcadexTypography.caption(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: defaultIconBg,
                  borderRadius: AcadexRadius.borderRadiusMd,
                ),
                child: Icon(icon, size: 18, color: defaultIconColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AcadexTypography.heading1(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          if (subtitle != null || trend != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (trend != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPositiveTrend ?? true)
                          ? (isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight)
                          : (isDark ? AcadexColors.errorDarkContainer : AcadexColors.errorLight),
                      borderRadius: AcadexRadius.borderRadiusXs,
                    ),
                    child: Text(
                      trend!,
                      style: AcadexTypography.eyebrow(
                        color: (isPositiveTrend ?? true) ? AcadexColors.success : AcadexColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                      ),
                      overflow: TextOverflow.ellipsis,
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
