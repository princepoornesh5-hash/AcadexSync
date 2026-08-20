import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/presentation/widgets/acadex_card.dart';

class AttendanceDistributionChart extends StatelessWidget {
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final int unmarkedCount;

  const AttendanceDistributionChart({
    super.key,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
    this.unmarkedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = presentCount + absentCount + lateCount + excusedCount + unmarkedCount;

    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.pieChart, size: 18, color: AcadexColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Attendance Distribution',
                  style: AcadexTypography.heading2(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (total == 0)
            SizedBox(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.pieChart,
                      size: 40,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No attendance records in this period',
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
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    if (presentCount > 0)
                      PieChartSectionData(
                        color: AcadexColors.success,
                        value: presentCount.toDouble(),
                        title: '${((presentCount / total) * 100).toStringAsFixed(0)}%',
                        radius: 28,
                        titleStyle: AcadexTypography.caption(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    if (absentCount > 0)
                      PieChartSectionData(
                        color: AcadexColors.error,
                        value: absentCount.toDouble(),
                        title: '${((absentCount / total) * 100).toStringAsFixed(0)}%',
                        radius: 28,
                        titleStyle: AcadexTypography.caption(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    if (lateCount > 0)
                      PieChartSectionData(
                        color: AcadexColors.warning,
                        value: lateCount.toDouble(),
                        title: '${((lateCount / total) * 100).toStringAsFixed(0)}%',
                        radius: 28,
                        titleStyle: AcadexTypography.caption(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    if (excusedCount > 0)
                      PieChartSectionData(
                        color: const Color(0xFF6366F1), // Indigo
                        value: excusedCount.toDouble(),
                        title: '${((excusedCount / total) * 100).toStringAsFixed(0)}%',
                        radius: 28,
                        titleStyle: AcadexTypography.caption(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    if (unmarkedCount > 0)
                      PieChartSectionData(
                        color: Colors.grey.shade400,
                        value: unmarkedCount.toDouble(),
                        title: '${((unmarkedCount / total) * 100).toStringAsFixed(0)}%',
                        radius: 28,
                        titleStyle: AcadexTypography.caption(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Accessible legend list
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem('Present', presentCount, total, AcadexColors.success, isDark),
                _buildLegendItem('Absent', absentCount, total, AcadexColors.error, isDark),
                _buildLegendItem('Late', lateCount, total, AcadexColors.warning, isDark),
                _buildLegendItem('Excused', excusedCount, total, const Color(0xFF6366F1), isDark),
                if (unmarkedCount > 0)
                  _buildLegendItem('Unmarked', unmarkedCount, total, Colors.grey.shade400, isDark),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, int total, Color color, bool isDark) {
    final pct = total > 0 ? ((count / total) * 100).toStringAsFixed(1) : '0';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count ($pct%)',
          style: AcadexTypography.caption(
            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
