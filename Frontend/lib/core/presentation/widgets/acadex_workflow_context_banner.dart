import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import 'acadex_badge.dart';

/// Context Item representation for the workflow header.
class AcadexContextItem {
  final String label;
  final String value;
  final IconData? icon;

  const AcadexContextItem({
    required this.label,
    required this.value,
    this.icon,
  });
}

/// Compact contextual header displayed when a workflow inherits known context
/// from Department Setup or another upstream screen (Prompt 12).
///
/// Clearly communicates:
/// - "What am I creating?"
/// - "Where does it belong?"
/// - Locks preselected parent relationships and removes redundant dropdowns.
class AcadexWorkflowContextBanner extends StatelessWidget {
  final String targetEntityName;
  final List<AcadexContextItem> contextItems;
  final VoidCallback? onChangeContext;
  final bool isChangeEnabled;

  const AcadexWorkflowContextBanner({
    super.key,
    required this.targetEntityName,
    required this.contextItems,
    this.onChangeContext,
    this.isChangeEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (contextItems.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : const Color(0xFFF8FAFC),
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 3,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AcadexColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'SETUP CONTEXT FOR $targetEntityName'.toUpperCase(),
                        style: AcadexTypography.eyebrow(
                          color: isDark ? AcadexColors.primaryMuted : AcadexColors.primary,
                        ).copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const AcadexBadge(
                label: 'INHERITED CONTEXT',
                variant: AcadexBadgeVariant.neutral,
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxItemWidth = constraints.maxWidth;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: contextItems.map((item) {
                  return Container(
                    constraints: BoxConstraints(maxWidth: maxItemWidth),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.darkCanvas : Colors.white,
                      borderRadius: AcadexRadius.borderRadiusSm,
                      border: Border.all(
                        color: isDark ? AcadexColors.darkHairline : const Color(0xFFCBD5E1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.icon != null) ...[
                          Icon(
                            item.icon,
                            size: 13,
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.primary,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${item.label}: ',
                                  style: AcadexTypography.caption(
                                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                  ).copyWith(fontSize: 11.5, fontWeight: FontWeight.w500),
                                ),
                                TextSpan(
                                  text: item.value,
                                  style: AcadexTypography.caption(
                                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                  ).copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (onChangeContext != null && isChangeEnabled) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: onChangeContext,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Change context…',
                    style: AcadexTypography.caption(
                      color: AcadexColors.primary,
                    ).copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
