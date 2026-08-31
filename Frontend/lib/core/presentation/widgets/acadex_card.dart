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
    final bg = backgroundColor ?? AcadexColors.surface;
    final border = borderColor ?? AcadexColors.hairline;
    final radius = borderRadius ?? AcadexRadius.borderRadiusLg;

    final content = Container(
      width: width,
      height: height,
      padding: padding ?? AcadexSpacing.cardPadding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: border, width: 1),
        boxShadow: AcadexShadows.lightSm,
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
  final EdgeInsetsGeometry? padding;

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
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final defaultIconColor = iconColor ?? AcadexColors.primary;
    final defaultIconBg = iconBackgroundColor ?? AcadexColors.primaryLight;

    return AcadexCard(
      onTap: onTap,
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: AcadexTypography.caption(
                    color: AcadexColors.inkMuted,
                  ).copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
              color: AcadexColors.ink,
            ),
          ),
          if (subtitle != null || trend != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trend != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPositiveTrend ?? true)
                          ? AcadexColors.successLight
                          : AcadexColors.errorLight,
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
                  Flexible(
                    child: Text(
                      subtitle!,
                      style: AcadexTypography.caption(
                        color: AcadexColors.inkSecondary,
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
