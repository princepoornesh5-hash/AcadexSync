import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/analytics_providers.dart';
import '../widgets/analytics_cards.dart';
import '../widgets/charts/trend_line_chart.dart';
import '../widgets/charts/comparison_bar_chart.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final summaryAsync = ref.watch(analyticsSummaryProvider);
    final trendAsync = ref.watch(trendChartProvider);
    final comparisonAsync = ref.watch(comparisonChartProvider);
    final insightsAsync = ref.watch(insightsProvider);
    final projection = ref.watch(studentProjectionProvider);

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: Text('Analytics', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
        backgroundColor: DashboardColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Projection Card for Students
            if (projection != null) ...[
              ProjectionCard(projection: projection),
              const SizedBox(height: 24),
            ],

            // Summary Metrics
            Text('Overview', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
            const SizedBox(height: 12),
            summaryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading metrics', style: GoogleFonts.inter(color: DashboardColors.error)),
              data: (summary) {
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: summary.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    final key = summary.keys.elementAt(index);
                    final value = summary[key]!;
                    return AnalyticsSummaryCard(title: key, value: value);
                  },
                );
              },
            ),
            const SizedBox(height: 28),

            // Charts
            Text('Trends & Comparisons', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
            const SizedBox(height: 12),
            
            // Trend Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DashboardColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DashboardColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('6-Month Trend', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: trendAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => const Center(child: Text('Error loading chart')),
                      data: (data) => TrendLineChart(data: data),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Comparison Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DashboardColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DashboardColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Distribution / Comparison', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: comparisonAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => const Center(child: Text('Error loading chart')),
                      data: (data) => ComparisonBarChart(data: data),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Insights
            Text('Key Insights', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
            const SizedBox(height: 12),
            insightsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading insights', style: GoogleFonts.inter(color: DashboardColors.error)),
              data: (insights) {
                if (insights.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No insights generated for this period.'),
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
    );
  }
}
