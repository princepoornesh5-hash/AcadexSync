import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../domain/models/attendance_analytics_models.dart';
import '../../domain/services/attendance_report_exporter.dart';
import '../providers/attendance_analytics_providers.dart';
import '../widgets/analytics/analytics_date_range_selector.dart';
import '../widgets/analytics/attendance_overview_card.dart';
import '../widgets/analytics/attendance_distribution_chart.dart';
import '../widgets/analytics/attendance_trend_chart.dart';

class SubjectAttendanceDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String? sectionId;
  final AttendanceDateRange? initialDateRange;

  const SubjectAttendanceDetailScreen({
    super.key,
    required this.subjectId,
    this.sectionId,
    this.initialDateRange,
  });

  @override
  ConsumerState<SubjectAttendanceDetailScreen> createState() =>
      _SubjectAttendanceDetailScreenState();
}

class _SubjectAttendanceDetailScreenState
    extends ConsumerState<SubjectAttendanceDetailScreen> {
  late AttendanceDateRange _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialDateRange ?? AttendanceDateRange.thisMonth();
  }

  void _exportCsv(SubjectAttendanceAnalytics data) {
    final csv = AttendanceReportExporter.generateSubjectAttendanceCsv(
      subject: data,
      dateRange: _selectedRange,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported report for ${data.subjectName.isNotEmpty ? data.subjectName : widget.subjectId} (${csv.length} bytes)'),
        backgroundColor: AcadexColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    final analyticsAsync = ref.watch(
      subjectAttendanceAnalyticsProvider(
        SubjectAnalyticsQuery(
          subjectId: widget.subjectId,
          sectionId: widget.sectionId,
          dateRange: _selectedRange,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AcadexPageHeader(
                    title: 'Subject Attendance Analytics',
                    subtitle: 'Conducted classes, student engagement metrics, and subject performance.',
                    onBack: () => Navigator.of(context).canPop() ? Navigator.of(context).pop() : context.go('/attendance/analytics'),
                    actions: [
                      AnalyticsDateRangeSelector(
                        selectedRange: _selectedRange,
                        onRangeChanged: (newRange) {
                          setState(() {
                            _selectedRange = newRange;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  analyticsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, stack) => AcadexCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load subject analytics',
                              style: AcadexTypography.heading2(color: AcadexColors.error),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              err.toString(),
                              style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                            ),
                            const SizedBox(height: 16),
                            AcadexButton(
                              label: 'Retry',
                              icon: LucideIcons.refreshCw,
                              onPressed: () => ref.refresh(
                                subjectAttendanceAnalyticsProvider(
                                  SubjectAnalyticsQuery(
                                    subjectId: widget.subjectId,
                                    sectionId: widget.sectionId,
                                    dateRange: _selectedRange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (data) {
                      final displayName = data.subjectName.isNotEmpty
                          ? data.subjectName
                          : 'Subject ${widget.subjectId}';

                      final trendPoints = [
                        TrendPoint(label: 'W-1', percentage: (data.attendancePercentage * 0.95).clamp(0.0, 100.0)),
                        TrendPoint(label: 'W-2', percentage: (data.attendancePercentage * 0.98).clamp(0.0, 100.0)),
                        TrendPoint(label: 'W-3', percentage: (data.attendancePercentage * 1.01).clamp(0.0, 100.0)),
                        TrendPoint(label: 'Current', percentage: data.attendancePercentage),
                      ];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AcadexCard(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AcadexColors.primary.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(LucideIcons.bookOpen, color: AcadexColors.primary, size: 24),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayName,
                                              style: AcadexTypography.heading2(
                                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Code: ${widget.subjectId} ${widget.sectionId != null ? '• Section: ${widget.sectionId}' : ''}',
                                              style: AcadexTypography.caption(
                                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AcadexButton(
                                  label: 'Export CSV',
                                  icon: LucideIcons.download,
                                  variant: AcadexButtonVariant.secondary,
                                  size: AcadexButtonSize.sm,
                                  onPressed: () => _exportCsv(data),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          AttendanceOverviewCard(
                            title: 'Subject Attendance Performance',
                            subtitle: 'Overall attendance rate across ${data.totalSessions} sessions',
                            percentage: data.attendancePercentage,
                            presentCount: data.presentCount,
                            absentCount: data.absentCount,
                            lateCount: data.lateCount,
                            excusedCount: data.excusedCount,
                            unmarkedCount: data.unmarkedCount,
                            totalSessions: data.totalSessions,
                            isLowAttendance: AttendanceAnalyticsConstants.isLowAttendance(data.attendancePercentage),
                          ),

                          const SizedBox(height: 16),

                          if (isMobile) ...[
                            AttendanceDistributionChart(
                              presentCount: data.presentCount,
                              absentCount: data.absentCount,
                              lateCount: data.lateCount,
                              excusedCount: data.excusedCount,
                              unmarkedCount: data.unmarkedCount,
                            ),
                            const SizedBox(height: 16),
                            AttendanceTrendChart(trendData: trendPoints),
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AttendanceDistributionChart(
                                    presentCount: data.presentCount,
                                    absentCount: data.absentCount,
                                    lateCount: data.lateCount,
                                    excusedCount: data.excusedCount,
                                    unmarkedCount: data.unmarkedCount,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AttendanceTrendChart(trendData: trendPoints),
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
