import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import 'acadex_feedback.dart';

class AcadexDataTable extends StatelessWidget {
  final List<String> columns;
  final List<DataRow> rows;
  final bool isLoading;
  final Widget? emptyState;
  final String? emptyTitle;
  final String? emptySubtitle;

  const AcadexDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyState,
    this.emptyTitle,
    this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return const AcadexLoadingState(message: 'Loading table data...');
    }

    if (rows.isEmpty) {
      if (emptyState != null) return emptyState!;
      return AcadexEmptyState(
        title: emptyTitle ?? 'No data found',
        subtitle: emptySubtitle ?? 'There are no records to display.',
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: ClipRRect(
        borderRadius: AcadexRadius.borderRadiusLg,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 600),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
              ),
              headingTextStyle: AcadexTypography.eyebrow(
                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
              ),
              dataTextStyle: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ),
              horizontalMargin: 20,
              columnSpacing: 28,
              dividerThickness: 1,
              columns: columns
                  .map((col) => DataColumn(
                        label: Text(col),
                      ))
                  .toList(),
              rows: rows,
            ),
          ),
        ),
      ),
    );
  }
}
