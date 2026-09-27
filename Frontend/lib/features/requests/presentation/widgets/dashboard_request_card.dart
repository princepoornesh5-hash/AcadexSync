import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../providers/requests_providers.dart';

class DashboardRequestCard extends ConsumerWidget {
  final AppRole role;

  const DashboardRequestCard({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(requestSummaryCountsProvider);

    return countsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (counts) {
        String title;
        String subtitle;
        IconData icon;
        Color accentColor;
        Color bgColor;
        bool hasAttention = false;

        if (role == AppRole.student) {
          final count = counts.myPendingCount;
          if (count > 0) {
            title = '$count ${count == 1 ? "request" : "requests"} in progress';
            subtitle = 'Tap to track status and review responses';
            icon = LucideIcons.clock;
            accentColor = AcadexColors.primary;
            bgColor = AcadexColors.primaryLight.withValues(alpha: 0.5);
            hasAttention = true;
          } else {
            title = 'Request Center';
            subtitle = 'Submit leave, attendance correction, or queries';
            icon = LucideIcons.send;
            accentColor = AcadexColors.inkSecondary;
            bgColor = AcadexColors.canvasSoft;
          }
        } else if (role == AppRole.faculty) {
          final count = counts.incomingCount;
          if (count > 0) {
            title = '$count ${count == 1 ? "request needs" : "requests need"} your response';
            subtitle = 'Student attendance and academic requests';
            icon = LucideIcons.alertCircle;
            accentColor = const Color(0xFFD97706); // amber-600
            bgColor = const Color(0xFFFEF3C7); // amber-100
            hasAttention = true;
          } else {
            final myCount = counts.myPendingCount;
            title = myCount > 0
                ? '$myCount ${myCount == 1 ? "request" : "requests"} in progress'
                : 'Request Center';
            subtitle = myCount > 0
                ? 'Your submitted leave or resource requests'
                : 'Submit requests to HOD or track status';
            icon = LucideIcons.inbox;
            accentColor = AcadexColors.inkSecondary;
            bgColor = AcadexColors.canvasSoft;
          }
        } else if (role == AppRole.hod) {
          final count = counts.incomingCount;
          if (count > 0) {
            title = '$count ${count == 1 ? "request needs" : "requests need"} attention';
            subtitle = 'Department faculty and student requests';
            icon = LucideIcons.alertCircle;
            accentColor = const Color(0xFFD97706); // amber-600
            bgColor = const Color(0xFFFEF3C7); // amber-100
            hasAttention = true;
          } else {
            final myCount = counts.myPendingCount;
            title = myCount > 0
                ? '$myCount ${myCount == 1 ? "request" : "requests"} in progress'
                : 'Department Requests';
            subtitle = myCount > 0
                ? 'Your submitted requests to Administration'
                : 'All department requests are up to date';
            icon = LucideIcons.checkCheck;
            accentColor = AcadexColors.success;
            bgColor = AcadexColors.canvasSoft;
          }
        } else {
          final count = counts.incomingCount;
          title = count > 0 ? '$count requests need administrative action' : 'Request Center';
          subtitle = 'Review and resolve institutional requests';
          icon = LucideIcons.inbox;
          accentColor = AcadexColors.primary;
          bgColor = AcadexColors.canvasSoft;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasAttention
                  ? accentColor.withValues(alpha: 0.4)
                  : AcadexColors.hairline,
              width: hasAttention ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: hasAttention
                    ? accentColor.withValues(alpha: 0.08)
                    : const Color(0x0507111F),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => context.push('/requests'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AcadexTypography.bodySmall().copyWith(
                              fontWeight: FontWeight.w700,
                              color: hasAttention ? accentColor : AcadexColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AcadexTypography.caption().copyWith(
                              color: AcadexColors.inkMuted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: hasAttention ? accentColor : AcadexColors.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
