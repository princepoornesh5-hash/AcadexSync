import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/activity_item_model.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';

class ActivityFeed extends StatelessWidget {
  final List<ActivityItemModel> items;

  const ActivityFeed({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (items.isEmpty) {
      return const AcadexEmptyState(
        title: 'No recent activity',
        subtitle: 'Activity logs and events will appear here.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: items.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          indent: 68,
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.iconBackground,
                borderRadius: AcadexRadius.borderRadiusMd,
              ),
              child: Icon(item.icon, color: item.iconColor, size: 18),
            ),
            title: Text(
              item.title,
              style: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              item.subtitle,
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
            trailing: Text(
              item.timeAgo,
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
              ),
            ),
          );
        },
      ),
    );
  }
}
