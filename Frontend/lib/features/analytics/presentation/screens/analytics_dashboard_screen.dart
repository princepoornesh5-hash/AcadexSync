import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/analytics_providers.dart';
import '../widgets/analytics_cards.dart';
import '../widgets/charts/trend_line_chart.dart';
import '../widgets/charts/comparison_bar_chart.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(analyticsSummaryProvider);
    final trendAsync = ref.watch(trendChartProvider);
    final comparisonAsync = ref.watch(comparisonChartProvider);
    final insightsAsync = ref.watch(insightsProvider);
    final projection = ref.watch(studentProjectionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: SingleChildScrollView(
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

                // Charts Section
                const AcadexSectionHeader(title: 'Trends & Comparisons'),
                const SizedBox(height: 12),
                
                // Trend Chart
                AcadexCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '6-Month Trend Overview',
                            style: AcadexTypography.title(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                          Icon(
                            LucideIcons.trendingUp,
                            size: 18,
                            color: AcadexColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 220,
                        child: trendAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => const Center(child: Text('Error loading trend chart')),
                          data: (data) => TrendLineChart(data: data),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Comparison Chart
                AcadexCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Distribution / Department Comparison',
                            style: AcadexTypography.title(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                          Icon(
                            LucideIcons.barChart2,
                            size: 18,
                            color: AcadexColors.accentPurple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 220,
                        child: comparisonAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => const Center(child: Text('Error loading comparison chart')),
                          data: (data) => ComparisonBarChart(data: data),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Insights
                const AcadexSectionHeader(title: 'Key Operational Insights'),
                const SizedBox(height: 12),
                insightsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Error loading insights: $err'),
                  data: (insights) {
                    if (insights.isEmpty) {
                      return const AcadexEmptyState(
                        icon: LucideIcons.lightbulb,
                        title: 'No insights generated',
                        subtitle: 'Insights will automatically generate as more data is recorded.',
                      );
                    }
                    return Column(
                      children: insights.map((insight) => InsightCard(insight: insight)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
