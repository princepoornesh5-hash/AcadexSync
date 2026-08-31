import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../providers/analytics_providers.dart';

class ReportsListScreen extends ConsumerWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;
    final reportsAsync = ref.watch(recentReportsProvider);

    final bodyContent = reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Error loading reports', style: GoogleFonts.inter(color: DashboardColors.error)),
      ),
      data: (reports) {
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.fileX, size: 48, color: DashboardColors.textSecondary),
                const SizedBox(height: 16),
                Text('No Reports Found', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
                const SizedBox(height: 8),
                Text('Try adjusting your filters or date range.', style: GoogleFonts.inter(fontSize: 14, color: DashboardColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final report = reports[index];
            return InkWell(
              onTap: () {
                context.push('/analytics/report_preview', extra: report);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DashboardColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DashboardColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DashboardColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.fileBarChart2, color: DashboardColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Generated ${DateFormat('MMM d, yyyy').format(report.generatedAt)}',
                            style: GoogleFonts.inter(fontSize: 13, color: DashboardColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, color: DashboardColors.textSecondary, size: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (hasEnclosingScaffold) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.safePop(fallbackRoute: '/analytics'),
        ),
        title: Text(
          'Reports',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw),
            onPressed: () => ref.refresh(recentReportsProvider),
            tooltip: 'Refresh Reports',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: bodyContent,
    );
  }
}
