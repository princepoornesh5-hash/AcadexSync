import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class AcadexDataTable extends StatelessWidget {
  final List<String> columns;
  final List<DataRow> rows;
  final bool isLoading;
  final Widget? emptyState;

  const AcadexDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (rows.isEmpty && emptyState != null) {
      return emptyState!;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairlineDark),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
          dataTextStyle: const TextStyle(
            color: AppColors.onDark,
          ),
          dividerThickness: 1,
          columns: columns
              .map((col) => DataColumn(
                    label: Text(col),
                  ))
              .toList(),
          rows: rows,
        ),
      ),
    );
  }
}
