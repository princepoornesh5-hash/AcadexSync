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
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 11,
                    color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ],
          ),
          const SizedBox(height: 6),
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
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    const SizedBox(width: 8),
                  ] else if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: AcadexTypography.heading2(
                        color: standardTitleColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: AcadexTypography.bodySmall(
                    color: standardSubtitleColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
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
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      const SizedBox(width: 10),
                    ] else if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 10),
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
                            const SizedBox(height: 3),
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
      padding: EdgeInsets.only(
        top: isMobile ? AcadexSpacing.space2 : AcadexSpacing.space12,
        bottom: isMobile ? AcadexSpacing.space12 : AcadexSpacing.space20,
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
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: AcadexColors.primary,
        ),
        child: Text(
          actionLabel!,
          style: const TextStyle(
            fontSize: 12.5,
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
          height: 14,
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
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
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
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AcadexTypography.caption(
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
      padding: const EdgeInsets.only(bottom: 8.0, top: 2.0),
      child: rowContent,
    );
  }
}
