import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';

class AcadexPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final List<String>? breadcrumbs;
  final Widget? leading;

  const AcadexPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onBack,
    this.breadcrumbs,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);

    final standardTitleColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final standardSubtitleColor = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;

    final headerContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
          Row(
            children: [
              for (int i = 0; i < breadcrumbs!.length; i++) ...[
                Text(
                  breadcrumbs![i],
                  style: AcadexTypography.caption(
                    color: i == breadcrumbs!.length - 1
                        ? standardTitleColor
                        : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                  ).copyWith(
                    fontWeight: i == breadcrumbs!.length - 1 ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (i < breadcrumbs!.length - 1) ...[
                  const SizedBox(width: 6),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 12,
                    color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onBack != null) ...[
                    IconButton(
                      icon: Icon(LucideIcons.arrowLeft, size: 20, color: standardTitleColor),
                      onPressed: onBack,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                  ] else if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: AcadexTypography.heading1(
                        color: standardTitleColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AcadexTypography.bodySmall(
                    color: standardSubtitleColor,
                  ),
                ),
              ],
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: actions!,
                ),
              ],
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (onBack != null) ...[
                      IconButton(
                        icon: Icon(LucideIcons.arrowLeft, size: 20, color: standardTitleColor),
                        onPressed: onBack,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                    ] else if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AcadexTypography.heading1(
                              color: standardTitleColor,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: AcadexTypography.bodySmall(
                                color: standardSubtitleColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(width: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions!,
                ),
              ],
            ],
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(
        top: AcadexSpacing.space16,
        bottom: AcadexSpacing.space24,
      ),
      child: headerContent,
    );
  }
}

class AcadexSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;
  final int? count;

  const AcadexSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.onAction,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final standardHeaderColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final standardSubtitleColor = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;

    Widget? effectiveAction = action;
    if (effectiveAction == null && actionLabel != null && onAction != null) {
      effectiveAction = TextButton(
        onPressed: onAction,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AcadexSpacing.space8,
            vertical: AcadexSpacing.space4,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: AcadexColors.primary,
        ),
        child: Text(
          actionLabel!,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AcadexColors.primary,
          ),
        ),
      );
    }

    final headerTitleRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AcadexColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: AcadexTypography.heading3(
              color: standardHeaderColor,
            ).copyWith(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
              borderRadius: AcadexRadius.borderRadiusFull,
              border: Border.all(
                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                width: 1,
              ),
            ),
            child: Text(
              count.toString(),
              style: AcadexTypography.eyebrow(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
          ),
        ],
      ],
    );

    final rowContent = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              headerTitleRow,
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AcadexTypography.bodySmall(
                    color: standardSubtitleColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (effectiveAction != null) effectiveAction,
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: rowContent,
    );
  }
}
