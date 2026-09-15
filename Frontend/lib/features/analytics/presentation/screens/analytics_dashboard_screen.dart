import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/analytics_providers.dart';
import '../widgets/analytics_cards.dart';
import '../widgets/charts/trend_line_chart.dart';
import '../widgets/charts/comparison_bar_chart.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import 'department_analytics_screen.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is AuthAuthenticated && authState.user.role == AppRole.hod) {
      return const DepartmentAnalyticsScreen();
    }

    final summaryAsync = ref.watch(analyticsSummaryProvider);
    final trendAsync = ref.watch(trendChartProvider);
    final comparisonAsync = ref.watch(comparisonChartProvider);
    final insightsAsync = ref.watch(insightsProvider);
    final projection = ref.watch(studentProjectionProvider);

    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AcadexPageHeader(
                  title: 'Campus Analytics',
                  subtitle: 'Real-time academic performance, attendance distribution, and cohort projections.',
                ),

                // Projection Card for Students
                if (projection != null) ...[
                  ProjectionCard(projection: projection),
                  const SizedBox(height: 24),
                ],

                // Summary Metrics
                const AcadexSectionHeader(title: 'Overview Metrics'),
                const SizedBox(height: 12),
                summaryAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => AcadexErrorState(
                    message: 'Error loading metrics: $err',
                    onRetry: () => ref.refresh(analyticsSummaryProvider),
                  ),
                  data: (summary) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final cols = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: summary.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: cols == 1 ? 2.5 : 1.4,
                          ),
                          itemBuilder: (context, index) {
                            final key = summary.keys.elementAt(index);
                            final value = summary[key]!;
                            return AnalyticsSummaryCard(title: key, value: value);
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Trend Line Chart
                const AcadexSectionHeader(title: 'Performance & Attendance Trends'),
                const SizedBox(height: 12),
                trendAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => AcadexErrorState(
                    message: 'Could not load trend data: $err',
                    onRetry: () => ref.refresh(trendChartProvider),
                  ),
                  data: (trend) {
                    return AcadexCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Institutional Attendance Trend',
                            style: AcadexTypography.heading3(color: AcadexColors.ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Historical data tracked over current academic cycle',
                            style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 260,
                            child: TrendLineChart(data: trend),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Comparison Bar Chart
                const AcadexSectionHeader(title: 'Cohort Comparison'),
                const SizedBox(height: 12),
                comparisonAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => AcadexErrorState(
                    message: 'Could not load comparison data: $err',
                    onRetry: () => ref.refresh(comparisonChartProvider),
                  ),
                  data: (comparison) {
                    return AcadexCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Department Attendance Comparison',
                            style: AcadexTypography.heading3(color: AcadexColors.ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Department / Class benchmarking against institutional average',
                            style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 260,
                            child: ComparisonBarChart(data: comparison),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // AI Generated Analytics Insights
                const AcadexSectionHeader(title: 'AI Insights & Observations'),
                const SizedBox(height: 12),
                insightsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => const SizedBox.shrink(),
                  data: (insights) {
                    return Column(
                      children: insights.map((insight) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InsightCard(insight: insight),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
  }
}
