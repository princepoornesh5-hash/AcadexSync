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
  final bool isFlat;

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
    this.isFlat = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface);
    final border = borderColor ?? (isDark ? AcadexColors.darkHairline : AcadexColors.hairline);
    final radius = borderRadius ?? AcadexRadius.borderRadiusLg;
    final effectivePadding = padding ?? AcadexBreakpoints.responsiveCardPadding(context);

    final content = Container(
      width: width,
      height: height,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: border, width: 1),
        boxShadow: isFlat
            ? null
            : (isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultIconColor = iconColor ?? AcadexColors.primary;
    final defaultIconBg = iconBackgroundColor ??
        (isDark ? AcadexColors.primary.withValues(alpha: 0.15) : AcadexColors.primaryLight);
    final isSmall = AcadexBreakpoints.isSmallMobile(context);

    final cardPadding = padding ??
        EdgeInsets.all(isSmall ? AcadexSpacing.space10 : AcadexSpacing.space14);

    return AcadexCard(
      onTap: onTap,
      padding: cardPadding,
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
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: isSmall ? 30 : 34,
                height: isSmall ? 30 : 34,
                decoration: BoxDecoration(
                  color: defaultIconBg,
                  borderRadius: AcadexRadius.borderRadiusMd,
                ),
                child: Icon(icon, size: isSmall ? 15 : 17, color: defaultIconColor),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 6 : 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: isSmall
                  ? AcadexTypography.heading2(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    )
                  : AcadexTypography.heading1(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
            ),
          ),
          if (subtitle != null || trend != null) ...[
            SizedBox(height: isSmall ? 4 : 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trend != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPositiveTrend ?? true)
                          ? AcadexColors.successLight
                          : AcadexColors.errorLight,
                      borderRadius: AcadexRadius.borderRadiusXs,
                    ),
                    child: Text(
                      trend!,
                      style: AcadexTypography.eyebrow(
                        color: (isPositiveTrend ?? true)
                            ? AcadexColors.successDark
                            : AcadexColors.errorDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (subtitle != null)
                  Flexible(
                    child: Text(
                      subtitle!,
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                      ),
                      maxLines: 1,
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
