import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/presentation/widgets/acadex_card.dart';
import '../../../domain/models/attendance_analytics_models.dart';

class TrendPoint {
  final String label;
  final double percentage;

  const TrendPoint({required this.label, required this.percentage});
}

class AttendanceTrendChart extends StatelessWidget {
  final String title;
  final List<TrendPoint> trendData;
  final double threshold;

  const AttendanceTrendChart({
    super.key,
    this.title = 'Attendance Trend Over Time',
    required this.trendData,
    this.threshold = AttendanceAnalyticsConstants.lowAttendanceThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.trendingUp, size: 18, color: AcadexColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AcadexTypography.heading2(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (trendData.isEmpty)
            SizedBox(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.trendingUp,
                      size: 40,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No trend data available for selected period',
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < trendData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                trendData[idx].label,
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ).copyWith(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 25,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ).copyWith(fontSize: 10),
                            textAlign: TextAlign.right,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (trendData.length - 1).toDouble().clamp(0.0, double.infinity),
                  minY: 0,
                  maxY: 100,
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: threshold,
                        color: AcadexColors.error.withValues(alpha: 0.6),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 6, bottom: 4),
                          style: AcadexTypography.caption(color: AcadexColors.error).copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                          labelResolver: (line) => '75% Threshold',
                        ),
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < trendData.length; i++)
                          FlSpot(i.toDouble(), trendData[i].percentage),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: AcadexColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isLow = spot.y < threshold;
                          return FlDotCirclePainter(
                            radius: 4,
                            color: isLow ? AcadexColors.error : AcadexColors.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AcadexColors.primary.withValues(alpha: 0.25),
                            AcadexColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
