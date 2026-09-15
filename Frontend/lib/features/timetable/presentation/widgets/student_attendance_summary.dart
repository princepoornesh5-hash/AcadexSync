import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../attendance/presentation/providers/student_portal_providers.dart';

class StudentAttendanceCompactSummary extends ConsumerWidget {
  const StudentAttendanceCompactSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(studentPortalSummaryProvider);
    final subjectsAsync = ref.watch(studentDetailedSubjectsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isVeryNarrow = width < 370;

    return summaryAsync.maybeWhen(
      data: (summary) {
        final totalOverall = summary.totalSessions;
        final presentOverall = summary.presentCount;
        final overallPct = totalOverall > 0 ? (presentOverall / totalOverall).clamp(0.0, 1.0) : 0.0;

        final subjects = subjectsAsync.valueOrNull ?? [];
        final primarySubject = subjects.isNotEmpty ? subjects.first : null;
        final totalSub = primarySubject?.totalClasses ?? 0;
        final presentSub = primarySubject?.presentCount ?? 0;
        final subPct = totalSub > 0 ? (presentSub / totalSub).clamp(0.0, 1.0) : 0.0;
        final subName = primarySubject?.subjectName ?? 'Subject';

        final cardColor = isDark ? Theme.of(context).colorScheme.surface : Colors.white;
        final borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.6);

        Widget overallCard = _buildGaugeCard(
          context,
          title: 'Overall Attendance',
          ratioText: '$presentOverall/$totalOverall',
          percentage: overallPct,
          ringColor: AcadexColors.primary,
          cardColor: cardColor,
          borderColor: borderColor,
          isDark: isDark,
        );

        Widget subjectCard = _buildGaugeCard(
          context,
          title: subName,
          ratioText: '$presentSub/$totalSub',
          percentage: subPct,
          ringColor: AcadexColors.accentOrange,
          cardColor: cardColor,
          borderColor: borderColor,
          isDark: isDark,
        );

        if (isVeryNarrow) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                overallCard,
                const SizedBox(height: 8),
                subjectCard,
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(child: overallCard),
              const SizedBox(width: 10),
              Expanded(child: subjectCard),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildGaugeCard(
    BuildContext context, {
    required String title,
    required String ratioText,
    required double percentage,
    required Color ringColor,
    required Color cardColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : AcadexShadows.lightSm,
      ),
      child: Row(
        children: [
          // Circular Progress Indicator Ring
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 4.5,
                  backgroundColor: ringColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '${(percentage * 100).round()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Title and Count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AcadexTypography.caption(
                    color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                  ).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  ratioText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
