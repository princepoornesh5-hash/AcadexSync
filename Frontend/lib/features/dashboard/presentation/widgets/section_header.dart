import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? titleColor;
  final Color? actionColor;
  final bool showAccent;
  final Color? accentColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.titleColor,
    this.actionColor,
    this.showAccent = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final standardTitleColor = titleColor ?? (isDark ? AcadexColors.darkInk : AcadexColors.ink);
    final standardActionColor = actionColor ?? AcadexColors.primary;
    final effectiveAccentColor = accentColor ?? AcadexColors.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showAccent) ...[
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: effectiveAccentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  title,
                  style: AcadexTypography.title(
                    color: standardTitleColor,
                  ).copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: standardActionColor,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(48, 44),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Text(
              actionLabel!,
              style: AcadexTypography.button(
                color: standardActionColor,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
