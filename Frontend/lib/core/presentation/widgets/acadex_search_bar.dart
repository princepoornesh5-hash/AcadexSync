import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';

class AcadexSearchFilterBar extends StatelessWidget {
  final String searchHint;
  final Function(String) onSearchChanged;
  final VoidCallback? onFilterTap;
  final String actionLabel;
  final VoidCallback? onActionTap;

  const AcadexSearchFilterBar({
    super.key,
    this.searchHint = "Search...",
    required this.onSearchChanged,
    this.onFilterTap,
    this.actionLabel = "Add New",
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceDarkElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.hairlineDark),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(LucideIcons.search, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: const TextStyle(color: AppColors.onDark),
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        if (onFilterTap != null)
          InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDarkElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.hairlineDark),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.filter, color: AppColors.onDark, size: 20),
                  SizedBox(width: 8),
                  Text("Filter", style: TextStyle(color: AppColors.onDark, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        if (onActionTap != null) ...[
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: onActionTap,
            icon: const Icon(LucideIcons.plus, size: 20, color: Colors.white),
            label: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            ),
          ),
        ]
      ],
    );
  }
}
